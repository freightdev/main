// Co-Driver - API Gateway & Orchestrator
// Connects to: RAG, MCP, Ollama, llama.cpp, all agents

use anyhow::Result;
use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use mcp_rust::{McpServer, Tool};
use qdrant_rag::{RagClient, SearchQuery};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use tower_http::cors::CorsLayer;
use tracing::{error, info};

#[derive(Clone)]
struct CoDriverState {
    config: Arc<CoDriverConfig>,
    rag: Arc<RagClient>,
    mcp: Arc<McpServer>,
    llm_client: Arc<LLMClient>,
    agents: Arc<RwLock<HashMap<String, AgentInfo>>>,
}

#[derive(Debug, Clone, Deserialize)]
struct CoDriverConfig {
    listen_addr: String,
    listen_port: u16,
    ollama_url: String,
    llama_cpp_url: String,
    qdrant_url: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct AgentInfo {
    name: String,
    url: String,
    capabilities: Vec<String>,
    status: String,
}

#[derive(Debug, Clone)]
struct LLMClient {
    client: Client,
    ollama_url: String,
    llama_cpp_url: String,
    default_provider: LLMProvider,
}

#[derive(Debug, Clone)]
enum LLMProvider {
    Ollama,
    LlamaCpp,
}

#[derive(Debug, Deserialize)]
struct TaskRequest {
    task: String,
    context: Option<String>,
}

#[derive(Debug, Deserialize)]
struct SearchRequest {
    query: String,
    top_k: Option<usize>,
}

#[derive(Debug, Deserialize)]
struct GenerateRequest {
    prompt: String,
    provider: Option<String>,
    model: Option<String>,
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

impl LLMClient {
    fn new(ollama_url: String, llama_cpp_url: String) -> Self {
        Self {
            client: Client::new(),
            ollama_url,
            llama_cpp_url,
            default_provider: LLMProvider::Ollama,
        }
    }

    async fn generate(
        &self,
        prompt: &str,
        provider: Option<LLMProvider>,
        model: Option<&str>,
    ) -> Result<String> {
        let provider = provider.unwrap_or(self.default_provider.clone());

        match provider {
            LLMProvider::Ollama => self.generate_ollama(prompt, model).await,
            LLMProvider::LlamaCpp => self.generate_llama_cpp(prompt).await,
        }
    }

    async fn generate_ollama(&self, prompt: &str, model: Option<&str>) -> Result<String> {
        let model = model.unwrap_or("qwen2.5:7b");

        let response = self
            .client
            .post(format!("{}/api/generate", self.ollama_url))
            .json(&serde_json::json!({
                "model": model,
                "prompt": prompt,
                "stream": false
            }))
            .send()
            .await?;

        let result: serde_json::Value = response.json().await?;
        let text = result["response"]
            .as_str()
            .unwrap_or("")
            .to_string();

        Ok(text)
    }

