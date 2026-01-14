// lib/ai-crates/mcp-rust/src/resources.rs

use crate::error::{McpError, McpResult};
use crate::protocol::Resource;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::info;

#[derive(Clone)]
pub struct ResourceRegistry {
    resources: Arc<RwLock<HashMap<String, Resource>>>,
}

impl ResourceRegistry {
    pub fn new() -> Self {
        Self {
            resources: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    pub async fn register(&self, resource: Resource) -> McpResult<()> {
        info!("Registering resource: {}", resource.name);
        let mut resources = self.resources.write().await;
        resources.insert(resource.name.clone(), resource);
        Ok(())
    }

    pub async fn unregister(&self, name: &str) -> McpResult<()> {
        info!("Unregistering resource: {}", name);
        let mut resources = self.resources.write().await;
        resources
            .remove(name)
            .ok_or_else(|| McpError::ResourceNotFound(name.to_string()))?;
        Ok(())
    }

    pub async fn get(&self, name: &str) -> McpResult<Resource> {
        let resources = self.resources.read().await;
        resources
            .get(name)
            .cloned()
            .ok_or_else(|| McpError::ResourceNotFound(name.to_string()))
    }

    pub async fn list(&self) -> Vec<Resource> {
        let resources = self.resources.read().await;
        resources.values().cloned().collect()
    }

    pub async fn count(&self) -> usize {
        let resources = self.resources.read().await;
        resources.len()
    }

    pub async fn exists(&self, name: &str) -> bool {
        let resources = self.resources.read().await;
        resources.contains_key(name)
    }
}

impl Default for ResourceRegistry {
    fn default() -> Self {
        Self::new()
    }
}
