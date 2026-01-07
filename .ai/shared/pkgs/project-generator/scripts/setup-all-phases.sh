#!/bin/bash
# ============================================================================
# MASTER SETUP SCRIPT
# Runs all phases (1-9) to complete project setup
# ============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Universal Project Generator - Complete Setup"
echo "  Running Phases 1-9"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${NC}"
echo

# ============================================================================
# Check Prerequisites
# ============================================================================
echo -e "${BLUE}Checking prerequisites...${NC}"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗ Python 3 not found${NC}"
    echo "  Please install Python 3.10 or higher"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
echo -e "${GREEN}✓ Python ${PYTHON_VERSION} found${NC}"

# Check if scripts exist
PHASES=(
    "setup-phase1-foundation.sh"
    "setup-phase2-core.sh"
    "setup-phase3-utilities.sh"
    "setup-phase4-clients.sh"
    "setup-phases-5-to-9-complete.sh"
)

for phase in "${PHASES[@]}"; do
    if [ ! -f "$SCRIPT_DIR/$phase" ]; then
        echo -e "${RED}✗ Missing: $phase${NC}"
        echo "  Please ensure all setup scripts are in the same directory"
        exit 1
    fi
    chmod +x "$SCRIPT_DIR/$phase"
done

echo -e "${GREEN}✓ All setup scripts found${NC}"
echo

# ============================================================================
# Run Setup Phases
# ============================================================================

START_TIME=$(date +%s)

# Phase 1: Foundation
echo -e "${BLUE}[1/5]${NC} Running Phase 1: Foundation..."
bash "$SCRIPT_DIR/setup-phase1-foundation.sh" || {
    echo -e "${RED}✗ Phase 1 failed${NC}"
    exit 1
}
echo

# Enter project directory
cd universal-project-generator || exit 1

# Phase 2: Core
echo -e "${BLUE}[2/5]${NC} Running Phase 2: Core Modules..."
bash "$SCRIPT_DIR/setup-phase2-core.sh" || {
    echo -e "${RED}✗ Phase 2 failed${NC}"
    exit 1
}
echo

# Phase 3: Utilities
echo -e "${BLUE}[3/5]${NC} Running Phase 3: Utilities..."
bash "$SCRIPT_DIR/setup-phase3-utilities.sh" || {
    echo -e "${RED}✗ Phase 3 failed${NC}"
    exit 1
}
echo

# Phase 4: Clients
echo -e "${BLUE}[4/5]${NC} Running Phase 4: Clients..."
bash "$SCRIPT_DIR/setup-phase4-clients.sh" || {
    echo -e "${RED}✗ Phase 4 failed${NC}"
    exit 1
}
echo

# Phases 5-9: Complete
echo -e "${BLUE}[5/5]${NC} Running Phases 5-9: Complete..."
bash "$SCRIPT_DIR/setup-phases-5-to-9-complete.sh" || {
    echo -e "${RED}✗ Phases 5-9 failed${NC}"
    exit 1
}
echo

# ============================================================================
# Create Virtual Environment
# ============================================================================
echo -e "${BLUE}Setting up Python virtual environment...${NC}"

if [ -d "venv" ]; then
    echo -e "${YELLOW}⚠  venv already exists, skipping creation${NC}"
else
    python3 -m venv venv
    echo -e "${GREEN}✓ Virtual environment created${NC}"
fi

# Activate and install dependencies
source venv/bin/activate

echo -e "${BLUE}Installing dependencies...${NC}"
pip install --upgrade pip > /dev/null 2>&1
pip install -r requirements.txt || {
    echo -e "${RED}✗ Failed to install dependencies${NC}"
    exit 1
}
echo -e "${GREEN}✓ Dependencies installed${NC}"

# Install in development mode
pip install -e . > /dev/null 2>&1
echo -e "${GREEN}✓ Package installed in development mode${NC}"

# ============================================================================
# Generate Example Configs
# ============================================================================
echo
echo -e "${BLUE}Generating example configurations...${NC}"

python -m src.cli.main examples || {
    echo -e "${YELLOW}⚠  Could not generate examples (Ollama may not be running)${NC}"
}

# ============================================================================
# Create Helper Scripts
# ============================================================================
echo
echo -e "${BLUE}Creating helper scripts...${NC}"

mkdir -p scripts

cat > scripts/activate.sh << 'ACTIVATE'
#!/bin/bash
# Activate virtual environment
source venv/bin/activate
echo "✓ Virtual environment activated"
echo "Run 'project-gen --help' to get started"
ACTIVATE

