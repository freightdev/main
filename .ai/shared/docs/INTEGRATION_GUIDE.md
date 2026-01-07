# Integration Guide: Agentic System → Your Existing Infrastructure

## 🎯 Overview

You have a sophisticated distributed infrastructure with:
- **4 Nodes**: callbox, devbox, gpubox, workbox (different CPU/GPU/NPU configs)
- **Agent Daemon (agentd)**: Existing agent configurations
- **Services**: SurrealDB, llama.cpp, various collectors
- **Apps**: FED-APP (Flutter), ELDA-APP, HWY-APP
- **System Tools**: Chat indexer, project generator, template engine

The agentic Rust system I built can act as the **orchestration layer** that coordinates all of this.

## 🔄 Architecture Integration

```
┌─────────────────────────────────────────────────────────────┐
│           Agentic Rust Controller (NEW)                      │
│  - Receives conversational input                             │
│  - Parses intent and creates tasks                           │
│  - Routes to appropriate nodes/services                      │
└─────────────────────────────────────────────────────────────┘
                              ↓
        ┌─────────────────────┼─────────────────────┐
        ↓                     ↓                     ↓
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│ callbox Node │      │ gpubox Node  │      │ workbox Node │
│ (4vCPU)      │      │ (8vCPU+GPU)  │      │ (20vCPU)     │
│ Chat/Simple  │      │ Code Gen     │      │ Analysis     │
└──────────────┘      └──────────────┘      └──────────────┘
        ↓                     ↓                     ↓
┌──────────────────────────────────────────────────────────┐
│              Existing Services (KEEP)                     │
│  - SurrealDB (database)                                   │
│  - llama.cpp (local models)                               │
│  - Lead scrapers/collectors                               │
│  - Agent daemon configs                                   │
└──────────────────────────────────────────────────────────┘
```

## 📂 File Integration Points

### 1. Node Configuration Mapping

**Your Nodes** → **Agentic Workers**

| Your Node | vCPU | Accelerator | RAM | → Worker Type |
|-----------|------|-------------|-----|---------------|
| callbox   | 4    | -           | 12GB| CPU Worker    |
| devbox    | 22   | iGPU+NPU    | 16GB| NPU Worker    |
| gpubox    | 8    | GPU 4GB     | 32GB| GPU Worker    |
| workbox   | 20   | iGPU        | 24GB| CPU Worker    |

### 2. Service Integration

**Existing Services** → **Task Executors**

```rust
// Map your existing services to executors

// SurrealDB → Database Executor
pub struct SurrealDbExecutor {
    db_url: String, // From cfgs/agentd/core/database.yaml
}

// llama.cpp → Already integrated in model-router
// Uses your existing llamacpp.service

// Agent Daemon → Custom Executors
// Read from cfgs/agentd/agent_settings.toml
```

### 3. Agent Configuration Bridge

Your `cfgs/agentd/` configs → Agentic system config:

```toml
# Bridge config: agentic-system/config.bridge.toml

[nodes]
# Map to your existing node configs
callbox = { path = "/path/to/cfgs/nodes/callbox_node.yaml" }
gpubox = { path = "/path/to/cfgs/nodes/gpubox_node.yaml" }
workbox = { path = "/path/to/cfgs/nodes/workbox_node.yaml" }
devbox = { path = "/path/to/cfgs/nodes/devbox_node.yaml" }

[services]
surrealdb = { systemd = "surrealdb.service", url = "localhost:8000" }
llamacpp = { systemd = "llamacpp.service", model_path = "/models" }

[agentd]
config_root = "/path/to/cfgs/agentd"
core_agents = "/path/to/cfgs/agentd/core/agents.yaml"

[apps]
fed_app = { type = "flutter", path = "/path/to/apps/FED-APP" }
elda_app = { type = "custom", path = "/path/to/apps/ELDA-APP" }

[tools]
chat_indexer = "/path/to/docs/system-tools/chat-indexer"
project_generator = "/path/to/docs/system-tools/project-generator"
template_engine = "/path/to/docs/system-tools/template-engine"
```

