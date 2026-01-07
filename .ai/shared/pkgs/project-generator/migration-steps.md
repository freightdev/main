# Migration Guide: Monolithic → Modular Structure

## Step-by-Step Refactoring

### Phase 1: Setup Project Structure (5 minutes)

```bash
# Create directory structure
mkdir -p universal-project-generator/{src/{core,agents,clients,validators,formatters,generators,templates/{go,python,dart,common},workflow,utils,cli},tests/{unit,integration,fixtures},config/{examples,presets},scripts,docs,generated,.checkpoint}

cd universal-project-generator

# Create __init__.py files
find src -type d -exec touch {}/__init__.py \;
find tests -type d -exec touch {}/__init__.py \;

# Create basic files
touch README.md requirements.txt .gitignore setup.py
```

### Phase 2: Extract Core Classes (15 minutes)

#### `src/core/schemas.py`

```python
"""Project schema definitions"""
from dataclasses import dataclass, field, asdict
from typing import List, Dict, Any
import yaml

@dataclass
class FileTemplate:
    """Individual file to generate"""
    path: str
    purpose: str
    file_type: str
    language: str
    dependencies: List[str] = field(default_factory=list)
    priority: int = 5

@dataclass
class ProjectSchema:
    """Complete project definition"""

    # Basic Info
    project_name: str
    project_type: str
    description: str

    # Technology Stack
    languages: List[str]
    frameworks: List[str]
    databases: List[str] = field(default_factory=list)
    external_services: List[str] = field(default_factory=list)

    # Architecture
    architecture_style: str
    design_patterns: List[str] = field(default_factory=list)

    # Features
    features: List[str] = field(default_factory=list)
    api_endpoints: List[Dict[str, Any]] = field(default_factory=list)

    # Requirements
    authentication: bool = False
    authorization: bool = False
    real_time: bool = False
    caching: bool = False
    logging: bool = True
    testing: bool = True
    documentation: bool = True

    # Deployment
    containerization: str = "docker"
    orchestration: str = "docker-compose"

    # Custom
    custom_requirements: str = ""
    coding_standards: str = ""

    @classmethod
    def from_yaml(cls, path: str) -> 'ProjectSchema':
        with open(path, 'r') as f:
            data = yaml.safe_load(f)
        return cls(**data)

    def to_yaml(self, path: str):
        with open(path, 'w') as f:
            yaml.dump(asdict(self), f, default_flow_style=False, sort_keys=False)
```

#### `src/core/config.py`

```python
"""Cluster configuration"""
from dataclasses import dataclass, asdict
import yaml

@dataclass
class AgentConfig:
    role: str
    model: str
    base_url: str
    temperature: float = 0.7
    timeout: int = 300
    max_retries: int = 3

@dataclass
class ClusterConfig:
    architect: AgentConfig
    coder: AgentConfig
    reviewer: AgentConfig

    output_dir: str = "./generated"
    logging_level: str = "INFO"
    save_intermediate: bool = True
    validate_syntax: bool = True
    format_code: bool = True

    @classmethod
    def from_yaml(cls, path: str) -> 'ClusterConfig':
        with open(path, 'r') as f:
            data = yaml.safe_load(f)
        return cls(
            architect=AgentConfig(**data['architect']),
            coder=AgentConfig(**data['coder']),
            reviewer=AgentConfig(**data['reviewer']),
            output_dir=data.get('output_dir', './generated'),
            logging_level=data.get('logging_level', 'INFO'),
            save_intermediate=data.get('save_intermediate', True),
            validate_syntax=data.get('validate_syntax', True),
            format_code=data.get('format_code', True)
        )

    def to_yaml(self, path: str):
        data = {
            'architect': asdict(self.architect),
            'coder': asdict(self.coder),
            'reviewer': asdict(self.reviewer),
            'output_dir': self.output_dir,
            'logging_level': self.logging_level,
            'save_intermediate': self.save_intermediate,
            'validate_syntax': self.validate_syntax,
            'format_code': self.format_code
        }
        with open(path, 'w') as f:
            yaml.dump(data, f, default_flow_style=False)
```

