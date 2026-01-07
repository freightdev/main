use async_trait::async_trait;
use shared_types::*;
use worker::TaskExecutor;
use surrealdb::{engine::remote::ws::{Client, Ws}, opt::auth::Root, Surreal};
use std::collections::HashMap;

/// Executor that integrates with your existing SurrealDB instance
/// Reads from cfgs/agentd/core/database.yaml configuration
pub struct SurrealDbExecutor {
    db: Surreal<Client>,
    namespace: String,
    database: String,
}

impl SurrealDbExecutor {
    pub async fn new(url: &str, namespace: &str, database: &str) -> Result<Self> {
        let db = Surreal::new::<Ws>(url).await
            .map_err(|e| AgentError::CommunicationError(format!("Failed to connect to SurrealDB: {}", e)))?;
        
        // Sign in with root credentials (from your config)
        db.signin(Root {
            username: "root",
            password: std::env::var("SURREAL_PASSWORD").unwrap_or_else(|_| "root".to_string()).as_str(),
        })
        .await
        .map_err(|e| AgentError::CommunicationError(format!("Auth failed: {}", e)))?;
        
        // Use namespace and database
        db.use_ns(namespace).use_db(database).await
            .map_err(|e| AgentError::CommunicationError(format!("Failed to use ns/db: {}", e)))?;
        
        Ok(Self {
            db,
            namespace: namespace.to_string(),
            database: database.to_string(),
        })
    }
    
    /// Query leads from your database
    pub async fn query_leads(&self, filter: Option<&str>) -> Result<Vec<serde_json::Value>> {
        let query = match filter {
            Some(f) => format!("SELECT * FROM leads WHERE {}", f),
            None => "SELECT * FROM leads".to_string(),
        };
        
        let results: Vec<serde_json::Value> = self.db
            .query(query)
            .await
            .map_err(|e| AgentError::ModelError(format!("Query failed: {}", e)))?
            .take(0)
            .map_err(|e| AgentError::ModelError(format!("Failed to take results: {}", e)))?;
        
        Ok(results)
    }
    
    /// Query drivers
    pub async fn query_drivers(&self) -> Result<Vec<serde_json::Value>> {
        let results: Vec<serde_json::Value> = self.db
            .query("SELECT * FROM drivers")
            .await
            .map_err(|e| AgentError::ModelError(format!("Query failed: {}", e)))?
            .take(0)
            .map_err(|e| AgentError::ModelError(format!("Failed to take results: {}", e)))?;
        
        Ok(results)
    }
    
    /// Query loads
    pub async fn query_loads(&self, status: Option<&str>) -> Result<Vec<serde_json::Value>> {
        let query = match status {
            Some(s) => format!("SELECT * FROM loads WHERE status = '{}'", s),
            None => "SELECT * FROM loads".to_string(),
        };
        
        let results: Vec<serde_json::Value> = self.db
            .query(query)
            .await
            .map_err(|e| AgentError::ModelError(format!("Query failed: {}", e)))?
            .take(0)
            .map_err(|e| AgentError::ModelError(format!("Failed to take results: {}", e)))?;
        
        Ok(results)
    }
    
    /// Execute arbitrary SurrealQL query
    pub async fn execute_query(&self, query: &str) -> Result<Vec<serde_json::Value>> {
        let results: Vec<serde_json::Value> = self.db
            .query(query)
            .await
            .map_err(|e| AgentError::ModelError(format!("Query failed: {}", e)))?
            .take(0)
            .map_err(|e| AgentError::ModelError(format!("Failed to take results: {}", e)))?;
        
        Ok(results)
    }
    
    /// Insert new record
    pub async fn insert(&self, table: &str, data: serde_json::Value) -> Result<serde_json::Value> {
        let result: Option<serde_json::Value> = self.db
            .create(table)
            .content(data)
            .await
            .map_err(|e| AgentError::ModelError(format!("Insert failed: {}", e)))?;
        
        result.ok_or_else(|| AgentError::ModelError("Insert returned no result".to_string()))
    }
    
    /// Update record
    pub async fn update(&self, table: &str, id: &str, data: serde_json::Value) -> Result<serde_json::Value> {
        let record_id = format!("{}:{}", table, id);
        let result: Option<serde_json::Value> = self.db
            .update(record_id)
            .content(data)
            .await
            .map_err(|e| AgentError::ModelError(format!("Update failed: {}", e)))?;
        
        result.ok_or_else(|| AgentError::ModelError("Update returned no result".to_string()))
    }
}

#[async_trait]
impl TaskExecutor for SurrealDbExecutor {
    async fn execute(&self, task: &Task) -> Result<TaskResult> {
        // Parse the task description to determine what DB operation to perform
        let description = task.description.to_lowercase();
        
        let result = if description.contains("lead") {
            let filter = if description.contains("last week") {
                Some("created > time::now() - 7d")
            } else if description.contains("today") {
                Some("created > time::now() - 1d")
            } else {
                None
            };
            
            let leads = self.query_leads(filter).await?;
            serde_json::to_string_pretty(&leads)
                .map_err(|e| AgentError::ModelError(e.to_string()))?
        } else if description.contains("driver") {
            let drivers = self.query_drivers().await?;
            serde_json::to_string_pretty(&drivers)
                .map_err(|e| AgentError::ModelError(e.to_string()))?
        } else if description.contains("load") {
            let status = if description.contains("available") {
                Some("available")
            } else if description.contains("in transit") {
                Some("in_transit")
            } else {
                None
            };
            
            let loads = self.query_loads(status).await?;
            serde_json::to_string_pretty(&loads)
                .map_err(|e| AgentError::ModelError(e.to_string()))?
        } else if description.starts_with("select ") || description.starts_with("insert ") {
            // Direct SurrealQL query
            let results = self.execute_query(&task.description).await?;
            serde_json::to_string_pretty(&results)
                .map_err(|e| AgentError::ModelError(e.to_string()))?
        } else {
            return Err(AgentError::TaskFailed(format!(
                "Don't know how to handle DB query: {}",
                task.description
            )));
        };
        
        Ok(TaskResult {
            success: true,
            output: result,
            metadata: HashMap::new(),
            completed_at: chrono::Utc::now(),
        })
    }
    
    fn can_handle(&self, task_type: &TaskType) -> bool {
        matches!(task_type, TaskType::Custom(s) if s == "db_query" || s == "database")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    #[ignore] // Only run with actual SurrealDB instance
    async fn test_surrealdb_connection() {
        let executor = SurrealDbExecutor::new(
            "127.0.0.1:8000",
            "codriver",
            "main"
        ).await;
        
        assert!(executor.is_ok());
    }
}
