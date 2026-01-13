// lib/ai-crates/mcp-rust/src/tools.rs

use crate::error::{McpError, McpResult};
use crate::protocol::Tool;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::{debug, info};

#[derive(Clone)]
pub struct ToolRegistry {
    tools: Arc<RwLock<HashMap<String, Tool>>>,
}

impl ToolRegistry {
    pub fn new() -> Self {
        Self {
            tools: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    pub async fn register(&self, tool: Tool) -> McpResult<()> {
        info!("Registering tool: {}", tool.name);
        let mut tools = self.tools.write().await;
        tools.insert(tool.name.clone(), tool);
        Ok(())
    }

    pub async fn unregister(&self, name: &str) -> McpResult<()> {
        info!("Unregistering tool: {}", name);
        let mut tools = self.tools.write().await;
        tools
            .remove(name)
            .ok_or_else(|| McpError::ToolNotFound(name.to_string()))?;
        Ok(())
    }

    pub async fn get(&self, name: &str) -> McpResult<Tool> {
        let tools = self.tools.read().await;
        tools
            .get(name)
            .cloned()
            .ok_or_else(|| McpError::ToolNotFound(name.to_string()))
    }

    pub async fn list(&self) -> Vec<Tool> {
        let tools = self.tools.read().await;
        tools.values().cloned().collect()
    }

    pub async fn execute(
        &self,
        name: &str,
        parameters: serde_json::Value,
    ) -> McpResult<serde_json::Value> {
        debug!("Executing tool: {} with params: {:?}", name, parameters);

        let tool = self.get(name).await?;

        let handler = tool
            .handler
            .ok_or_else(|| McpError::ServerError(format!("Tool {} has no handler", name)))?;

        let result = handler(parameters)
            .await
            .map_err(|e| McpError::ServerError(format!("Tool execution failed: {}", e)))?;

        Ok(result)
    }

    pub async fn count(&self) -> usize {
        let tools = self.tools.read().await;
        tools.len()
    }

    pub async fn exists(&self, name: &str) -> bool {
        let tools = self.tools.read().await;
        tools.contains_key(name)
    }
}

impl Default for ToolRegistry {
    fn default() -> Self {
        Self::new()
    }
}
