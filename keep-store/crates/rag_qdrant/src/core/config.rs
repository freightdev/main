// lib/ai-crates/qdrant-rag/src/config.rs

use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use crate::error::{RagError, RagResult};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RagConfig {
    pub qdrant: QdrantConfig,
    pub collection: CollectionConfig,
    pub embedding: EmbeddingConfig,
    pub indexing: IndexingConfig,
    pub chunking: ChunkingConfig,
    pub search: SearchConfig,
    pub performance: PerformanceConfig,
    pub metadata: MetadataConfig,
    pub repositories: RepositoriesConfig,
    pub logging: LoggingConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QdrantConfig {
    pub host: String,
    pub port: u16,
    pub api_key: Option<String>,
    pub use_tls: bool,
    pub timeout_seconds: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CollectionConfig {
    pub name: String,
    pub vector_size: usize,
    pub distance_metric: DistanceMetric,
    pub on_disk_payload: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "PascalCase")]
pub enum DistanceMetric {
    Cosine,
    Euclid,
    Dot,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EmbeddingConfig {
    pub provider: EmbeddingProvider,
    pub model: String,
    pub api_key: Option<String>,
    pub api_url: Option<String>,
    pub batch_size: usize,
    pub rate_limit_per_minute: usize,
    pub max_retries: usize,
    pub timeout_seconds: u64,
    pub local: Option<LocalModelConfig>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum EmbeddingProvider {
    OpenAI,
    Anthropic,
    Local,
    Ollama,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LocalModelConfig {
    pub model_path: String,
    pub device: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IndexingConfig {
    pub root_path: PathBuf,
    pub include_patterns: Vec<String>,
    pub exclude_patterns: Vec<String>,
    pub max_file_size_mb: usize,
    pub parallel_workers: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChunkingConfig {
    pub strategy: ChunkingStrategy,
    pub size: usize,
    pub overlap: usize,
    pub min_size: usize,
    pub max_size: usize,
    pub respect_boundaries: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ChunkingStrategy {
    Semantic,
    Fixed,
    Adaptive,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchConfig {
    pub top_k: usize,
    pub score_threshold: f32,
    pub with_payload: bool,
    pub with_vectors: bool,
    pub rerank: bool,
    pub hybrid_search: bool,
    pub filters: Option<SearchFilters>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchFilters {
    pub file_types: Option<Vec<String>>,
    pub paths: Option<Vec<String>>,
    pub exclude_paths: Option<Vec<String>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PerformanceConfig {
    pub max_concurrent_requests: usize,
    pub connection_pool_size: usize,
    pub cache_embeddings: bool,
    pub cache_ttl_seconds: u64,
    pub prefetch_enabled: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MetadataConfig {
    pub include_git_info: bool,
    pub include_file_stats: bool,
    pub include_syntax_tree: bool,
    pub custom_tags: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RepositoriesConfig {
    pub external: Vec<ExternalRepo>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExternalRepo {
    pub name: String,
    pub path: PathBuf,
    pub enabled: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoggingConfig {
    pub level: String,
    pub format: String,
    pub log_file: Option<PathBuf>,
}

impl RagConfig {
    pub fn from_file(path: &str) -> RagResult<Self> {
        let content = std::fs::read_to_string(path)
            .map_err(|e| RagError::ConfigError(format!("Failed to read config file: {}", e)))?;

        let config: RagConfig = toml::from_str(&content)
            .map_err(|e| RagError::ConfigError(format!("Failed to parse config: {}", e)))?;

        Ok(config)
    }

    pub fn from_env() -> RagResult<Self> {
        let qdrant = QdrantConfig {
            host: std::env::var("QDRANT_HOST").unwrap_or_else(|_| "localhost".to_string()),
            port: std::env::var("QDRANT_PORT")
                .unwrap_or_else(|_| "6333".to_string())
                .parse()
                .unwrap_or(6333),
            api_key: std::env::var("QDRANT_API_KEY").ok(),
            use_tls: std::env::var("QDRANT_USE_TLS")
                .unwrap_or_else(|_| "false".to_string())
                .parse()
                .unwrap_or(false),
            timeout_seconds: 30,
        };

        // Build default config with env overrides
        Ok(RagConfig {
            qdrant,
            collection: CollectionConfig {
                name: std::env::var("QDRANT_COLLECTION_NAME")
                    .unwrap_or_else(|_| "codebase".to_string()),
                vector_size: 1536,
                distance_metric: DistanceMetric::Cosine,
                on_disk_payload: false,
            },
            embedding: EmbeddingConfig {
                provider: EmbeddingProvider::Anthropic,
                model: "voyage-2".to_string(),
                api_key: std::env::var("EMBEDDING_API_KEY").ok(),
                api_url: Some("https://api.anthropic.com/v1/embeddings".to_string()),
                batch_size: 100,
                rate_limit_per_minute: 1000,
                max_retries: 3,
                timeout_seconds: 60,
                local: None,
            },
            indexing: IndexingConfig {
                root_path: PathBuf::from("../../"),
                include_patterns: vec!["**/*.rs".to_string(), "**/*.toml".to_string()],
                exclude_patterns: vec!["**/target/**".to_string()],
                max_file_size_mb: 10,
                parallel_workers: 4,
            },
            chunking: ChunkingConfig {
                strategy: ChunkingStrategy::Semantic,
                size: 512,
                overlap: 50,
                min_size: 100,
                max_size: 2048,
                respect_boundaries: vec!["function".to_string()],
            },
            search: SearchConfig {
                top_k: 10,
                score_threshold: 0.7,
                with_payload: true,
                with_vectors: false,
                rerank: false,
                hybrid_search: false,
                filters: None,
            },
            performance: PerformanceConfig {
                max_concurrent_requests: 10,
                connection_pool_size: 10,
                cache_embeddings: true,
                cache_ttl_seconds: 3600,
                prefetch_enabled: true,
            },
            metadata: MetadataConfig {
                include_git_info: false,
                include_file_stats: true,
                include_syntax_tree: false,
                custom_tags: vec![],
            },
            repositories: RepositoriesConfig {
                external: vec![],
            },
            logging: LoggingConfig {
                level: "info".to_string(),
                format: "json".to_string(),
                log_file: None,
            },
        })
    }

    pub fn qdrant_url(&self) -> String {
        let protocol = if self.qdrant.use_tls { "https" } else { "http" };
        format!("{}://{}:{}", protocol, self.qdrant.host, self.qdrant.port)
    }
}
