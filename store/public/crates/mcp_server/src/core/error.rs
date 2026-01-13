// lib/ai-crates/mcp-rust/src/error.rs

use thiserror::Error;

pub type McpResult<T> = Result<T, McpError>;

#[derive(Error, Debug)]
pub enum McpError {
    #[error("Configuration error: {0}")]
    ConfigError(String),

    #[error("Server error: {0}")]
    ServerError(String),

    #[error("Client error: {0}")]
    ClientError(String),

    #[error("Protocol error: {0}")]
    ProtocolError(String),

    #[error("Tool not found: {0}")]
    ToolNotFound(String),

    #[error("Resource not found: {0}")]
    ResourceNotFound(String),

    #[error("Agent not found: {0}")]
    AgentNotFound(String),

    #[error("Authentication failed: {0}")]
    AuthenticationError(String),

    #[error("Authorization failed: {0}")]
    AuthorizationError(String),

    #[error("Rate limit exceeded: {0}")]
    RateLimitError(String),

    #[error("Request timeout: {0}")]
    TimeoutError(String),

    #[error("Discovery error: {0}")]
    DiscoveryError(String),

    #[error("Integration error: {0}")]
    IntegrationError(String),

    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),

    #[error("HTTP error: {0}")]
    HttpError(#[from] reqwest::Error),

    #[error("JSON error: {0}")]
    JsonError(#[from] serde_json::Error),

    #[error("TOML error: {0}")]
    TomlError(#[from] toml::de::Error),

    #[error("Invalid request: {0}")]
    InvalidRequest(String),

    #[error("Invalid response: {0}")]
    InvalidResponse(String),
}
