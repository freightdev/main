// Example: Simple MCP agent server

use mcp_rust::{init_server, Tool};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize logging
    tracing_subscriber::fmt::init();

    println!("=== MCP Agent Server Example ===\n");

    // Initialize server from config.toml
    let mut server = init_server(Some("config.toml")).await?;
    println!("✓ MCP server initialized\n");

    // Register a simple echo tool
    server.register_tool(
        Tool::new("echo", "Echo back the input")
            .with_parameters(serde_json::json!({
                "type": "object",
                "properties": {
                    "message": {
                        "type": "string",
                        "description": "The message to echo"
                    }
                },
                "required": ["message"]
            }))
            .with_handler(|params| async move {
                let message = params["message"].as_str().unwrap_or("No message");
                Ok(serde_json::json!({
                    "echo": message
                }))
            })
    ).await?;

    println!("✓ Registered tool: echo");

    // Register a calculation tool
    server.register_tool(
        Tool::new("add", "Add two numbers")
            .with_parameters(serde_json::json!({
                "type": "object",
                "properties": {
                    "a": { "type": "number" },
                    "b": { "type": "number" }
                },
                "required": ["a", "b"]
            }))
            .with_handler(|params| async move {
                let a = params["a"].as_f64().unwrap_or(0.0);
                let b = params["b"].as_f64().unwrap_or(0.0);
                let sum = a + b;
                Ok(serde_json::json!({
                    "result": sum
                }))
            })
    ).await?;

    println!("✓ Registered tool: add");

    // Register a status tool
    server.register_tool(
        Tool::new("status", "Get agent status")
            .with_handler(|_params| async move {
                Ok(serde_json::json!({
                    "status": "online",
                    "uptime": "running",
                    "version": env!("CARGO_PKG_VERSION")
                }))
            })
    ).await?;

    println!("✓ Registered tool: status\n");

    println!("Server ready! Try these commands:");
    println!("  curl http://localhost:3000/health");
    println!("  curl http://localhost:3000/tools");
    println!("  curl -X POST http://localhost:3000/tools/echo -H 'Content-Type: application/json' -d '{{\"message\":\"Hello\"}}'");
    println!("  curl -X POST http://localhost:3000/tools/add -H 'Content-Type: application/json' -d '{{\"a\":5,\"b\":3}}'\n");

    // Start serving
    server.serve().await?;

    Ok(())
}
