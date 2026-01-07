// Example: MCP agent client

use mcp_rust::{init_client};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize logging
    tracing_subscriber::fmt::init();

    println!("=== MCP Agent Client Example ===\n");

    // Initialize client from config.toml
    let client = init_client(Some("config.toml")).await?;
    println!("✓ MCP client initialized\n");

    // Example 1: Call echo tool
    println!("1. Calling 'echo' tool on 'my-agent'...");
    match client.call_tool(
        "my-agent",
        "echo",
        serde_json::json!({
            "message": "Hello from client!"
        })
    ).await {
        Ok(response) => {
            println!("   Response: {}", response);
        }
        Err(e) => {
            eprintln!("   Error: {}", e);
        }
    }

    // Example 2: Call add tool
    println!("\n2. Calling 'add' tool on 'my-agent'...");
    match client.call_tool(
        "my-agent",
        "add",
        serde_json::json!({
            "a": 42,
            "b": 13
        })
    ).await {
        Ok(response) => {
            println!("   Response: {}", response);
        }
        Err(e) => {
            eprintln!("   Error: {}", e);
        }
    }

    // Example 3: List available tools
    println!("\n3. Listing tools on 'my-agent'...");
    match client.list_tools("my-agent").await {
        Ok(tools) => {
            println!("   Available tools:");
            for tool in tools {
                println!("     - {} : {}", tool.name, tool.description);
            }
        }
        Err(e) => {
            eprintln!("   Error: {}", e);
        }
    }

    // Example 4: Health check
    println!("\n4. Health check on 'my-agent'...");
    match client.health_check("my-agent").await {
        Ok(healthy) => {
            println!("   Status: {}", if healthy { "✓ Healthy" } else { "✗ Unhealthy" });
        }
        Err(e) => {
            eprintln!("   Error: {}", e);
        }
    }

    // Example 5: Get agent info
    println!("\n5. Getting agent info...");
    match client.get_agent_info("my-agent").await {
        Ok(info) => {
            println!("   Info: {}", serde_json::to_string_pretty(&info)?);
        }
        Err(e) => {
            eprintln!("   Error: {}", e);
        }
    }

    println!("\n✓ Client demo complete");

    Ok(())
}
