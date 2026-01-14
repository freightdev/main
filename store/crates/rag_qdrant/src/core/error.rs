// lib/ai-crates/qdrant-rag/src/error.rs

use thiserror::Error;

pub type RagResult<T> = Result<T, RagError>;

#[derive(Error, Debug)]
pub enum RagError {
    #[error("Configuration error: {0}")]
    ConfigError(String),

    #[error("Qdrant client error: {0}")]
    QdrantError(String),

    #[error("Embedding generation error: {0}")]
    EmbeddingError(String),

    #[error("Indexing error: {0}")]
    IndexingError(String),

    #[error("Search error: {0}")]
    SearchError(String),

    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),

    #[error("HTTP error: {0}")]
    HttpError(#[from] reqwest::Error),

    #[error("JSON serialization error: {0}")]
    JsonError(#[from] serde_json::Error),

    #[error("Collection not found: {0}")]
    CollectionNotFound(String),

    #[error("Invalid vector dimension: expected {expected}, got {actual}")]
    InvalidVectorDimension { expected: usize, actual: usize },

    #[error("Rate limit exceeded, retry after {retry_after} seconds")]
    RateLimitExceeded { retry_after: u64 },

    #[error("Invalid configuration: {0}")]
    InvalidConfig(String),

    #[error("Parse error: {0}")]
    ParseError(String),

    #[error("Timeout error: operation took longer than {timeout_seconds}s")]
    TimeoutError { timeout_seconds: u64 },
}

impl From<qdrant_client::QdrantError> for RagError {
    fn from(err: qdrant_client::QdrantError) -> Self {
        RagError::QdrantError(err.to_string())
    }
}
