// lib/ai-crates/mcp-rust/src/config.rs

use crate::error::{McpError, McpResult};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpConfig {
    pub server: ServerConfig,
    pub security: SecurityConfig,
    pub agents: AgentsConfig,
    pub discovery: Option<DiscoveryConfig>,
    pub integrations: IntegrationsConfig,
    pub performance: PerformanceConfig,
    pub logging: LoggingConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerConfig {
    pub name: String,
    pub host: String,
    pub port: u16,
    pub description: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SecurityConfig {
    pub auth_enabled: bool,
    pub auth_token: Option<String>,
    pub cors_origins: Vec<String>,
    pub use_tls: bool,
    pub cert_path: Option<String>,
    pub key_path: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentsConfig {
    pub known: Vec<KnownAgent>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KnownAgent {
    pub name: String,
    pub url: String,
    pub capabilities: Vec<String>,
    pub enabled: bool,
    pub auth_token: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DiscoveryConfig {
    pub enabled: bool,
    pub discovery_type: DiscoveryType,
    pub etcd_endpoints: Option<Vec<String>>,
    pub consul_url: Option<String>,
    pub registry_ttl_seconds: u64,
    pub heartbeat_interval_seconds: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum DiscoveryType {
    Etcd,
    Consul,
    Manual,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IntegrationsConfig {
    pub dragonfly: Option<DragonflyConfig>,
    pub marketeer: Option<MarketeerConfig>,
    pub firecracker: Option<FirecrackerConfig>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DragonflyConfig {
    pub enabled: bool,
    pub host: String,
    pub port: u16,
    pub channel_prefix: String,
    pub subscribe_channels: Vec<String>,
    pub publish_heartbeat: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MarketeerConfig {
    pub enabled: bool,
    pub url: String,
    pub api_key: String,
    pub verify_all_requests: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FirecrackerConfig {
    pub enabled: bool,
    pub socket_path: String,
    pub vm_id_prefix: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PerformanceConfig {
    pub max_connections: usize,
    pub request_timeout_seconds: u64,
    pub rate_limit_per_second: usize,
    pub connection_pool_size: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoggingConfig {
    pub level: String,
    pub format: String,
    pub log_file: Option<String>,
}

impl McpConfig {
    pub fn from_file(path: &str) -> McpResult<Self> {
        let content = std::fs::read_to_string(path)
            .map_err(|e| McpError::ConfigError(format!("Failed to read config file: {}", e)))?;

        let config: McpConfig = toml::from_str(&content)?;
        Ok(config)
    }

    pub fn from_env() -> McpResult<Self> {
        Ok(McpConfig {
            server: ServerConfig {
                name: std::env::var("MCP_SERVER_NAME")
                    .unwrap_or_else(|_| "mcp-agent".to_string()),
                host: std::env::var("MCP_SERVER_HOST")
                    .unwrap_or_else(|_| "0.0.0.0".to_string()),
                port: std::env::var("MCP_SERVER_PORT")
                    .unwrap_or_else(|_| "3000".to_string())
                    .parse()
                    .unwrap_or(3000),
                description: std::env::var("MCP_SERVER_DESCRIPTION")
                    .unwrap_or_else(|_| "MCP Agent".to_string()),
            },
            security: SecurityConfig {
                auth_enabled: std::env::var("MCP_AUTH_ENABLED")
                    .unwrap_or_else(|_| "false".to_string())
                    .parse()
                    .unwrap_or(false),
                auth_token: std::env::var("MCP_AUTH_TOKEN").ok(),
                cors_origins: std::env::var("MCP_CORS_ORIGINS")
                    .unwrap_or_else(|_| "*".to_string())
                    .split(',')
                    .map(|s| s.to_string())
                    .collect(),
                use_tls: false,
                cert_path: None,
                key_path: None,
            },
            agents: AgentsConfig { known: vec![] },
            discovery: None,
            integrations: IntegrationsConfig {
                dragonfly: None,
                marketeer: None,
                firecracker: None,
            },
            performance: PerformanceConfig {
                max_connections: 1000,
                request_timeout_seconds: 30,
                rate_limit_per_second: 100,
                connection_pool_size: 100,
            },
            logging: LoggingConfig {
                level: std::env::var("MCP_LOG_LEVEL")
                    .unwrap_or_else(|_| "info".to_string()),
                format: "json".to_string(),
                log_file: None,
            },
        })
    }

    pub fn server_url(&self) -> String {
        format!("http://{}:{}", self.server.host, self.server.port)
    }
}