cat > scripts/test-connection.sh << 'TEST_CONN'
#!/bin/bash
# Test Ollama connections
source venv/bin/activate

python << 'PYTHON'
import sys
sys.path.insert(0, '.')

from src.core.config import ClusterConfig
from src.clients.ollama_client import OllamaClient
from src.utils.logger import setup_logging

logger = setup_logging("INFO")

try:
    config = ClusterConfig.from_yaml("config/cluster_config.yaml")
    
    print("\nTesting Ollama connections...")
    print("-" * 60)
    
    # Test each client
    for role in ['architect', 'coder', 'reviewer']:
        agent_config = getattr(config, role)
        try:
            client = OllamaClient(agent_config, logger)
            if client.is_healthy():
                print(f"✓ {role.upper()}: Connected ({agent_config.model})")
            else:
                print(f"✗ {role.upper()}: Unhealthy")
        except Exception as e:
            print(f"✗ {role.upper()}: Failed - {e}")
    
    print("-" * 60)
    print("\nConnection test complete!")
    
except Exception as e:
    print(f"✗ Failed to load config: {e}")
    sys.exit(1)
PYTHON
TEST_CONN

cat > scripts/run-example.sh << 'RUN_EXAMPLE'
#!/bin/bash
# Run example project generation
source venv/bin/activate

echo "Generating example Go microservice..."
echo

project-gen generate \
  --project config/examples/go_microservice.yaml \
  --cluster config/cluster_config.yaml

echo
echo "Check the output in: generated/auth-service/"
RUN_EXAMPLE

