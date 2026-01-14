// lib/ai-crates/mcp-rust/src/server.rs

use crate::config::McpConfig;
use crate::error::{McpError, McpResult};
use crate::protocol::{Message, Request, Response, Tool, Resource};
use crate::resources::ResourceRegistry;
use crate::tools::ToolRegistry;
use axum::{
    extract::{Path, State},
    http::{HeaderMap, StatusCode},
    response::{IntoResponse, Json},
    routing::{get, post},
    Router,
};
use std::sync::Arc;
use tower_http::cors::CorsLayer;
use tracing::{error, info};

#[derive(Clone)]
pub struct McpServer {
    config: McpConfig,
    tools: ToolRegistry,
    resources: ResourceRegistry,
}

#[derive(Clone)]
struct AppState {
    server: McpServer,
}

impl McpServer {
    pub async fn new(config: McpConfig) -> McpResult<Self> {
        Ok(Self {
            config,
            tools: ToolRegistry::new(),
            resources: ResourceRegistry::new(),
        })
    }

    pub async fn register_tool(&self, tool: Tool) -> McpResult<()> {
        self.tools.register(tool).await
    }

    pub async fn register_resource(&self, resource: Resource) -> McpResult<()> {
        self.resources.register(resource).await
    }

    pub async fn serve(self) -> McpResult<()> {
        let addr = format!("{}:{}", self.config.server.host, self.config.server.port);
        info!("Starting MCP server '{}' on {}", self.config.server.name, addr);

        let state = AppState { server: self };

        let app = Router::new()
            .route("/health", get(health_handler))
            .route("/tools", get(list_tools_handler))
            .route("/tools/:name", post(call_tool_handler))
            .route("/resources", get(list_resources_handler))
            .route("/resources/:name", get(get_resource_handler))
            .route("/info", get(info_handler))
            .layer(CorsLayer::permissive())
            .with_state(Arc::new(state));

        let listener = tokio::net::TcpListener::bind(&addr)
            .await
            .map_err(|e| McpError::ServerError(format!("Failed to bind to {}: {}", addr, e)))?;

        info!("MCP server listening on {}", addr);

        axum::serve(listener, app)
            .await
            .map_err(|e| McpError::ServerError(format!("Server error: {}", e)))?;

        Ok(())
    }

    pub fn host(&self) -> &str {
        &self.config.server.host
    }

    pub fn port(&self) -> u16 {
        self.config.server.port
    }
}

// Health check endpoint
async fn health_handler(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let tools_count = state.server.tools.count().await;
    let resources_count = state.server.resources.count().await;

    Json(serde_json::json!({
        "status": "healthy",
        "agent": state.server.config.server.name,
        "tools": tools_count,
        "resources": resources_count,
    }))
}

// List all tools
async fn list_tools_handler(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let tools = state.server.tools.list().await;
    Json(tools)
}

// Call a tool
async fn call_tool_handler(
    State(state): State<Arc<AppState>>,
    Path(name): Path<String>,
    headers: HeaderMap,
    Json(payload): Json<serde_json::Value>,
) -> impl IntoResponse {
    // Check authentication if enabled
    if state.server.config.security.auth_enabled {
        if let Some(auth_token) = &state.server.config.security.auth_token {
            let provided_token = headers
                .get("authorization")
                .and_then(|h| h.to_str().ok())
                .and_then(|s| s.strip_prefix("Bearer "));

            if provided_token != Some(auth_token.as_str()) {
                return (
                    StatusCode::UNAUTHORIZED,
                    Json(Response::error("Invalid authentication token")),
                )
                    .into_response();
            }
        }
    }

    // Execute tool
    match state.server.tools.execute(&name, payload).await {
        Ok(result) => (StatusCode::OK, Json(Response::success(result))).into_response(),
        Err(e) => {
            error!("Tool execution error: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(Response::error(e.to_string())),
            )
                .into_response()
        }
    }
}

// List all resources
async fn list_resources_handler(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let resources = state.server.resources.list().await;
    Json(resources)
}

// Get a resource
async fn get_resource_handler(
    State(state): State<Arc<AppState>>,
    Path(name): Path<String>,
) -> impl IntoResponse {
    match state.server.resources.get(&name).await {
        Ok(resource) => (StatusCode::OK, Json(resource)).into_response(),
        Err(e) => (
            StatusCode::NOT_FOUND,
            Json(serde_json::json!({"error": e.to_string()})),
        )
            .into_response(),
    }
}

// Server info endpoint
async fn info_handler(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    Json(serde_json::json!({
        "name": state.server.config.server.name,
        "description": state.server.config.server.description,
        "version": env!("CARGO_PKG_VERSION"),
        "tools": state.server.tools.list().await.iter().map(|t| &t.name).collect::<Vec<_>>(),
        "resources": state.server.resources.list().await.iter().map(|r| &r.name).collect::<Vec<_>>(),
    }))
}