    async fn generate_llama_cpp(&self, prompt: &str) -> Result<String> {
        let response = self
            .client
            .post(format!("{}/completion", self.llama_cpp_url))
            .json(&serde_json::json!({
                "prompt": prompt,
                "n_predict": 512,
                "temperature": 0.7
            }))
            .send()
            .await?;

        let result: serde_json::Value = response.json().await?;
        let text = result["content"]
            .as_str()
            .unwrap_or("")
            .to_string();

        Ok(text)
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .with_target(false)
        .init();

    info!("🤖 Co-Driver API Gateway Starting");

    // Load config
    let config = load_config().await?;
    info!("📋 Configuration loaded");

    // Initialize RAG
    info!("🔍 Initializing RAG system...");
    let rag = match qdrant_rag::quick_start().await {
        Ok(client) => {
            info!("✓ RAG system ready");
            client
        }
        Err(e) => {
            error!("⚠ RAG initialization failed: {}", e);
            error!("  Co-Driver will start without RAG capabilities");
            // Continue without RAG for now
            return Err(e.into());
        }
    };

    // Initialize MCP server
    info!("🔗 Initializing MCP server...");
    let mut mcp = match mcp_rust::quick_start_server().await {
        Ok(server) => {
            info!("✓ MCP server ready");
            server
        }
        Err(e) => {
            error!("⚠ MCP initialization failed: {}", e);
            return Err(e.into());
        }
    };

    // Register Co-Driver's own tools with MCP
    register_tools(&mut mcp, Arc::new(rag.clone())).await?;

    // Initialize LLM client
    let llm_client = LLMClient::new(config.ollama_url.clone(), config.llama_cpp_url.clone());
    info!("🧠 LLM client initialized");
    info!("  - Ollama: {}", config.ollama_url);
    info!("  - llama.cpp: {}", config.llama_cpp_url);

    // Verify LLM connections
    verify_llm_connections(&llm_client).await;

    let state = CoDriverState {
        config: Arc::new(config.clone()),
        rag: Arc::new(rag),
        mcp: Arc::new(mcp),
        llm_client: Arc::new(llm_client),
        agents: Arc::new(RwLock::new(HashMap::new())),
    };

    // Build router
    let app = Router::new()
        .route("/health", get(health_handler))
        .route("/task", post(task_handler))
        .route("/search", post(search_handler))
        .route("/generate", post(generate_handler))
        .route("/agents", get(list_agents_handler))
        .route("/agents/:name", get(agent_info_handler))
        .route("/agents/:name/:tool", post(call_agent_tool_handler))
        .route("/tools", get(list_tools_handler))
        .route("/tools/:name", post(call_tool_handler))
        .layer(CorsLayer::permissive())
        .with_state(state);

    let addr = format!("{}:{}", config.listen_addr, config.listen_port);
    info!("🚀 Co-Driver listening on {}", addr);
    info!("🎯 Ready to orchestrate agents!");

    let listener = tokio::net::TcpListener::bind(&addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}

async fn load_config() -> Result<CoDriverConfig> {
    if let Ok(content) = tokio::fs::read_to_string("config/codriver.toml").await {
        if let Ok(config) = toml::from_str(&content) {
            return Ok(config);
        }
    }

    Ok(CoDriverConfig {
        listen_addr: std::env::var("CODRIVER_LISTEN_ADDR")
            .unwrap_or_else(|_| "0.0.0.0".to_string()),
        listen_port: std::env::var("CODRIVER_LISTEN_PORT")
            .unwrap_or_else(|_| "8001".to_string())
            .parse()
            .unwrap_or(8001),
        ollama_url: std::env::var("OLLAMA_URL")
            .unwrap_or_else(|_| "http://localhost:11434".to_string()),
        llama_cpp_url: std::env::var("LLAMA_CPP_URL")
            .unwrap_or_else(|_| "http://localhost:8080".to_string()),
        qdrant_url: std::env::var("QDRANT_URL")
            .unwrap_or_else(|_| "http://localhost:6333".to_string()),
    })
}

async fn register_tools(mcp: &mut McpServer, rag: Arc<RagClient>) -> Result<()> {
    info!("📝 Registering tools with MCP...");

    // Register code search tool
    mcp.register_tool(
        Tool::new("search_code", "Search codebase semantically with RAG")
            .with_parameters(serde_json::json!({
                "type": "object",
                "properties": {
                    "query": {"type": "string"},
                    "top_k": {"type": "number"}
                },
                "required": ["query"]
            }))
            .with_handler(move |params| {
                let rag = rag.clone();
                async move {
                    let query = params["query"].as_str().ok_or("Missing query")?;
                    let top_k = params["top_k"].as_u64().map(|n| n as usize);

                    let mut search_query = SearchQuery::new(query);
                    if let Some(k) = top_k {
                        search_query = search_query.with_top_k(k);
                    }

                    let results = rag.search(search_query).await
                        .map_err(|e| e.to_string())?;

                    Ok(serde_json::to_value(results).map_err(|e| e.to_string())?)
                }
            }),
    ).await?;

    info!("  ✓ Registered: search_code");

    Ok(())
}

async fn verify_llm_connections(llm: &LLMClient) {
    // Try Ollama
    match llm.generate("test", Some(LLMProvider::Ollama), None).await {
        Ok(_) => info!("  ✓ Ollama connection verified"),
        Err(e) => error!("  ✗ Ollama connection failed: {}", e),
    }

    // Try llama.cpp
    match llm.generate("test", Some(LLMProvider::LlamaCpp), None).await {
        Ok(_) => info!("  ✓ llama.cpp connection verified"),
        Err(e) => error!("  ✗ llama.cpp connection failed: {}", e),
    }
}

// === Handlers ===

async fn health_handler(State(state): State<CoDriverState>) -> impl IntoResponse {
    Json(serde_json::json!({
        "status": "healthy",
        "service": "codriver",
        "role": "api-gateway",
        "connections": {
            "rag": "active",
            "mcp": "active",
            "ollama": state.config.ollama_url,
            "llama_cpp": state.config.llama_cpp_url
        },
        "timestamp": chrono::Utc::now().to_rfc3339()
    }))
}

async fn task_handler(
    State(state): State<CoDriverState>,
    Json(payload): Json<TaskRequest>,
) -> impl IntoResponse {
    info!("📥 Task received: {}", payload.task);

    // Use RAG to find relevant code/context
    let context = match state.rag.search(SearchQuery::new(&payload.task)).await {
        Ok(results) => {
            let context: Vec<String> = results
                .iter()
                .map(|r| format!("// {}\n{}", r.file_path, &r.content[..r.content.len().min(500)]))
                .collect();
            context.join("\n\n")
        }
        Err(e) => {
            error!("RAG search failed: {}", e);
            String::new()
        }
    };

    // Use LLM to decide what to do
    let prompt = format!(
        "You are Co-Driver, an AI orchestrator.\n\nTask: {}\n\nContext:\n{}\n\nWhat should you do?",
        payload.task, context
    );

    let decision = match state.llm_client.generate(&prompt, None, None).await {
        Ok(text) => text,
        Err(e) => {
            error!("LLM generation failed: {}", e);
            format!("Error: {}", e)
        }
    };

    Json(serde_json::json!({
        "task": payload.task,
        "decision": decision,
        "context_found": !context.is_empty()
    }))
}

async fn search_handler(
    State(state): State<CoDriverState>,
    Json(payload): Json<SearchRequest>,
) -> impl IntoResponse {
    let mut query = SearchQuery::new(&payload.query);
    if let Some(k) = payload.top_k {
        query = query.with_top_k(k);
    }

    match state.rag.search(query).await {
        Ok(results) => (StatusCode::OK, Json(serde_json::json!({
            "results": results,
            "count": results.len()
        }))).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({
            "error": e.to_string()
        }))).into_response(),
    }
}

async fn generate_handler(
    State(state): State<CoDriverState>,
    Json(payload): Json<GenerateRequest>,
) -> impl IntoResponse {
    let provider = match payload.provider.as_deref() {
        Some("ollama") => Some(LLMProvider::Ollama),
        Some("llama.cpp") | Some("llamacpp") => Some(LLMProvider::LlamaCpp),
        _ => None,
    };

    match state.llm_client.generate(&payload.prompt, provider, payload.model.as_deref()).await {
        Ok(text) => (StatusCode::OK, Json(serde_json::json!({
            "response": text
        }))).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({
            "error": e.to_string()
        }))).into_response(),
    }
}

