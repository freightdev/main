use async_trait::async_trait;
use model_router::{ModelRouter, ModelBackend};
use shared_types::*;
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::{info, warn, error};

/// Trait for task execution
#[async_trait]
pub trait TaskExecutor: Send + Sync {
    async fn execute(&self, task: &Task) -> Result<TaskResult>;
    fn can_handle(&self, task_type: &TaskType) -> bool;
}

/// General purpose worker
pub struct Worker {
    pub capabilities: WorkerCapabilities,
    model_router: Arc<RwLock<ModelRouter>>,
    executors: Vec<Arc<dyn TaskExecutor>>,
}

impl Worker {
    pub fn new(capabilities: WorkerCapabilities, model_router: ModelRouter) -> Self {
        Self {
            capabilities,
            model_router: Arc::new(RwLock::new(model_router)),
            executors: Vec::new(),
        }
    }

    pub fn add_executor(&mut self, executor: Arc<dyn TaskExecutor>) {
        self.executors.push(executor);
    }

    pub async fn execute_task(&self, mut task: Task) -> Result<TaskResult> {
        info!(
            "Worker {} executing task: {:?}",
            self.capabilities.worker_id, task.task_type
        );

        task.status = TaskStatus::InProgress;

        // Find appropriate executor
        for executor in &self.executors {
            if executor.can_handle(&task.task_type) {
                match executor.execute(&task).await {
                    Ok(result) => {
                        info!("Task {} completed successfully", task.id);
                        return Ok(result);
                    }
                    Err(e) => {
                        warn!("Task {} failed, attempting recovery: {:?}", task.id, e);
                        
                        // Attempt to get help from external model
                        if let Ok(help_response) = self.request_help(&task, &e).await {
                            info!("Received help, retrying task");
                            task.status = TaskStatus::Retrying;
                            // Could retry with help
                        }
                        
                        return Err(e);
                    }
                }
            }
        }

        Err(AgentError::TaskFailed(format!(
            "No executor found for task type: {:?}",
            task.task_type
        )))
    }

    async fn request_help(&self, task: &Task, error: &AgentError) -> Result<String> {
        let context = format!(
            "Task: {:?}\nDescription: {}\nError: {:?}",
            task.task_type, task.description, error
        );
        let question = "How should I handle this error and complete the task?".to_string();

        let router = self.model_router.read().await;
        router.ask_for_help(context, question).await
    }

    pub async fn run(&self) -> Result<()> {
        info!("Worker {} starting", self.capabilities.worker_id);
        
        // In a real system, this would:
        // 1. Connect to controller
        // 2. Receive tasks via IPC/network
        // 3. Execute tasks
        // 4. Report results
        // 5. Monitor resource usage
        
        Ok(())
    }
}

/// Code generation executor
pub struct CodeGenerationExecutor {
    model_router: Arc<RwLock<ModelRouter>>,
}

impl CodeGenerationExecutor {
    pub fn new(model_router: Arc<RwLock<ModelRouter>>) -> Self {
        Self { model_router }
    }
}

#[async_trait]
impl TaskExecutor for CodeGenerationExecutor {
    async fn execute(&self, task: &Task) -> Result<TaskResult> {
        info!("Generating code for: {}", task.description);

        let prompt = format!(
            "Generate Rust code for the following requirement:\n{}",
            task.description
        );

        let router = self.model_router.read().await;
        let code = router.route(prompt, Some(ComputeBackend::GPU)).await?;

        Ok(TaskResult {
            success: true,
            output: code,
            metadata: std::collections::HashMap::new(),
            completed_at: chrono::Utc::now(),
        })
    }

    fn can_handle(&self, task_type: &TaskType) -> bool {
        matches!(task_type, TaskType::CodeGeneration)
    }
}

/// Chat executor
pub struct ChatExecutor {
    model_router: Arc<RwLock<ModelRouter>>,
}

impl ChatExecutor {
    pub fn new(model_router: Arc<RwLock<ModelRouter>>) -> Self {
        Self { model_router }
    }
}

#[async_trait]
impl TaskExecutor for ChatExecutor {
    async fn execute(&self, task: &Task) -> Result<TaskResult> {
        info!("Processing chat: {}", task.description);

        let router = self.model_router.read().await;
        let response = router.route(task.description.clone(), Some(ComputeBackend::CPU)).await?;

        Ok(TaskResult {
            success: true,
            output: response,
            metadata: std::collections::HashMap::new(),
            completed_at: chrono::Utc::now(),
        })
    }

    fn can_handle(&self, task_type: &TaskType) -> bool {
        matches!(task_type, TaskType::Chat)
    }
}

/// Analysis executor
pub struct AnalysisExecutor {
    model_router: Arc<RwLock<ModelRouter>>,
}

impl AnalysisExecutor {
    pub fn new(model_router: Arc<RwLock<ModelRouter>>) -> Self {
        Self { model_router }
    }
}

#[async_trait]
impl TaskExecutor for AnalysisExecutor {
    async fn execute(&self, task: &Task) -> Result<TaskResult> {
        info!("Performing analysis: {}", task.description);

        let prompt = format!(
            "Analyze the following and provide insights:\n{}",
            task.description
        );

        let router = self.model_router.read().await;
        let analysis = router.route(prompt, None).await?;

        Ok(TaskResult {
            success: true,
            output: analysis,
            metadata: std::collections::HashMap::new(),
            completed_at: chrono::Utc::now(),
        })
    }

    fn can_handle(&self, task_type: &TaskType) -> bool {
        matches!(task_type, TaskType::Analysis)
    }
}

/// File operation executor
pub struct FileOperationExecutor {}

impl FileOperationExecutor {
    pub fn new() -> Self {
        Self {}
    }
}

#[async_trait]
impl TaskExecutor for FileOperationExecutor {
    async fn execute(&self, task: &Task) -> Result<TaskResult> {
        info!("Executing file operation: {}", task.description);

        // Parse file operation from description
        // This is a simplified version - in production you'd have a proper parser
        let result = "File operation completed".to_string();

        Ok(TaskResult {
            success: true,
            output: result,
            metadata: std::collections::HashMap::new(),
            completed_at: chrono::Utc::now(),
        })
    }

    fn can_handle(&self, task_type: &TaskType) -> bool {
        matches!(task_type, TaskType::FileOperation)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_worker_creation() {
        let capabilities = WorkerCapabilities {
            worker_id: "test-worker".to_string(),
            compute_backend: ComputeBackend::CPU,
            available_memory_gb: 16.0,
            task_types: vec![TaskType::Chat],
            is_available: true,
            current_load: 0.0,
        };

        let router = ModelRouter::new();
        let worker = Worker::new(capabilities, router);

        assert_eq!(worker.capabilities.worker_id, "test-worker");
    }
}
