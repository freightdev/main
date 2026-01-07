# Agentic Rust System

A foundational multi-agent system built in Rust that coordinates tasks across distributed workers using different compute backends (CPU/llama.cpp, GPU/Candle, NPU/OpenVINO).

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Controller                           │
│  (Orchestrates everything, maintains conversation state)    │
└─────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┼─────────────┐
                │             │             │
        ┌───────▼──────┐ ┌───▼────────┐ ┌──▼───────────┐
        │  Worker CPU  │ │ Worker GPU │ │  Worker NPU  │
        │ (llama.cpp)  │ │  (Candle)  │ │ (OpenVINO)   │
        └──────────────┘ └────────────┘ └──────────────┘
                │             │             │
        ┌───────▼─────────────▼─────────────▼────────┐
        │          Model Router & Executors          │
        │  (Routes tasks to appropriate backends)    │
        └────────────────────────────────────────────┘
```

## Key Components

### 1. **Controller** (`crates/controller`)
The brain of the system. It:
- Maintains conversation context
- Parses user intent into tasks
- Coordinates workers
- Routes tasks based on capabilities
- Can request help from external models (Claude, OpenAI)

### 2. **Shared Types** (`crates/shared-types`)
Common data structures used across all crates:
- `Task`, `TaskType`, `TaskStatus`
- `WorkerCapabilities`, `ComputeBackend`
- `Message`, `MessageContent`
- Error types

### 3. **Model Router** (`crates/model-router`)
Routes inference requests to appropriate backends:
- **CPU Backend**: llama.cpp for efficient CPU inference
- **GPU Backend**: Candle for GPU-accelerated inference
- **NPU Backend**: OpenVINO for NPU-specific workloads
- **External Models**: Claude API, OpenAI API for complex queries

### 4. **Worker** (`crates/worker`)
Executes tasks with pluggable executors:
- `CodeGenerationExecutor`: Generates Rust code
- `ChatExecutor`: Handles conversational tasks
- `AnalysisExecutor`: Performs data analysis
- `FileOperationExecutor`: File system operations

### 5. **Crate Builder** (`crates/crate-builder`)
Dynamically creates and modifies Rust crates:
- Generate new crates with dependencies
- Add functions, structs, modules
- Compile and test crates
- Update workspace configuration

### 6. **Task Coordinator** (`crates/task-coordinator`)
TODO: Implements task scheduling, dependency management, and resource allocation

### 7. **Web Search** (`crates/web-search`)
TODO: Integrates web search capabilities

### 8. **Chat** (`crates/chat`)
TODO: Advanced conversational interface

### 9. **Code Generator** (`crates/code-generator`)
TODO: Specialized code generation with retries and validation

## Features

### ✅ Multi-Backend Support
- CPU (llama.cpp)
- GPU (Candle)
- NPU (OpenVINO)
- External APIs (Claude, OpenAI)

### ✅ Dynamic Task Distribution
Workers register their capabilities and the controller routes tasks to the most appropriate worker based on:
- Task type
- Current load
- Available resources
- Backend availability

### ✅ Self-Modification
The system can create new crates and modify existing ones:
```rust
let builder = CrateBuilder::new(workspace_root);
builder.create_crate("my-new-crate", CrateType::Lib, vec!["tokio"]).await?;
builder.compile_crate("my-new-crate").await?;
```

### ✅ Error Recovery
Workers can request help from smarter external models when they encounter errors:
```rust
// Worker encounters an error
let help = self.request_help(&task, &error).await?;
// Retry with context from external model
```

### ✅ Distributed Architecture
Workers can run on different machines with different hardware configurations:
- Machine 1: NPU worker (10GB RAM, optimized for inference)
- Machine 2: GPU worker (24GB VRAM, handles code generation)
- Machine 3: CPU worker (32GB RAM, handles analysis)

## Usage

### Running the Controller

```bash
cd agentic-system
cargo run -p controller
```

### Creating a New Worker

```rust
use worker::{Worker, ChatExecutor, CodeGenerationExecutor};
use model_router::ModelRouter;
use shared_types::{WorkerCapabilities, ComputeBackend, TaskType};

