# MCP-Rust - Model Context Protocol for Distributed Agents

A production-ready Rust implementation of the Model Context Protocol (MCP) for building distributed, communicating AI agent systems.

## Features

- 🤖 **Agent-to-Agent Communication**: Standardized protocol for inter-agent messaging
- 🔧 **Tool Registry**: Register and discover agent capabilities
- 📦 **Resource Management**: Share resources across agents
- 🔍 **Service Discovery**: Automatic agent discovery (etcd, Consul, or manual)
- 🛡️ **Security**: Token-based auth, CORS, rate limiting
- 🚀 **High Performance**: Async I/O, connection pooling, compression
- 📊 **Observability**: Health checks, metrics, structured logging
- 🔌 **Plug-and-Play**: Just configure and run

## Quick Start

### 1. Installation

Add to your `Cargo.toml`:

```toml
[dependencies]
mcp-rust = { path = "../mcp-rust" }
tokio = { version = "1", features = ["full"] }
```

### 2. Configuration

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

Edit `.env`:
```bash
MCP_SERVER_NAME=my-agent
MCP_SERVER_PORT=3000
MCP_AUTH_TOKEN=your_secret_token
```

### 3. Start an MCP Server

```rust
use mcp_rust::{quick_start_server, Tool, Resource};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Start server with config.toml
    let mut server = quick_start_server().await?;
    
    // Register a tool
    server.register_tool(Tool {
        name: "search_code".to_string(),
        description: "Search codebase semantically".to_string(),
        handler: Box::new(|params| async move {
            // Your tool logic here
            Ok(serde_json::json!({"results": []}))
        }),
    })?;
    
    // Register a resource
    server.register_resource(Resource {
        name: "codebase".to_string(),
        resource_type: "filesystem".to_string(),
        uri: "file://../../".to_string(),
    })?;
    
    // Start serving
    server.serve().await?;
    
    Ok(())
}
```

### 4. Call Another Agent

```rust
use mcp_rust::{quick_start_client, Request};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let client = quick_start_client().await?;
    
    // Call a tool on another agent
    let response = client.call_tool(
        "co-driver",  // Agent name
        "route_task", // Tool name
        serde_json::json!({
            "task": "Find leads in trucking industry",
            "priority": "high"
        })
    ).await?;
    
    println!("Response: {:?}", response);
    
    Ok(())
}
```

## Architecture

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│  Co-Driver  │◄───────►│  Marketeer  │◄───────►│  Big Bear   │
│   (Port     │   MCP   │   (Port     │   MCP   │   (Port     │
│    3001)    │         │    3002)    │         │    3003)    │
└─────────────┘         └─────────────┘         └─────────────┘
       ▲                       ▲                       ▲
       │                       │                       │
       └───────────────────────┴───────────────────────┘
                          MCP Protocol
```

## Configuration

### Basic Server Config

```toml
[server]
host = "0.0.0.0"
port = 3000
name = "my-agent"
description = "My AI Agent"

[security]
auth_enabled = true
auth_token = "${MCP_AUTH_TOKEN}"
cors_origins = ["http://localhost:3000"]
```

### Register Known Agents

```toml
[[agents.known]]
name = "co-driver"
url = "http://localhost:3001"
capabilities = ["orchestration", "task-routing"]
enabled = true

[[agents.known]]
name = "marketeer"
url = "http://localhost:3002"
capabilities = ["security", "routing"]
enabled = true
```

### Service Discovery with etcd

```toml
[discovery]
enabled = true
type = "etcd"
etcd_endpoints = ["http://localhost:2379"]
registry_ttl_seconds = 60
heartbeat_interval_seconds = 30
```

## Core Concepts

### Tools

Tools are functions/capabilities your agent exposes:

```rust
use mcp_rust::Tool;

let tool = Tool {
    name: "analyze_sentiment".to_string(),
    description: "Analyze sentiment of text".to_string(),
    parameters: serde_json::json!({
        "type": "object",
        "properties": {
            "text": {"type": "string"}
        },
        "required": ["text"]
    }),
    handler: Box::new(|params| async move {
        let text = params["text"].as_str().unwrap();
        // Your analysis logic
        Ok(serde_json::json!({
            "sentiment": "positive",
            "score": 0.8
        }))
    }),
};

server.register_tool(tool)?;
```

### Resources

Resources are data/content your agent provides:

```rust
use mcp_rust::Resource;

let resource = Resource {
    name: "load_data".to_string(),
    resource_type: "database".to_string(),
    uri: "postgres://localhost/loads".to_string(),
    metadata: serde_json::json!({
        "tables": ["loads", "drivers", "routes"]
    }),
};

server.register_resource(resource)?;
```

### Calling Other Agents

```rust
// Call a tool
let response = client
    .call_tool("big-bear", "track_location", serde_json::json!({
        "driver_id": "DRV-001",
        "timestamp": "2024-01-01T12:00:00Z"
    }))
    .await?;

// Access a resource
let resource = client
    .get_resource("legal-logger", "audit_log")
    .await?;