#### `src/core/state.py`

```python
"""Generation state definition"""
from typing import TypedDict, Annotated, Sequence, Dict, Any, List
from langchain_core.messages import BaseMessage
import operator

from .schemas import ProjectSchema
from .config import ClusterConfig

class GenerationState(TypedDict):
    # Configuration
    project_schema: ProjectSchema
    cluster_config: ClusterConfig

    # Artifacts
    architecture_plan: Dict[str, Any]
    generated_files: Dict[str, str]
    file_metadata: Dict[str, Dict[str, Any]]
    validated_files: set[str]
    formatted_files: set[str]

    # Dependencies
    dependency_files: Dict[str, str]
    deployment_files: Dict[str, str]
    test_files: Dict[str, str]
    doc_files: Dict[str, str]

    # Quality
    review_results: Dict[str, Any]
    issues_found: List[Dict[str, Any]]
    syntax_errors: List[Dict[str, Any]]

    # Progress
    current_phase: str
    files_to_generate: List[str]
    files_generated: List[str]
    files_failed: List[str]
    can_resume: bool
    checkpoint_path: str

    # Communication
    messages: Annotated[Sequence[BaseMessage], operator.add]
    errors: List[Dict[str, Any]]
    warnings: List[Dict[str, Any]]
```

### Phase 3: Extract Utilities (10 minutes)

#### `src/utils/logger.py`

```python
"""Logging setup"""
import logging
from datetime import datetime

def setup_logging(level: str = "INFO") -> logging.Logger:
    logger = logging.getLogger("ProjectGenerator")
    logger.setLevel(getattr(logging, level))
    logger.handlers.clear()

    console = logging.StreamHandler()
    console.setLevel(getattr(logging, level))
    console.setFormatter(logging.Formatter(
        '%(asctime)s [%(levelname)s] %(message)s',
        datefmt='%H:%M:%S'
    ))
    logger.addHandler(console)

    log_file = f"generation_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
    file_handler = logging.FileHandler(log_file)
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(funcName)s:%(lineno)d - %(message)s'
    ))
    logger.addHandler(file_handler)

    return logger
```

#### `src/utils/json_parser.py`

````python
"""Robust JSON parsing from LLM responses"""
import json
import re
from typing import Optional, Dict

def parse_json_robust(response: str) -> Optional[Dict]:
    """Parse JSON from LLM response with multiple fallback strategies"""

    # Strategy 1: Remove markdown code blocks
    if "```" in response:
        patterns = [
            r'```json\s*(.*?)\s*```',
            r'```\s*(.*?)\s*```',
        ]
        for pattern in patterns:
            match = re.search(pattern, response, re.DOTALL)
            if match:
                response = match.group(1)
                break

    # Strategy 2: Find JSON object boundaries
    try:
        start = response.find('{')
        end = response.rfind('}') + 1
        if start != -1 and end > start:
            json_str = response[start:end]
            return json.loads(json_str)
    except:
        pass

    # Strategy 3: Try parsing entire response
    try:
        return json.loads(response.strip())
    except:
        pass

    return None
````

### Phase 4: Extract Clients (10 minutes)

#### `src/clients/ollama_client.py`

