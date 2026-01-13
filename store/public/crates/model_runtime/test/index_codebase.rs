// Example: Index a codebase with Qdrant RAG

use qdrant_rag::{quick_start, SearchQuery};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize logging
    tracing_subscriber::fmt::init();

    println!("=== Qdrant RAG: Index Codebase Example ===\n");

    // Initialize RAG client from config.toml
    println!("Initializing RAG client...");
    let client = quick_start().await?;
    println!("✓ RAG client initialized\n");

    // Check collection status
    let count = client.collection_info().await?;
    println!("Current collection has {} documents\n", count);

    // Index a directory
    println!("Indexing directory: ../../");
    let chunks = client.index_directory("../../").await?;
    println!("✓ Indexed {} chunks\n", chunks);

    // Verify indexing
    let count = client.collection_info().await?;
    println!("Collection now has {} documents\n", count);

    // Example search
    println!("Testing search: 'agent communication protocol'");
    let query = SearchQuery::new("agent communication protocol").with_top_k(3);
    let results = client.search(query).await?;

    println!("\nFound {} results:", results.len());
    for (i, result) in results.iter().enumerate() {
        println!("\n--- Result {} (score: {:.2}) ---", i + 1, result.score);
        println!("File: {}", result.file_path);
        if let Some(line_start) = result.metadata.line_start {
            println!("Lines: {}-{}", line_start, result.metadata.line_end.unwrap_or(line_start));
        }
        println!("Preview: {}", &result.content[..result.content.len().min(200)]);
    }

    Ok(())
}