// List agent capabilities
let tools = client.list_tools("co-driver").await?;
let resources = client.list_resources("cargo-connect").await?;
```

## Integration Examples

### Co-Driver (Orchestrator)

```rust
use mcp_rust::{McpServer, Tool};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let mut server = McpServer::from_config("co-driver-config.toml").await?;
    
    // Register orchestration tool
    server.register_tool(Tool {
        name: "dispatch_task".to_string(),
        description: "Route task to appropriate agent".to_string(),
        handler: Box::new(|params| async move {
            let task = params["task"].as_str().unwrap();
            
            // Use RAG to find relevant agent
            let rag = qdrant_rag::quick_start().await?;
            let results = rag.search(task).await?;
            
            // Route to agent
            let agent = determine_agent(&results);
            let client = mcp_rust::quick_start_client().await?;
            
            client.call_tool(agent, "execute", params).await
        }),
    })?;
    
    server.serve().await
}
```

### Marketeer (Security Router)

```rust
use mcp_rust::{McpServer, middleware};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let mut server = McpServer::from_config("marketeer-config.toml").await?;
    
    // Add security middleware
    server.use_middleware(middleware::auth_required());
    server.use_middleware(middleware::rate_limit(100));
    server.use_middleware(middleware::audit_log());
    
    // Register routing tool
    server.register_tool(Tool {
        name: "route_request".to_string(),
        description: "Securely route request to agent".to_string(),
        handler: Box::new(|params| async move {
            // Verify request
            verify_security(&params)?;
            
            // Mark the request
            let marked = mark_request(&params);
            
            // Forward to target
            forward_to_agent(marked).await
        }),
    })?;
    
    server.serve().await
}
```

### Specialized Agent (Big Bear)

```rust
use mcp_rust::{McpServer, Tool};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let mut server = McpServer::from_config("big-bear-config.toml").await?;
    
    // Register domain-specific tools
    server.register_tool(Tool {
        name: "track_weigh_station".to_string(),
        description: "Track weigh station status".to_string(),
        handler: Box::new(|params| async move {
            // Big Bear specific logic
            track_weigh_station(params).await
        }),
    })?;
    
    server.register_tool(Tool {
        name: "alert_incident".to_string(),
        description: "Alert about road incident".to_string(),
        handler: Box::new(|params| async move {
            alert_incident(params).await
        }),
    })?;
    
    server.serve().await
}
```

## Advanced Features

### DragonflyDB Integration

```toml
[integrations.dragonfly]
enabled = true
host = "localhost"
port = 6379
channel_prefix = "mcp:"
subscribe_channels = ["agents:*", "tasks:*"]
publish_heartbeat = true
```

```rust
// Agents can communicate via pub/sub
server.subscribe("tasks:high_priority", |message| async move {
    handle_priority_task(message).await
})?;

server.publish("tasks:completed", result)?;
```

### Marketeer Integration

```toml
[integrations.marketeer]
enabled = true
url = "http://localhost:8000"
api_key = "${MARKETEER_API_KEY}"
verify_all_requests = true
```

All requests automatically go through Marketeer for security verification.

### Firecracker VM Orchestration

```toml
[firecracker]
enabled = true
socket_path = "/var/run/firecracker.sock"
vm_id_prefix = "mcp-agent"
```

Agents can be spawned in isolated Firecracker VMs.

## Health & Monitoring

### Health Checks

```bash
curl http://localhost:3000/health
```

Response:
```json
{
  "status": "healthy",
  "agent": "co-driver",
  "uptime_seconds": 3600,
  "checks": {
    "qdrant": "healthy",
    "dragonfly": "healthy"
  }
}
```

### Metrics (Prometheus)

```toml
[metrics]
enabled = true
path = "/metrics"
```

```bash
curl http://localhost:3000/metrics
```

## Examples

### Example 1: Simple Agent
```bash
cargo run --example agent_server
```

### Example 2: Agent Client
```bash
cargo run --example agent_client
```

### Example 3: Full System
```bash
# Terminal 1: Start Co-Driver
cd lib/ai-agents/co-driver
cargo run

# Terminal 2: Start Marketeer
cd lib/ai-agents/marketeer
cargo run

# Terminal 3: Start Big Bear
cd lib/ai-agents/big-bear
cargo run

# Terminal 4: Test communication
curl -X POST http://localhost:3001/tools/dispatch_task \
  -H "Authorization: Bearer ${MCP_AUTH_TOKEN}" \
  -d '{"task": "Track driver location"}'
```

## Security Best Practices

1. **Always use authentication** in production
2. **Use TLS** for remote connections
3. **Rotate tokens** regularly
4. **Rate limit** all endpoints
5. **Validate** all inputs
6. **Audit log** security events

## Performance Tuning

```toml
[performance]
max_connections = 1000
request_timeout_seconds = 30
rate_limit_per_second = 100
connection_pool_size = 100
```

## Troubleshooting

### Agent Not Discoverable
- Check etcd is running: `etcdctl get --prefix mcp:`
- Verify heartbeat: `RUST_LOG=mcp_rust=debug cargo run`

### Connection Refused
- Verify agent is running: `curl http://localhost:3000/health`
- Check firewall rules
- Verify ports in config

### Authentication Fails
- Check token matches in both client and server
- Verify `MCP_AUTH_TOKEN` env var is set
