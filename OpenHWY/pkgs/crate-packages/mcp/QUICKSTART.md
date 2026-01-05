# Quick Start Guide - MCP (Model Context Protocol)

Get your MCP agent system running in 5 minutes.

## Prerequisites

- Rust (1.70+)
- Basic understanding of HTTP APIs

## Step 1: Configure

```bash
# Copy environment variables
cp .env.example .env

# Edit .env
nano .env
```

Set your agent name and port:
```bash
MCP_SERVER_NAME=my-agent
MCP_SERVER_PORT=3000
MCP_AUTH_TOKEN=your_secret_token_here
```

Optionally, edit `config.toml` to register known agents.

## Step 2: Run Example Server

```bash
# Start the example agent server
cargo run --example agent_server

# You should see:
# ✓ MCP server initialized
# ✓ Registered tool: echo
# ✓ Registered tool: add
# ✓ Registered tool: status
# Server listening on 0.0.0.0:3000
```

## Step 3: Test Your Agent

In another terminal:

```bash
# Health check
curl http://localhost:3000/health

# List available tools
curl http://localhost:3000/tools

# Call the echo tool
curl -X POST http://localhost:3000/tools/echo \
  -H 'Content-Type: application/json' \
  -d '{"message":"Hello MCP!"}'

# Call the add tool
curl -X POST http://localhost:3000/tools/add \
  -H 'Content-Type: application/json' \
  -d '{"a":10,"b":5}'
```

## Step 4: Use the Client

```bash
# In another terminal, run the client example
cargo run --example agent_client

# This will:
# 1. Call tools on your agent
# 2. List available tools
# 3. Check agent health
# 4. Get agent info
```

## Step 5: Build Your Own Agent

```rust
use mcp_rust::{quick_start_server, Tool, Resource};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let mut server = quick_start_server().await?;

    // Register your tools
    server.register_tool(
        Tool::new("my_tool", "What this tool does")
            .with_handler(|params| async move {
                // Your logic here
                Ok(serde_json::json!({"result": "success"}))
            })
    ).await?;

    // Register your resources
    server.register_resource(
        Resource::new("my_data", "database", "postgres://...")
    ).await?;

    // Start serving
    server.serve().await?;
    Ok(())
}
```

## Multi-Agent System

Start multiple agents on different ports:

### Terminal 1: Co-Driver (Orchestrator)
```bash
# Edit config.toml:
# [server]
# name = "co-driver"
# port = 3001

cargo run --example agent_server
```

### Terminal 2: Big Bear (Worker Agent)
```bash
# Edit config.toml:
# [server]
# name = "big-bear"
# port = 3003

cargo run --example agent_server
```

### Terminal 3: Call from One Agent to Another

```rust
use mcp_rust::quick_start_client;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let client = quick_start_client().await?;

    // Call Big Bear from Co-Driver
    let result = client.call_tool(
        "big-bear",
        "track_location",
        serde_json::json!({"driver_id": "DRV-001"})
    ).await?;

    println!("Result: {}", result);
    Ok(())
}
```

## Adding Authentication

In your config.toml:
```toml
[security]
auth_enabled = true
auth_token = "${MCP_AUTH_TOKEN}"
```

Then clients must include the token:
```bash
curl -X POST http://localhost:3000/tools/echo \
  -H 'Authorization: Bearer your_secret_token_here' \
  -H 'Content-Type: application/json' \
  -d '{"message":"Hello"}'
```

## Troubleshooting

### Port already in use
```bash
# Change the port in config.toml
[server]
port = 3001  # or any other available port
```

### Agent not found error
- Verify the agent is listed in `config.toml` under `[[agents.known]]`
- Check the agent is running and the URL is correct
- Ensure `enabled = true` in the agent configuration

### Connection refused
- Verify the server is running: `curl http://localhost:3000/health`
- Check firewall settings
- Verify the port in config matches

## Next Steps

- Read the full [README.md](README.md) for advanced features
- Check [examples/](examples/) for more patterns
- Integrate with DragonflyDB for pub/sub
- Add service discovery with etcd
- Connect to Marketeer for security

## Integration with Other Systems

### With RAG (Qdrant)
```rust
// In your agent
let rag = qdrant_rag::quick_start().await?;

server.register_tool(
    Tool::new("search_code", "Search codebase")
        .with_handler(move |params| {
            let rag = rag.clone();
            async move {
                let query = params["query"].as_str().unwrap();
                let results = rag.search(SearchQuery::new(query)).await?;
                Ok(serde_json::to_value(results)?)
            }
        })
).await?;
```

### With DragonflyDB
Enable in config.toml:
```toml
[integrations.dragonfly]
enabled = true
host = "localhost"
port = 6379
```

Ready to build your distributed agent system? See the [README.md](README.md) for architecture details!
