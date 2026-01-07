# RAG and MCP Systems - Complete Setup Guide

This guide shows you how to set up and use the RAG (Retrieval-Augmented Generation) and MCP (Model Context Protocol) systems together to build an AI-powered agent platform.

## 🎯 What You're Building

**RAG System**: Semantic code search that lets your agents find relevant code, documentation, and examples across your entire codebase.

**MCP System**: Communication protocol that lets your agents talk to each other, share capabilities, and work together.

**Together**: Agents that can search your knowledge base, find relevant code, and coordinate with other agents to complete complex tasks.

---

## 📦 Prerequisites

### Required
- **Rust** 1.70+ (`curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`)
- **Docker** & Docker Compose (for Qdrant database)
- **Embedding API Key** (one of):
  - Anthropic API key (recommended)
  - OpenAI API key
  - Local Ollama installation

### Optional
- **etcd** (for service discovery)
- **DragonflyDB** (for pub/sub messaging)
- **PostgreSQL** (for persistent storage)

---

## 🚀 Quick Start (5 Minutes)

### 1. Start Qdrant Database

```bash
cd /home/admin/ws/OpenHWY/package/rust-crate/rag::qdrant
docker-compose up -d

# Verify it's running
curl http://localhost:6333/health
```

### 2. Configure RAG System

```bash
cd /home/admin/ws/OpenHWY/package/rust-crate/rag::qdrant

# Copy environment template
cp .env.example .env

# Edit and add your API key
nano .env
```

Set your embedding provider:
```bash
EMBEDDING_PROVIDER=anthropic
EMBEDDING_API_KEY=your_api_key_here
```

### 3. Index Your Codebase

```bash
# Index the entire OpenHWY platform
cargo run --example index_codebase

# This will index:
# - All Rust crates
# - Agent code
# - Documentation
# - Configuration files
```

### 4. Test RAG Search

```bash
# Run interactive search
cargo run --example search_demo
```

Try searching for:
- "agent communication"
- "database connection"
- "load board integration"

### 5. Start MCP Agent

```bash
cd /home/admin/ws/OpenHWY/package/rust-crate/mcp

# Copy environment template
cp .env.example .env

# Edit configuration
nano config.toml

# Start the agent
cargo run --example agent_server
```

### 6. Verify Everything Works

```bash
# Test MCP agent
curl http://localhost:3000/health

# Test RAG search via agent tool (coming soon)
curl -X POST http://localhost:3000/tools/search \
  -H 'Content-Type: application/json' \
  -d '{"query":"How do I implement an agent?"}'
```

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Your Application                      │
│           (FED, ELDA, HWY, or Custom Agent)             │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │   MCP Client/Server   │ ◄──── Inter-agent communication
         └───────┬───────────────┘
                 │
      ┌──────────┼──────────┐
      ▼          ▼           ▼
┌─────────┐ ┌─────────┐ ┌──────────┐
│   RAG   │ │  Tools  │ │Resources │
│(Qdrant) │ │Registry │ │ Registry │
└─────────┘ └─────────┘ └──────────┘
     │
     ▼
