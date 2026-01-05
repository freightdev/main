#!/bin/bash
# ============================================================================
# PHASE 1: Foundation Setup
# Creates directory structure and basic configuration files
# ============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_NAME="universal-project-generator"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  PHASE 1: Foundation Setup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# ============================================================================
# Create Directory Structure
# ============================================================================
echo -e "${GREEN}[1/6]${NC} Creating directory structure..."

mkdir -p ${PROJECT_NAME}/{src/{core,clients,validators,formatters,generators,templates/{go,python,dart,common},workflow,agents,utils,cli},tests/{unit,integration,fixtures},config/{examples,presets},scripts,docs,generated,.checkpoint}

cd ${PROJECT_NAME}

echo -e "  ${GREEN}✓${NC} Directory structure created"

# ============================================================================
# Create __init__.py Files
# ============================================================================
echo -e "${GREEN}[2/6]${NC} Creating __init__.py files..."

find src -type d -exec touch {}/__init__.py \;
find tests -type d -exec touch {}/__init__.py \;

echo -e "  ${GREEN}✓${NC} Python package structure ready"

# ============================================================================
# Create requirements.txt
# ============================================================================
echo -e "${GREEN}[3/6]${NC} Creating requirements.txt..."

cat > requirements.txt << 'EOF'
# Core Dependencies
langgraph>=0.0.20
langchain>=0.1.0
langchain-community>=0.0.10
pyyaml>=6.0

# LLM Clients
ollama>=0.1.0

# Queue System
redis>=5.0.0
celery>=5.3.0

# Utilities
jinja2>=3.1.0
tqdm>=4.66.0

# Development
pytest>=7.4.0
pytest-cov>=4.1.0
pytest-asyncio>=0.21.0
black>=23.0.0
mypy>=1.5.0
flake8>=6.1.0

# API
fastapi>=0.104.0
uvicorn>=0.24.0
pydantic>=2.4.0

# Production
gunicorn>=21.2.0
python-dotenv>=1.0.0
EOF

echo -e "  ${GREEN}✓${NC} requirements.txt created"

# ============================================================================
# Create .gitignore
# ============================================================================
echo -e "${GREEN}[4/6]${NC} Creating .gitignore..."

cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Virtual Environment
venv/
env/
ENV/
.venv

# IDE
.vscode/
.idea/
*.swp
*.swo
*.sublime-project
*.sublime-workspace

# Generated files
generated/
.checkpoint/
*.log

# Testing
.pytest_cache/
.coverage
htmlcov/
.tox/

# OS
.DS_Store
Thumbs.db

# Environment
.env
.env.local
.env.production

# Redis
dump.rdb

# Celery
celerybeat-schedule
EOF

echo -e "  ${GREEN}✓${NC} .gitignore created"

# ============================================================================
# Create pyproject.toml
# ============================================================================
echo -e "${GREEN}[5/6]${NC} Creating pyproject.toml..."

cat > pyproject.toml << 'EOF'
[build-system]
requires = ["setuptools>=45", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "universal-project-generator"
version = "1.0.0"
description = "Universal project generator with 3-agent Ollama cluster"
requires-python = ">=3.10"

[tool.black]
line-length = 100
target-version = ['py310']
include = '\.pyi?$'

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = "-v --cov=src --cov-report=html"

[tool.mypy]
python_version = "3.10"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = false
ignore_missing_imports = true
EOF

echo -e "  ${GREEN}✓${NC} pyproject.toml created"

# ============================================================================
# Create README.md
# ============================================================================
echo -e "${GREEN}[6/6]${NC} Creating README.md..."

cat > README.md << 'EOF'
# Universal Project Generator

AI-powered project generator using a 3-agent Ollama cluster to create production-ready code.

## Features

- 🏗️  **Architecture Planning** - Intelligent project structure design
- 💻 **Code Generation** - Complete, working implementations
- 🔍 **Code Review** - Automated quality checks
- 📝 **Documentation** - Auto-generated README, API docs
- 🐳 **Deployment** - Docker, docker-compose ready
- ✅ **Testing** - Test file generation
- 🔄 **Multi-language** - Go, Python, Dart/Flutter support
- 📊 **Queue System** - Handle 100+ concurrent users

## Quick Start

```bash
# Run setup phases
./scripts/setup-phase1-foundation.sh
./scripts/setup-phase2-core.sh
./scripts/setup-phase3-utilities.sh
# ... continue through phase 9

# Or run all at once
./scripts/setup-all.sh

# Generate a project
project-gen generate --project config/examples/go_microservice.yaml
```

## Status

- [x] Phase 1: Foundation (Directory structure, config files)
- [ ] Phase 2: Core modules (schemas, config, state)
- [ ] Phase 3: Utilities (logger, JSON parser)
- [ ] Phase 4: Clients (Ollama client)
- [ ] Phase 5: Validators & Formatters
- [ ] Phase 6: Generators
- [ ] Phase 7: Agents
- [ ] Phase 8: Workflow & Queue System
- [ ] Phase 9: CLI & API

## Documentation

- [Installation Guide](docs/installation.md)
- [Configuration](docs/configuration.md)
- [Architecture](docs/architecture.md)

## License

MIT
EOF

echo -e "  ${GREEN}✓${NC} README.md created"

# ============================================================================
# Create .env.example
# ============================================================================
cat > .env.example << 'EOF'
# Ollama Configuration
OLLAMA_ARCHITECT_URL=http://192.168.1.102:11434
OLLAMA_CODER_URL=http://192.168.1.100:11434
OLLAMA_REVIEWER_URL=http://192.168.1.101:11434

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
SECRET_KEY=your-secret-key-here

# Queue Configuration
MAX_CONCURRENT_JOBS=3
JOB_TIMEOUT_SECONDS=3600

# Storage
OUTPUT_DIR=./generated
CHECKPOINT_DIR=./.checkpoint

# Logging
LOG_LEVEL=INFO
EOF

echo -e "  ${GREEN}✓${NC} .env.example created"

# ============================================================================
# Summary
# ============================================================================
echo
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ Phase 1 Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo -e "${YELLOW}Created:${NC}"
echo "  ✓ Directory structure"
echo "  ✓ Python package layout"
echo "  ✓ requirements.txt"
echo "  ✓ .gitignore"
echo "  ✓ pyproject.toml"
echo "  ✓ README.md"
echo "  ✓ .env.example"
echo
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. cd ${PROJECT_NAME}"
echo "  2. Run: ../setup-phase2-core.sh"
echo
echo -e "${GREEN}Ready for Phase 2! 🚀${NC}"
echo