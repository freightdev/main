/// Complete Integration Example
/// This shows how to put everything together and actually use the system

use anyhow::Result;
use std::sync::Arc;
use tokio::sync::RwLock;

// Import all the components
use shared_types::*;
use model_router::{ModelRouter, LlamaCppBackend, CandleBackend, ExternalModelClient};
use worker::{Worker, ChatExecutor, CodeGenerationExecutor, AnalysisExecutor};
use crate_builder::{CrateBuilder, CrateType};

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize logging
    tracing_subscriber::fmt::init();

    println!("🚀 Initializing Agentic System\n");

    // ==========================================
    // STEP 1: Set up Model Router
    // ==========================================
    println!("📡 Setting up model backends...");
    
    let mut model_router = ModelRouter::new();

    // Add CPU backend (llama.cpp)
    let cpu_backend = LlamaCppBackend::new(
        "/path/to/llama-model.gguf".to_string(),
        4096,
    );
    model_router.add_backend(Arc::new(cpu_backend));

    // Add GPU backend (Candle)
    let gpu_backend = CandleBackend::new(
        "/path/to/codellama-model".to_string(),
    );
    model_router.add_backend(Arc::new(gpu_backend));

    // Add external model client for help requests
    if let Ok(api_key) = std::env::var("ANTHROPIC_API_KEY") {
        let claude_client = ExternalModelClient::new(
            ModelProvider::Claude {
                model: "claude-sonnet-4-20250514".to_string(),
            },
            Some(api_key),
        );
        model_router.set_external_client(claude_client);
        println!("✅ Claude API configured for help requests");
    }

    let model_router = Arc::new(RwLock::new(model_router));

    // ==========================================
    // STEP 2: Create Workers
    // ==========================================
    println!("\n👷 Creating workers...");

    // CPU Worker
    let cpu_capabilities = WorkerCapabilities {
        worker_id: "worker-cpu-01".to_string(),
        compute_backend: ComputeBackend::CPU,
        available_memory_gb: 32.0,
        task_types: vec![TaskType::Chat, TaskType::Analysis],
        is_available: true,
        current_load: 0.0,
    };

    let mut cpu_worker = Worker::new(
        cpu_capabilities,
        model_router.read().await.clone(),
    );
    cpu_worker.add_executor(Arc::new(ChatExecutor::new(model_router.clone())));
    cpu_worker.add_executor(Arc::new(AnalysisExecutor::new(model_router.clone())));

    // GPU Worker
    let gpu_capabilities = WorkerCapabilities {
        worker_id: "worker-gpu-01".to_string(),
        compute_backend: ComputeBackend::GPU,
        available_memory_gb: 24.0,
        task_types: vec![TaskType::CodeGeneration],
        is_available: true,
        current_load: 0.0,
    };

    let mut gpu_worker = Worker::new(
        gpu_capabilities,
        model_router.read().await.clone(),
    );
    gpu_worker.add_executor(Arc::new(CodeGenerationExecutor::new(model_router.clone())));

    println!("✅ Workers created: CPU, GPU");

    // ==========================================
    // STEP 3: Set up Crate Builder
    // ==========================================
    println!("\n🔨 Setting up crate builder...");

    let workspace_root = std::path::PathBuf::from("./workspace");
    let crate_builder = CrateBuilder::new(workspace_root);

    // ==========================================
    // STEP 4: Example Tasks
    // ==========================================
    println!("\n📋 Running example tasks...\n");

    // Task 1: Chat
    println!("═══════════════════════════════════════");
    println!("Task 1: Simple Chat");
    println!("═══════════════════════════════════════");
    
    let chat_task = Task::new(
        TaskType::Chat,
        "Explain Rust ownership in simple terms".to_string(),
        Priority::Medium,
    );

    match cpu_worker.execute_task(chat_task).await {
        Ok(result) => {
            println!("✅ Chat completed");
            println!("Response: {}\n", result.output);
        }
        Err(e) => println!("❌ Chat failed: {:?}\n", e),
    }

    // Task 2: Code Generation
    println!("═══════════════════════════════════════");
    println!("Task 2: Code Generation");
    println!("═══════════════════════════════════════");
    
    let code_task = Task::new(
        TaskType::CodeGeneration,
        "Create a function that calculates fibonacci numbers using memoization".to_string(),
        Priority::High,
    );

    match gpu_worker.execute_task(code_task).await {
        Ok(result) => {
            println!("✅ Code generated");
            println!("Code:\n{}\n", result.output);
        }
        Err(e) => println!("❌ Code generation failed: {:?}\n", e),
    }

    // Task 3: Create New Crate
    println!("═══════════════════════════════════════");
    println!("Task 3: Create New Crate");
    println!("═══════════════════════════════════════");
    
    match crate_builder
        .create_crate(
            "fibonacci-lib",
            CrateType::Lib,
            vec!["tokio".to_string()],
        )
        .await
    {
        Ok(path) => {
            println!("✅ Crate created at: {:?}", path);
            
            // Try to compile it
            match crate_builder.compile_crate("fibonacci-lib").await {
                Ok(output) => println!("✅ Compilation successful\n"),
                Err(e) => println!("⚠️  Compilation failed: {}\n", e),
            }
        }
        Err(e) => println!("❌ Crate creation failed: {:?}\n", e),
    }

    // ==========================================
    // STEP 5: Demonstrate Error Recovery
    // ==========================================
    println!("═══════════════════════════════════════");
    println!("Task 4: Error Recovery with External Help");
    println!("═══════════════════════════════════════");

    let complex_task = Task::new(
        TaskType::CodeGeneration,
        "Implement a lock-free concurrent hash map using atomic operations".to_string(),
        Priority::Critical,
    );

    println!("Attempting complex task...");
    match gpu_worker.execute_task(complex_task.clone()).await {
        Ok(result) => {
            println!("✅ Completed (possibly with external help)");
            println!("Output: {}\n", result.output);
        }
        Err(e) => {
            println!("⚠️  Task failed: {:?}", e);
            println!("🆘 Worker would request help from Claude API");
            println!("   Context: {:?}", complex_task.description);
            println!("   Question: How should I implement this?\n");
        }
    }

    // ==========================================
    // STEP 6: Integration with Your Systems
    // ==========================================
    println!("═══════════════════════════════════════");
    println!("Integration Examples");
    println!("═══════════════════════════════════════\n");

    println!("To integrate your RAG system:");
    println!("1. Create RagExecutor implementing TaskExecutor");
    println!("2. Register with worker: worker.add_executor(Arc::new(rag_executor))");
    println!("3. Tasks of type TaskType::Custom('rag_query') will route to it\n");

    println!("To integrate your MCP system:");
    println!("1. Create McpExecutor implementing TaskExecutor");
    println!("2. Handle TaskType::Custom('mcp_request')");
    println!("3. Call your existing MCP client in execute()\n");

    // ==========================================
    // STEP 7: Conversational Flow Example
    // ==========================================
    println!("═══════════════════════════════════════");
    println!("Conversational Flow");
    println!("═══════════════════════════════════════\n");

    simulate_conversation().await;

    println!("\n✨ System demonstration complete!");

    Ok(())
}