```python
"""Ollama client with retry logic"""
import logging
import time
from typing import Optional

from langchain_community.llms import Ollama
from ..core.config import AgentConfig

class OllamaClient:
    """Ollama client with retry and validation"""

    def __init__(self, config: AgentConfig, logger: logging.Logger):
        self.config = config
        self.logger = logger
        self.llm = None
        self._validate_connection()

    def _validate_connection(self):
        """Validate Ollama connection before starting"""
        try:
            self.llm = Ollama(
                model=self.config.model,
                base_url=self.config.base_url,
                timeout=self.config.timeout,
                temperature=self.config.temperature
            )
            # Test connection
            self.llm.invoke("test", max_tokens=10)
            self.logger.info(f"✅ Connected to {self.config.role} at {self.config.base_url}")
        except Exception as e:
            self.logger.error(f"❌ Failed to connect to {self.config.role}: {e}")
            raise ConnectionError(f"Cannot connect to Ollama at {self.config.base_url}")

    def invoke(self, prompt: str) -> Optional[str]:
        """Invoke with retry"""
        for attempt in range(self.config.max_retries):
            try:
                self.logger.debug(f"[{self.config.role}] Attempt {attempt + 1}")
                response = self.llm.invoke(prompt)

                if not response or len(response.strip()) == 0:
                    raise ValueError("Empty response")

                return response

            except Exception as e:
                self.logger.warning(f"[{self.config.role}] Attempt {attempt + 1} failed: {e}")

                if attempt == self.config.max_retries - 1:
                    raise

                time.sleep(2 ** attempt)

        return None
```

### Phase 5: Extract Validators (15 minutes)

#### `src/validators/syntax_validator.py`

```python
"""Code syntax validation"""
import subprocess
import os
import tempfile
from typing import Optional

class FileValidator:
    """Validate generated code syntax"""

    @staticmethod
    def validate_go(code: str) -> tuple[bool, Optional[str]]:
        """Validate Go syntax"""
        try:
            with tempfile.NamedTemporaryFile(mode='w', suffix='.go', delete=False) as f:
                f.write(code)
                temp_path = f.name

            result = subprocess.run(
                ['go', 'fmt', temp_path],
                capture_output=True,
                text=True,
                timeout=10
            )

            os.unlink(temp_path)

            if result.returncode == 0:
                return True, None
            return False, result.stderr

        except FileNotFoundError:
            return True, "Go not installed, skipping validation"
        except Exception as e:
            return False, str(e)

    @staticmethod
    def validate_python(code: str) -> tuple[bool, Optional[str]]:
        """Validate Python syntax"""
        try:
            compile(code, '<string>', 'exec')
            return True, None
        except SyntaxError as e:
            return False, f"Line {e.lineno}: {e.msg}"

    @staticmethod
    def validate(language: str, code: str) -> tuple[bool, Optional[str]]:
        """Validate code based on language"""
        validators = {
            'go': FileValidator.validate_go,
            'python': FileValidator.validate_python,
        }

        validator = validators.get(language.lower())
        if validator:
            return validator(code)
        return True, f"No validator for {language}"
```

### Phase 6: Extract Agents (20 minutes each)

#### `src/agents/base.py`

```python
"""Base agent class"""
import logging
from abc import ABC, abstractmethod

from ..core.state import GenerationState
from ..clients.ollama_client import OllamaClient

class BaseAgent(ABC):
    """Base class for all agents"""

    def __init__(self, client: OllamaClient, logger: logging.Logger):
        self.client = client
        self.logger = logger

    @abstractmethod
    def __call__(self, state: GenerationState) -> GenerationState:
        """Process state and return updated state"""
        pass
```

#### `src/agents/architect.py`

Move `ArchitectAgent` class here, import from `base.py`

#### `src/agents/coder.py`

Move `CoderAgent` class here

#### `src/agents/reviewer.py`

Move `ReviewerAgent` class here

#### `src/agents/writer.py`

Move `FileWriterAgent` class here

### Phase 7: Extract Generators (15 minutes)

#### `src/generators/dependency_gen.py`

Move `DependencyGenerator` class here

#### `src/generators/deployment_gen.py`

Move `DeploymentGenerator` class here

#### `src/generators/doc_gen.py`

Move `DocTestGenerator` class here (rename to `DocGenerator`)

### Phase 8: Create CLI (10 minutes)