#[tokio::main]
async fn main() {
    // Set up model router
    let mut router = ModelRouter::new();
    router.add_backend(Arc::new(LlamaCppBackend::new(
        "/path/to/model.gguf".to_string(),
        4096,
    )));

    // Create worker
    let capabilities = WorkerCapabilities {
        worker_id: "worker-001".to_string(),
        compute_backend: ComputeBackend::CPU,
        available_memory_gb: 16.0,
        task_types: vec![TaskType::Chat, TaskType::Analysis],
        is_available: true,
        current_load: 0.0,
    };

    let mut worker = Worker::new(capabilities, router);
    worker.add_executor(Arc::new(ChatExecutor::new(model_router.clone())));
    
    worker.run().await.unwrap();
}
```

### Integrating with Existing RAG/MCP

Your existing RAG and MCP systems can be integrated as executors:

```rust
// Create a custom executor for your RAG system
pub struct RagExecutor {
    rag_client: YourRagClient,
}

#[async_trait]
impl TaskExecutor for RagExecutor {
    async fn execute(&self, task: &Task) -> Result<TaskResult> {
        let response = self.rag_client.query(&task.description).await?;
        Ok(TaskResult {
            success: true,
            output: response,
            metadata: HashMap::new(),
            completed_at: Utc::now(),
        })
    }

    fn can_handle(&self, task_type: &TaskType) -> bool {
        matches!(task_type, TaskType::Custom("rag".to_string()))
    }
}
```

## Conversational Interface

The system is designed for natural conversation:

**User**: "Hey, can you build me a web scraper that extracts product prices?"

**System**:
1. Controller parses intent → Creates CodeGeneration task
2. Routes to GPU worker (best for code generation)
3. Worker generates code using local model
4. If generation fails, requests help from Claude API
5. Returns generated code to user

**User**: "That's not quite right, I need it to handle pagination"

**System**:
1. Controller detects refinement request
2. Creates new task with previous context
3. Worker retries with additional context
4. Returns improved code

## Extending the System

### Add a New Task Type

1. Add to `TaskType` enum in `shared-types`:
```rust
pub enum TaskType {
    // ... existing types
    ImageGeneration,
}
```

2. Create executor in worker:
```rust
pub struct ImageGenExecutor { /* ... */ }

#[async_trait]
impl TaskExecutor for ImageGenExecutor {
    async fn execute(&self, task: &Task) -> Result<TaskResult> {
        // Implementation
    }
    
    fn can_handle(&self, task_type: &TaskType) -> bool {
        matches!(task_type, TaskType::ImageGeneration)
    }
}
```

3. Register with worker:
```rust
worker.add_executor(Arc::new(ImageGenExecutor::new()));
```

### Add a New Backend

1. Implement `ModelBackend` trait:
```rust
pub struct MyCustomBackend { /* ... */ }

#[async_trait]
impl ModelBackend for MyCustomBackend {
    async fn infer(&self, prompt: String) -> Result<String> {
        // Your implementation
    }
    
    fn backend_type(&self) -> ComputeBackend {
        ComputeBackend::Custom("my-backend".to_string())
    }
    
    fn is_available(&self) -> bool {
        // Check availability
    }
    
    async fn warmup(&mut self) -> Result<()> {
        // Load model
    }
}
```

2. Register with router:
```rust
router.add_backend(Arc::new(MyCustomBackend::new()));
```

## Configuration

### Environment Variables

```bash
# Model paths
export LLAMA_CPP_MODEL_PATH="/path/to/model.gguf"
export CANDLE_MODEL_PATH="/path/to/model"
export OPENVINO_MODEL_PATH="/path/to/model.xml"

# API keys for external models
export ANTHROPIC_API_KEY="your-key"
export OPENAI_API_KEY="your-key"

# Worker configuration
export WORKER_ID="worker-001"
export WORKER_BACKEND="cpu"  # cpu, gpu, npu
export WORKER_MEMORY_GB="16"
```

## Building

```bash
# Build everything
cargo build --release

# Build specific crate
cargo build -p controller --release

# Run tests
cargo test

# Check all crates
cargo check --workspace
```

## Roadmap

- [ ] Implement distributed communication (gRPC/ZeroMQ)
- [ ] Add task scheduling with priorities
- [ ] Implement resource monitoring and optimization
- [ ] Add conversation memory and context management
- [ ] Implement retry logic with exponential backoff
- [ ] Add metrics and observability
- [ ] Create web dashboard for monitoring
- [ ] Implement task DAG execution
- [ ] Add support for streaming responses
- [ ] Integration tests across workers

## License

MIT

## Contributing

This is a foundational system - feel free to extend and modify as needed!
