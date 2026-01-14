// lib/ai-crates/qdrant-rag/src/embeddings.rs

use crate::config::{EmbeddingConfig, EmbeddingProvider};
use crate::error::{RagError, RagResult};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::time::Duration;
use tracing::{debug, warn};

#[derive(Debug, Clone)]
pub struct EmbeddingService {
    config: EmbeddingConfig,
    client: Client,
}

#[derive(Debug, Serialize)]
struct OpenAIEmbeddingRequest {
    input: Vec<String>,
    model: String,
}

#[derive(Debug, Deserialize)]
struct OpenAIEmbeddingResponse {
    data: Vec<OpenAIEmbedding>,
}

#[derive(Debug, Deserialize)]
struct OpenAIEmbedding {
    embedding: Vec<f32>,
}

#[derive(Debug, Serialize)]
struct AnthropicEmbeddingRequest {
    texts: Vec<String>,
    model: String,
}

#[derive(Debug, Deserialize)]
struct AnthropicEmbeddingResponse {
    embeddings: Vec<Vec<f32>>,
}

impl EmbeddingService {
    pub fn new(config: EmbeddingConfig) -> RagResult<Self> {
        let client = Client::builder()
            .timeout(Duration::from_secs(config.timeout_seconds))
            .build()
            .map_err(|e| RagError::ConfigError(format!("Failed to build HTTP client: {}", e)))?;

        Ok(Self { config, client })
    }

    /// Generate embeddings for multiple texts
    pub async fn embed_batch(&self, texts: Vec<String>) -> RagResult<Vec<Vec<f32>>> {
        if texts.is_empty() {
            return Ok(vec![]);
        }

        debug!("Generating embeddings for {} texts", texts.len());

        // Process in batches to respect rate limits
        let batch_size = self.config.batch_size;
        let mut all_embeddings = Vec::new();

        for (i, chunk) in texts.chunks(batch_size).enumerate() {
            debug!("Processing batch {}/{}", i + 1, (texts.len() + batch_size - 1) / batch_size);

            let embeddings = self.embed_chunk(chunk.to_vec()).await?;
            all_embeddings.extend(embeddings);

            // Rate limiting: simple sleep between batches
            if i < (texts.len() + batch_size - 1) / batch_size - 1 {
                let sleep_ms = 60000 / self.config.rate_limit_per_minute as u64;
                tokio::time::sleep(Duration::from_millis(sleep_ms)).await;
            }
        }

        Ok(all_embeddings)
    }

    /// Generate embedding for single text
    pub async fn embed(&self, text: String) -> RagResult<Vec<f32>> {
        let embeddings = self.embed_batch(vec![text]).await?;
        embeddings.into_iter().next()
            .ok_or_else(|| RagError::EmbeddingError("No embedding returned".to_string()))
    }

    /// Generate embeddings for a chunk of texts
    async fn embed_chunk(&self, texts: Vec<String>) -> RagResult<Vec<Vec<f32>>> {
        match self.config.provider {
            EmbeddingProvider::OpenAI => self.embed_openai(texts).await,
            EmbeddingProvider::Anthropic => self.embed_anthropic(texts).await,
            EmbeddingProvider::Ollama => self.embed_ollama(texts).await,
            EmbeddingProvider::Local => self.embed_local(texts).await,
        }
    }

    async fn embed_openai(&self, texts: Vec<String>) -> RagResult<Vec<Vec<f32>>> {
        let api_key = self.config.api_key.as_ref()
            .ok_or_else(|| RagError::ConfigError("OpenAI API key not configured".to_string()))?;

        let url = self.config.api_url.as_ref()
            .map(|s| s.as_str())
            .unwrap_or("https://api.openai.com/v1/embeddings");

        let request = OpenAIEmbeddingRequest {
            input: texts,
            model: self.config.model.clone(),
        };

        let response = self.client
            .post(url)
            .header("Authorization", format!("Bearer {}", api_key))
            .header("Content-Type", "application/json")
            .json(&request)
            .send()
            .await?;

        if !response.status().is_success() {
            let status = response.status();
            let body = response.text().await.unwrap_or_default();
            return Err(RagError::EmbeddingError(
                format!("OpenAI API error {}: {}", status, body)
            ));
        }

        let data: OpenAIEmbeddingResponse = response.json().await?;
        Ok(data.data.into_iter().map(|e| e.embedding).collect())
    }

    async fn embed_anthropic(&self, texts: Vec<String>) -> RagResult<Vec<Vec<f32>>> {
        let api_key = self.config.api_key.as_ref()
            .ok_or_else(|| RagError::ConfigError("Anthropic API key not configured".to_string()))?;

        let url = self.config.api_url.as_ref()
            .map(|s| s.as_str())
            .unwrap_or("https://api.anthropic.com/v1/embeddings");

        let request = AnthropicEmbeddingRequest {
            texts,
            model: self.config.model.clone(),
        };

        let response = self.client
            .post(url)
            .header("x-api-key", api_key)
            .header("anthropic-version", "2023-06-01")
            .header("Content-Type", "application/json")
            .json(&request)
            .send()
            .await?;

        if !response.status().is_success() {
            let status = response.status();
            let body = response.text().await.unwrap_or_default();
            return Err(RagError::EmbeddingError(
                format!("Anthropic API error {}: {}", status, body)
            ));
        }

        let data: AnthropicEmbeddingResponse = response.json().await?;
        Ok(data.embeddings)
    }

    async fn embed_ollama(&self, texts: Vec<String>) -> RagResult<Vec<Vec<f32>>> {
        let url = self.config.api_url.as_ref()
            .map(|s| format!("{}/api/embeddings", s))
            .unwrap_or_else(|| "http://localhost:11434/api/embeddings".to_string());

        let mut embeddings = Vec::new();

        for text in texts {
            let request = serde_json::json!({
                "model": self.config.model,
                "prompt": text,
            });

            let response = self.client
                .post(&url)
                .json(&request)
                .send()
                .await?;

            if !response.status().is_success() {
                let status = response.status();
                let body = response.text().await.unwrap_or_default();
                return Err(RagError::EmbeddingError(
                    format!("Ollama API error {}: {}", status, body)
                ));
            }

            let data: serde_json::Value = response.json().await?;
            let embedding: Vec<f32> = data["embedding"]
                .as_array()
                .ok_or_else(|| RagError::EmbeddingError("Invalid Ollama response".to_string()))?
                .iter()
                .filter_map(|v| v.as_f64().map(|f| f as f32))
                .collect();

            embeddings.push(embedding);
        }

        Ok(embeddings)
    }

    async fn embed_local(&self, texts: Vec<String>) -> RagResult<Vec<Vec<f32>>> {
        warn!("Local embedding not implemented yet, falling back to Ollama");
        self.embed_ollama(texts).await
    }

    pub fn vector_size(&self) -> usize {
        // Return expected vector size based on model
        match self.config.provider {
            EmbeddingProvider::OpenAI => {
                if self.config.model.contains("text-embedding-3-large") {
                    3072
                } else if self.config.model.contains("text-embedding-3-small") {
                    1536
                } else if self.config.model.contains("ada-002") {
                    1536
                } else {
                    1536 // default
                }
            }
            EmbeddingProvider::Anthropic => {
                if self.config.model.contains("voyage-2") {
                    1536
                } else {
                    1536 // default
                }
            }
            EmbeddingProvider::Ollama => {
                if self.config.model.contains("nomic-embed-text") {
                    768
                } else {
                    768 // default
                }
            }
            EmbeddingProvider::Local => 768, // default
        }
    }
}