#### `src/cli/main.py`

```python
"""Main CLI entry point"""
import argparse
import sys
from pathlib import Path

from .commands import generate_command, init_command, resume_command, validate_command

def main():
    parser = argparse.ArgumentParser(
        description="Universal Project Generator with 3-Agent Ollama Cluster"
    )

    subparsers = parser.add_subparsers(dest='command', help='Commands')

    # Generate command
    gen_parser = subparsers.add_parser('generate', help='Generate project')
    gen_parser.add_argument('--project', required=True, help='Project schema YAML')
    gen_parser.add_argument('--cluster', default='cluster_config.yaml', help='Cluster config')

    # Init command
    init_parser = subparsers.add_parser('init', help='Interactive project setup')

    # Resume command
    resume_parser = subparsers.add_parser('resume', help='Resume from checkpoint')
    resume_parser.add_argument('--checkpoint', required=True, help='Checkpoint directory')

    # Validate command
    val_parser = subparsers.add_parser('validate', help='Validate configuration')
    val_parser.add_argument('--project', required=True, help='Project schema YAML')

    args = parser.parse_args()

    if args.command == 'generate':
        generate_command(args.project, args.cluster)
    elif args.command == 'init':
        init_command()
    elif args.command == 'resume':
        resume_command(args.checkpoint)
    elif args.command == 'validate':
        validate_command(args.project)
    else:
        parser.print_help()
        sys.exit(1)

if __name__ == '__main__':
    main()
```

#### `src/cli/commands.py`

```python
"""CLI command implementations"""
import os
from pathlib import Path

from ..core.schemas import ProjectSchema
from ..core.config import ClusterConfig
from ..workflow.builder import WorkflowBuilder

def generate_command(project_path: str, cluster_path: str):
    """Generate project from schema"""

    # Validate files exist
    if not os.path.exists(cluster_path):
        print(f"❌ Cluster config not found: {cluster_path}")
        return

    if not os.path.exists(project_path):
        print(f"❌ Project schema not found: {project_path}")
        return

    # Load configurations
    cluster = ClusterConfig.from_yaml(cluster_path)
    schema = ProjectSchema.from_yaml(project_path)

    # Build and run workflow
    builder = WorkflowBuilder(schema, cluster)
    builder.generate()

    print("\n✨ Generation complete!")
    print(f"📂 Output: {cluster.output_dir}/{schema.project_name}/")

def init_command():
    """Interactive project setup"""
    # TODO: Implement interactive wizard
    print("Interactive setup wizard - Coming soon!")

def resume_command(checkpoint_dir: str):
    """Resume from checkpoint"""
    # TODO: Implement resume logic
    print(f"Resuming from {checkpoint_dir} - Coming soon!")

def validate_command(project_path: str):
    """Validate project schema"""
    try:
        schema = ProjectSchema.from_yaml(project_path)
        print(f"✅ Valid project schema: {schema.project_name}")
    except Exception as e:
        print(f"❌ Invalid schema: {e}")
```

### Phase 9: Create Workflow Builder (20 minutes)

#### `src/workflow/builder.py`

