// lib/ai-crates/qdrant-rag/src/client.rs

use crate::config::RagConfig;
use crate::embeddings::EmbeddingService;
use crate::error::{RagError, RagResult};
use crate::indexer::Indexer;
use crate::search::{SearchQuery, SearchResult, SearchMetadata};
use qdrant_client::prelude::*;
use qdrant_client::qdrant::{
    CreateCollection, Distance, PointStruct, SearchPoints, VectorParams, VectorsConfig,
};
use std::path::Path;
use tracing::{debug, info, warn};

pub struct RagClient {
    config: RagConfig,
    qdrant: QdrantClient,
    embedding_service: EmbeddingService,
    indexer: Indexer,
}

impl RagClient {
    pub async fn new(config: RagConfig) -> RagResult<Self> {
        info!("Initializing RAG client");
        debug!("Connecting to Qdrant at {}", config.qdrant_url());

        // Connect to Qdrant
        let qdrant = QdrantClient::from_url(&config.qdrant_url())
            .api_key(config.qdrant.api_key.clone())
            .timeout(std::time::Duration::from_secs(config.qdrant.timeout_seconds))
            .build()?;

        // Create embedding service
        let embedding_service = EmbeddingService::new(config.embedding.clone())?;

        // Create indexer
        let indexer = Indexer::new(config.indexing.clone(), config.chunking.clone());

        let client = Self {
            config,
            qdrant,
            embedding_service,
            indexer,
        };

        // Ensure collection exists
        client.ensure_collection().await?;

        info!("RAG client initialized successfully");
        Ok(client)
    }

    async fn ensure_collection(&self) -> RagResult<()> {
        let collection_name = &self.config.collection.name;

        // Check if collection exists
        let collections = self.qdrant.list_collections().await?;
        let exists = collections
            .collections
            .iter()
            .any(|c| c.name == *collection_name);

        if exists {
            info!("Collection '{}' already exists", collection_name);
            return Ok(());
        }

        info!("Creating collection '{}'", collection_name);

        // Create collection
        let distance = match self.config.collection.distance_metric {
            crate::config::DistanceMetric::Cosine => Distance::Cosine,
            crate::config::DistanceMetric::Euclid => Distance::Euclid,
            crate::config::DistanceMetric::Dot => Distance::Dot,
        };

        self.qdrant
            .create_collection(&CreateCollection {
                collection_name: collection_name.clone(),
                vectors_config: Some(VectorsConfig {
                    config: Some(qdrant_client::qdrant::vectors_config::Config::Params(
                        VectorParams {
                            size: self.embedding_service.vector_size() as u64,
                            distance: distance.into(),
                            ..Default::default()
                        },
                    )),
                }),
                ..Default::default()
            })
            .await?;

        info!("Collection '{}' created successfully", collection_name);
        Ok(())
    }

    /// Index a directory
    pub async fn index_directory(&self, path: impl AsRef<Path>) -> RagResult<usize> {
        let path = path.as_ref();
        info!("Indexing directory: {}", path.display());

        // Index files
        let chunks = self.indexer.index_directory(path).await?;
        info!("Generated {} chunks from directory", chunks.len());

        if chunks.is_empty() {
            warn!("No chunks generated from directory");
            return Ok(0);
        }

        // Extract texts for embedding
        let texts: Vec<String> = chunks.iter().map(|c| c.content.clone()).collect();

        // Generate embeddings
        info!("Generating embeddings for {} chunks", texts.len());
        let embeddings = self.embedding_service.embed_batch(texts).await?;

        // Create points for Qdrant
        let points: Vec<PointStruct> = chunks
            .into_iter()
            .zip(embeddings.into_iter())
            .enumerate()
            .map(|(idx, (chunk, embedding))| {
                let id = uuid::Uuid::new_v4().to_string();
                let mut payload = qdrant_client::qdrant::Payload::new();
                payload.insert("file_path", chunk.file_path);
                payload.insert("content", chunk.content);
                payload.insert("line_start", chunk.line_start as i64);
                payload.insert("line_end", chunk.line_end as i64);
                if let Some(crate_name) = chunk.crate_name {
                    payload.insert("crate_name", crate_name);
                }
                if let Some(chunk_type) = chunk.chunk_type {
                    payload.insert("chunk_type", chunk_type);
                }
                if let Some(language) = chunk.language {
                    payload.insert("language", language);
                }

                PointStruct::new(id, embedding, payload)
            })
            .collect();

        // Insert into Qdrant
        info!("Inserting {} points into Qdrant", points.len());
        self.qdrant
            .upsert_points_blocking(&self.config.collection.name, points, None)
            .await?;

        info!("Successfully indexed directory");
        Ok(self.indexer.chunks_generated())
    }

