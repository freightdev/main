// lib/ai-crates/mcp-rust/src/protocol.rs

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;

/// MCP Protocol Message
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Message {
    pub id: String,
    pub message_type: MessageType,
    pub payload: serde_json::Value,
    pub timestamp: i64,
    pub sender: String,
    pub recipient: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum MessageType {
    Request,
    Response,
    Event,
    Error,
}

impl Message {
    pub fn new_request(sender: String, recipient: String, payload: serde_json::Value) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            message_type: MessageType::Request,
            payload,
            timestamp: chrono::Utc::now().timestamp(),
            sender,
            recipient: Some(recipient),
        }
    }

    pub fn new_response(request_id: String, sender: String, payload: serde_json::Value) -> Self {
        Self {
            id: request_id,
            message_type: MessageType::Response,
            payload,
            timestamp: chrono::Utc::now().timestamp(),
            sender,
            recipient: None,
        }
    }

    pub fn new_event(sender: String, payload: serde_json::Value) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            message_type: MessageType::Event,
            payload,
            timestamp: chrono::Utc::now().timestamp(),
            sender,
            recipient: None,
        }
    }

    pub fn new_error(request_id: String, sender: String, error: String) -> Self {
        Self {
            id: request_id,
            message_type: MessageType::Error,
            payload: serde_json::json!({ "error": error }),
            timestamp: chrono::Utc::now().timestamp(),
            sender,
            recipient: None,
        }
    }
}

/// Tool definition for MCP
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Tool {
    pub name: String,
    pub description: String,
    pub parameters: serde_json::Value,
    #[serde(skip)]
    pub handler: Option<ToolHandler>,
}

pub type ToolHandler = std::sync::Arc<
    dyn Fn(serde_json::Value) -> std::pin::Pin<Box<dyn std::future::Future<Output = Result<serde_json::Value, String>> + Send>>
        + Send
        + Sync,
>;

impl Tool {
    pub fn new(name: impl Into<String>, description: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            description: description.into(),
            parameters: serde_json::json!({}),
            handler: None,
        }
    }

    pub fn with_parameters(mut self, parameters: serde_json::Value) -> Self {
        self.parameters = parameters;
        self
    }

    pub fn with_handler<F, Fut>(mut self, handler: F) -> Self
    where
        F: Fn(serde_json::Value) -> Fut + Send + Sync + 'static,
        Fut: std::future::Future<Output = Result<serde_json::Value, String>> + Send + 'static,
    {
        self.handler = Some(std::sync::Arc::new(move |params| Box::pin(handler(params))));
        self
    }
}

/// Resource definition for MCP
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Resource {
    pub name: String,
    pub resource_type: String,
    pub uri: String,
    pub metadata: serde_json::Value,
}

impl Resource {
    pub fn new(
        name: impl Into<String>,
        resource_type: impl Into<String>,
        uri: impl Into<String>,
    ) -> Self {
        Self {
            name: name.into(),
            resource_type: resource_type.into(),
            uri: uri.into(),
            metadata: serde_json::json!({}),
        }
    }

    pub fn with_metadata(mut self, metadata: serde_json::Value) -> Self {
        self.metadata = metadata;
        self
    }
}

/// Request sent to call a tool
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Request {
    pub tool_name: String,
    pub parameters: serde_json::Value,
}

/// Response from a tool call
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Response {
    pub success: bool,
    pub data: Option<serde_json::Value>,
    pub error: Option<String>,
}

impl Response {
    pub fn success(data: serde_json::Value) -> Self {
        Self {
            success: true,
            data: Some(data),
            error: None,
        }
    }

    pub fn error(error: impl Into<String>) -> Self {
        Self {
            success: false,
            data: None,
            error: Some(error.into()),
        }
    }
}

/// Agent information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentInfo {
    pub name: String,
    pub url: String,
    pub capabilities: Vec<String>,
    pub tools: Vec<String>,
    pub resources: Vec<String>,
    pub status: AgentStatus,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum AgentStatus {
    Online,
    Offline,
    Busy,
    Error,
}
