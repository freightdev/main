# Universal Project Generator - Setup Instructions

Complete setup guide for the 3-agent Ollama cluster project generator.

## 📋 Prerequisites

- **Python 3.10+**
- **3 machines/laptops** with Ollama installed (or 1 for development)
- **Network connectivity** between machines (if using cluster)
- **Git** (optional)

### Your Hardware Setup

```
Laptop 1: 20 threads, 24GB RAM, iGPU (Coder)
Laptop 2: 22 threads, 16GB RAM, iGPU + NPU (Reviewer)
Laptop 3: 8 threads, 32GB RAM, iGPU + GTX 1650 (Architect)
```

---

## 🚀 Quick Setup (5 Minutes)

### Option 1: All-in-One Setup

```bash
# Download all setup scripts to a directory
cd ~/Downloads  # or wherever you saved the scripts

# Make executable
chmod +x setup-*.sh

# Run complete setup
./setup-all-phases.sh
```

This runs all 9 phases automatically and takes about 2-5 minutes.

### Option 2: Step-by-Step Setup

Run each phase individually:

```bash
# Phase 1: Foundation (directory structure, configs)
./setup-phase1-foundation.sh
cd universal-project-generator

# Phase 2: Core modules (schemas, config, state)
../setup-phase2-core.sh

# Phase 3: Utilities (logger, JSON parser, file utils)
../setup-phase3-utilities.sh

# Phase 4: Clients (Ollama client with retry)
../setup-phase4-clients.sh

# Phases 5-9: Complete (validators, generators, agents, workflow, CLI)
../setup-phases-5-to-9-complete.sh
```

---

## 📁 What Gets Created

```
universal-project-generator/
├── src/
│   ├── core/          # Schemas, config, state
│   ├── agents/        # AI agents (need to copy implementations)
│   ├── clients/       # Ollama client
│   ├── validators/    # Syntax validators
│   ├── formatters/    # Code formatters
│   ├── generators/    # File generators
│   ├── workflow/      # LangGraph workflow
│   ├── utils/         # Utilities
│   └── cli/           # Command-line interface
│
├── config/
│   ├── cluster_config.yaml
│   └── examples/
│       ├── go_microservice.yaml
│       ├── python_api.yaml
│       └── flutter_app.yaml
│
├── tests/             # Test structure
├── scripts/           # Helper scripts
├── docs/              # Documentation
├── requirements.txt   # Python dependencies
└── setup.py          # Package setup
```

---

## ⚙️ Configuration

### Step 1: Configure Your Ollama Cluster

Edit `config/cluster_config.yaml`:

```yaml
architect:
  role: architect
  model: qwen2.5-coder:32b
  base_url: http://192.168.1.102:11434 # Your L3 (most powerful)
  temperature: 0.7
  timeout: 300

coder:
  role: coder
  model: qwen2.5-coder:14b
  base_url: http://192.168.1.100:11434 # Your L1
  temperature: 0.7
  timeout: 300

reviewer:
  role: reviewer
  model: qwen2.5-coder:7b
  base_url: http://192.168.1.101:11434 # Your L2
  temperature: 0.7
  timeout: 300
```

### Step 2: Setup Ollama on Each Laptop

**On Laptop 1 (Coder - L1):**

```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Pull model
ollama pull qwen2.5-coder:14b

# Run Ollama (expose to network)
OLLAMA_HOST=0.0.0.0:11434 ollama serve
```

**On Laptop 2 (Reviewer - L2):**

```bash
ollama pull qwen2.5-coder:7b
OLLAMA_HOST=0.0.0.0:11434 ollama serve
```

**On Laptop 3 (Architect - L3):**

```bash
ollama pull qwen2.5-coder:32b
OLLAMA_HOST=0.0.0.0:11434 ollama serve
```

### Step 3: Test Connections

```bash
cd universal-project-generator
source venv/bin/activate
./scripts/test-connection.sh
```

You should see:

```
✓ ARCHITECT: Connected (qwen2.5-coder:32b)
✓ CODER: Connected (qwen2.5-coder:14b)
✓ REVIEWER: Connected (qwen2.5-coder:7b)
```

---

## 🔧 Copy Agent Implementations

**CRITICAL STEP:** The setup creates placeholder agents. You need to copy the actual implementations from your monolithic file.

### What to Copy

From your original `generator.py` file, copy these classes:

1. **ArchitectAgent** → `src/agents/architect.py`
2. **CoderAgent** → `src/agents/coder.py`
3. **ReviewerAgent** → `src/agents/reviewer.py`
4. **FileWriterAgent** → `src/agents/writer.py`

### How to Copy

#### Option A: Manual Copy (Recommended)

Open both files side-by-side and copy the class implementation:

```python
# In src/agents/architect.py
from .base import BaseAgent
from ..core.state import GenerationState
from ..clients.ollama_client import OllamaClient
from ..utils.json_parser import parse_json_robust

class ArchitectAgent(BaseAgent):
    """Plans project architecture"""

    def __init__(self, client: OllamaClient, logger):
        super().__init__(client, logger)

    def __call__(self, state: GenerationState) -> GenerationState:
        # Copy implementation from your monolithic file
        # Remember to update imports!
        pass
```