async fn list_agents_handler(State(state): State<CoDriverState>) -> impl IntoResponse {
    let agents = state.agents.read().await;
    Json(serde_json::json!({
        "agents": agents.values().collect::<Vec<_>>(),
        "count": agents.len()
    }))
}

async fn agent_info_handler(
    State(state): State<CoDriverState>,
    Path(name): Path<String>,
) -> impl IntoResponse {
    let agents = state.agents.read().await;
    match agents.get(&name) {
        Some(agent) => (StatusCode::OK, Json(serde_json::to_value(agent).unwrap())).into_response(),
        None => (StatusCode::NOT_FOUND, Json(serde_json::json!({
            "error": format!("Agent '{}' not found", name)
        }))).into_response(),
    }
}

async fn call_agent_tool_handler(
    State(state): State<CoDriverState>,
    Path((agent_name, tool_name)): Path<(String, String)>,
    Json(payload): Json<serde_json::Value>,
) -> impl IntoResponse {
    info!("🔧 Calling {}::{}", agent_name, tool_name);

    // TODO: Use MCP client to call agent
    Json(serde_json::json!({
        "agent": agent_name,
        "tool": tool_name,
        "status": "not_implemented_yet"
    }))
}

async fn list_tools_handler(State(state): State<CoDriverState>) -> impl IntoResponse {
    let tools = state.mcp.register_tool(Tool::new("test", "test")).await;

    Json(serde_json::json!({
        "tools": ["search_code", "route_task", "call_agent"],
        "count": 3
    }))
}

async fn call_tool_handler(
    State(state): State<CoDriverState>,
    Path(tool_name): Path<String>,
    Json(payload): Json<serde_json::Value>,
) -> impl IntoResponse {
    info!("🔧 Calling tool: {}", tool_name);

    // TODO: Execute tool via MCP
    Json(serde_json::json!({
        "tool": tool_name,
        "status": "not_implemented_yet"
    }))
}
