# Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Prerequisites
- Rust 1.70+ installed
- (Optional) CUDA for GPU support
- (Optional) OpenVINO for NPU support

### Step 1: Clone and Build

```bash
cd agentic-system
cargo build --release
```

### Step 2: Set Up Environment

```bash
# Set API keys for external model fallback (optional but recommended)
export ANTHROPIC_API_KEY="your-key-here"
export OPENAI_API_KEY="your-key-here"

# Set model paths
export LLAMA_CPP_MODEL_PATH="/path/to/model.gguf"
export CANDLE_MODEL_PATH="/path/to/model"
export OPENVINO_MODEL_PATH="/path/to/model.xml"
```

### Step 3: Start the Controller

```bash
cargo run -p controller --release
```

### Step 4: Start Workers

In separate terminals:

```bash
# CPU Worker
./scripts/start-worker.sh cpu

# GPU Worker (if you have CUDA)
./scripts/start-worker.sh gpu

# NPU Worker (if you have OpenVINO)
./scripts/start-worker.sh npu
```

## 💬 Example Interactions

### Simple Chat
```
You: "Hey, what can you do?"
System: "I can help you with code generation, web searches, analysis, 
         file operations, and creating new Rust crates. I have workers 
         running on CPU, GPU, and NPU for different types of tasks."
```

### Code Generation
```
You: "Build me a REST API with authentication in Rust"
System: *Creates CodeGeneration task*
        *Routes to GPU worker*
        *Returns generated code*
        "Here's a REST API using Actix-web with JWT authentication..."
```

### Crate Creation
```
You: "Make that into a new crate called 'my-api'"
System: *Creates CrateCreation task*
        *Generates crate structure*
        *Adds code*
        *Compiles and tests*
        "Created 'my-api' crate successfully. Tests passing."
```

### Refinement
```
You: "Add rate limiting to the API"
System: *Detects refinement*
        *Updates existing crate*
        *Recompiles*
        "Added rate limiting using governor crate. Updated documentation."
```

### Error Recovery
```
System encounters error generating complex code
→ Automatically requests help from Claude API
→ Gets guidance
→ Retries with better approach
→ Succeeds
```

## 🔧 Integrating Your Existing Systems

### RAG Integration

```bash
# Run the integration script
./scripts/integrate-rag.sh
```

Then modify `crates/rag-integration/src/lib.rs`:

```rust
use async_trait::async_trait;
use worker::TaskExecutor;
use shared_types::*;

pub struct RagExecutor {
    rag_client: YourRagClient,  // Your existing RAG
}

#[async_trait]
impl TaskExecutor for RagExecutor {
    async fn execute(&self, task: &Task) -> Result<TaskResult> {
        let docs = self.rag_client.retrieve(&task.description).await?;
        let response = self.rag_client.generate(&task.description, docs).await?;
        
        Ok(TaskResult {
            success: true,
            output: response,
            /* ... */
        })
    }
    
    fn can_handle(&self, task_type: &TaskType) -> bool {
        matches!(task_type, TaskType::Custom(s) if s == "rag_query")
    }
}
```

Register it:
```rust
let rag = Arc::new(RagExecutor::new(your_rag_config));
worker.add_executor(rag);
```

### MCP Integration

Same pattern - implement `TaskExecutor` trait and register it.

## 📊 Architecture Overview

```
You talk to Controller
    ↓
Controller parses intent → Creates tasks
    ↓
Distributes to appropriate Workers
    ↓
Workers execute using:
    - Local models (CPU/GPU/NPU)
    - Your RAG system
    - Your MCP system
    - External APIs (when needed)
    ↓
Results aggregated and returned
```

## 🎯 Key Features You Get

✅ **Multi-backend**: Automatically routes to CPU/GPU/NPU based on task
✅ **Self-modifying**: Can create and modify its own crates
✅ **Error recovery**: Asks for help when stuck
✅ **Distributed**: Workers can run on different machines
✅ **Extensible**: Easy to add new task types and executors
✅ **Conversational**: Natural language interface

## 🔍 Monitoring

View logs:
```bash
tail -f /var/log/agentic-system.log
```

Check worker status:
```bash
# In controller interface
status
```

## 📝 Next Steps

1. **Customize Configuration**: Edit `config.toml` for your setup
2. **Add Your Systems**: Integrate RAG, MCP, or other tools
3. **Create Custom Tasks**: Add new TaskType variants
4. **Deploy Workers**: Set up on your distributed machines
5. **Optimize**: Tune memory limits and task routing

## ❓ Common Issues

### "No available worker"
- Make sure workers are started
- Check worker capabilities match task type

### "CUDA out of memory"
- Reduce batch size
- Use CPU worker instead
- System will auto-request help and retry

### "Compilation failed"
- Check Rust toolchain is up to date
- Verify model paths are correct

## 🆘 Getting Help

The system can request help from Claude or OpenAI APIs when it encounters:
- Complex code generation
- Optimization questions
- Error recovery strategies
- Design decisions

Just set your API keys and it happens automatically.

## 🎓 Learn More

- See `examples/conversational_usage.rs` for detailed interaction patterns
- Read `README.md` for architecture details
- Check `crates/*/src/lib.rs` for implementation details
