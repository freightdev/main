#!/usr/bin/env bash
# Create workers for each of the user's physical nodes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🏗️  Creating node-specific workers for your infrastructure"
echo ""

# ==========================================
# callbox Worker (4vCPU, 12GB RAM, CPU only)
# ==========================================
echo "Creating callbox-worker..."
mkdir -p "$WORKSPACE_ROOT/crates/callbox-worker/src"

cat > "$WORKSPACE_ROOT/crates/callbox-worker/Cargo.toml" << 'EOF'
[package]
name = "callbox-worker"
version.workspace = true
edition.workspace = true

[[bin]]
name = "callbox-worker"
path = "src/main.rs"

[dependencies]
shared-types = { path = "../shared-types" }
worker = { path = "../worker" }
model-router = { path = "../model-router" }
tokio.workspace = true
anyhow.workspace = true
tracing.workspace = true
tracing-subscriber.workspace = true
serde.workspace = true
EOF

cat > "$WORKSPACE_ROOT/crates/callbox-worker/src/main.rs" << 'EOF'
use anyhow::Result;
use model_router::{ModelRouter, LlamaCppBackend};
use shared_types::*;
use std::sync::Arc;
use tokio::sync::RwLock;
use worker::{Worker, ChatExecutor};

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();
    
    println!("🟢 Starting callbox-worker (4vCPU, 12GB RAM)");
    println!("   Tasks: Chat, Simple queries, Lightweight operations");
    
    // Set up model router with CPU backend
    let mut router = ModelRouter::new();
    
    let cpu_backend = LlamaCppBackend::new(
        std::env::var("LLAMA_CPP_MODEL_PATH")
            .unwrap_or_else(|_| "/models/llama-3.1-8b.gguf".to_string()),
        4096,
    );
    router.add_backend(Arc::new(cpu_backend));
    
    let router = Arc::new(RwLock::new(router));
    
    // Create worker capabilities
    let capabilities = WorkerCapabilities {
        worker_id: std::env::var("WORKER_ID")
            .unwrap_or_else(|_| "callbox-01".to_string()),
        compute_backend: ComputeBackend::CPU,
        available_memory_gb: 12.0,
        task_types: vec![
            TaskType::Chat,
            TaskType::Custom("simple_query".to_string()),
        ],
        is_available: true,
        current_load: 0.0,
    };
    
    // Create worker with executors
    let mut worker = Worker::new(capabilities, router.read().await.clone());
    worker.add_executor(Arc::new(ChatExecutor::new(router.clone())));
    
    println!("✅ callbox-worker ready");
    
    // Run worker
    worker.run().await?;
    
    Ok(())
}
EOF

# ==========================================
# gpubox Worker (8vCPU, 32GB RAM, GPU 4GB)
# ==========================================
echo "Creating gpubox-worker..."
mkdir -p "$WORKSPACE_ROOT/crates/gpubox-worker/src"

cat > "$WORKSPACE_ROOT/crates/gpubox-worker/Cargo.toml" << 'EOF'
[package]
name = "gpubox-worker"
version.workspace = true
edition.workspace = true

[[bin]]
name = "gpubox-worker"
path = "src/main.rs"

[dependencies]
shared-types = { path = "../shared-types" }
worker = { path = "../worker" }
model-router = { path = "../model-router", features = ["gpu"] }
tokio.workspace = true
anyhow.workspace = true
tracing.workspace = true
tracing-subscriber.workspace = true
serde.workspace = true
EOF

cat > "$WORKSPACE_ROOT/crates/gpubox-worker/src/main.rs" << 'EOF'
use anyhow::Result;
use model_router::{ModelRouter, CandleBackend};
use shared_types::*;
use std::sync::Arc;
use tokio::sync::RwLock;
use worker::{Worker, CodeGenerationExecutor};

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();
    
    println!("🟢 Starting gpubox-worker (8vCPU, 32GB RAM, GPU 4GB)");
    println!("   Tasks: Code generation, Model inference, GPU-intensive tasks");
    
    // Set up model router with GPU backend
    let mut router = ModelRouter::new();
    
    let gpu_backend = CandleBackend::new(
        std::env::var("CANDLE_MODEL_PATH")
            .unwrap_or_else(|_| "/models/codellama-34b".to_string()),
    );
    router.add_backend(Arc::new(gpu_backend));
    
    let router = Arc::new(RwLock::new(router));
    
    // Create worker capabilities
    let capabilities = WorkerCapabilities {
        worker_id: std::env::var("WORKER_ID")
            .unwrap_or_else(|_| "gpubox-01".to_string()),
        compute_backend: ComputeBackend::GPU,
        available_memory_gb: 32.0,
        task_types: vec![
            TaskType::CodeGeneration,
            TaskType::ModelInference,
        ],
        is_available: true,
        current_load: 0.0,
    };
    
    // Create worker with executors
    let mut worker = Worker::new(capabilities, router.read().await.clone());
    worker.add_executor(Arc::new(CodeGenerationExecutor::new(router.clone())));
    
    println!("✅ gpubox-worker ready");
    
    // Run worker
    worker.run().await?;
    
    Ok(())
}
EOF

# ==========================================
# workbox Worker (20vCPU, 24GB RAM, iGPU)
# ==========================================
echo "Creating workbox-worker..."
mkdir -p "$WORKSPACE_ROOT/crates/workbox-worker/src"

cat > "$WORKSPACE_ROOT/crates/workbox-worker/Cargo.toml" << 'EOF'
[package]
name = "workbox-worker"
version.workspace = true
edition.workspace = true

[[bin]]
name = "workbox-worker"
path = "src/main.rs"