#### Option B: Automated (If you have the monolithic file)

```bash
# Run this in the universal-project-generator directory
python << 'PYTHON'
import re

# Read monolithic file
with open('../generator.py', 'r') as f:
    content = f.read()

# Extract ArchitectAgent class
match = re.search(r'class ArchitectAgent.*?(?=\nclass |\Z)', content, re.DOTALL)
if match:
    with open('src/agents/architect.py', 'a') as f:
        f.write('\n\n' + match.group(0))
    print("✓ ArchitectAgent copied")

# Repeat for other agents...
PYTHON
```

### Fix Imports

After copying, update imports in each agent file:

**Old (monolithic):**

```python
from GenerationState import ...
```

**New (modular):**

```python
from ..core.state import GenerationState
from ..core.schemas import ProjectSchema
from ..clients.ollama_client import OllamaClient
from ..utils.json_parser import parse_json_robust
```

---

## 🧪 Test Your Setup

### 1. Generate Example Project

```bash
cd universal-project-generator
source venv/bin/activate

# Generate Go microservice
./scripts/run-example.sh

# Or manually
project-gen generate --project config/examples/go_microservice.yaml
```

### 2. Check Output

```bash
ls -la generated/auth-service/

# Should show:
# - cmd/server/main.go
# - internal/handlers/
# - internal/services/
# - go.mod
# - Dockerfile
# - docker-compose.yml
# - README.md
```

### 3. Test Generated Code

```bash
cd generated/auth-service

# For Go projects
go mod tidy
go build ./...
go test ./...

# For Python projects
pip install -r requirements.txt
python -m pytest

# For Dart/Flutter
dart pub get
flutter test
```

---

## 📊 Usage Examples

### Generate Go Microservice

```bash
project-gen generate --project config/examples/go_microservice.yaml
```

### Generate Python API

```bash
project-gen generate --project config/examples/python_api.yaml
```

### Generate Flutter App

```bash
project-gen generate --project config/examples/flutter_app.yaml
```

### Create Custom Project

1. Copy example:

```bash
cp config/examples/go_microservice.yaml config/my-api.yaml
```

2. Edit schema:

```yaml
project_name: payment-api
project_type: rest_api
description: Payment processing API

languages:
  - python

frameworks:
  - fastapi

databases:
  - postgres
  - redis

features:
  - payment_processing
  - webhook_handling
  - invoice_generation

authentication: true
logging: true
testing: true
documentation: true
```

3. Generate:

```bash
project-gen generate --project config/my-api.yaml
```

---

## 🐛 Troubleshooting

### Issue: "Module not found" errors

**Solution:**

```bash
source venv/bin/activate
pip install -e .
```

### Issue: "Cannot connect to Ollama"

**Solution:**

```bash
# Check Ollama is running
curl http://localhost:11434/api/tags

# If not, start it
ollama serve

# Check firewall allows port 11434
sudo ufw allow 11434
```

### Issue: "Empty response from LLM"

**Solution:**

```bash
# Check model is loaded
ollama list

# If not, pull it
ollama pull qwen2.5-coder:7b

# Increase timeout in config
vim config/cluster_config.yaml
# Set: timeout: 600
```

### Issue: Generation hangs

**Solution:**

- Check Ollama logs: `journalctl -u ollama -f`
- Try smaller model if out of memory
- Check CPU/RAM usage: `htop`
- Restart Ollama: `sudo systemctl restart ollama`

### Issue: Syntax validation fails

**Solution:**

```bash
# Install language tools
sudo apt install golang-go python3 dart

# Or disable validation
vim config/cluster_config.yaml
# Set: validate_syntax: false
```

---

## 📚 Documentation

- **docs/GETTING_STARTED.md** - Quick start guide
- **docs/TODO.md** - Implementation checklist
- **README.md** - Project overview

---

## 🎯 Next Steps

1. ✅ Complete setup (phases 1-9)
2. ✅ Configure Ollama cluster
3. ✅ Copy agent implementations
4. ✅ Test connections
5. ✅ Generate example project
6. 🚀 Start generating your projects!

---

## 💡 Tips

- **Start with small projects** to test your setup
- **Check logs** in `generation_*.log` for debugging
- **Use free tier first** to test queue system
- **Monitor resources** with `htop` on each laptop
- **Back up generated code** before modifying

---

## 🆘 Getting Help

If you encounter issues:

1. Check the logs: `generation_*.log`
2. Test Ollama connections: `./scripts/test-connection.sh`
3. Verify Python imports: `python -c "from src.core.schemas import ProjectSchema"`
4. Review TODO list: `cat docs/TODO.md`

---

## ✨ Success Checklist

- [ ] All phases completed
- [ ] Virtual environment activated
- [ ] Ollama running on all 3 laptops
- [ ] Connections tested successfully
- [ ] Agent implementations copied
- [ ] Example project generated
- [ ] Generated code compiles/runs

**When all checked, you're ready to generate projects! 🎉**
