// Marketeer - Edge Router Library

use anyhow::Result;
use axum::{
    extract::{Request, State},
    http::{HeaderMap, StatusCode},
    middleware::Next,
    response::{IntoResponse, Response},
    routing::{get, post},
    Json, Router,
    middleware,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use std::time::Duration;
use tokio::time::Instant;
use tower_http::cors::CorsLayer;
use tracing::{error, info, warn};
use uuid::Uuid;

pub mod config;
// pub mod middleware;
pub mod pingora_router;

use config::MarketeerConfig;

#[derive(Clone)]
pub struct MarketeerState {
    pub config: Arc<MarketeerConfig>,
    pub client: reqwest::Client,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct MarkedRequest {
    pub mark_id: String,
    pub original_path: String,
    pub method: String,
    pub timestamp: i64,
    pub source_ip: Option<String>,
    pub verified: bool,
}

pub struct MarketeerApp {
    state: MarketeerState,
}

impl MarketeerApp {
    pub async fn new() -> Result<Self> {
        // Load config
        let config = MarketeerConfig::load().await?;
        info!("📋 Configuration loaded");

        // Create HTTP client for proxying
        let client = reqwest::Client::builder()
            .timeout(Duration::from_secs(30))
            .build()?;

        let addr = format!("{}:{}", config.listen_addr, config.listen_port);
        let state = MarketeerState {
            config: Arc::new(config),
            client,
        };

        Ok(Self { state })
    }

    pub async fn run(self) -> Result<()> {
        let state = self.state.clone();
        let config = state.config.clone();
        
        // Build router
        let app = Router::new()
            .route("/health", get(health_handler))
            .route("/mark", post(mark_request_handler))
            .route("/verify/:mark_id", get(verify_mark_handler))
            .route("/metrics", get(metrics_handler))
            .fallback(proxy_handler)
            .layer(middleware::from_fn_with_state(
                state.clone(),
                security_middleware,
            ))
            .layer(middleware::from_fn(logging_middleware))
            .layer(CorsLayer::permissive())
            .with_state(state);

        let addr = format!("{}:{}", config.listen_addr, config.listen_port);
        info!("🚀 Marketeer listening on {}", addr);
        info!("🎯 Routing to Co-Driver at {}", config.codriver_url);
        info!("🔐 Security: {}", if config.security.enabled { "ENABLED" } else { "DISABLED" });
        info!("🏷️  Request marking: {}", if config.marking.enabled { "ENABLED" } else { "DISABLED" });

        let listener = tokio::net::TcpListener::bind(&addr).await?;
        axum::serve(listener, app).await?;

        Ok(())
    }
}

// Security middleware
async fn security_middleware(
    State(state): State<MarketeerState>,
    headers: HeaderMap,
    request: Request,
    next: Next,
) -> Result<Response, StatusCode> {
    if !state.config.security.enabled {
        return Ok(next.run(request).await);
    }

    // Check for API key
    let api_key = headers
        .get(&state.config.security.required_header)
        .and_then(|v| v.to_str().ok());

    if let Some(key) = api_key {
        if state.config.security.api_keys.contains(&key.to_string()) {
            return Ok(next.run(request).await);
        }
    }

    warn!("🚫 Unauthorized request blocked");
    Err(StatusCode::UNAUTHORIZED)
}

// Logging middleware
async fn logging_middleware(request: Request, next: Next) -> Response {
    let start = Instant::now();
    let method = request.method().clone();
    let uri = request.uri().clone();

    let response = next.run(request).await;

    let duration = start.elapsed();
    let status = response.status();

    info!(
        "{} {} {} - {:?}",
        method,
        uri,
        status.as_u16(),
        duration
    );

    response
}

// Health check
async fn health_handler() -> impl IntoResponse {
    Json(serde_json::json!({
        "status": "healthy",
        "service": "marketeer",
        "role": "edge-router",
        "timestamp": chrono::Utc::now().to_rfc3339()
    }))
}

// Mark a request for tracking
async fn mark_request_handler(
    State(state): State<MarketeerState>,
    Json(payload): Json<serde_json::Value>,
) -> impl IntoResponse {
    if !state.config.marking.enabled {
        return (
            StatusCode::BAD_REQUEST,
            Json(serde_json::json!({"error": "Marking not enabled"})),
        );
    }

    let mark_id = format!("{}-{}", state.config.marking.prefix, Uuid::new_v4());

    let marked = MarkedRequest {
        mark_id: mark_id.clone(),
        original_path: payload["path"].as_str().unwrap_or("/").to_string(),
        method: payload["method"].as_str().unwrap_or("GET").to_string(),
        timestamp: chrono::Utc::now().timestamp(),
        source_ip: payload["source_ip"].as_str().map(|s| s.to_string()),
        verified: true,
    };

    info!("🏷️  Marked request: {}", mark_id);

    (StatusCode::OK, Json(serde_json::json!({
        "mark_id": marked.mark_id,
        "verified": marked.verified,
        "timestamp": marked.timestamp
    })))
}

// Verify a mark
async fn verify_mark_handler(
    axum::extract::Path(mark_id): axum::extract::Path<String>,
) -> impl IntoResponse {
    // TODO: Look up mark in database
    // For now, just check format
    let valid = mark_id.starts_with("MRK-");

    Json(serde_json::json!({
        "mark_id": mark_id,
        "valid": valid,
        "verified": valid
    }))
}

// Metrics endpoint
async fn metrics_handler() -> impl IntoResponse {
    // TODO: Implement Prometheus metrics
    "# Marketeer metrics coming soon\n"
}

// Main proxy handler - forwards everything to Co-Driver
async fn proxy_handler(
    State(state): State<MarketeerState>,
    method: axum::http::Method,
    uri: axum::http::Uri,
    headers: HeaderMap,
    body: String,
) -> Result<Response, StatusCode> {
    let target_url = format!("{}{}", state.config.codriver_url, uri.path());

    info!("🔀 Proxying {} {} to Co-Driver", method, uri.path());

    // TODO: Add marking header when enabled
    // For now, just clone headers
    let req_headers = headers.clone();

    // Forward request to Co-Driver
    use reqwest::Method as ReqMethod;
    use axum::http::Method as AxumMethod;
    
    let reqwest_method = match method {
        AxumMethod::GET => ReqMethod::GET,
        AxumMethod::POST => ReqMethod::POST,
        AxumMethod::PUT => ReqMethod::PUT,
        AxumMethod::DELETE => ReqMethod::DELETE,
        AxumMethod::PATCH => ReqMethod::PATCH,
        _ => ReqMethod::GET,
    };

    let client_request = state
        .client
        .request(reqwest_method, &target_url)
        .body(body)
        .timeout(Duration::from_secs(30));

    match client_request.send().await {
        Ok(response) => {
            let status = response.status();
            let body = response.text().await.unwrap_or_default();
            
            use axum::http::StatusCode as AxumStatus;
            let axum_status = match status.as_u16() {
                200 => AxumStatus::OK,
                404 => AxumStatus::NOT_FOUND,
                500 => AxumStatus::INTERNAL_SERVER_ERROR,
                _ => AxumStatus::INTERNAL_SERVER_ERROR,
            };

            Ok((axum_status, body).into_response())
        }
        Err(e) => {
            error!("❌ Proxy error: {}", e);
            Err(StatusCode::BAD_GATEWAY)
        }
    }
}