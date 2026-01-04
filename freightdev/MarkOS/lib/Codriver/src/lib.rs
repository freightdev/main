// Co-Driver - API Gateway & AI Orchestrator Library
// Simplified version without RAG+MCP dependencies for now

use anyhow::Result;
use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use tower_http::cors::CorsLayer;
use tracing::{error, info, warn};

pub mod config;
pub mod handlers;
pub mod middleware;
pub mod routes;
pub mod core;

use config::CoDriverConfig;

// Placeholder types for now
pub type RagClient = ();
pub type McpServer = ();

#[derive(Clone)]
pub struct CoDriverState {
    pub config: Arc<CoDriverConfig>,
    pub rag: Arc<RagClient>,
    pub mcp: Arc<McpServer>,
    pub llm_client: Arc<LLMClient>,
    pub agents: Arc<RwLock<HashMap<String, AgentInfo>>>,
}

#[derive(Debug, Clone)]
pub struct LLMClient {
    pub client: Client,
    pub ollama_url: String,
    pub llama_cpp_url: String,
    pub default_provider: LLMProvider,
}

#[derive(Debug, Clone)]
pub enum LLMProvider {
    Ollama,
    LlamaCpp,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentInfo {
    pub name: String,
    pub url: String,
    pub capabilities: Vec<String>,
    pub status: String,
}

#[derive(Debug, Deserialize)]
pub struct TaskRequest {
    pub task: String,
    pub context: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct SearchRequest {
    pub query: String,
    pub top_k: Option<usize>,
}

#[derive(Debug, Deserialize)]
pub struct GenerateRequest {
    pub prompt: String,
    pub provider: Option<String>,
    pub model: Option<String>,
}

pub struct CoDriverApp {
    state: CoDriverState,
}

impl CoDriverApp {
    pub async fn new() -> Result<Self> {
        // Load config
        let config = CoDriverConfig::load().await?;
        info!("📋 Configuration loaded");

        // TODO: Initialize RAG when available
        info!("🔍 RAG system disabled for now");
        let rag = ();

        // TODO: Initialize MCP server when available
        info!("🔗 MCP server disabled for now");
        let mcp = ();

        // Initialize LLM client
        let llm_client = LLMClient::new(config.ollama_url.clone(), config.llama_cpp_url.clone());
        info!("🧠 LLM client initialized");
        info!("  - Ollama: {}", config.ollama_url);
        info!("  - llama.cpp: {}", config.llama_cpp_url);

        // Skip LLM connection verification for now
        info!("⚠ LLM connection verification skipped");

        let state = CoDriverState {
            config: Arc::new(config.clone()),
            rag: Arc::new(rag),
            mcp: Arc::new(mcp),
            llm_client: Arc::new(llm_client),
            agents: Arc::new(RwLock::new(HashMap::new())),
        };

        Ok(Self { state })
    }

    pub async fn run(self) -> Result<()> {
        let addr = format!("{}:{}", self.state.config.listen_addr, self.state.config.listen_port);
        info!("🚀 Co-Driver listening on {}", addr);
        info!("🎯 Ready to orchestrate agents!");

        // Build router
        let app = Router::new()
            .route("/health", get(routes::health_handler))
            .route("/task", post(routes::task_handler))
            .route("/search", post(routes::search_handler))
            .route("/generate", post(routes::generate_handler))
            .route("/agents", get(routes::list_agents_handler))
            .route("/agents/:name", get(routes::agent_info_handler))
            .route("/agents/:name/:tool", post(routes::call_agent_tool_handler))
            .route("/tools", get(routes::list_tools_handler))
            .route("/tools/:name", post(routes::call_tool_handler))
            .layer(CorsLayer::permissive())
            .with_state(self.state);

        let listener = tokio::net::TcpListener::bind(&addr).await?;
        axum::serve(listener, app).await?;

        Ok(())
    }
}

impl LLMClient {
    pub fn new(ollama_url: String, llama_cpp_url: String) -> Self {
        Self {
            client: Client::new(),
            ollama_url,
            llama_cpp_url,
            default_provider: LLMProvider::Ollama,
        }
    }

    pub async fn generate(
        &self,
        prompt: &str,
        provider: Option<LLMProvider>,
        model: Option<&str>,
    ) -> Result<String> {
        warn!("🚫 LLM generation not implemented yet - returning placeholder");
        Ok(format!("LLM response to: {}", &prompt[..prompt.len().min(50)]))
    }
}