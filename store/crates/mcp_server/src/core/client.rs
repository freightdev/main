// lib/ai-crates/mcp-rust/src/client.rs

use crate::config::McpConfig;
use crate::error::{McpError, McpResult};
use crate::protocol::{Request, Response, Tool, Resource};
use reqwest::Client;
use std::time::Duration;
use tracing::{debug, info};

pub struct McpClient {
    config: McpConfig,
    client: Client,
}

impl McpClient {
    pub fn new(config: McpConfig) -> McpResult<Self> {
        let client = Client::builder()
            .timeout(Duration::from_secs(config.performance.request_timeout_seconds))
            .build()
            .map_err(|e| McpError::ClientError(format!("Failed to create HTTP client: {}", e)))?;

        Ok(Self { config, client })
    }

    /// Call a tool on a remote agent
    pub async fn call_tool(
        &self,
        agent_name: &str,
        tool_name: &str,
        parameters: serde_json::Value,
    ) -> McpResult<serde_json::Value> {
        debug!("Calling tool {} on agent {}", tool_name, agent_name);

        let agent = self.find_agent(agent_name)?;
        let url = format!("{}/tools/{}", agent.url, tool_name);

        let mut request = self.client.post(&url).json(&parameters);

        // Add authentication if configured
        if self.config.security.auth_enabled {
            if let Some(token) = &agent.auth_token {
                request = request.header("Authorization", format!("Bearer {}", token));
            } else if let Some(token) = &self.config.security.auth_token {
                request = request.header("Authorization", format!("Bearer {}", token));
            }
        }

        let response = request
            .send()
            .await
            .map_err(|e| McpError::ClientError(format!("Request failed: {}", e)))?;

        if !response.status().is_success() {
            let status = response.status();
            let body = response.text().await.unwrap_or_default();
            return Err(McpError::ClientError(format!(
                "Request failed with status {}: {}",
                status, body
            )));
        }

        let result: Response = response
            .json()
            .await
            .map_err(|e| McpError::ClientError(format!("Failed to parse response: {}", e)))?;

        if result.success {
            result
                .data
                .ok_or_else(|| McpError::ClientError("Response has no data".to_string()))
        } else {
            Err(McpError::ClientError(
                result
                    .error
                    .unwrap_or_else(|| "Unknown error".to_string()),
            ))
        }
    }

    /// List tools available on an agent
    pub async fn list_tools(&self, agent_name: &str) -> McpResult<Vec<Tool>> {
        let agent = self.find_agent(agent_name)?;
        let url = format!("{}/tools", agent.url);

        let response = self
            .client
            .get(&url)
            .send()
            .await
            .map_err(|e| McpError::ClientError(format!("Request failed: {}", e)))?;

        let tools: Vec<Tool> = response
            .json()
            .await
            .map_err(|e| McpError::ClientError(format!("Failed to parse response: {}", e)))?;

        Ok(tools)
    }

    /// List resources available on an agent
    pub async fn list_resources(&self, agent_name: &str) -> McpResult<Vec<Resource>> {
        let agent = self.find_agent(agent_name)?;
        let url = format!("{}/resources", agent.url);

        let response = self
            .client
            .get(&url)
            .send()
            .await
            .map_err(|e| McpError::ClientError(format!("Request failed: {}", e)))?;

        let resources: Vec<Resource> = response
            .json()
            .await
            .map_err(|e| McpError::ClientError(format!("Failed to parse response: {}", e)))?;

        Ok(resources)
    }

    /// Get a specific resource from an agent
    pub async fn get_resource(
        &self,
        agent_name: &str,
        resource_name: &str,
    ) -> McpResult<Resource> {
        let agent = self.find_agent(agent_name)?;
        let url = format!("{}/resources/{}", agent.url, resource_name);

        let response = self
            .client
            .get(&url)
            .send()
            .await
            .map_err(|e| McpError::ClientError(format!("Request failed: {}", e)))?;

        let resource: Resource = response
            .json()
            .await
            .map_err(|e| McpError::ClientError(format!("Failed to parse response: {}", e)))?;

        Ok(resource)
    }

    /// Check if an agent is healthy
    pub async fn health_check(&self, agent_name: &str) -> McpResult<bool> {
        let agent = self.find_agent(agent_name)?;
        let url = format!("{}/health", agent.url);

        match self.client.get(&url).send().await {
            Ok(response) => Ok(response.status().is_success()),
            Err(_) => Ok(false),
        }
    }

    /// Get agent information
    pub async fn get_agent_info(&self, agent_name: &str) -> McpResult<serde_json::Value> {
        let agent = self.find_agent(agent_name)?;
        let url = format!("{}/info", agent.url);

        let response = self
            .client
            .get(&url)
            .send()
            .await
            .map_err(|e| McpError::ClientError(format!("Request failed: {}", e)))?;

        let info: serde_json::Value = response
            .json()
            .await
            .map_err(|e| McpError::ClientError(format!("Failed to parse response: {}", e)))?;

        Ok(info)
    }

    fn find_agent(&self, name: &str) -> McpResult<&crate::config::KnownAgent> {
        self.config
            .agents
            .known
            .iter()
            .find(|a| a.name == name && a.enabled)
            .ok_or_else(|| McpError::AgentNotFound(name.to_string()))
    }
}
