use anyhow::Result;
use dashmap::DashMap;
use shared_types::*;
use std::sync::Arc;
use tokio::sync::{mpsc, RwLock};
use tracing::{info, warn, error};

/// The Controller is the central orchestrator of the agentic system
/// It maintains conversation state, coordinates workers, and routes tasks
pub struct Controller {
    /// Active workers in the system
    workers: Arc<DashMap<String, WorkerCapabilities>>,
    /// Current conversation context
    conversation: Arc<RwLock<ConversationContext>>,
    /// Task queue and tracking
    tasks: Arc<DashMap<uuid::Uuid, Task>>,
    /// Communication channels
    task_tx: mpsc::Sender<Task>,
    task_rx: Arc<RwLock<mpsc::Receiver<Task>>>,
    result_tx: mpsc::Sender<TaskResult>,
    result_rx: Arc<RwLock<mpsc::Receiver<TaskResult>>>,
}

impl Controller {
    pub fn new() -> Self {
        let (task_tx, task_rx) = mpsc::channel(1000);
        let (result_tx, result_rx) = mpsc::channel(1000);

        Self {
            workers: Arc::new(DashMap::new()),
            conversation: Arc::new(RwLock::new(ConversationContext {
                messages: Vec::new(),
                active_tasks: Vec::new(),
                user_preferences: std::collections::HashMap::new(),
            })),
            tasks: Arc::new(DashMap::new()),
            task_tx,
            task_rx: Arc::new(RwLock::new(task_rx)),
            result_tx,
            result_rx: Arc::new(RwLock::new(result_rx)),
        }
    }

    /// Register a new worker with the controller
    pub async fn register_worker(&self, capabilities: WorkerCapabilities) {
        info!("Registering worker: {}", capabilities.worker_id);
        self.workers.insert(capabilities.worker_id.clone(), capabilities);
    }

    /// Process incoming user message
    pub async fn process_message(&self, content: String) -> Result<String> {
        info!("Processing user message");

        // Add message to conversation
        let message = Message {
            id: uuid::Uuid::new_v4(),
            from: "user".to_string(),
            to: "controller".to_string(),
            content: MessageContent::Text(content.clone()),
            timestamp: chrono::Utc::now(),
        };

        {
            let mut conv = self.conversation.write().await;
            conv.messages.push(message);
        }

        // Parse intent and create tasks
        let tasks = self.parse_intent(&content).await?;

        // Submit tasks to workers
        for task in tasks {
            self.submit_task(task).await?;
        }

        // Generate response
        self.generate_response().await
    }

    /// Parse user intent and generate tasks
    async fn parse_intent(&self, content: &str) -> Result<Vec<Task>> {
        let mut tasks = Vec::new();

        // Simple intent detection (you'll want to use a model here)
        if content.to_lowercase().contains("search") || content.contains("web") {
            tasks.push(Task::new(
                TaskType::WebSearch,
                content.to_string(),
                Priority::High,
            ));
        }

        if content.to_lowercase().contains("code") || content.contains("build") {
            tasks.push(Task::new(
                TaskType::CodeGeneration,
                content.to_string(),
                Priority::High,
            ));
        }

        if content.to_lowercase().contains("crate") {
            tasks.push(Task::new(
                TaskType::CrateCreation,
                content.to_string(),
                Priority::Medium,
            ));
        }

        // If no specific intent, create a chat task
        if tasks.is_empty() {
            tasks.push(Task::new(
                TaskType::Chat,
                content.to_string(),
                Priority::Medium,
            ));
        }

        Ok(tasks)
    }

    /// Submit a task to the appropriate worker
    pub async fn submit_task(&self, mut task: Task) -> Result<()> {
        info!("Submitting task: {:?} - {}", task.task_type, task.description);

        // Find best worker for this task
        let worker = self.find_best_worker(&task.task_type).await?;
        task.assigned_to = Some(worker.worker_id.clone());
        task.status = TaskStatus::Assigned;

        // Store task
        let task_id = task.id;
        self.tasks.insert(task_id, task.clone());

        // Add to active tasks
        {
            let mut conv = self.conversation.write().await;
            conv.active_tasks.push(task_id);
        }

        // Send to task queue
        self.task_tx.send(task).await?;

        Ok(())
    }