    /// Index a single file
    pub async fn index_file(&self, path: impl AsRef<Path>) -> RagResult<usize> {
        let path = path.as_ref();
        info!("Indexing file: {}", path.display());

        let chunks = self.indexer.index_file(path).await?;

        if chunks.is_empty() {
            return Ok(0);
        }

        let texts: Vec<String> = chunks.iter().map(|c| c.content.clone()).collect();
        let embeddings = self.embedding_service.embed_batch(texts).await?;

        let points: Vec<PointStruct> = chunks
            .into_iter()
            .zip(embeddings.into_iter())
            .map(|(chunk, embedding)| {
                let id = uuid::Uuid::new_v4().to_string();
                let mut payload = qdrant_client::qdrant::Payload::new();
                payload.insert("file_path", chunk.file_path);
                payload.insert("content", chunk.content);
                payload.insert("line_start", chunk.line_start as i64);
                payload.insert("line_end", chunk.line_end as i64);
                if let Some(crate_name) = chunk.crate_name {
                    payload.insert("crate_name", crate_name);
                }
                if let Some(chunk_type) = chunk.chunk_type {
                    payload.insert("chunk_type", chunk_type);
                }
                if let Some(language) = chunk.language {
                    payload.insert("language", language);
                }

                PointStruct::new(id, embedding, payload)
            })
            .collect();

        self.qdrant
            .upsert_points_blocking(&self.config.collection.name, points, None)
            .await?;

        Ok(self.indexer.chunks_generated())
    }

    /// Search for similar content
    pub async fn search(&self, query: SearchQuery) -> RagResult<Vec<SearchResult>> {
        debug!("Searching for: {}", query.text);

        // Generate embedding for query
        let embedding = self.embedding_service.embed(query.text.clone()).await?;

        // Determine search parameters
        let limit = query.top_k.unwrap_or(self.config.search.top_k) as u64;
        let threshold = query.threshold.unwrap_or(self.config.search.score_threshold);

        // Build search request
        let search_points = SearchPoints {
            collection_name: self.config.collection.name.clone(),
            vector: embedding,
            limit,
            with_payload: Some(true.into()),
            score_threshold: Some(threshold),
            ..Default::default()
        };

        // Execute search
        let results = self.qdrant.search_points(&search_points).await?;

        // Convert to SearchResult
        let search_results: Vec<SearchResult> = results
            .result
            .into_iter()
            .map(|point| {
                let payload = point.payload;
                SearchResult {
                    file_path: payload
                        .get("file_path")
                        .and_then(|v| v.as_str())
                        .unwrap_or("unknown")
                        .to_string(),
                    content: payload
                        .get("content")
                        .and_then(|v| v.as_str())
                        .unwrap_or("")
                        .to_string(),
                    score: point.score,
                    metadata: SearchMetadata {
                        crate_name: payload
                            .get("crate_name")
                            .and_then(|v| v.as_str())
                            .map(|s| s.to_string()),
                        line_start: payload
                            .get("line_start")
                            .and_then(|v| v.as_integer())
                            .map(|i| i as usize),
                        line_end: payload
                            .get("line_end")
                            .and_then(|v| v.as_integer())
                            .map(|i| i as usize),
                        chunk_type: payload
                            .get("chunk_type")
                            .and_then(|v| v.as_str())
                            .map(|s| s.to_string()),
                        language: payload
                            .get("language")
                            .and_then(|v| v.as_str())
                            .map(|s| s.to_string()),
                    },
                }
            })
            .collect();

        debug!("Found {} results", search_results.len());
        Ok(search_results)
    }

    /// Clear all data from the collection
    pub async fn clear_collection(&self) -> RagResult<()> {
        info!("Clearing collection: {}", self.config.collection.name);
        self.qdrant
            .delete_collection(&self.config.collection.name)
            .await?;
        self.ensure_collection().await?;
        Ok(())
    }

    /// Get collection info
    pub async fn collection_info(&self) -> RagResult<u64> {
        let info = self
            .qdrant
            .collection_info(&self.config.collection.name)
            .await?;
        Ok(info.result.and_then(|r| r.points_count).unwrap_or(0))
    }
}
