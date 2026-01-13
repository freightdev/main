// Example: Interactive search demo

use qdrant_rag::{quick_start, SearchQuery};
use std::io::{self, Write};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize logging
    tracing_subscriber::fmt::init();

    println!("=== Qdrant RAG: Interactive Search Demo ===\n");

    // Initialize RAG client
    let client = quick_start().await?;
    println!("✓ RAG client initialized");

    // Check if collection has data
    let count = client.collection_info().await?;
    if count == 0 {
        println!("\n⚠ Collection is empty! Run `cargo run --example index_codebase` first.");
        return Ok(());
    }

    println!("Collection has {} documents\n", count);

    // Interactive search loop
    loop {
        print!("Enter search query (or 'quit' to exit): ");
        io::stdout().flush()?;

        let mut input = String::new();
        io::stdin().read_line(&mut input)?;
        let query_text = input.trim();

        if query_text.is_empty() {
            continue;
        }

        if query_text.eq_ignore_ascii_case("quit") || query_text.eq_ignore_ascii_case("exit") {
            println!("Goodbye!");
            break;
        }

        // Search
        let query = SearchQuery::new(query_text).with_top_k(5);

        match client.search(query).await {
            Ok(results) => {
                if results.is_empty() {
                    println!("\nNo results found.\n");
                    continue;
                }

                println!("\nFound {} results:\n", results.len());

                for (i, result) in results.iter().enumerate() {
                    println!("{}. {} (score: {:.2})", i + 1, result.file_path, result.score);
                    if let Some(line_start) = result.metadata.line_start {
                        println!("   Lines: {}-{}", line_start, result.metadata.line_end.unwrap_or(line_start));
                    }
                    if let Some(lang) = &result.metadata.language {
                        println!("   Language: {}", lang);
                    }
                    println!("   Preview: {}\n", &result.content[..result.content.len().min(150)].replace('\n', " "));
                }
            }
            Err(e) => {
                eprintln!("Error searching: {}", e);
            }
        }
    }

    Ok(())
}
