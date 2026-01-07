/// Example: Conversational Interaction with the Agentic System
/// 
/// This demonstrates how a user would interact with the system naturally

use controller::Controller;
use worker::{Worker, ChatExecutor, CodeGenerationExecutor, AnalysisExecutor};
use model_router::{ModelRouter, LlamaCppBackend, CandleBackend, OpenVinoBackend};
use crate_builder::CrateBuilder;
use shared_types::*;
use std::sync::Arc;
use tokio::sync::RwLock;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    println!("🤖 Starting Agentic System...\n");

    // Initialize the controller
    let controller = Controller::new();

    // Set up workers for different backends
    setup_workers(&controller).await?;

    println!("✅ System ready! You can now interact with it.\n");
    println!("═══════════════════════════════════════════════════\n");

    // Simulate conversational interactions
    let conversations = vec![
        // Example 1: Code generation with refinement
        Conversation {
            user: "Hey, I need you to build me a web scraper that extracts product prices from Amazon",
            expected_flow: vec![
                "Controller parses intent → CodeGeneration task",
                "Routes to GPU worker (best for code generation)",
                "Worker generates initial code",
                "Returns Rust code with reqwest and scraper",
            ],
        },
        
        Conversation {
            user: "Actually, that's not quite right. I need it to handle pagination and extract reviews too",
            expected_flow: vec![
                "Controller recognizes refinement request",
                "Creates new CodeGeneration task with previous context",
                "Worker retries with additional requirements",
                "If stuck, requests help from Claude API",
                "Returns improved code",
            ],
        },

        // Example 2: Building a new crate
        Conversation {
            user: "Now create a new crate called 'amazon-scraper' with that code and make it work",
            expected_flow: vec![
                "Controller detects CrateCreation intent",
                "Routes to CrateBuilder",
                "Creates new crate structure",
                "Adds generated code",
                "Compiles and tests",
                "Reports success or compilation errors",
            ],
        },

        // Example 3: Research task
        Conversation {
            user: "Search the web for the latest Rust web scraping best practices and update the crate",
            expected_flow: vec![
                "Controller creates WebSearch task",
                "Worker searches for Rust scraping techniques",
                "Analyzes results",
                "Creates CodeGeneration task to update crate",
                "Applies improvements",
                "Recompiles and tests",
            ],
        },

        // Example 4: Analysis with external help
        Conversation {
            user: "Analyze my codebase and tell me how to optimize memory usage across my distributed workers",
            expected_flow: vec![
                "Controller creates Analysis task",
                "Worker analyzes code patterns",
                "If complex, requests help from Claude API",
                "Returns optimization recommendations",
                "Suggests specific changes",
            ],
        },

        // Example 5: Self-modification
        Conversation {
            user: "I need a new worker type that can handle image processing. Create it for me",
            expected_flow: vec![
                "Controller creates CrateCreation task",
                "CrateBuilder generates 'image-worker' crate",
                "Adds ImageProcessingExecutor",
                "Implements ModelBackend for GPU inference",
                "Registers with controller",
                "Worker automatically starts",
            ],
        },
    ];

    // Run through conversations
    for (i, conv) in conversations.iter().enumerate() {
        println!("📝 Example {}: {}", i + 1, conv.user);
        println!("\n🔄 Expected Flow:");
        for (j, step) in conv.expected_flow.iter().enumerate() {
            println!("   {}. {}", j + 1, step);
        }
        
        // Actually process the message
        let response = controller.process_message(conv.user.to_string()).await?;
        println!("\n💬 System: {}", response);
        println!("\n═══════════════════════════════════════════════════\n");
    }

    // Example of worker requesting help
    println!("🆘 Example: Worker Needs Help\n");
    println!("Scenario: GPU worker encounters CUDA OOM error while generating code");
    println!("\nFlow:");
    println!("1. Worker detects error: 'CUDA out of memory'");
    println!("2. Worker sends help request to controller");
    println!("3. Controller formats context for Claude API:");
    println!("   'Task: Generate large codebase");
    println!("    Error: CUDA OOM");
    println!("    Question: How should I handle this?'");
    println!("4. Claude responds with strategies:");
    println!("   - Split generation into smaller chunks");
    println!("   - Use gradient checkpointing");
    println!("   - Offload to CPU worker");
    println!("5. Worker implements suggestion and retries");
    println!("\n═══════════════════════════════════════════════════\n");

    Ok(())
}

async fn setup_workers(controller: &Controller) -> anyhow::Result<()> {
    // CPU Worker
    controller.register_worker(WorkerCapabilities {
        worker_id: "worker-cpu-01".to_string(),
        compute_backend: ComputeBackend::CPU,
        available_memory_gb: 32.0,
        task_types: vec![TaskType::Chat, TaskType::Analysis, TaskType::FileOperation],
        is_available: true,
        current_load: 0.0,
    }).await;

    // GPU Worker
    controller.register_worker(WorkerCapabilities {
        worker_id: "worker-gpu-01".to_string(),
        compute_backend: ComputeBackend::GPU,
        available_memory_gb: 24.0,
        task_types: vec![TaskType::CodeGeneration, TaskType::ModelInference],
        is_available: true,
        current_load: 0.0,
    }).await;

    // NPU Worker
    controller.register_worker(WorkerCapabilities {
        worker_id: "worker-npu-01".to_string(),
        compute_backend: ComputeBackend::NPU,
        available_memory_gb: 10.0,
        task_types: vec![TaskType::ModelInference],
        is_available: true,
        current_load: 0.0,
    }).await;

    Ok(())
}

struct Conversation {
    user: &'static str,
    expected_flow: Vec<&'static str>,
}

/// Example of creating a custom executor
mod custom_executor_example {
    use super::*;

    /// Your custom executor that integrates with existing systems
    pub struct MyCustomExecutor {
        // Your dependencies
    }

    impl MyCustomExecutor {
        pub fn new() -> Self {
            Self {}
        }
    }

    #[async_trait::async_trait]
    impl worker::TaskExecutor for MyCustomExecutor {
        async fn execute(&self, task: &Task) -> Result<TaskResult> {
            // Your custom logic here
            // Can call your existing RAG, MCP, or any other system
            
            Ok(TaskResult {
                success: true,
                output: "Custom result".to_string(),
                metadata: std::collections::HashMap::new(),
                completed_at: chrono::Utc::now(),
            })
        }

        fn can_handle(&self, task_type: &TaskType) -> bool {
            matches!(task_type, TaskType::Custom(s) if s == "my_custom_task")
        }
    }
}