## 🔧 Implementation Steps

### Step 1: Create Node-Specific Workers

```bash
cd agentic-system

# Create worker configs matching your nodes
./scripts/create-node-workers.sh
```

This generates:
```
crates/
├── workers/
│   ├── callbox-worker/    # 4vCPU, chat tasks
│   ├── gpubox-worker/     # GPU, code generation
│   ├── workbox-worker/    # 20vCPU, analysis
│   └── devbox-worker/     # NPU, inference
```

### Step 2: Integrate Existing Services

```rust
// crates/executors/surrealdb-executor/src/lib.rs

use surrealdb::{Surreal, engine::remote::ws::Ws};
use shared_types::*;

pub struct SurrealDbExecutor {
    db: Surreal<Ws>,
}

impl SurrealDbExecutor {
    pub async fn new() -> Result<Self> {
        let db = Surreal::new::<Ws>("127.0.0.1:8000").await?;
        db.use_ns("codriver").use_db("main").await?;
        Ok(Self { db })
    }
}

#[async_trait]
impl TaskExecutor for SurrealDbExecutor {
    async fn execute(&self, task: &Task) -> Result<TaskResult> {
        // Query SurrealDB based on task
        // This integrates with your existing database
        match task.task_type {
            TaskType::Custom(ref s) if s == "db_query" => {
                let result: Vec<serde_json::Value> = self.db
                    .query(&task.description)
                    .await?
                    .take(0)?;
                
                Ok(TaskResult {
                    success: true,
                    output: serde_json::to_string(&result)?,
                    metadata: HashMap::new(),
                    completed_at: Utc::now(),
                })
            }
            _ => Err(AgentError::TaskFailed("Not a DB query".to_string()))
        }
    }
    
    fn can_handle(&self, task_type: &TaskType) -> bool {
        matches!(task_type, TaskType::Custom(s) if s == "db_query")
    }
}
```

### Step 3: Integrate Agent Daemon Configs

```rust
// crates/executors/agentd-executor/src/lib.rs

use std::path::PathBuf;

pub struct AgentDaemonExecutor {
    config_root: PathBuf,
}

impl AgentDaemonExecutor {
    pub fn load_from_yaml(path: &str) -> Result<Self> {
        // Read cfgs/agentd/core/agents.yaml
        // Parse agent configurations
        // Create executors for each agent type
        Ok(Self {
            config_root: PathBuf::from(path),
        })
    }
    
    pub async fn execute_agent_task(&self, agent_type: &str, input: &str) -> Result<String> {
        // Use your existing agent configs
        // Call appropriate agent based on type
        Ok(format!("Agent {} processed: {}", agent_type, input))
    }
}
```

### Step 4: Integrate Your Tools

```rust
// crates/executors/tools-executor/src/lib.rs

pub struct ToolsExecutor {
    chat_indexer_path: PathBuf,
    template_engine_path: PathBuf,
}

impl ToolsExecutor {
    pub async fn query_conversations(&self, query: &str) -> Result<String> {
        // Call your chat-indexer
        let output = Command::new("python3")
            .arg(self.chat_indexer_path.join("query_conversations.py"))
            .arg(query)
            .output()?;
        
        Ok(String::from_utf8_lossy(&output.stdout).to_string())
    }
    
    pub async fn generate_from_template(&self, template: &str, values: serde_json::Value) -> Result<String> {
        // Use your template engine
        let output = Command::new("python3")
            .arg(self.template_engine_path.join("render_service.py"))
            .arg("--template").arg(template)
            .arg("--values").arg(values.to_string())
            .output()?;
        
        Ok(String::from_utf8_lossy(&output.stdout).to_string())
    }
}
```

## 🚀 Deployment Strategy