```python
"""Workflow builder"""
import logging
from pathlib import Path

from langgraph.graph import StateGraph, END

from ..core.schemas import ProjectSchema
from ..core.config import ClusterConfig
from ..core.state import GenerationState
from ..clients.ollama_client import OllamaClient
from ..agents.architect import ArchitectAgent
from ..agents.coder import CoderAgent
from ..agents.reviewer import ReviewerAgent
from ..agents.writer import FileWriterAgent
from ..validators.syntax_validator import FileValidator
from ..formatters.code_formatter import CodeFormatter
from ..utils.logger import setup_logging

class WorkflowBuilder:
    """Builds and executes generation workflow"""

    def __init__(self, schema: ProjectSchema, config: ClusterConfig):
        self.schema = schema
        self.config = config
        self.logger = setup_logging(config.logging_level)

        self.logger.info("="*70)
        self.logger.info(f"🚀 Project Generator: {schema.project_name}")
        self.logger.info("="*70)

        # Initialize clients
        try:
            self.architect_client = OllamaClient(config.architect, self.logger)
            self.coder_client = OllamaClient(config.coder, self.logger)
            self.reviewer_client = OllamaClient(config.reviewer, self.logger)
        except ConnectionError as e:
            self.logger.critical(f"Failed to connect to Ollama: {e}")
            raise

        # Initialize utilities
        self.validator = FileValidator()
        self.formatter = CodeFormatter()

    def generate(self, resume_from_checkpoint: bool = False) -> GenerationState:
        """Run complete generation pipeline"""

        # Create initial state
        initial_state = self._create_initial_state()

        # Create workflow
        workflow = self._create_workflow()
        app = workflow.compile()

        # Execute
        try:
            self.logger.info("🎯 Starting generation pipeline...")
            final_state = app.invoke(initial_state)

            # Print summary
            self._print_summary(final_state)

            return final_state

        except Exception as e:
            self.logger.critical(f"💥 Generation failed: {e}", exc_info=True)
            raise

    def _create_initial_state(self) -> GenerationState:
        """Create initial generation state"""
        return {
            "project_schema": self.schema,
            "cluster_config": self.config,
            "architecture_plan": {},
            "generated_files": {},
            "file_metadata": {},
            "validated_files": set(),
            "formatted_files": set(),
            "dependency_files": {},
            "deployment_files": {},
            "test_files": {},
            "doc_files": {},
            "review_results": {},
            "issues_found": [],
            "syntax_errors": [],
            "current_phase": "init",
            "files_to_generate": [],
            "files_generated": [],
            "files_failed": [],
            "can_resume": True,
            "checkpoint_path": str(Path(self.config.output_dir) / ".checkpoint"),
            "messages": [],
            "errors": [],
            "warnings": []
        }

    def _create_workflow(self) -> StateGraph:
        """Create LangGraph workflow"""

        # Create agents
        architect = ArchitectAgent(self.architect_client, self.logger)
        coder = CoderAgent(
            self.coder_client,
            self.logger,
            self.validator,
            self.formatter
        )
        reviewer = ReviewerAgent(self.reviewer_client, self.logger)
        writer = FileWriterAgent(self.logger)

        # Build graph
        workflow = StateGraph(GenerationState)

        workflow.add_node("architect", architect)
        workflow.add_node("coder", coder)
        workflow.add_node("reviewer", reviewer)
        workflow.add_node("writer", writer)

        # Define flow
        workflow.set_entry_point("architect")

        # Conditional edges with error handling
        workflow.add_conditional_edges(
            "architect",
            lambda s: "coder" if not s["errors"] else END
        )

        workflow.add_conditional_edges(
            "coder",
            lambda s: "reviewer" if not s["errors"] else END
        )

        workflow.add_edge("reviewer", "writer")
        workflow.add_edge("writer", END)

        return workflow

    def _print_summary(self, state: GenerationState):
        """Print generation summary"""
        self.logger.info("="*70)
        self.logger.info("📊 GENERATION SUMMARY")
        self.logger.info("="*70)
        self.logger.info(f"Project: {self.schema.project_name}")
        self.logger.info(f"Type: {self.schema.project_type}")
        self.logger.info(f"Final Phase: {state['current_phase']}")
        self.logger.info("")
        self.logger.info(f"📁 Files:")
        self.logger.info(f"   Generated: {len(state['generated_files'])}")
        self.logger.info(f"   Failed: {len(state['files_failed'])}")
        self.logger.info(f"   Validated: {len(state['validated_files'])}")
        self.logger.info(f"   Formatted: {len(state['formatted_files'])}")
        self.logger.info("")
        self.logger.info(f"🔍 Quality:")
        self.logger.info(f"   Issues Found: {len(state['issues_found'])}")
        self.logger.info(f"   Syntax Errors: {len(state['syntax_errors'])}")

        if state['errors']:
            self.logger.info("")
            self.logger.info(f"❌ Errors: {len(state['errors'])}")
            for error in state['errors']:
                self.logger.error(f"   {error['agent']}: {error['error']}")

        output_dir = Path(self.config.output_dir) / self.schema.project_name
        self.logger.info("")
        self.logger.info(f"📂 Output: {output_dir.absolute()}")
        self.logger.info("="*70)
```

