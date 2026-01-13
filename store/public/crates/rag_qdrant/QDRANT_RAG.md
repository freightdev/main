# Qdrant RAG - Production-Ready Semantic Code Search

A plug-and-play Rust crate for building production-ready RAG (Retrieval-Augmented Generation) systems using Qdrant vector database.

## Features

- 🚀 **Plug-and-Play**: Just configure and run
- 🔍 **Semantic Search**: Find code by meaning, not just keywords
- 📦 **Multi-Repository Support**: Index multiple codebases
- ⚡ **High Performance**: Parallel indexing and caching
- 🎯 **Smart Chunking**: Semantic, fixed, or adaptive strategies
- 🔌 **Multiple Embedding Providers**: OpenAI, Anthropic, Local, Ollama
- 📊 **Rich Metadata**: Git info, file stats, syntax trees
- 🛡️ **Production Ready**: Error handling, logging, rate limiting

## Quick Start

### 1. Installation

Add to your `Cargo.toml`:

```toml
[dependencies]
qdrant-rag = { path = "../qdrant-rag" }
```

### 2. Configuration

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Edit `.env`:
```bash
QDRANT_HOST=localhost
QDRANT_PORT=6333
EMBEDDING_PROVIDER=anthropic
EMBEDDING_API_KEY=your_api_key_here
```

### 3. Basic Usage

```rust
use qdrant_rag::{quick_start, SearchQuery};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize with default config.toml
    let client = quick_start().await?;
    
    // Index your codebase
    client.index_directory("../../lib/ai-crates").await?;
    
    // Search semantically
    let query = SearchQuery::new("How do I generate leads?");
    let results = client.search(query).await?;
    
    for result in results {
        println!("File: {}", result.file_path);
        println!("Score: {:.2}", result.score);
        println!("Code: {}\n", result.content);
    }
    
    Ok(())
}
```

## Configuration

### Config File (`config.toml`)

```toml
[qdrant]
host = "localhost"
port = 6333

[embedding]
provider = "anthropic"
model = "voyage-2"
api_key = "${EMBEDDING_API_KEY}"

[indexing]
root_path = "../../"
include_patterns = ["**/*.rs", "**/*.toml", "**/*.md"]
exclude_patterns = ["**/target/**", "**/node_modules/**"]
```

### Environment Variables

All config values can be overridden with environment variables:

```bash
QDRANT_HOST=remote-server
QDRANT_PORT=6333
EMBEDDING_PROVIDER=anthropic
EMBEDDING_API_KEY=sk-xxx
```

## Embedding Providers

### Anthropic (Recommended)
```toml
[embedding]
provider = "anthropic"
model = "voyage-2"
api_key = "${EMBEDDING_API_KEY}"
```

### OpenAI
```toml
[embedding]
provider = "openai"
model = "text-embedding-3-small"
api_key = "${OPENAI_API_KEY}"
```

### Local Model
```toml
[embedding]
provider = "local"
[embedding.local]
model_path = "/path/to/model"
device = "cuda"
```

### Ollama
```toml
[embedding]
provider = "ollama"
model = "nomic-embed-text"
api_url = "http://localhost:11434"
```

## Chunking Strategies

### Semantic (Recommended for Code)
Respects code structure boundaries:
```toml
[chunking]
strategy = "semantic"
respect_boundaries = ["function", "impl", "struct", "enum", "mod"]
```

### Fixed Size
Simple fixed-size chunks:
```toml
[chunking]
strategy = "fixed"
size = 512
overlap = 50
```

### Adaptive
Dynamically adjusts chunk size:
```toml
[chunking]
strategy = "adaptive"
min_size = 100
max_size = 2048
```

## Advanced Usage

### Index Multiple Repositories

```toml
[[repositories.external]]
name = "agent-templates"
path = "/path/to/agent/templates"
enabled = true

[[repositories.external]]
name = "shared-crates"
path = "/path/to/shared/crates"
enabled = true
```

### Filtered Search

```rust
use qdrant_rag::{SearchQuery, SearchFilter};

let query = SearchQuery::new("authentication logic")
    .with_filter(SearchFilter {
        file_types: Some(vec!["rs".to_string()]),
        paths: Some(vec!["lib/ai-crates/auth/**".to_string()]),
        exclude_paths: Some(vec!["**/tests/**".to_string()]),
    })
    .with_top_k(20)
    .with_threshold(0.8);

let results = client.search(query).await?;
```

### Custom Metadata

```toml
[metadata]
include_git_info = true
include_file_stats = true
include_syntax_tree = true
custom_tags = ["team:backend", "priority:high"]
```

## Performance Tuning

### Indexing Performance
```toml
[indexing]
parallel_workers = 8
max_file_size_mb = 10

[performance]
max_concurrent_requests = 20
cache_embeddings = true
cache_ttl_seconds = 7200
```

### Search Performance
```toml
[search]
top_k = 10
score_threshold = 0.7
prefetch_enabled = true
```

## Examples

### Example 1: Index Entire Project
```bash
cargo run --example index_codebase
```

### Example 2: Interactive Search
```bash
cargo run --example search_demo
```

### Example 3: Agent Integration
```rust
// In your agent code
use qdrant_rag::RagClient;

let rag = RagClient::from_config("config.toml").await?;

// Agent receives task: "Find code that handles user authentication"
let results = rag.search("user authentication handling").await?;

// Use results to generate context for LLM
let context = results.into_iter()
    .map(|r| format!("// {}\n{}", r.file_path, r.content))
    .collect::<Vec<_>>()
    .join("\n\n");
```

## Integration with Your Agent System

### Co-Driver (Dispatcher) Integration
```rust
// In Co-Driver
use qdrant_rag::RagClient;

struct CoDriver {
    rag: RagClient,
    // ... other fields
}

impl CoDriver {
    async fn find_relevant_crate(&self, task: &str) -> Result<String> {
        let results = self.rag.search(task).await?;
        // Determine which crate to use based on results
        Ok(results[0].file_path.clone())
    }
}
```

### Agent Builder Integration
```rust
// In Agent Builder
async fn build_agent_with_context(&self, spec: AgentSpec) -> Result<Agent> {
    // Find relevant code examples
    let examples = self.rag
        .search(&format!("agent {} implementation", spec.agent_type))
        .await?;
    
    // Use examples to build agent
    self.construct_agent(spec, examples).await
}
```

## Monitoring & Logging

```toml
[logging]
level = "info"
format = "json"
log_file = "logs/qdrant-rag.log"
```

View logs:
```bash
tail -f logs/qdrant-rag.log | jq
```

## Troubleshooting

### Qdrant Connection Issues
```bash
# Check Qdrant is running
curl http://localhost:6333/health

# Start Qdrant with Docker
docker run -p 6333:6333 qdrant/qdrant
```

### Embedding API Issues
- Verify API key is correct
- Check rate limits
- Enable verbose logging: `RUST_LOG=qdrant_rag=debug`

### Memory Issues
- Reduce `parallel_workers`
- Decrease `embedding.batch_size`
- Enable `on_disk_payload`