### Phase 1: Single Node Testing (callbox)

```bash
# On callbox node
cd agentic-system

# Start controller
cargo run -p controller --release &

# Start callbox worker
WORKER_ID="callbox-01" \
WORKER_BACKEND="cpu" \
WORKER_MEMORY_GB="12" \
cargo run -p callbox-worker --release &
```

### Phase 2: Add GPU Node (gpubox)

```bash
# On gpubox node
cd agentic-system

# Start GPU worker
WORKER_ID="gpubox-01" \
WORKER_BACKEND="gpu" \
WORKER_MEMORY_GB="32" \
CUDA_VISIBLE_DEVICES="0" \
cargo run -p gpubox-worker --release &
```

### Phase 3: Full Distributed Deployment

```bash
# Controller on workbox (most powerful)
# Workers on all nodes
# Communication via gRPC or ZeroMQ
```

## 🎭 Example Conversational Flows

### Flow 1: Query Your Database

```
You: "Check SurrealDB for leads from last week"

System:
1. Controller parses intent → db_query task
2. Routes to SurrealDbExecutor
3. Executes: SELECT * FROM leads WHERE created > time::now() - 7d
4. Returns results

You: "Now analyze those leads and create outreach messages"

System:
1. Creates analysis task → workbox worker
2. Creates code_generation task → gpubox worker
3. Uses template-engine to generate messages
4. Returns personalized outreach for each lead
```

### Flow 2: Generate and Deploy Code

```
You: "Build me a new microservice for handling driver onboarding"

System:
1. CodeGeneration task → gpubox worker
2. Generates Rust/Python code
3. Uses crate-builder to create new crate
4. Integrates with your FED-APP Flutter interfaces
5. Uses template-engine for K8s deployment manifests
6. Returns complete service + deployment config
```

### Flow 3: Multi-Node Orchestration

```
You: "Scrape new freight leads, analyze them, and update the database"

System:
1. WebSearch task → callbox worker (lightweight)
2. Analysis task → workbox worker (CPU intensive)
3. Database update → SurrealDbExecutor
4. All coordinated by Controller
5. Real-time status updates
```

## 📊 Monitoring Integration

Your existing infrastructure has systemd services. Integrate monitoring:

```toml
# agentic-system/config.monitoring.toml

[systemd_integration]
enable = true
services = [
    "surrealdb.service",
    "llamacpp.service",
    "lead-scraper.service",
    "housing-collector.service",
    "trucking-collector.service"
]

[health_checks]
surrealdb = "http://localhost:8000/health"
llamacpp = "http://localhost:8080/health"

[metrics]
export_to_prometheus = true
grafana_dashboard = true  # Use your existing Grafana
```

## 🔐 Security Considerations

1. **Service Authentication**: Use your existing auth systems
2. **Node Communication**: Secure with TLS
3. **API Keys**: Store in your zbox-env
4. **Database Access**: Use SurrealDB's existing auth

## 📝 Configuration Files to Create

1. `agentic-system/config.bridge.toml` - Bridge to your infrastructure
2. `agentic-system/config.nodes.toml` - Node-specific settings
3. `agentic-system/config.services.toml` - Service integration
4. `agentic-system/config.tools.toml` - Tool integration

## 🎯 Next Steps

1. **Review your agent configs** in `cfgs/agentd/`
2. **Map your services** to executors
3. **Test on single node** (callbox)
4. **Deploy distributed** (all nodes)
5. **Integrate with FED-APP** for UI

## 💡 Key Benefits

✅ **Conversational Interface** to your entire infrastructure
✅ **Unified Orchestration** across all nodes
✅ **Automatic Load Balancing** based on node capabilities
✅ **Self-Modifying** - can extend itself
✅ **Preserves Existing Work** - wraps your services, doesn't replace
✅ **Fault Tolerant** - falls back to external APIs when needed

This gives you a **natural language interface** to your entire distributed system!