---

## Phase 10: Create Package Files (5 minutes)

### `requirements.txt`

```
langgraph>=0.0.20
langchain>=0.1.0
langchain-community>=0.0.10
ollama>=0.1.0
pyyaml>=6.0
jinja2>=3.1.0
tqdm>=4.66.0
```

### `setup.py`

```python
from setuptools import setup, find_packages

setup(
    name="universal-project-generator",
    version="1.0.0",
    description="Universal project generator with 3-agent Ollama cluster",
    author="Your Name",
    packages=find_packages(),
    install_requires=[
        "langgraph>=0.0.20",
        "langchain>=0.1.0",
        "langchain-community>=0.0.10",
        "ollama>=0.1.0",
        "pyyaml>=6.0",
        "jinja2>=3.1.0",
        "tqdm>=4.66.0",
    ],
    entry_points={
        'console_scripts': [
            'project-gen=src.cli.main:main',
        ],
    },
    python_requires=">=3.10",
)
```

### `.gitignore`

```
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

# Virtual Environment
venv/
env/
ENV/

# IDE
.vscode/
.idea/
*.swp
*.swo

# Generated files
generated/
.checkpoint/
*.log

# OS
.DS_Store
Thumbs.db

# Testing
.pytest_cache/
.coverage
htmlcov/
```

### `pyproject.toml`

```toml
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

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
```

---

## Phase 11: Create Example Configs (5 minutes)

### `config/cluster_config.yaml`

```yaml
architect:
  role: architect
  model: qwen2.5-coder:7b
  base_url: http://192.168.1.100:11434
  temperature: 0.7
  timeout: 300
  max_retries: 3

coder:
  role: coder
  model: qwen2.5-coder:7b
  base_url: http://192.168.1.101:11434
  temperature: 0.7
  timeout: 300
  max_retries: 3

reviewer:
  role: reviewer
  model: qwen2.5-coder:7b
  base_url: http://192.168.1.102:11434
  temperature: 0.7
  timeout: 300
  max_retries: 3

output_dir: ./generated
logging_level: INFO
save_intermediate: true
validate_syntax: true
format_code: true
```

### `config/examples/go_microservice.yaml`

```yaml
project_name: auth-service
project_type: microservice
description: Authentication service with JWT and session management

languages:
  - go

frameworks:
  - chi

databases:
  - surrealdb
  - redis

architecture_style: clean_architecture

design_patterns:
  - repository
  - dependency_injection
  - factory

features:
  - login
  - register
  - refresh_token
  - logout
  - session_management

api_endpoints:
  - method: POST
    path: /api/v1/auth/register
    description: Register new user
  - method: POST
    path: /api/v1/auth/login
    description: Login user
  - method: POST
    path: /api/v1/auth/refresh
    description: Refresh access token
  - method: POST
    path: /api/v1/auth/logout
    description: Logout user

authentication: true
authorization: true
logging: true
testing: true
documentation: true

containerization: docker
orchestration: docker-compose
```

---

## Phase 12: Installation & Usage

### Install

```bash
cd universal-project-generator

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install in development mode
pip install -e .

# Or install dependencies only
pip install -r requirements.txt
```

### Run

