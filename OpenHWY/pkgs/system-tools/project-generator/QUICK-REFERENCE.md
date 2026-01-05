# Universal Project Generator - Quick Reference

## 🚀 Quick Setup (5 minutes)

```bash
# Run setup script
chmod +x setup_project.sh
./setup_project.sh

# Enter project
cd universal-project-generator

# Activate environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

## 📁 File Copy Order (From Monolithic File)

### 1. Core Files (Copy First)

```
monolithic.py → src/core/schemas.py
  - ProjectSchema class
  - FileTemplate class

monolithic.py → src/core/config.py
  - ClusterConfig class
  - AgentConfig class

monolithic.py → src/core/state.py
  - GenerationState TypedDict
```

### 2. Utility Files

```
monolithic.py → src/clients/ollama_client.py
  - OllamaClient class

monolithic.py → src/validators/syntax_validator.py
  - FileValidator class

monolithic.py → src/formatters/code_formatter.py
  - CodeFormatter class
```

### 3. Generator Files

```
monolithic.py → src/generators/dependency_gen.py
  - DependencyGenerator class

monolithic.py → src/generators/deployment_gen.py
  - DeploymentGenerator class

monolithic.py → src/generators/doc_gen.py
  - DocTestGenerator class (rename to DocGenerator)
```

### 4. Agent Files

```
monolithic.py → src/agents/architect.py
  - ArchitectAgent class

monolithic.py → src/agents/coder.py
  - CoderAgent class

monolithic.py → src/agents/reviewer.py
  - ReviewerAgent class

monolithic.py → src/agents/writer.py
  - FileWriterAgent class
```

### 5. Workflow Files

```
monolithic.py → src/workflow/checkpoints.py
  - CheckpointManager class

monolithic.py → src/workflow/builder.py
  - ProjectGenerator class (rename to WorkflowBuilder)
```

## 🔧 Import Fix Patterns

### Pattern 1: Relative Imports

```python
# OLD (monolithic)
from GenerationState import ...

# NEW (modular)
from ..core.state import GenerationState
```

### Pattern 2: Agent Base Class

```python
# NEW: All agents inherit from BaseAgent
from .base import BaseAgent

class ArchitectAgent(BaseAgent):
    def __init__(self, client: OllamaClient, logger: logging.Logger):
        super().__init__(client, logger)
```

### Pattern 3: Using Utilities

```python
# NEW: Import from utils
from ..utils.json_parser import parse_json_robust
from ..utils.logger import setup_logging
```

## ⚡ Command Cheat Sheet

### Generate Example Configs

```bash
python -m src.cli.main examples
```

### Generate Project

```bash
python -m src.cli.main generate \
  --project config/examples/go_microservice.yaml \
  --cluster config/cluster_config.yaml
```

### Interactive Setup

```bash
python -m src.cli.main init
```

### Validate Config

```bash
python -m src.cli.main validate \
  --project myproject.yaml
```

### After Installation

```bash
# Use installed command
project-gen generate --project myproject.yaml
```

## 🧪 Testing

### Run All Tests

```bash
pytest tests/ -v
```

### With Coverage

```bash
pytest tests/ --cov=src --cov-report=html
open htmlcov/index.html
```

### Single Test File

```bash
pytest tests/unit/test_schemas.py -v
```

## 📝 Configuration Quick Reference

### Minimal cluster_config.yaml

```yaml
architect:
  role: architect
  model: qwen2.5-coder:7b
  base_url: http://localhost:11434

coder:
  role: coder
  model: qwen2.5-coder:7b
  base_url: http://localhost:11434

reviewer:
  role: reviewer
  model: qwen2.5-coder:7b
  base_url: http://localhost:11434
```

### Minimal project.yaml

```yaml
project_name: my-service
project_type: microservice
description: My awesome service

languages:
  - go

frameworks:
  - chi

architecture_style: clean_architecture
```

## 🐛 Common Issues & Fixes

### Issue: Import Error

```bash
# Problem
ModuleNotFoundError: No module named 'src'

# Fix
pip install -e .
```

### Issue: Ollama Connection Failed

```bash
# Problem
ConnectionError: Cannot connect to Ollama

# Fix
# Check Ollama is running:
curl http://localhost:11434/api/tags

# Update cluster_config.yaml with correct URLs
```

### Issue: Empty Response from Agent

```bash
# Problem
Empty response from LLM

# Fix
# Check model is pulled:
ollama pull qwen2.5-coder:7b