┌────────────┐
│  Qdrant DB │ ◄──── Vector embeddings
└────────────┘
```

---

## 🔧 Integration Patterns

### Pattern 1: Simple Agent with Code Search

```rust
use mcp_rust::{quick_start_server, Tool};
use qdrant_rag::{quick_start as rag_start, SearchQuery};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize RAG
    let rag = rag_start().await?;

    // Initialize MCP server
    let mut server = quick_start_server().await?;

    // Register code search tool
    server.register_tool(
        Tool::new("search_code", "Search codebase semantically")
            .with_parameters(serde_json::json!({
                "type": "object",
                "properties": {
                    "query": {"type": "string"}
                },
                "required": ["query"]
            }))
            .with_handler(move |params| {
                let rag = rag.clone();
                async move {
                    let query = params["query"].as_str().unwrap();
                    let results = rag.search(SearchQuery::new(query)).await
                        .map_err(|e| e.to_string())?;

                    Ok(serde_json::to_value(results)
                        .map_err(|e| e.to_string())?)
                }
            })
    ).await?;

    server.serve().await?;
    Ok(())
}
```

### Pattern 2: Co-Driver (Orchestrator)

The Co-Driver uses RAG to find the right agent for each task:

```rust
// Co-Driver agent
server.register_tool(
    Tool::new("route_task", "Route task to appropriate agent")
        .with_handler(move |params| {
            let rag = rag.clone();
            let client = mcp_client.clone();

            async move {
                let task = params["task"].as_str().unwrap();

                // Use RAG to find relevant agent
                let query = format!("agent for: {}", task);
                let results = rag.search(SearchQuery::new(&query)).await?;

                // Determine best agent from results
                let agent_name = determine_agent(&results)?;

                // Route to agent
                client.call_tool(agent_name, "execute", params).await
            }
        })
).await?;
```

### Pattern 3: Agent Builder with Context

Build agents dynamically using RAG to find relevant code:

```rust
async fn build_agent_with_context(
    agent_spec: AgentSpec,
    rag: &RagClient,
) -> Result<Agent> {
    // Search for similar agent implementations
    let query = format!("{} agent implementation", agent_spec.agent_type);
    let examples = rag.search(SearchQuery::new(&query)).await?;

    // Use examples as context for building new agent
    let context = examples.into_iter()
        .map(|r| format!("// {}\n{}", r.file_path, r.content))
        .collect::<Vec<_>>()
        .join("\n\n");

    // Generate agent code with LLM using context
    generate_agent_code(agent_spec, &context).await
}
```

---

## 🤖 Building Your Agent System

### Step 1: Define Your Agents

For OpenHWY, you have:
- **Co-Driver**: Orchestrator that routes tasks
- **Marketeer**: Security and request verification
- **Big Bear**: Weather, traffic, weigh stations
- **Cargo Connect**: Load board integration
- **Legal Logger**: Document encryption and audit
- **Packet Pilot**: Document processing and forms
- **Trucker Tales**: Story collection
- **Whisper Witness**: Call recording and analysis

### Step 2: Create Agent Configuration

`co-driver-config.toml`:
```toml
[server]
name = "co-driver"
port = 3001
description = "Task orchestrator and agent manager"

[[agents.known]]
name = "big-bear"
url = "http://localhost:3003"
capabilities = ["traffic", "weather", "weigh-stations"]
enabled = true

[[agents.known]]
name = "cargo-connect"
url = "http://localhost:3004"
capabilities = ["load-board", "load-scoring"]
enabled = true

# ... more agents
```

### Step 3: Implement Agent Logic

```rust
// Big Bear agent
#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let mut server = McpServer::from_config("big-bear-config.toml").await?;
    let rag = rag_start().await?;

    // Register domain-specific tools
    server.register_tool(
        Tool::new("track_weigh_station", "Track weigh station status")
            .with_handler(|params| async move {
                let location = params["location"].as_str().unwrap();
                // Implementation...
                Ok(serde_json::json!({"status": "open"}))
            })
    ).await?;

    // Use RAG to find relevant documentation
    server.register_tool(
        Tool::new("get_regulations", "Get DOT regulations")
            .with_handler(move |params| {
                let rag = rag.clone();
                async move {
                    let topic = params["topic"].as_str().unwrap();
                    let results = rag.search(
                        SearchQuery::new(&format!("DOT regulations {}", topic))
                    ).await?;

                    Ok(serde_json::to_value(results)?)
                }
            })
    ).await?;

    server.serve().await
}
```

### Step 4: Start All Agents

```bash
# Terminal 1: Co-Driver
cd package/rust-crate/agent/co-driver
cargo run

# Terminal 2: Big Bear
cd package/rust-crate/agent/big-bear
cargo run

# Terminal 3: Cargo Connect
cd package/rust-crate/agent/cargo-connect
cargo run

# ... etc for other agents
```

### Step 5: Test Inter-Agent Communication

```rust
// Test script
let client = quick_start_client().await?;

// Co-Driver routes task to Big Bear
let result = client.call_tool(
    "co-driver",
    "route_task",
    serde_json::json!({
        "task": "Check weigh station on I-80",
        "priority": "high"
    })
).await?;

println!("Result: {}", result);
```

---

## 📊 Monitoring & Debugging

### Health Checks

```bash
# Check all agents
for port in 3001 3002 3003 3004 3005 3006; do
  echo "Agent on port $port:"
  curl -s http://localhost:$port/health | jq
done
```

### Qdrant Statistics

```bash
# Collection info
curl http://localhost:6333/collections/codebase | jq

# Point count
curl http://localhost:6333/collections/codebase/points/count | jq
```

### View Logs

```bash
# Enable debug logging
export RUST_LOG=debug

