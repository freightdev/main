// Co-Driver - API Gateway & Orchestrator
// Entry point for the Co-Driver service

use anyhow::Result;
use codriver::CoDriverApp;
use tracing::{error, info};

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .with_target(false)
        .init();

    info!("🤖 Co-Driver API Gateway Starting");

    let app = CoDriverApp::new().await?;
    
    if let Err(e) = app.run().await {
        error!("❌ Co-Driver failed: {}", e);
        return Err(e);
    }

    Ok(())
}