    /// Find the best worker for a given task type
    async fn find_best_worker(&self, task_type: &TaskType) -> Result<WorkerCapabilities> {
        // Find available workers that can handle this task type
        let mut candidates: Vec<WorkerCapabilities> = self
            .workers
            .iter()
            .filter(|w| {
                w.is_available
                    && w.task_types.iter().any(|t| {
                        std::mem::discriminant(t) == std::mem::discriminant(task_type)
                    })
            })
            .map(|w| w.clone())
            .collect();

        if candidates.is_empty() {
            return Err(anyhow::anyhow!(
                "No available worker for task type: {:?}",
                task_type
            ));
        }

        // Sort by current load
        candidates.sort_by(|a, b| a.current_load.partial_cmp(&b.current_load).unwrap());

        Ok(candidates[0].clone())
    }

    /// Generate response based on completed tasks
    async fn generate_response(&self) -> Result<String> {
        // In a real system, you'd aggregate task results and generate a coherent response
        // For now, return a simple acknowledgment
        Ok("Task(s) submitted and being processed.".to_string())
    }

    /// Request help from an external model (Claude, OpenAI, etc.)
    pub async fn request_external_help(
        &self,
        provider: ModelProvider,
        prompt: String,
    ) -> Result<String> {
        match provider {
            ModelProvider::Claude { model } => {
                info!("Requesting help from Claude: {}", model);
                // This would call the Claude API
                Ok(format!("Would call Claude API with prompt: {}", prompt))
            }
            ModelProvider::OpenAI { model } => {
                info!("Requesting help from OpenAI: {}", model);
                // This would call the OpenAI API
                Ok(format!("Would call OpenAI API with prompt: {}", prompt))
            }
            ModelProvider::Local { backend } => {
                info!("Using local model with backend: {:?}", backend);
                // Route to appropriate local worker
                Ok(format!("Would use local {:?} backend", backend))
            }
        }
    }

    /// Main event loop
    pub async fn run(&self) -> Result<()> {
        info!("Controller starting...");

        // In a real system, you'd have multiple async tasks handling:
        // - Task distribution
        // - Result collection
        // - Worker health monitoring
        // - Resource optimization

        tokio::select! {
            _ = self.handle_tasks() => {},
            _ = self.handle_results() => {},
        }

        Ok(())
    }

    async fn handle_tasks(&self) -> Result<()> {
        loop {
            let mut rx = self.task_rx.write().await;
            if let Some(task) = rx.recv().await {
                info!("Dispatching task: {}", task.id);
                // Here you'd actually send to worker via IPC, gRPC, etc.
            }
        }
    }

    async fn handle_results(&self) -> Result<()> {
        loop {
            let mut rx = self.result_rx.write().await;
            if let Some(result) = rx.recv().await {
                info!("Received result: {}", result.output);
                // Update task status, notify user, etc.
            }
        }
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt::init();

    info!("Starting Agentic Controller System");

    let controller = Controller::new();

    // Register some example workers
    controller
        .register_worker(WorkerCapabilities {
            worker_id: "worker-cpu-01".to_string(),
            compute_backend: ComputeBackend::CPU,
            available_memory_gb: 32.0,
            task_types: vec![TaskType::Chat, TaskType::Analysis],
            is_available: true,
            current_load: 0.0,
        })
        .await;

    controller
        .register_worker(WorkerCapabilities {
            worker_id: "worker-gpu-01".to_string(),
            compute_backend: ComputeBackend::GPU,
            available_memory_gb: 24.0,
            task_types: vec![TaskType::CodeGeneration, TaskType::ModelInference],
            is_available: true,
            current_load: 0.0,
        })
        .await;

    controller
        .register_worker(WorkerCapabilities {
            worker_id: "worker-npu-01".to_string(),
            compute_backend: ComputeBackend::NPU,
            available_memory_gb: 10.0,
            task_types: vec![TaskType::ModelInference],
            is_available: true,
            current_load: 0.0,
        })
        .await;

    // Example interaction
    let response = controller
        .process_message("Hey, can you search the web for Rust agentic frameworks?".to_string())
        .await?;

    info!("Response: {}", response);

    // Run main loop
    // controller.run().await?;

    Ok(())
}
