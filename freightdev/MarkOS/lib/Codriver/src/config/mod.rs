// Co-Driver Configuration

use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::env;

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct CoDriverConfig {
    pub listen_addr: String,
    pub listen_port: u16,
    pub ollama_url: String,
    pub llama_cpp_url: String,
    pub qdrant_url: String,
}

impl Default for CoDriverConfig {
    fn default() -> Self {
        Self {
            listen_addr: "0.0.0.0".to_string(),
            listen_port: 8001,
            ollama_url: "http://localhost:11434".to_string(),
            llama_cpp_url: "http://localhost:8080".to_string(),
            qdrant_url: "http://localhost:6333".to_string(),
        }
    }
}

impl CoDriverConfig {
    pub async fn load() -> Result<Self> {
        // Try to load from file first
        if let Ok(content) = tokio::fs::read_to_string("config/codriver.toml").await {
            if let Ok(config) = toml::from_str(&content) {
                return Ok(config);
            }
        }

        // Fall back to environment variables
        Ok(Self {
            listen_addr: env::var("CODRIVER_LISTEN_ADDR")
                .unwrap_or_else(|_| "0.0.0.0".to_string()),
            listen_port: env::var("CODRIVER_LISTEN_PORT")
                .unwrap_or_else(|_| "8001".to_string())
                .parse()
                .unwrap_or(8001),
            ollama_url: env::var("OLLAMA_URL")
                .unwrap_or_else(|_| "http://localhost:11434".to_string()),
            llama_cpp_url: env::var("LLAMA_CPP_URL")
                .unwrap_or_else(|_| "http://localhost:8080".to_string()),
            qdrant_url: env::var("QDRANT_URL")
                .unwrap_or_else(|_| "http://localhost:6333".to_string()),
        })
    }
}
