# Quick Start Guide - Qdrant RAG

Get up and running with the Qdrant RAG system in 5 minutes.

## Prerequisites

- Rust (1.70+)
- Docker (for Qdrant)
- Embedding API key (Anthropic, OpenAI, or local Ollama)

## Step 1: Start Qdrant

```bash
# Start Qdrant with Docker Compose
docker-compose up -d

# Verify Qdrant is running
curl http://localhost:6333/health
```

You should see: `{"title":"qdrant - vector search engine","version":"..."}`

## Step 2: Configure

```bash
# Copy environment variables
cp .env.example .env

# Edit .env and add your API key
nano .env
```

Set your embedding provider:
```bash
# For Anthropic
EMBEDDING_PROVIDER=anthropic
EMBEDDING_API_KEY=your_anthropic_key_here

# OR for OpenAI
EMBEDDING_PROVIDER=openai
EMBEDDING_API_KEY=sk-your_openai_key_here

# OR for local Ollama
EMBEDDING_PROVIDER=ollama
EMBEDDING_API_URL=http://localhost:11434
```

## Step 3: Index Your Codebase

```bash
# Index the OpenHWY codebase
cargo run --example index_codebase

# This will:
# 1. Connect to Qdrant
# 2. Scan your codebase
# 3. Generate embeddings
# 4. Store in vector database
```

## Step 4: Search

```bash
# Run interactive search
cargo run --example search_demo
```

Example queries:
- "How do I implement agent communication?"
- "Load board integration code"
- "Authentication and security"
- "Database connection handling"

## Step 5: Use in Your Code

```rust
use qdrant_rag::{quick_start, SearchQuery};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize
    let client = quick_start().await?;

    // Index
    client.index_directory("../../lib/ai-crates").await?;

    // Search
    let query = SearchQuery::new("agent tools");
    let results = client.search(query).await?;

    for result in results {
        println!("{}: {}", result.file_path, result.score);
    }

    Ok(())
}
```

## Troubleshooting

### Qdrant not starting
```bash
# Check logs
docker logs qdrant-rag

# Restart
docker-compose restart
```

### Embedding API errors
- Verify API key is correct
- Check rate limits
- Try reducing `batch_size` in config.toml

### No results found
- Ensure you ran `index_codebase` first
- Lower `score_threshold` in config.toml
- Try different search queries

## Next Steps

- Read the full [README.md](README.md) for advanced features
- Check [examples/](examples/) for more usage patterns
- Customize [config.toml](config.toml) for your needs
- Integrate with your agents (see README)

## Quick Commands

```bash
# Start Qdrant
docker-compose up -d

# Stop Qdrant
docker-compose down

# View Qdrant logs
docker logs -f qdrant-rag

# Check collection status
curl http://localhost:6333/collections

# Reset everything
docker-compose down -v  # Warning: deletes all data!
docker-compose up -d
```

## Performance Tips

For large codebases (>10GB):
1. Increase `parallel_workers` in config.toml
2. Use `semantic` chunking strategy
3. Enable `cache_embeddings`
4. Consider using local Ollama for faster embedding generation

Ready to integrate with your agents? See the [README.md](README.md) Integration section!