```bash
# Generate project
python -m src.cli.main generate \
  --project config/examples/go_microservice.yaml \
  --cluster config/cluster_config.yaml

# Or use installed command
project-gen generate \
  --project config/examples/go_microservice.yaml \
  --cluster config/cluster_config.yaml
```

---

## Quick Migration Script

Create `migrate.py` in project root:

```python
#!/usr/bin/env python3
"""
Quick migration script to extract classes from monolithic file
"""
import re
from pathlib import Path

# Mapping of class names to their destination files
CLASS_MAP = {
    'ProjectSchema': 'src/core/schemas.py',
    'FileTemplate': 'src/core/schemas.py',
    'ClusterConfig': 'src/core/config.py',
    'AgentConfig': 'src/core/config.py',
    'GenerationState': 'src/core/state.py',
    'OllamaClient': 'src/clients/ollama_client.py',
    'FileValidator': 'src/validators/syntax_validator.py',
    'CodeFormatter': 'src/formatters/code_formatter.py',
    'DependencyGenerator': 'src/generators/dependency_gen.py',
    'DeploymentGenerator': 'src/generators/deployment_gen.py',
    'DocTestGenerator': 'src/generators/doc_gen.py',
    'ArchitectAgent': 'src/agents/architect.py',
    'CoderAgent': 'src/agents/coder.py',
    'ReviewerAgent': 'src/agents/reviewer.py',
    'FileWriterAgent': 'src/agents/writer.py',
    'CheckpointManager': 'src/workflow/checkpoints.py',
}

def extract_class(content: str, class_name: str) -> str:
    """Extract class definition from content"""
    pattern = rf'class {class_name}.*?(?=\nclass |\n# ===|$)'
    match = re.search(pattern, content, re.DOTALL)
    return match.group(0) if match else ""

def main():
    monolithic_file = Path("generator.py")

    if not monolithic_file.exists():
        print("❌ generator.py not found")
        return

    print("📖 Reading monolithic file...")
    content = monolithic_file.read_text()

    print("✂️  Extracting classes...")

    for class_name, dest_path in CLASS_MAP.items():
        class_code = extract_class(content, class_name)

        if class_code:
            dest = Path(dest_path)
            dest.parent.mkdir(parents=True, exist_ok=True)

            # Read existing or create new
            if dest.exists():
                existing = dest.read_text()
                dest.write_text(existing + "\n\n" + class_code)
            else:
                dest.write_text(class_code)

            print(f"   ✅ {class_name} → {dest_path}")
        else:
            print(f"   ⚠️  {class_name} not found")

    print("\n✨ Migration complete!")
    print("📝 Next steps:")
    print("   1. Review extracted files")
    print("   2. Fix imports")
    print("   3. Run tests")

if __name__ == "__main__":
    main()
```

Run migration:

```bash
python migrate.py
```

---

## Testing Your Modular Setup

### `tests/unit/test_schemas.py`

```python
import pytest
from src.core.schemas import ProjectSchema, FileTemplate

def test_file_template_creation():
    template = FileTemplate(
        path="main.go",
        purpose="entry point",
        file_type="main",
        language="go"
    )
    assert template.path == "main.go"
    assert template.priority == 5

def test_project_schema_defaults():
    schema = ProjectSchema(
        project_name="test",
        project_type="api",
        description="test project",
        languages=["go"],
        frameworks=["chi"],
        architecture_style="clean"
    )
    assert schema.authentication == False
    assert schema.testing == True
    assert schema.logging == True
```

### Run tests

```bash
pytest tests/ -v
```

---

## Summary

You now have:

1. ✅ **Modular structure** - Easy to maintain and extend
2. ✅ **Clear separation** - Each file has one responsibility
3. ✅ **Installable package** - Use via CLI or Python API
4. ✅ **Type safety** - Proper imports and type hints
5. ✅ **Testable** - Unit tests for each component
6. ✅ **Professional** - Follows Python best practices

**Total Time**: ~2-3 hours for complete migration
