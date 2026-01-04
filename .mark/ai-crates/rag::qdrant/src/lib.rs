// lib/ai-crates/qdrant-rag/src/lib.rs

//! # Qdrant RAG - Production-Ready Semantic Code Search
//!
//! A plug-and-play Rust crate for building production-ready RAG (Retrieval-Augmented Generation)
//! systems using Qdrant vector database.
//!
//! ## Quick Start
//!
//! ```no_run
//! use qdrant_rag::{quick_start, SearchQuery};
//!
//! #[tokio::main]
//! async fn main() -> anyhow::Result<()> {
//!     // Initialize with default config.toml
//!     let client = quick_start().await?;
//!
//!     // Index your codebase
//!     client.index_directory("../../lib/ai-crates").await?;
//!
//!     // Search semantically
//!     let query = SearchQuery::new("How do I generate leads?");
//!     let results = client.search(query).await?;
//!
//!     for result in results {
//!         println!("File: {}", result.file_path);
//!         println!("Score: {:.2}", result.score);
//!         println!("Code: {}\n", result.content);
//!     }
//!
//!     Ok(())
//! }
//! ```

pub mod client;
pub mod config;
pub mod embeddings;
pub mod error;
pub mod indexer;
pub mod search;

pub use client::RagClient;
pub use config::{RagConfig, EmbeddingProvider, ChunkingStrategy};
pub use error::{RagError, RagResult};
pub use search::{SearchQuery, SearchResult, SearchFilter};

use tracing::info;

/// Quick start with default configuration from config.toml
pub async fn quick_start() -> RagResult<RagClient> {
    dotenv::dotenv().ok();

    let config = if std::path::Path::new("config.toml").exists() {
        RagConfig::from_file("config.toml")?
    } else {
        info!("No config.toml found, using environment variables");
        RagConfig::from_env()?
    };

    RagClient::new(config).await
}

/// Initialize RAG client with custom config file
pub async fn from_config(path: &str) -> RagResult<RagClient> {
    dotenv::dotenv().ok();
    let config = RagConfig::from_file(path)?;
    RagClient::new(config).await
}

/// Initialize RAG client from environment variables
pub async fn from_env() -> RagResult<RagClient> {
    dotenv::dotenv().ok();
    let config = RagConfig::from_env()?;
    RagClient::new(config).await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_config_loading() {
        // Test config loading
        let result = RagConfig::from_env();
        assert!(result.is_ok());
    }
}