async fn simulate_conversation() {
    let conversations = vec![
        "User: Hey, build me a REST API for managing todos",
        "System: [Creates CodeGeneration task → Routes to GPU worker]",
        "System: Here's a REST API using Actix-web...",
        "",
        "User: That's good, but add authentication with JWT",
        "System: [Detects refinement → Creates new task with context]",
        "System: Updated the API with JWT authentication...",
        "",
        "User: Now make it a crate called 'todo-api'",
        "System: [Creates CrateCreation task → Uses CrateBuilder]",
        "System: Created 'todo-api' crate, tests passing",
        "",
        "User: Search the web for Rust API best practices and apply them",
        "System: [Creates WebSearch task → Analyzes results → Updates code]",
        "System: Applied best practices: error handling, logging, CORS...",
    ];

    for line in conversations {
        println!("{}", line);
        tokio::time::sleep(tokio::time::Duration::from_millis(500)).await;
    }
}

// ==========================================
// Custom Executor Example
// ==========================================

/// Example of integrating your existing RAG system
struct YourRagExecutor {
    // Your RAG client
}

impl YourRagExecutor {
    fn new() -> Self {
        Self {}
    }
}

#[async_trait::async_trait]
impl worker::TaskExecutor for YourRagExecutor {
    async fn execute(&self, task: &Task) -> Result<TaskResult> {
        // Call your RAG system
        let query = &task.description;
        
        // Pseudo-code for your integration:
        // let documents = self.rag_client.retrieve(query).await?;
        // let response = self.rag_client.generate(query, documents).await?;
        
        let response = format!("[RAG] Retrieved and generated response for: {}", query);

        Ok(TaskResult {
            success: true,
            output: response,
            metadata: std::collections::HashMap::new(),
            completed_at: chrono::Utc::now(),
        })
    }

    fn can_handle(&self, task_type: &TaskType) -> bool {
        matches!(task_type, TaskType::Custom(s) if s == "rag_query")
    }
}

/// Example of integrating your MCP system
struct YourMcpExecutor {
    // Your MCP client
}

impl YourMcpExecutor {
    fn new() -> Self {
        Self {}
    }
}

#[async_trait::async_trait]
impl worker::TaskExecutor for YourMcpExecutor {
    async fn execute(&self, task: &Task) -> Result<TaskResult> {
        // Call your MCP system
        let request = &task.description;
        
        // Pseudo-code:
        // let response = self.mcp_client.handle(request).await?;
        
        let response = format!("[MCP] Handled request: {}", request);

        Ok(TaskResult {
            success: true,
            output: response,
            metadata: std::collections::HashMap::new(),
            completed_at: chrono::Utc::now(),
        })
    }

    fn can_handle(&self, task_type: &TaskType) -> bool {
        matches!(task_type, TaskType::Custom(s) if s == "mcp_request")
    }
}