chmod +x scripts/*.sh

echo -e "${GREEN}✓ Helper scripts created${NC}"
echo "  - scripts/activate.sh (activate venv)"
echo "  - scripts/test-connection.sh (test Ollama)"
echo "  - scripts/run-example.sh (generate example)"

# ============================================================================
# Create Documentation
# ============================================================================
echo
echo -e "${BLUE}Creating documentation...${NC}"

cat > docs/GETTING_STARTED.md << 'GETTING_STARTED'
# Getting Started

## Quick Start

### 1. Activate Virtual Environment
```bash
source venv/bin/activate
# or
./scripts/activate.sh
```

### 2. Configure Your Cluster

Edit `config/cluster_config.yaml` with your Ollama node URLs:

```yaml
architect:
  base_url: http://192.168.1.102:11434  # Your L3 laptop
  model: qwen2.5-coder:32b

coder:
  base_url: http://192.168.1.100:11434  # Your L1 laptop
  model: qwen2.5-coder:14b

reviewer:
  base_url: http://192.168.1.101:11434  # Your L2 laptop
  model: qwen2.5-coder:7b
```

### 3. Test Connections
```bash
./scripts/test-connection.sh
```

### 4. Generate Your First Project
```bash
./scripts/run-example.sh
```

Or manually:
```bash
project-gen generate --project config/examples/go_microservice.yaml
```

## Next Steps

### Create Your Own Project

1. Copy an example:
```bash
cp config/examples/go_microservice.yaml config/my-project.yaml
```

2. Edit the schema:
```yaml
project_name: my-awesome-api
project_type: rest_api
description: My project description
languages:
  - python
frameworks:
  - fastapi
# ... customize as needed
```

3. Generate:
```bash
project-gen generate --project config/my-project.yaml
```

### Output Structure

Your generated project will be in `generated/<project-name>/`:
```
generated/my-awesome-api/
├── main.py
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
├── README.md
└── ... (all your code)
```

## TODO: Copy Agent Implementations

The setup created placeholder agents. You need to copy the actual implementations from your monolithic file:

**Files to copy:**
1. `src/agents/architect.py` - Architecture planning logic
2. `src/agents/coder.py` - Code generation logic
3. `src/agents/reviewer.py` - Code review logic
4. `src/agents/writer.py` - File writing logic

Look for the classes in your original `generator.py`:
- `ArchitectAgent`
- `CoderAgent`
- `ReviewerAgent`
- `FileWriterAgent`

Copy each class and its methods into the corresponding file.

## Troubleshooting

### Ollama Connection Failed
- Ensure Ollama is running: `ollama serve`
- Check URLs in `config/cluster_config.yaml`
- Test with: `curl http://localhost:11434/api/tags`

### Module Import Errors
- Activate venv: `source venv/bin/activate`
- Reinstall: `pip install -e .`

### Generation Hangs
- Check Ollama logs for errors
- Try smaller model if out of memory
- Increase timeout in config

## Support

Check the logs:
- Console output (real-time)
- `generation_YYYYMMDD_HHMMSS.log` (detailed)
GETTING_STARTED

cat > docs/TODO.md << 'TODO_DOC'
# Implementation TODO List

## ✅ Completed
- [x] Project structure
- [x] Core modules (schemas, config, state)
- [x] Utilities (logger, JSON parser, file utils)
- [x] Ollama client with retry logic
- [x] Validators (syntax checking)
- [x] Formatters (code formatting)
- [x] Generators (dependencies, deployment)
- [x] Workflow builder (LangGraph)
- [x] Queue system (Redis-based)
- [x] CLI interface
- [x] Example configurations

## 🚧 TODO: Copy from Monolithic File

### High Priority
- [ ] **src/agents/architect.py** - Copy `ArchitectAgent` class
  - Architecture planning logic
  - File dependency ordering
  - JSON response parsing

- [ ] **src/agents/coder.py** - Copy `CoderAgent` class
  - Code generation for each file
  - Validation integration
  - Formatting integration
  - Progress tracking

- [ ] **src/agents/reviewer.py** - Copy `ReviewerAgent` class
  - Code review logic
  - Issue detection
  - Quality scoring

- [ ] **src/agents/writer.py** - Copy `FileWriterAgent` class
  - File system operations
  - Directory creation
  - Metadata writing
  - Result packaging

### Medium Priority
- [ ] **Add more generators**
  - Test file generator
  - Config file generator
  - CI/CD pipeline generator

- [ ] **Enhanced validators**
  - Circular dependency detection
  - Config schema validation

- [ ] **Checkpoint system**
  - Save/load state for resumption
  - Progress persistence

### Low Priority
- [ ] API server (FastAPI)
- [ ] Web UI
- [ ] Parallel generation
- [ ] Custom templates support
- [ ] Plugin system

## 🧪 Testing Checklist
- [ ] Test with Go project
- [ ] Test with Python project
- [ ] Test with Flutter project
- [ ] Test all 3 Ollama nodes
- [ ] Test queue system
- [ ] Test error handling
- [ ] Test resume from checkpoint

## 📚 Documentation
- [x] Getting Started guide
- [ ] Architecture documentation
- [ ] API reference
- [ ] Contributing guide
- [ ] Deployment guide
TODO_DOC

echo -e "${GREEN}✓ Documentation created${NC}"

# ============================================================================
# Calculate Setup Time
# ============================================================================
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

# ============================================================================
# Final Summary
# ============================================================================
echo
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ SETUP COMPLETE! ✨${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo -e "${YELLOW}Summary:${NC}"
echo "  ✓ All 9 phases completed"
echo "  ✓ Virtual environment created"
echo "  ✓ Dependencies installed"
echo "  ✓ Example configs generated"
echo "  ✓ Helper scripts created"
echo "  ✓ Documentation created"
echo
echo -e "  ${GREEN}Setup time: ${MINUTES}m ${SECONDS}s${NC}"
echo
echo -e "${YELLOW}Project Location:${NC}"
echo "  $(pwd)"
echo
echo -e "${YELLOW}Next Steps:${NC}"
echo
echo "  ${BLUE}1. Copy agent implementations from your monolithic file:${NC}"
echo "     - src/agents/architect.py (ArchitectAgent class)"
echo "     - src/agents/coder.py (CoderAgent class)"
echo "     - src/agents/reviewer.py (ReviewerAgent class)"
echo "     - src/agents/writer.py (FileWriterAgent class)"
echo
echo "  ${BLUE}2. Configure your Ollama cluster:${NC}"
echo "     vim config/cluster_config.yaml"
echo
echo "  ${BLUE}3. Test Ollama connections:${NC}"
echo "     ./scripts/test-connection.sh"
echo
echo "  ${BLUE}4. Generate your first project:${NC}"
echo "     ./scripts/run-example.sh"
echo
echo -e "${YELLOW}Documentation:${NC}"
echo "  - docs/GETTING_STARTED.md - Quick start guide"
echo "  - docs/TODO.md - Implementation checklist"
echo "  - README.md - Project overview"
echo
echo -e "${YELLOW}Useful Commands:${NC}"
echo "  source venv/bin/activate   # Activate environment"
echo "  project-gen examples       # Generate example configs"
echo "  project-gen generate --project <file>  # Generate project"
echo
echo -e "${GREEN}Happy Coding! 🚀${NC}"
echo

# Save completion marker
touch .setup-complete
echo "Setup completed at $(date)" > .setup-complete

# Deactivate venv
deactivate 2>/dev/null || true