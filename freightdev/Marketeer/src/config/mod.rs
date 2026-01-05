// Marketeer Configuration

use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::env;

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct MarketeerConfig {
    pub listen_addr: String,
    pub listen_port: u16,
    pub codriver_url: String,
    pub security: SecurityConfig,
    pub marking: MarkingConfig,
}

#[derive(Debug, Clone, Deserialize, serde::Serialize)]
pub struct SecurityConfig {
    pub enabled: bool,
    pub required_header: String,
    pub api_keys: Vec<String>,
}

#[derive(Debug, Clone, Deserialize, serde::Serialize)]
pub struct MarkingConfig {
    pub enabled: bool,
    pub header_name: String,
    pub prefix: String,
}

impl Default for MarketeerConfig {
    fn default() -> Self {
        Self {
            listen_addr: "0.0.0.0".to_string(),
            listen_port: 8000,
            codriver_url: "http://localhost:8001".to_string(),
            security: SecurityConfig {
                enabled: true,
                required_header: "X-API-Key".to_string(),
                api_keys: vec!["dev-key-change-me".to_string()],
            },
            marking: MarkingConfig {
                enabled: true,
                header_name: "X-Marketeer-Mark".to_string(),
                prefix: "MRK".to_string(),
            },
        }
    }
}

impl MarketeerConfig {
    pub async fn load() -> Result<Self> {
        // Try to load from file first
        if let Ok(content) = tokio::fs::read_to_string("config/marketeer.toml").await {
            if let Ok(config) = toml::from_str(&content) {
                return Ok(config);
            }
        }

        // Fall back to environment variables
        Ok(Self {
            listen_addr: env::var("MARKETEER_LISTEN_ADDR")
                .unwrap_or_else(|_| "0.0.0.0".to_string()),
            listen_port: env::var("MARKETEER_LISTEN_PORT")
                .unwrap_or_else(|_| "8000".to_string())
                .parse()
                .unwrap_or(8000),
            codriver_url: env::var("CODRIVER_URL")
                .unwrap_or_else(|_| "http://localhost:8001".to_string()),
            ..Default::default()
        })
    }
}
