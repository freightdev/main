// lib/ai-crates/mcp-rust/src/lib.rs

pub mod client;
pub mod server;
pub mod protocol;
pub mod config;
pub mod error;
pub mod tools;
pub mod resources;
pub mod discovery;
pub mod integrations;

pub use client::McpClient;
pub use server::McpServer;
pub use config::McpConfig;
pub use error::{McpError, McpResult};
pub use protocol::{Tool, Resource, Message, Request, Response};

use tracing::info;

/// Initialize MCP server with configuration
pub async fn init_server(config_path: Option<&str>) -> McpResult<McpServer> {
    dotenv::dotenv().ok();

    let config = if let Some(path) = config_path {
        McpConfig::from_file(path)?
    } else {
        McpConfig::from_env()?
    };

    info!("Initializing MCP server: {}", config.server.name);
    let server = McpServer::new(config).await?;

    info!("MCP server initialized successfully on {}:{}",
          server.host(), server.port());
    Ok(server)
}

/// Initialize MCP client
pub async fn init_client(config_path: Option<&str>) -> McpResult<McpClient> {
    dotenv::dotenv().ok();

    let config = if let Some(path) = config_path {
        McpConfig::from_file(path)?
    } else {
        McpConfig::from_env()?
    };

    info!("Initializing MCP client");
    let client = McpClient::new(config)?;

    Ok(client)
}

/// Quick start server for plug-and-play usage
pub async fn quick_start_server() -> McpResult<McpServer> {
    init_server(Some("config.toml")).await
}

/// Quick start client for plug-and-play usage
pub async fn quick_start_client() -> McpResult<McpClient> {
    init_client(Some("config.toml")).await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_config_loading() {
        let config = McpConfig::from_file("config.toml");
        assert!(config.is_ok());
    }
}
