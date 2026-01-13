#!/usr/bin/env bash
# Setup script for qdrant-rag and mcp-rust crates

set -e

echo "🚀 Setting up Qdrant RAG and MCP-Rust crates..."

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directories
RAG_DIR="lib/ai-crates/qdrant-rag"
MCP_DIR="lib/ai-crates/mcp-rust"

# Function to setup a crate
setup_crate() {
    local dir=$1
    local name=$2

    echo -e "${BLUE}📦 Setting up ${name}...${NC}"

    # Create directory structure
    mkdir -p "$dir/src"
    mkdir -p "$dir/examples"
    mkdir -p "$dir/logs"
    mkdir -p "$dir/tools"
    mkdir -p "$dir/resources"

    # Copy env example to .env if it doesn't exist
    if [ ! -f "$dir/.env" ] && [ -f "$dir/.env.example" ]; then
        echo -e "${YELLOW}  ⚙️  Creating .env from .env.example${NC}"
        cp "$dir/.env.example" "$dir/.env"
        echo -e "${YELLOW}  ⚠️  Please edit $dir/.env with your configuration${NC}"
    fi

    echo -e "${GREEN}  ✅ ${name} structure created${NC}"
}

# Setup Qdrant RAG
echo ""
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}  Qdrant RAG Setup${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
setup_crate "$RAG_DIR" "Qdrant RAG"

# Setup MCP-Rust
echo ""
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}  MCP-Rust Setup${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
setup_crate "$MCP_DIR" "MCP-Rust"

# Check for dependencies
echo ""
echo -e "${BLUE}🔍 Checking dependencies...${NC}"

# Check Rust
if command -v cargo &> /dev/null; then
    echo -e "${GREEN}  ✅ Rust/Cargo installed${NC}"
else
    echo -e "${YELLOW}  ⚠️  Rust not found. Install from https://rustup.rs/${NC}"
fi

# Check Docker (for Qdrant)
if command -v docker &> /dev/null; then
    echo -e "${GREEN}  ✅ Docker installed${NC}"

    # Check if Qdrant is running
    if curl -s http://localhost:6333/health &> /dev/null; then
        echo -e "${GREEN}  ✅ Qdrant is running${NC}"
    else
        echo -e "${YELLOW}  ⚠️  Qdrant not running. Start with:${NC}"
        echo "     docker run -p 6333:6333 -v $(pwd)/qdrant_storage:/qdrant/storage qdrant/qdrant"
    fi
else
    echo -e "${YELLOW}  ⚠️  Docker not found. Install from https://docker.com/${NC}"
fi

# Check etcd (optional for service discovery)
if command -v etcdctl &> /dev/null; then
    echo -e "${GREEN}  ✅ etcd installed (optional)${NC}"
else
    echo -e "${BLUE}  ℹ️  etcd not found (optional for service discovery)${NC}"
fi

# Build check
echo ""
echo -e "${BLUE}🔨 Checking if crates build...${NC}"

if [ -f "$RAG_DIR/Cargo.toml" ]; then
    echo -e "${BLUE}  Building qdrant-rag...${NC}"
    cd "$RAG_DIR"
    if cargo check --quiet 2>/dev/null; then
        echo -e "${GREEN}  ✅ qdrant-rag builds successfully${NC}"
    else
        echo -e "${YELLOW}  ⚠️  qdrant-rag has build issues (expected if incomplete)${NC}"
    fi
    cd - > /dev/null
fi

if [ -f "$MCP_DIR/Cargo.toml" ]; then
    echo -e "${BLUE}  Building mcp-rust...${NC}"
    cd "$MCP_DIR"
    if cargo check --quiet 2>/dev/null; then
        echo -e "${GREEN}  ✅ mcp-rust builds successfully${NC}"
    else
        echo -e "${YELLOW}  ⚠️  mcp-rust has build issues (expected if incomplete)${NC}"
    fi
    cd - > /dev/null
fi

# Create agents.json for MCP
echo ""
echo -e "${BLUE}📝 Creating default agents.json...${NC}"
cat > "$MCP_DIR/agents.json" << 'EOF'
{
  "agents": [
    {
      "name": "co-driver",
      "url": "http://localhost:3001",
      "capabilities": ["orchestration", "task-routing", "agent-building"],
      "enabled": true
    },
    {
      "name": "marketeer",
      "url": "http://localhost:3002",
      "capabilities": ["security", "routing", "marking"],
      "enabled": true
    },
    {
      "name": "big-bear",
      "url": "http://localhost:3003",
      "capabilities": ["geo-tracking", "alerts", "weigh-stations"],
      "enabled": true
    },
    {
      "name": "cargo-connect",
      "url": "http://localhost:3004",
      "capabilities": ["load-boards", "freight-matching"],
      "enabled": true
    },
    {
      "name": "legal-logger",
      "url": "http://localhost:3005",
      "capabilities": ["compliance", "audit-logs", "encryption"],
      "enabled": true
    }
  ]
}
EOF
echo -e "${GREEN}  ✅ agents.json created${NC}"

# Summary
echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Setup Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo "1. Configure your environment:"
echo "   ${YELLOW}cd $RAG_DIR && vim .env${NC}"
echo "   ${YELLOW}cd $MCP_DIR && vim .env${NC}"
echo ""
echo "2. Start Qdrant (if not running):"
echo "   ${YELLOW}docker run -p 6333:6333 -v \$(pwd)/qdrant_storage:/qdrant/storage qdrant/qdrant${NC}"
echo ""
echo "3. Test Qdrant RAG:"
echo "   ${YELLOW}cd $RAG_DIR${NC}"
echo "   ${YELLOW}cargo run --example index_codebase${NC}"
echo "   ${YELLOW}cargo run --example search_demo${NC}"
echo ""
echo "4. Test MCP Server:"
echo "   ${YELLOW}cd $MCP_DIR${NC}"
echo "   ${YELLOW}cargo run --example agent_server${NC}"
echo ""
echo "5. Test MCP Client:"
echo "   ${YELLOW}cd $MCP_DIR${NC}"
echo "   ${YELLOW}cargo run --example agent_client${NC}"
echo ""
echo "6. Integrate into your agents:"
echo "   ${YELLOW}# Add to your agent's Cargo.toml:${NC}"
echo "   ${YELLOW}qdrant-rag = { path = \"../ai-crates/qdrant-rag\" }${NC}"
echo "   ${YELLOW}mcp-rust = { path = \"../ai-crates/mcp-rust\" }${NC}"
echo ""
echo -e "${BLUE}📚 Documentation:${NC}"
echo "   - Qdrant RAG: $RAG_DIR/README.md"
echo "   - MCP-Rust: $MCP_DIR/README.md"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"