[dependencies]
shared-types = { path = "../shared-types" }
worker = { path = "../worker" }
model-router = { path = "../model-router" }
tokio.workspace = true
anyhow.workspace = true
tracing.workspace = true
tracing-subscriber.workspace = true
serde.workspace = true
EOF

cat > "$WORKSPACE_ROOT/crates/workbox-worker/src/main.rs" << 'EOF'
use anyhow::Result;
use model_router::{ModelRouter, LlamaCppBackend};
use shared_types::*;
use std::sync::Arc;
use tokio::sync::RwLock;
use worker::{Worker, AnalysisExecutor, ChatExecutor};

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();
    
    println!("🟢 Starting workbox-worker (20vCPU, 24GB RAM)");
    println!("   Tasks: Analysis, Data processing, CPU-intensive tasks");
    
    // Set up model router with CPU backend
    let mut router = ModelRouter::new();
    
    let cpu_backend = LlamaCppBackend::new(
        std::env::var("LLAMA_CPP_MODEL_PATH")
            .unwrap_or_else(|_| "/models/llama-3.1-8b.gguf".to_string()),
        8192,  // Larger context for analysis
    );
    router.add_backend(Arc::new(cpu_backend));
    
    let router = Arc::new(RwLock::new(router));
    
    // Create worker capabilities
    let capabilities = WorkerCapabilities {
        worker_id: std::env::var("WORKER_ID")
            .unwrap_or_else(|_| "workbox-01".to_string()),
        compute_backend: ComputeBackend::CPU,
        available_memory_gb: 24.0,
        task_types: vec![
            TaskType::Analysis,
            TaskType::Chat,
            TaskType::FileOperation,
        ],
        is_available: true,
        current_load: 0.0,
    };
    
    // Create worker with executors
    let mut worker = Worker::new(capabilities, router.read().await.clone());
    worker.add_executor(Arc::new(AnalysisExecutor::new(router.clone())));
    worker.add_executor(Arc::new(ChatExecutor::new(router.clone())));
    
    println!("✅ workbox-worker ready");
    
    // Run worker
    worker.run().await?;
    
    Ok(())
}
EOF

# ==========================================
# devbox Worker (22vCPU, 16GB RAM, iGPU+NPU)
# ==========================================
echo "Creating devbox-worker..."
mkdir -p "$WORKSPACE_ROOT/crates/devbox-worker/src"

cat > "$WORKSPACE_ROOT/crates/devbox-worker/Cargo.toml" << 'EOF'
[package]
name = "devbox-worker"
version.workspace = true
edition.workspace = true

[[bin]]
name = "devbox-worker"
path = "src/main.rs"

[dependencies]
shared-types = { path = "../shared-types" }
worker = { path = "../worker" }
model-router = { path = "../model-router" }
tokio.workspace = true
anyhow.workspace = true
tracing.workspace = true
tracing-subscriber.workspace = true
serde.workspace = true
EOF

cat > "$WORKSPACE_ROOT/crates/devbox-worker/src/main.rs" << 'EOF'
use anyhow::Result;
use model_router::{ModelRouter, OpenVinoBackend};
use shared_types::*;
use std::sync::Arc;
use tokio::sync::RwLock;
use worker::Worker;

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();
    
    println!("🟢 Starting devbox-worker (22vCPU, 16GB RAM, NPU)");
    println!("   Tasks: NPU-optimized inference, Development tasks");
    
    // Set up model router with NPU backend
    let mut router = ModelRouter::new();
    
    let npu_backend = OpenVinoBackend::new(
        std::env::var("OPENVINO_MODEL_PATH")
            .unwrap_or_else(|_| "/models/llama-3.1-8b-int4-ov".to_string()),
    );
    router.add_backend(Arc::new(npu_backend));
    
    let router = Arc::new(RwLock::new(router));
    
    // Create worker capabilities
    let capabilities = WorkerCapabilities {
        worker_id: std::env::var("WORKER_ID")
            .unwrap_or_else(|_| "devbox-01".to_string()),
        compute_backend: ComputeBackend::NPU,
        available_memory_gb: 16.0,
        task_types: vec![
            TaskType::ModelInference,
        ],
        is_available: true,
        current_load: 0.0,
    };
    
    // Create worker
    let worker = Worker::new(capabilities, router.read().await.clone());
    
    println!("✅ devbox-worker ready");
    
    // Run worker
    worker.run().await?;
    
    Ok(())
}
EOF

# ==========================================
# Update workspace Cargo.toml
# ==========================================
echo "Updating workspace Cargo.toml..."

# Backup original
cp "$WORKSPACE_ROOT/Cargo.toml" "$WORKSPACE_ROOT/Cargo.toml.bak"

# Add new workers to members
sed -i '/members = \[/a\    "crates/callbox-worker",\n    "crates/gpubox-worker",\n    "crates/workbox-worker",\n    "crates/devbox-worker",' "$WORKSPACE_ROOT/Cargo.toml"

echo ""
echo "✅ Node-specific workers created!"
echo ""
echo "Workers created:"
echo "  - callbox-worker  (4vCPU, 12GB, CPU)"
echo "  - gpubox-worker   (8vCPU+GPU, 32GB, GPU)"
echo "  - workbox-worker  (20vCPU, 24GB, CPU)"
echo "  - devbox-worker   (22vCPU, 16GB, NPU)"
echo ""
echo "To run:"
echo "  cargo run -p callbox-worker"
echo "  cargo run -p gpubox-worker"
echo "  cargo run -p workbox-worker"
echo "  cargo run -p devbox-worker"
