// Co-Driver HTTP Routes

use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use crate::{CoDriverState, GenerateRequest, SearchRequest, TaskRequest};
use serde_json::json;
use tracing::{error, info, warn};

pub async fn health_handler(State(state): State<CoDriverState>) -> impl IntoResponse {
    Json(json!({
        "status": "healthy",
        "service": "codriver",
        "role": "api-gateway",
        "connections": {
            "rag": "disabled",
            "mcp": "disabled",
            "ollama": state.config.ollama_url,
            "llama_cpp": state.config.llama_cpp_url
        },
        "timestamp": chrono::Utc::now().to_rfc3339()
    }))
}

pub async fn task_handler(
    State(state): State<CoDriverState>,
    Json(payload): Json<TaskRequest>,
) -> impl IntoResponse {
    info!("📥 Task received: {}", payload.task);

    // TODO: Use RAG to find relevant code/context
    warn!("🔍 RAG search disabled - using placeholder context");

    // TODO: Use LLM to decide what to do
    let decision = match state.llm_client.generate(&payload.task, None, None).await {
        Ok(text) => text,
        Err(e) => {
            error!("LLM generation failed: {}", e);
            format!("Error: {}", e)
        }
    };

    Json(json!({
        "task": payload.task,
        "decision": decision,
        "context_found": false
    }))
}

pub async fn search_handler(
    State(_state): State<CoDriverState>,
    Json(payload): Json<SearchRequest>,
) -> impl IntoResponse {
    warn!("🔍 Search disabled for now - returning placeholder");
    
    (StatusCode::OK, Json(json!({
        "results": [],
        "count": 0,
        "message": "Search disabled until RAG is implemented",
        "query": payload.query
    }))).into_response()
}

pub async fn generate_handler(
    State(state): State<CoDriverState>,
    Json(payload): Json<GenerateRequest>,
) -> impl IntoResponse {
    match state.llm_client.generate(&payload.prompt, None, payload.model.as_deref()).await {
        Ok(text) => (StatusCode::OK, Json(json!({
            "response": text
        }))).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, Json(json!({
            "error": e.to_string()
        }))).into_response(),
    }
}

pub async fn list_agents_handler(State(state): State<CoDriverState>) -> impl IntoResponse {
    let agents = state.agents.read().await;
    Json(json!({
        "agents": agents.values().collect::<Vec<_>>(),
        "count": agents.len()
    }))
}

pub async fn agent_info_handler(
    State(state): State<CoDriverState>,
    Path(name): Path<String>,
) -> impl IntoResponse {
    let agents = state.agents.read().await;
    match agents.get(&name) {
        Some(agent) => (StatusCode::OK, Json(serde_json::to_value(agent).unwrap())).into_response(),
        None => (StatusCode::NOT_FOUND, Json(json!({
            "error": format!("Agent '{}' not found", name)
        }))).into_response(),
    }
}

pub async fn call_agent_tool_handler(
    State(_state): State<CoDriverState>,
    Path((agent_name, tool_name)): Path<(String, String)>,
    Json(_payload): Json<serde_json::Value>,
) -> impl IntoResponse {
    info!("🔧 Calling {}::{}", agent_name, tool_name);

    // TODO: Use MCP client to call agent
    Json(json!({
        "agent": agent_name,
        "tool": tool_name,
        "status": "not_implemented_yet"
    }))
}

pub async fn list_tools_handler(State(_state): State<CoDriverState>) -> impl IntoResponse {
    Json(json!({
        "tools": ["search_code", "route_task", "call_agent"],
        "count": 3
    }))
}

pub async fn call_tool_handler(
    State(_state): State<CoDriverState>,
    Path(tool_name): Path<String>,
    Json(_payload): Json<serde_json::Value>,
) -> impl IntoResponse {
    info!("🔧 Calling tool: {}", tool_name);

    // TODO: Execute tool via MCP
    Json(json!({
        "tool": tool_name,
        "status": "not_implemented_yet"
    }))
}