# Universal Project Generator - Project Structure

## Directory Tree

```
universal-project-generator/
├── README.md
├── requirements.txt
├── pyproject.toml
├── setup.py
├── .gitignore
├── LICENSE
│
├── config/                          # Configuration templates
│   ├── __init__.py
│   ├── cluster_config.yaml          # Default cluster config
│   ├── examples/                    # Example project schemas
│   │   ├── go_microservice.yaml
│   │   ├── python_api.yaml
│   │   ├── flutter_app.yaml
│   │   ├── nextjs_app.yaml
│   │   └── fullstack_app.yaml
│   └── presets/                     # Preset configurations
│       ├── architectures.yaml       # Common architecture patterns
│       ├── tech_stacks.yaml         # Common tech stack combos
│       └── frameworks.yaml          # Framework-specific settings
│
├── src/                             # Main source code
│   ├── __init__.py
│   │
│   ├── core/                        # Core functionality
│   │   ├── __init__.py
│   │   ├── schemas.py               # ProjectSchema, FileTemplate classes
│   │   ├── state.py                 # GenerationState TypedDict
│   │   ├── config.py                # ClusterConfig, AgentConfig classes
│   │   └── constants.py             # Global constants
│   │
│   ├── agents/                      # LangGraph agents
│   │   ├── __init__.py
│   │   ├── base.py                  # BaseAgent abstract class
│   │   ├── architect.py             # ArchitectAgent
│   │   ├── coder.py                 # CoderAgent
│   │   ├── reviewer.py              # ReviewerAgent
│   │   └── writer.py                # FileWriterAgent
│   │
│   ├── clients/                     # External service clients
│   │   ├── __init__.py
│   │   ├── ollama_client.py         # OllamaClient with retry logic
│   │   └── llm_factory.py           # Factory for different LLM providers
│   │
│   ├── validators/                  # Code validation
│   │   ├── __init__.py
│   │   ├── base.py                  # BaseValidator interface
│   │   ├── syntax_validator.py      # FileValidator (syntax checking)
│   │   ├── dependency_validator.py  # Circular dependency detection
│   │   └── config_validator.py      # ConfigValidator
│   │
│   ├── formatters/                  # Code formatting
│   │   ├── __init__.py
│   │   ├── base.py                  # BaseFormatter interface
│   │   ├── code_formatter.py        # CodeFormatter (gofmt, black, etc)
│   │   └── template_formatter.py    # Template file formatting
│   │
│   ├── generators/                  # File generators
│   │   ├── __init__.py
│   │   ├── base.py                  # BaseGenerator interface
│   │   ├── dependency_gen.py        # DependencyGenerator (go.mod, package.json)
│   │   ├── deployment_gen.py        # DeploymentGenerator (Docker, k8s)
│   │   ├── doc_gen.py               # DocGenerator (README, API docs)
│   │   ├── test_gen.py              # TestGenerator
│   │   └── config_gen.py            # ConfigGenerator (.env, config files)
│   │
│   ├── templates/                   # Code templates
│   │   ├── __init__.py
│   │   ├── go/                      # Go templates
│   │   │   ├── main.go.jinja2
│   │   │   ├── handler.go.jinja2
│   │   │   ├── service.go.jinja2
│   │   │   ├── model.go.jinja2
│   │   │   └── test.go.jinja2
│   │   ├── python/                  # Python templates
│   │   │   ├── main.py.jinja2
│   │   │   ├── api.py.jinja2
│   │   │   ├── model.py.jinja2
│   │   │   └── test.py.jinja2
│   │   ├── dart/                    # Dart/Flutter templates
│   │   │   ├── main.dart.jinja2
│   │   │   ├── widget.dart.jinja2
│   │   │   └── test.dart.jinja2
│   │   └── common/                  # Common templates
│   │       ├── dockerfile.jinja2
│   │       ├── docker-compose.jinja2
│   │       ├── readme.md.jinja2
│   │       └── gitignore.jinja2
│   │
│   ├── workflow/                    # LangGraph workflow
│   │   ├── __init__.py
│   │   ├── builder.py               # WorkflowBuilder - creates graph
│   │   ├── nodes.py                 # Node definitions
│   │   ├── edges.py                 # Edge conditions
│   │   └── checkpoints.py           # CheckpointManager
│   │
│   ├── utils/                       # Utilities
│   │   ├── __init__.py
│   │   ├── logger.py                # setup_logging()
│   │   ├── file_utils.py            # File I/O helpers
│   │   ├── json_parser.py           # parse_json_robust()
│   │   ├── progress.py              # Progress bar utilities
│   │   └── error_handler.py         # Error handling decorators
│   │
│   └── cli/                         # Command-line interface
│       ├── __init__.py
│       ├── main.py                  # Main CLI entry point
│       ├── commands.py              # CLI commands (generate, validate, resume)
│       └── interactive.py           # Interactive project setup wizard
│
├── tests/                           # Unit tests
│   ├── __init__.py
│   ├── conftest.py                  # Pytest fixtures
│   │
│   ├── unit/                        # Unit tests
│   │   ├── test_schemas.py
│   │   ├── test_validators.py
│   │   ├── test_formatters.py
│   │   ├── test_generators.py
│   │   └── test_agents.py
│   │
│   ├── integration/                 # Integration tests
│   │   ├── test_workflow.py
│   │   ├── test_full_generation.py
│   │   └── test_ollama_integration.py
│   │
│   └── fixtures/                    # Test fixtures
│       ├── sample_schemas/
│       ├── expected_outputs/
│       └── mock_responses/
│
├── scripts/                         # Utility scripts
│   ├── setup_ollama.sh              # Setup Ollama nodes
│   ├── validate_config.py           # Validate configuration files
│   ├── benchmark.py                 # Performance benchmarking
│   └── migrate_checkpoint.py        # Checkpoint migration tools
│
├── docs/                            # Documentation
│   ├── README.md
│   ├── installation.md
│   ├── quick_start.md
│   ├── configuration.md
│   ├── architecture.md
│   ├── extending.md
│   ├── api_reference.md
│   └── examples/
│       ├── basic_usage.md
│       ├── advanced_patterns.md
│       └── custom_templates.md
│
├── generated/                       # Output directory (gitignored)
│   └── .gitkeep
│
└── .checkpoint/                     # Checkpoint storage (gitignored)
    └── .gitkeep
```