# Run agent with detailed logs
cargo run --example agent_server
```

### RAG Search Performance

```rust
// Measure search performance
let start = std::time::Instant::now();
let results = client.search(query).await?;
println!("Search took: {:?}", start.elapsed());
println!("Found {} results", results.len());
```

---

## 🔐 Security Best Practices

### 1. Enable Authentication

```toml
[security]
auth_enabled = true
auth_token = "${MCP_AUTH_TOKEN}"  # Use strong random token
```

### 2. Use TLS in Production

```toml
[security]
use_tls = true
cert_path = "/path/to/cert.pem"
key_path = "/path/to/key.pem"
```

### 3. Rate Limiting

```toml
[performance]
rate_limit_per_second = 100
```

### 4. Restrict CORS

```toml
[security]
cors_origins = [
    "https://yourdomain.com",
    "https://api.yourdomain.com"
]
```

### 5. Network Isolation

Use Marketeer as a gateway for all inter-agent communication.

---

## 🚢 Production Deployment

### Docker Compose Setup

`docker-compose.yml`:
```yaml
version: '3.8'

services:
  qdrant:
    image: qdrant/qdrant:latest
    volumes:
      - qdrant_data:/qdrant/storage
    ports:
      - "6333:6333"

  co-driver:
    build: ./agents/co-driver
    ports:
      - "3001:3001"
    environment:
      - MCP_AUTH_TOKEN=${CO_DRIVER_TOKEN}
      - QDRANT_HOST=qdrant
    depends_on:
      - qdrant

  big-bear:
    build: ./agents/big-bear
    ports:
      - "3003:3003"
    environment:
      - MCP_AUTH_TOKEN=${BIG_BEAR_TOKEN}
    depends_on:
      - co-driver

  # ... more agents

volumes:
  qdrant_data:
```

### Kubernetes Deployment

See `k8s/` directory for Kubernetes manifests (to be created).

---

## 📚 Additional Resources

### RAG System
- [rag::qdrant/README.md](rag::qdrant/README.md) - Full documentation
- [rag::qdrant/QUICKSTART.md](rag::qdrant/QUICKSTART.md) - Quick start guide
- [rag::qdrant/examples/](rag::qdrant/examples/) - Code examples

### MCP System
- [mcp/README.md](mcp/README.md) - Full documentation
- [mcp/QUICKSTART.md](mcp/QUICKSTART.md) - Quick start guide
- [mcp/examples/](mcp/examples/) - Code examples

### Architecture
- [/document/architecture.md](/home/admin/ws/OpenHWY/document/architecture.md) - System architecture
- [/document/SCHEMA.md](/home/admin/ws/OpenHWY/document/SCHEMA.md) - Database schema

---

## 🐛 Troubleshooting

### RAG System Issues

**Problem**: Embeddings API rate limit errors
```bash
# Solution: Reduce batch size in config.toml
[embedding]
batch_size = 50  # Reduce from 100
rate_limit_per_minute = 500  # Reduce from 1000
```

**Problem**: No search results
```bash
# Check collection has data
curl http://localhost:6333/collections/codebase/points/count

# If empty, re-index
cargo run --example index_codebase
```

**Problem**: Slow indexing
```bash
# Increase parallel workers in config.toml
[indexing]
parallel_workers = 8  # Increase from 4
```

### MCP System Issues

**Problem**: Agent not found
```bash
# Check agent is configured in config.toml
[[agents.known]]
name = "big-bear"
url = "http://localhost:3003"
enabled = true  # Make sure this is true

# Verify agent is running
curl http://localhost:3003/health
```

**Problem**: Authentication failures
```bash
# Verify tokens match
# In server .env:
MCP_AUTH_TOKEN=same_token_here

# In client config.toml:
[[agents.known]]
name = "server-name"
auth_token = "same_token_here"
```

**Problem**: Connection timeouts
```bash
# Increase timeout in config.toml
[performance]
request_timeout_seconds = 60  # Increase from 30
```

---

## 🎓 Next Steps

1. **Integrate with FED**: Add RAG-powered code search to your Flutter TMS app
2. **Build Co-Driver**: Create the orchestrator that routes tasks to agents
3. **Add Packet Pilot**: Implement document processing automation
4. **Deploy Cargo Connect**: Connect to load boards with intelligent filtering
5. **Scale**: Deploy to Kubernetes for production

---

## 💡 Pro Tips

1. **Index Often**: Re-index after major code changes
2. **Tune Thresholds**: Adjust `score_threshold` based on your use case
3. **Cache Aggressively**: Enable embedding caching for faster searches
4. **Monitor Performance**: Track search latency and adjust workers
5. **Use Semantic Chunking**: Better results for code search
6. **Start Small**: Begin with 2-3 agents, add more as needed
7. **Test Locally**: Use docker-compose before deploying to production

---

## 📝 License

Both systems are released under their respective licenses. See individual directories for details.

---

**Questions?** Check the individual README files or open an issue on GitHub.

**Ready to build?** Start with the Quick Start section above! 🚀
