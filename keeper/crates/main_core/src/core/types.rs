use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Task {
    pub id: Uuid,
    pub task_type: TaskType,
    pub description: String,
    pub priority: Priority,
    pub status: TaskStatus,
    pub created_at: DateTime<Utc>,
    pub assigned_to: Option<String>,
    pub result: Option<TaskResult>,
    pub dependencies: Vec<Uuid>,
    pub metadata: HashMap<String, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum TaskType {
    Chat,
    CodeGeneration,
    WebSearch,
    CrateCreation,
    ModelInference,
    FileOperation,
    Analysis,
    Custom(String),
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, PartialOrd, Ord)]
pub enum Priority {
    Low = 0,
    Medium = 1,
    High = 2,
    Critical = 3,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum TaskStatus {
    Pending,
    Assigned,
    InProgress,
    NeedsHelp,
    Completed,
    Failed,
    Retrying,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TaskResult {
    pub success: bool,
    pub output: String,
    pub metadata: HashMap<String, String>,
    pub completed_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkerCapabilities {
    pub worker_id: String,
    pub compute_backend: ComputeBackend,
    pub available_memory_gb: f32,
    pub task_types: Vec<TaskType>,
    pub is_available: bool,
    pub current_load: f32,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq)]
pub enum ComputeBackend {
    CPU,          // llama.cpp
    GPU,          // candle
    NPU,          // OpenVINO
    Distributed,  // Can coordinate across backends
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Message {
    pub id: Uuid,
    pub from: String,
    pub to: String,
    pub content: MessageContent,
    pub timestamp: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum MessageContent {
    Text(String),
    TaskRequest(Task),
    TaskResponse(TaskResult),
    HelpRequest { reason: String, context: String },
    SystemCommand(SystemCommand),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum SystemCommand {
    CreateCrate { name: String, purpose: String },
    UpdateWorker { worker_id: String, new_config: HashMap<String, String> },
    ScaleWorkers { count: usize },
    CallExternalModel { provider: ModelProvider, prompt: String },
    Shutdown,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ModelProvider {
    OpenAI { model: String },
    Claude { model: String },
    Local { backend: ComputeBackend },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConversationContext {
    pub messages: Vec<Message>,
    pub active_tasks: Vec<Uuid>,
    pub user_preferences: HashMap<String, String>,
}

impl Task {
    pub fn new(task_type: TaskType, description: String, priority: Priority) -> Self {
        Self {
            id: Uuid::new_v4(),
            task_type,
            description,
            priority,
            status: TaskStatus::Pending,
            created_at: Utc::now(),
            assigned_to: None,
            result: None,
            dependencies: Vec::new(),
            metadata: HashMap::new(),
        }
    }
}

#[derive(Debug, thiserror::Error)]
pub enum AgentError {
    #[error("Task failed: {0}")]
    TaskFailed(String),
    
    #[error("No available worker for task type: {0:?}")]
    NoWorkerAvailable(TaskType),
    
    #[error("Model inference error: {0}")]
    ModelError(String),
    
    #[error("Communication error: {0}")]
    CommunicationError(String),
    
    #[error("Resource exhausted: {0}")]
    ResourceExhausted(String),
    
    #[error("External API error: {0}")]
    ExternalApiError(String),
}

pub type Result<T> = std::result::Result<T, AgentError>;