## File Responsibilities

### Core (`src/core/`)

**schemas.py**

```python
- ProjectSchema dataclass
- FileTemplate dataclass
- ArchitecturePattern enum
- ProjectType enum
```

**state.py**

```python
- GenerationState TypedDict
- PhaseStatus enum
- Helper functions for state management
```

**config.py**

```python
- ClusterConfig dataclass
- AgentConfig dataclass
- Config loading/validation
```

### Agents (`src/agents/`)

**base.py**

```python
- BaseAgent abstract class
- Common agent functionality
- Retry logic decorator
```

**architect.py**

```python
- ArchitectAgent class
- Project structure planning
- Dependency ordering
```

**coder.py**

```python
- CoderAgent class
- Code generation logic
- Template rendering
```

**reviewer.py**

```python
- ReviewerAgent class
- Code review logic
- Issue detection
```

**writer.py**

```python
- FileWriterAgent class
- File system operations
- Directory structure creation
```

### Generators (`src/generators/`)

Each generator is responsible for specific file types:

**dependency_gen.py** - `go.mod`, `package.json`, `requirements.txt`, etc.

**deployment_gen.py** - `Dockerfile`, `docker-compose.yml`, K8s manifests

**doc_gen.py** - `README.md`, `ARCHITECTURE.md`, API documentation

**test_gen.py** - Test files for all languages

**config_gen.py** - `.env`, `config.yaml`, environment configs

### Workflow (`src/workflow/`)

**builder.py**

```python
- WorkflowBuilder class
- Constructs LangGraph from config
- Dynamic node/edge creation
```

**checkpoints.py**

```python
- CheckpointManager class
- Save/load state
- Resume functionality
```

### CLI (`src/cli/`)

**main.py**

```python
- Main entry point
- Argument parsing
- Command routing
```

**commands.py**

```python
- generate_command()
- validate_command()
- resume_command()
- init_command() - Interactive setup
```

## Key Design Decisions

### 1. **Separation of Concerns**

- Each agent is independent
- Generators are pluggable
- Validators can be added easily

### 2. **Template-Based Code Generation**

- Jinja2 templates for common patterns
- LLM fills in custom logic
- Reduces token usage

### 3. **Extensibility**

- Easy to add new languages
- Custom validators/formatters
- Plugin architecture for generators

### 4. **Configuration Over Convention**

- YAML-based configuration
- Preset templates
- Override at any level

### 5. **Testability**

- Mock Ollama responses
- Unit test each component
- Integration tests for workflows

## Entry Points

### CLI Usage

```bash
# Generate from schema
python -m src.cli.main generate --project config/examples/go_microservice.yaml

# Interactive setup
python -m src.cli.main init

# Resume from checkpoint
python -m src.cli.main resume --checkpoint .checkpoint/

# Validate configuration
python -m src.cli.main validate --project my_project.yaml
```

### Python API

```python
from src.core.schemas import ProjectSchema
from src.core.config import ClusterConfig
from src.workflow.builder import WorkflowBuilder

# Load configs
schema = ProjectSchema.from_yaml("project.yaml")
config = ClusterConfig.from_yaml("cluster.yaml")

# Build and run workflow
builder = WorkflowBuilder(schema, config)
workflow = builder.build()
result = workflow.run()
```

## Configuration Files

### Minimal Setup

```
config/
├── cluster_config.yaml    # Your 3 Ollama nodes
└── my_project.yaml        # Your project definition
```

### Professional Setup

```
config/
├── cluster_config.yaml
├── presets/
│   ├── microservices.yaml
│   ├── mobile_app.yaml
│   └── fullstack.yaml
└── projects/
    ├── auth_service.yaml
    ├── payment_api.yaml
    └── dashboard_app.yaml
```

## Next Steps

1. **Start with core classes** (`schemas.py`, `config.py`, `state.py`)
2. **Implement base agents** (`base.py`, then specific agents)
3. **Add basic generators** (start with dependency_gen.py)
4. **Build workflow** (simple linear flow first)
5. **Add CLI** (basic generate command)
6. **Expand** (templates, validators, advanced features)

This structure allows you to:

- ✅ Work on components independently
- ✅ Test each module in isolation
- ✅ Scale to enterprise complexity
- ✅ Maintain clean separation of concerns
- ✅ Add new languages/frameworks easily