# Increase timeout in cluster_config.yaml:
timeout: 600
```

## 🔍 Directory Structure Reference

```
universal-project-generator/
├── src/
│   ├── core/           # Schemas, config, state
│   ├── agents/         # AI agents (architect, coder, reviewer, writer)
│   ├── clients/        # Ollama client
│   ├── validators/     # Syntax, dependency, config validators
│   ├── formatters/     # Code formatters
│   ├── generators/     # File generators
│   ├── workflow/       # LangGraph workflow
│   ├── utils/          # Utilities (logger, json parser)
│   └── cli/            # Command-line interface
│
├── tests/
│   ├── unit/           # Unit tests
│   ├── integration/    # Integration tests
│   └── fixtures/       # Test data
│
├── config/
│   ├── cluster_config.yaml
│   └── examples/       # Example project schemas
│
├── docs/               # Documentation
├── scripts/            # Helper scripts
├── generated/          # Output directory
└── .checkpoint/        # Resume checkpoints
```

## 🎯 Development Workflow

### 1. Create Feature Branch

```bash
git checkout -b feature/my-feature
```

### 2. Make Changes

```python
# Edit files in src/
```

### 3. Format Code

```bash
./scripts/format.sh
```

### 4. Run Tests

```bash
./scripts/test.sh
```

### 5. Commit

```bash
git add .
git commit -m "Add my feature"
```

## 📦 Adding New Language Support

### 1. Update Constants

```python
# src/core/constants.py
SUPPORTED_LANGUAGES.add('rust')
SUPPORTED_FRAMEWORKS['rust'] = {'actix', 'rocket'}
```

### 2. Add Validator

```python
# src/validators/syntax_validator.py
@staticmethod
def validate_rust(code: str) -> tuple[bool, Optional[str]]:
    # Implementation
```

### 3. Add Formatter

```python
# src/formatters/code_formatter.py
@staticmethod
def format_rust(code: str) -> str:
    # Implementation
```

### 4. Add Dependency Generator

```python
# src/generators/dependency_gen.py
@staticmethod
def generate_cargo_toml(project_name: str, deps: Dict[str, str]) -> str:
    # Implementation
```

### 5. Add Templates

```
src/templates/rust/
├── main.rs.jinja2
├── lib.rs.jinja2
└── test.rs.jinja2
```

## 🎨 Code Style Guide

### Import Order

```python
# 1. Standard library
import os
import json
from typing import Dict, List

# 2. Third-party
from langchain_core.messages import AIMessage

# 3. Relative imports
from .base import BaseAgent
from ..core.state import GenerationState
```

### Docstrings

```python
def my_function(param: str) -> bool:
    """Short description

    Args:
        param: Description of parameter

    Returns:
        Description of return value
    """
    pass
```

### Type Hints

```python
from typing import Optional, Dict, Any

def process(data: Dict[str, Any]) -> Optional[str]:
    pass
```

## 🚨 Troubleshooting

### Check Installation

```bash
python -c "from src.core.schemas import ProjectSchema; print('✅ OK')"
```

### Check Ollama Connection

```bash
python -c "
from src.clients.ollama_client import OllamaClient
from src.core.config import AgentConfig
import logging

config = AgentConfig(
    role='test',
    model='qwen2.5-coder:7b',
    base_url='http://localhost:11434'
)
logger = logging.getLogger()
client = OllamaClient(config, logger)
print('✅ Connected')
"
```

### Debug Mode

```bash
# Enable debug logging
export LOG_LEVEL=DEBUG
python -m src.cli.main generate --project myproject.yaml
```

## 📊 Performance Tips

### Parallel Generation (Coming Soon)

```yaml
# cluster_config.yaml
parallel_generation: true
max_workers: 3
```

### Reduce Token Usage

```yaml
# Use smaller context
context_window: 2000

# Skip review for faster generation
skip_review: true
```

### Resume Failed Runs

```bash
# Generation saves checkpoints automatically
project-gen resume --checkpoint .checkpoint/
```

## 🔗 Useful Links

- [LangGraph Docs](https://langchain-ai.github.io/langgraph/)
- [Ollama Docs](https://ollama.ai/docs)
- [Jinja2 Docs](https://jinja.palletsprojects.com/)

## 💡 Tips & Tricks

1. **Test Changes Incrementally**: Test each module as you copy it
2. **Use Type Hints**: Makes debugging easier
3. **Check Logs**: Detailed logs in `generation_*.log`
4. **Start Small**: Test with small projects first
5. **Custom Prompts**: Edit agent prompts in agent files
6. **Template Customization**: Edit Jinja2 templates for your style
7. **Checkpoint Recovery**: Always resume from checkpoints on failure

## 🎓 Learning Path

1. ✅ Run setup script
2. ✅ Copy core files (schemas, config, state)
3. ✅ Copy one agent (start with architect)
4. ✅ Test that agent works
5. ✅ Copy remaining agents
6. ✅ Copy generators
7. ✅ Create CLI
8. ✅ Test full workflow
9. ✅ Add custom features
10. ✅ Deploy to production

---

**Need Help?** Check the logs, they're your best friend!
