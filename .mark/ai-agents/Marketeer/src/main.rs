// Marketeer - Edge Router
// Entry point for Marketeer service

use anyhow::Result;
use marketeer::MarketeerApp;
use tracing::{error, info};

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .with_target(false)
        .init();

    info!("🛡️  Marketeer Edge Router Starting");

    let app = MarketeerApp::new().await?;
    
    if let Err(e) = app.run().await {
        error!("❌ Marketeer failed: {}", e);
        return Err(e);
    }

    Ok(())
}
