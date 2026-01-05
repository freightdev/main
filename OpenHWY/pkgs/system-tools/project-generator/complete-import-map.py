"""
COMPLETE IMPORT MAP - Copy this to understand dependencies
Shows exactly what each file imports from where
"""

# ============================================================================
# src/core/schemas.py
# ============================================================================
"""
from dataclasses import dataclass, field, asdict
from typing import List, Dict, Any
import yaml
"""

# ============================================================================
# src/core/config.py
# ============================================================================
"""
from dataclasses import dataclass, asdict
import yaml
"""

# ============================================================================
# src/core/state.py
# ============================================================================
"""
from typing import TypedDict, Annotated, Sequence, Dict, Any, List
from langchain_core.messages import BaseMessage
import operator

from .schemas import ProjectSchema
from .config import ClusterConfig
"""

# ============================================================================
# src/core/constants.py
# ============================================================================
"""
from enum import Enum

class ProjectType(Enum):
    MICROSERVICE = "microservice"
    REST_API = "rest_api"
    MOBILE_APP = "mobile_app"
    WEB_APP = "web_app"
    CLI_TOOL = "cli_tool"
    LIBRARY = "library"

class ArchitectureStyle(Enum):
    CLEAN_ARCHITECTURE = "clean_architecture"
    HEXAGONAL = "hexagonal"
    LAYERED = "layered"
    MVC = "mvc"
    MVVM = "mvvm"
    BLOC = "bloc_pattern"

SUPPORTED_LANGUAGES = {'go', 'python', 'dart', 'javascript', 'typescript', 'rust', 'java'}
SUPPORTED_DATABASES = {'postgres', 'mysql', 'mongodb', 'redis', 'surrealdb', 'sqlite'}
"""

# ============================================================================
# src/utils/logger.py
# ============================================================================
"""
import logging
from datetime import datetime
from pathlib import Path
"""

# ============================================================================
# src/utils/json_parser.py
# ============================================================================
"""
import json
import re
from typing import Optional, Dict, Any
"""

# ============================================================================
# src/utils/file_utils.py
# ============================================================================
"""
import os
import shutil
from pathlib import Path
from typing import List, Optional
"""

# ============================================================================
# src/utils/progress.py
# ============================================================================
"""
try:
    from tqdm import tqdm
    HAS_TQDM = True
except ImportError:
    HAS_TQDM = False

from typing import Iterable, Optional
"""

# ============================================================================
# src/utils/error_handler.py
# ============================================================================
"""
import functools
import logging
from typing import Callable, Any
"""

# ============================================================================
# src/clients/ollama_client.py
# ============================================================================
"""
import logging
import time
from typing import Optional

from langchain_community.llms import Ollama
from ..core.config import AgentConfig
"""

# ============================================================================
# src/validators/base.py
# ============================================================================
"""
from abc import ABC, abstractmethod
from typing import Tuple, Optional
"""

# ============================================================================
# src/validators/syntax_validator.py
# ============================================================================
"""
import subprocess
import os
import tempfile
from typing import Optional, Tuple
import logging

from .base import BaseValidator
"""

# ============================================================================
# src/validators/dependency_validator.py
# ============================================================================
"""
from typing import List, Set, Dict, Any

def detect_circular_dependencies(files: List[Dict[str, Any]]) -> List[str]:
    # Implementation
    pass

def validate_dependency_order(files: List[Dict[str, Any]]) -> bool:
    # Implementation
    pass
"""

# ============================================================================
# src/validators/config_validator.py
# ============================================================================
"""
import re
from typing import List
import logging

from ..core.schemas import ProjectSchema
from ..core.config import ClusterConfig
from ..core.constants import SUPPORTED_LANGUAGES, SUPPORTED_DATABASES

class ConfigValidator:
    @classmethod
    def validate_project_schema(cls, schema: ProjectSchema) -> List[str]:
        # Implementation
        pass
    
    @classmethod
    def validate_cluster_config(cls, config: ClusterConfig) -> List[str]:
        # Implementation
        pass
"""

# ============================================================================
# src/formatters/base.py
# ============================================================================
"""
from abc import ABC, abstractmethod
"""

# ============================================================================
# src/formatters/code_formatter.py
# ============================================================================
"""
import subprocess
import logging
from typing import Optional

from .base import BaseFormatter
"""

# ============================================================================
# src/generators/base.py
# ============================================================================
"""
from abc import ABC, abstractmethod
from typing import Any
import logging

from ..core.schemas import ProjectSchema
"""

# ============================================================================
# src/generators/dependency_gen.py
# ============================================================================
"""
import json
from typing import List, Dict, Tuple

from .base import BaseGenerator
"""

# ============================================================================
# src/generators/deployment_gen.py
# ============================================================================
"""
import yaml
from typing import List, Dict, Optional

from .base import BaseGenerator
from ..core.schemas import ProjectSchema
"""

# ============================================================================
# src/generators/doc_gen.py
# ============================================================================
"""
import json
from typing import List, Dict, Any
import logging

from .base import BaseGenerator
from ..core.schemas import ProjectSchema
from ..clients.ollama_client import OllamaClient
"""

# ============================================================================
# src/generators/test_gen.py
# ============================================================================
"""
import logging
from typing import Dict, Optional

from .base import BaseGenerator
from ..core.schemas import ProjectSchema
from ..clients.ollama_client import OllamaClient
"""

# ============================================================================
# src/generators/config_gen.py
# ============================================================================
"""
from typing import Dict, List
import logging

from .base import BaseGenerator
from ..core.schemas import ProjectSchema
"""

# ============================================================================
# src/templates/__init__.py
# ============================================================================
"""
# Template files are .jinja2 - no Python imports needed
"""

# ============================================================================
# src/workflow/checkpoints.py
# ============================================================================
"""
import json
import hashlib
from pathlib import Path
from typing import Optional, Dict, Any
import logging

from ..core.state import GenerationState
"""

# ============================================================================
# src/workflow/nodes.py
# ============================================================================
"""
# Optional: Define node wrapper functions if needed
from ..core.state import GenerationState
"""

# ============================================================================
# src/workflow/edges.py
# ============================================================================
"""
# Optional: Define edge condition functions
from ..core.state import GenerationState

def should_continue_to_coder(state: GenerationState) -> str:
    return "coder" if not state["errors"] else "end"

def should_continue_to_reviewer(state: GenerationState) -> str:
    return "reviewer" if not state["errors"] else "end"
"""

# ============================================================================
# src/workflow/builder.py
# ============================================================================
"""
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
from .checkpoints import CheckpointManager
"""

# ============================================================================
# src/agents/base.py
# ============================================================================
"""
import logging
from abc import ABC, abstractmethod

from ..core.state import GenerationState
from ..clients.ollama_client import OllamaClient
"""

# ============================================================================
# src/agents/architect.py
# ============================================================================
"""
import logging
from typing import Optional, Dict, Any
import yaml
from dataclasses import asdict

from langchain_core.messages import AIMessage

from .base import BaseAgent
from ..core.state import GenerationState
from ..clients.ollama_client import OllamaClient
from ..utils.json_parser import parse_json_robust
from ..validators.dependency_validator import detect_circular_dependencies
"""

# ============================================================================
# src/agents/coder.py
# ============================================================================
"""
import logging
from typing import Optional, Dict, Any
from datetime import datetime
from pathlib import Path

from langchain_core.messages import AIMessage

from .base import BaseAgent
from ..core.state import GenerationState
from ..clients.ollama_client import OllamaClient
from ..validators.syntax_validator import FileValidator
from ..formatters.code_formatter import CodeFormatter
from ..workflow.checkpoints import CheckpointManager
from ..utils.progress import tqdm, HAS_TQDM
"""

# ============================================================================
# src/agents/reviewer.py
# ============================================================================
"""
import logging
from typing import Optional, Dict, Any
from datetime import datetime

from langchain_core.messages import AIMessage

from .base import BaseAgent
from ..core.state import GenerationState
from ..clients.ollama_client import OllamaClient
from ..utils.json_parser import parse_json_robust
"""

# ============================================================================
# src/agents/writer.py
# ============================================================================
"""
import logging
from pathlib import Path
from datetime import datetime
from dataclasses import asdict
import json

from langchain_core.messages import AIMessage

from .base import BaseAgent
from ..core.state import GenerationState
from ..generators.dependency_gen import DependencyGenerator
from ..generators.deployment_gen import DeploymentGenerator
from ..generators.doc_gen import DocGenerator
from ..generators.test_gen import TestGenerator
from ..generators.config_gen import ConfigGenerator
"""

# ============================================================================
# src/cli/main.py
# ============================================================================
"""
import argparse
import sys
from pathlib import Path

from .commands import (
    generate_command, 
    init_command, 
    resume_command, 
    validate_command,
    examples_command
)
"""

# ============================================================================
# src/cli/commands.py
# ============================================================================
"""
import os
from pathlib import Path
import logging

from ..core.schemas import ProjectSchema
from ..core.config import ClusterConfig
from ..workflow.builder import WorkflowBuilder
from ..validators.config_validator import ConfigValidator
from ..utils.logger import setup_logging
"""

# ============================================================================
# src/cli/interactive.py
# ============================================================================
"""
# Optional: Interactive wizard
import questionary
from typing import Dict, Any

from ..core.schemas import ProjectSchema
from ..core.constants import ProjectType, ArchitectureStyle, SUPPORTED_LANGUAGES
"""

# ============================================================================
# COMPLETE EXAMPLE FILE: src/agents/architect.py
# ============================================================================

# Here's what a complete file looks like with all imports:

"""
# src/agents/architect.py

import logging
from typing import Optional, Dict, Any
import yaml
from dataclasses import asdict

from langchain_core.messages import AIMessage

from .base import BaseAgent
from ..core.state import GenerationState
from ..clients.ollama_client import OllamaClient
from ..utils.json_parser import parse_json_robust
from ..validators.dependency_validator import detect_circular_dependencies


class ArchitectAgent(BaseAgent):
    '''Plans project architecture'''
    
    def __init__(self, client: OllamaClient, logger: logging.Logger):
        super().__init__(client, logger)
    
    def __call__(self, state: GenerationState) -> GenerationState:
        self.logger.info("🏗️  ARCHITECT: Planning project structure...")
        
        try:
            schema = state["project_schema"]
            
            prompt = f'''You are a software architect. Plan the complete structure for this project:

PROJECT SCHEMA:
{yaml.dump(asdict(schema), default_flow_style=False)}

Your task:
1. Design complete directory structure
2. List ALL files needed with purpose and dependencies
3. Specify generation order (dependencies first)
4. Include test files, config files, and documentation

Return ONLY valid JSON (no markdown, no explanations):
{{
    "directories": ["path/to/dir"],
    "files": [
        {{
            "path": "relative/path/file.ext",
            "purpose": "what this does",
            "type": "handler|service|model|config|test|doc",
            "language": "{schema.languages[0]}",
            "dependencies": ["other/files.ext"],
            "priority": 1
        }}
    ],
    "generation_order": ["file1.ext", "file2.ext"],
    "dependencies_needed": ["github.com/pkg/module@v1.0.0"],
    "architecture_notes": "key decisions"
}}'''
            
            response = self.client.invoke(prompt)
            plan = parse_json_robust(response)
            
            if not plan or 'files' not in plan:
                raise ValueError("Invalid architecture plan format")
            
            # Check for circular dependencies
            files = plan.get("files", [])
            circular = detect_circular_dependencies(files)
            
            if circular:
                self.logger.warning(f"⚠️  Circular dependencies detected: {circular}")
                state["warnings"].append({
                    "agent": "architect",
                    "warning": f"Circular dependencies: {circular}"
                })
            
            state["architecture_plan"] = plan
            state["files_to_generate"] = plan.get("generation_order", [])
            state["current_phase"] = "architecture_complete"
            
            state["messages"].append(
                AIMessage(content=f"Architect: Planned {len(plan['files'])} files")
            )
            
            self.logger.info(f"✅ Planned {len(plan['files'])} files")
            
        except Exception as e:
            self.logger.error(f"❌ Architect failed: {e}")
            state["errors"].append({"agent": "architect", "error": str(e)})
            state["current_phase"] = "failed"
        
        return state
"""

# ============================================================================
# DEPENDENCY GRAPH (What depends on what)
# ============================================================================

"""
LAYER 0 (No dependencies - create these first):
  - src/core/constants.py
  - src/utils/logger.py
  - src/utils/json_parser.py
  - src/utils/file_utils.py
  - src/utils/progress.py
  - src/utils/error_handler.py

LAYER 1 (Depends on Layer 0):
  - src/core/schemas.py        (uses constants)
  - src/core/config.py         (uses constants)

LAYER 2 (Depends on Layer 0-1):
  - src/core/state.py          (uses schemas, config)
  - src/validators/base.py     (no deps)
  - src/formatters/base.py     (no deps)
  - src/generators/base.py     (uses schemas)

LAYER 3 (Depends on Layer 0-2):
  - src/clients/ollama_client.py      (uses config, logger)
  - src/validators/syntax_validator.py (uses base)
  - src/validators/dependency_validator.py
  - src/validators/config_validator.py (uses schemas, config, constants)
  - src/formatters/code_formatter.py   (uses base)
  - src/generators/dependency_gen.py   (uses base, schemas)
  - src/generators/deployment_gen.py   (uses base, schemas)
  - src/generators/doc_gen.py          (uses base, schemas, ollama_client)
  - src/generators/test_gen.py         (uses base, schemas, ollama_client)
  - src/generators/config_gen.py       (uses base, schemas)

LAYER 4 (Depends on Layer 0-3):
  - src/workflow/checkpoints.py        (uses state, logger)
  - src/agents/base.py                 (uses state, ollama_client)

LAYER 5 (Depends on Layer 0-4):
  - src/agents/architect.py            (uses base, state, ollama_client, json_parser, dependency_validator)
  - src/agents/coder.py                (uses base, state, ollama_client, validators, formatters, checkpoints)
  - src/agents/reviewer.py             (uses base, state, ollama_client, json_parser)
  - src/agents/writer.py               (uses base, state, all generators)

LAYER 6 (Depends on Layer 0-5):
  - src/workflow/builder.py            (uses schemas, config, state, all agents, validators, formatters, logger, checkpoints)

LAYER 7 (Top level - depends on everything):
  - src/cli/commands.py                (uses schemas, config, workflow.builder, validators, logger)
  - src/cli/main.py                    (uses commands)
"""

# ============================================================================
# CREATION ORDER (Follow this order to avoid import errors)
# ============================================================================

"""
STEP 1: Create directory structure
  mkdir -p src/{core,clients,validators,formatters,generators,templates,workflow,agents,utils,cli}
  mkdir -p tests/{unit,integration,fixtures}
  mkdir -p config/{examples,presets}
  mkdir -p docs scripts generated .checkpoint

STEP 2: Create all __init__.py files
  touch src/__init__.py
  touch src/core/__init__.py
  touch src/clients/__init__.py
  touch src/validators/__init__.py
  touch src/formatters/__init__.py
  touch src/generators/__init__.py
  touch src/templates/__init__.py
  touch src/workflow/__init__.py
  touch src/agents/__init__.py
  touch src/utils/__init__.py
  touch src/cli/__init__.py

STEP 3: Create Layer 0 files (no dependencies)
  1. src/core/constants.py
  2. src/utils/logger.py
  3. src/utils/json_parser.py
  4. src/utils/file_utils.py
  5. src/utils/progress.py
  6. src/utils/error_handler.py

STEP 4: Create Layer 1 files
  1. src/core/schemas.py
  2. src/core/config.py

STEP 5: Create Layer 2 files
  1. src/core/state.py
  2. src/validators/base.py
  3. src/formatters/base.py
  4. src/generators/base.py

STEP 6: Create Layer 3 files
  1. src/clients/ollama_client.py
  2. src/validators/syntax_validator.py
  3. src/validators/dependency_validator.py
  4. src/validators/config_validator.py
  5. src/formatters/code_formatter.py
  6. src/generators/dependency_gen.py
  7. src/generators/deployment_gen.py
  8. src/generators/doc_gen.py
  9. src/generators/test_gen.py
  10. src/generators/config_gen.py

STEP 7: Create Layer 4 files
  1. src/workflow/checkpoints.py
  2. src/agents/base.py

STEP 8: Create Layer 5 files
  1. src/agents/architect.py
  2. src/agents/coder.py
  3. src/agents/reviewer.py
  4. src/agents/writer.py

STEP 9: Create Layer 6 files
  1. src/workflow/builder.py

STEP 10: Create Layer 7 files
  1. src/cli/commands.py
  2. src/cli/main.py

STEP 11: Create configuration files
  1. requirements.txt
  2. setup.py
  3. pyproject.toml
  4. .gitignore
  5. README.md

STEP 12: Create config files
  1. config/cluster_config.yaml
  2. config/examples/go_microservice.yaml
  3. config/examples/python_api.yaml
  4. config/examples/flutter_app.yaml
"""

# ============================================================================
# EXAMPLE: Complete src/formatters/code_formatter.py
# ============================================================================

"""
# src/formatters/code_formatter.py

import subprocess
import logging
from typing import Optional

from .base import BaseFormatter


class CodeFormatter(BaseFormatter):
    '''Format generated code using language-specific formatters'''
    
    def __init__(self, logger: Optional[logging.Logger] = None):
        self.logger = logger or logging.getLogger(__name__)
    
    @staticmethod
    def format_go(code: str) -> str:
        '''Format Go code with gofmt'''
        try:
            result = subprocess.run(
                ['gofmt'],
                input=code,
                capture_output=True,
                text=True,
                timeout=10
            )
            return result.stdout if result.returncode == 0 else code
        except Exception:
            return code
    
    @staticmethod
    def format_python(code: str) -> str:
        '''Format Python code with black'''
        try:
            result = subprocess.run(
                ['black', '-', '--quiet'],
                input=code,
                capture_output=True,
                text=True,
                timeout=10
            )
            return result.stdout if result.returncode == 0 else code
        except Exception:
            return code
    
    @staticmethod
    def format_dart(code: str) -> str:
        '''Format Dart code'''
        try:
            result = subprocess.run(
                ['dart', 'format'],
                input=code,
                capture_output=True,
                text=True,
                timeout=10
            )
            return result.stdout if result.returncode == 0 else code
        except Exception:
            return code
    
    def format(self, language: str, code: str) -> str:
        '''Format code based on language'''
        formatters = {
            'go': self.format_go,
            'python': self.format_python,
            'dart': self.format_dart,
        }
        
        formatter = formatters.get(language.lower())
        if formatter:
            try:
                formatted = formatter(code)
                if formatted != code:
                    self.logger.info(f"✅ Formatted {language} code")
                return formatted
            except Exception as e:
                self.logger.warning(f"⚠️  Failed to format {language}: {e}")
                return code
        
        return code
"""

# ============================================================================
# EXAMPLE: Complete src/generators/dependency_gen.py
# ============================================================================

"""
# src/generators/dependency_gen.py

import json
from typing import List, Dict, Tuple

from .base import BaseGenerator


class DependencyGenerator(BaseGenerator):
    '''Generate dependency management files'''
    
    @staticmethod
    def parse_go_dependency(dep: str) -> Tuple[str, str]:
        '''Parse 'github.com/pkg/module@v1.0.0' -> (module, version)'''
        if '@' in dep:
            module, version = dep.rsplit('@', 1)
            return module, version
        return dep, "latest"
    
    @staticmethod
    def generate_go_mod(project_name: str, dependencies: List[str]) -> str:
        '''Generate go.mod with proper versions'''
        require_lines = []
        
        for dep in dependencies:
            module, version = DependencyGenerator.parse_go_dependency(dep)
            require_lines.append(f"    {module} {version}")
        
        requires = "\\n".join(require_lines) if require_lines else "    // No external dependencies"
        
        return f\"\"\"module github.com/yourorg/{project_name}

go 1.21

require (
{requires}
)
\"\"\"
    
    @staticmethod
    def generate_package_json(
        project_name: str, 
        dependencies: List[str],
        dev_dependencies: List[str] = None
    ) -> str:
        '''Generate package.json with version parsing'''
        
        deps = {}
        for dep in dependencies:
            if '@' in dep and not dep.startswith('@'):
                pkg, ver = dep.rsplit('@', 1)
                deps[pkg] = ver
            else:
                deps[dep] = "latest"
        
        dev_deps = {}
        for dep in (dev_dependencies or []):
            if '@' in dep and not dep.startswith('@'):
                pkg, ver = dep.rsplit('@', 1)
                dev_deps[pkg] = ver
            else:
                dev_deps[dep] = "latest"
        
        return json.dumps({
            "name": project_name,
            "version": "1.0.0",
            "description": "",
            "main": "index.js",
            "scripts": {
                "start": "node index.js",
                "test": "jest",
                "dev": "nodemon index.js"
            },
            "dependencies": deps,
            "devDependencies": dev_deps
        }, indent=2)
    
    @staticmethod
    def generate_pubspec_yaml(project_name: str, dependencies: Dict[str, str]) -> str:
        '''Generate pubspec.yaml for Flutter'''
        deps = '\\n'.join(f"  {k}: {v}" for k, v in dependencies.items())
        return f\"\"\"name: {project_name}
description: A new Flutter project
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
{deps}

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
\"\"\"
    
    @staticmethod
    def generate_requirements_txt(dependencies: List[str]) -> str:
        '''Generate requirements.txt for Python'''
        return '\\n'.join(dependencies)
    
    @staticmethod
    def generate_cargo_toml(project_name: str, dependencies: Dict[str, str]) -> str:
        '''Generate Cargo.toml for Rust'''
        deps = '\\n'.join(f'{k} = "{v}"' for k, v in dependencies.items())
        return f\"\"\"[package]
name = "{project_name}"
version = "0.1.0"
edition = "2021"

[dependencies]
{deps}
\"\"\"
"""

# ============================================================================
# EXAMPLE: Complete src/cli/commands.py
# ============================================================================

"""
# src/cli/commands.py

import os
from pathlib import Path
import logging
import yaml

from ..core.schemas import ProjectSchema
from ..core.config import ClusterConfig
from ..workflow.builder import WorkflowBuilder
from ..validators.config_validator import ConfigValidator
from ..utils.logger import setup_logging


def generate_command(project_path: str, cluster_path: str):
    '''Generate project from schema'''
    
    logger = setup_logging("INFO")
    
    # Validate files exist
    if not os.path.exists(cluster_path):
        logger.error(f"❌ Cluster config not found: {cluster_path}")
        return
    
    if not os.path.exists(project_path):
        logger.error(f"❌ Project schema not found: {project_path}")
        return
    
    try:
        # Load configurations
        cluster = ClusterConfig.from_yaml(cluster_path)
        schema = ProjectSchema.from_yaml(project_path)
        
        # Validate configurations
        schema_errors = ConfigValidator.validate_project_schema(schema)
        config_errors = ConfigValidator.validate_cluster_config(cluster)
        
        if schema_errors or config_errors:
            logger.error("❌ Configuration validation failed:")
            for error in schema_errors + config_errors:
                logger.error(f"   - {error}")
            return
        
        logger.info("✅ Configuration validated")
        
        # Build and run workflow
        builder = WorkflowBuilder(schema, cluster)
        builder.generate()
        
        print("\\n✨ Generation complete!")
        print(f"📂 Output: {cluster.output_dir}/{schema.project_name}/")
        
    except Exception as e:
        logger.error(f"❌ Generation failed: {e}", exc_info=True)


def init_command():
    '''Interactive project setup wizard'''
    print("🎯 Interactive Project Generator")
    print("=" * 60)
    print()
    
    # Collect basic info
    project_name = input("Project name: ").strip()
    project_type = input("Project type (microservice/api/app): ").strip()
    description = input("Description: ").strip()
    
    # Technology stack
    print("\\nLanguages (comma-separated, e.g., go,python):")
    languages = [l.strip() for l in input().split(',')]
    
    print("\\nFrameworks (comma-separated):")
    frameworks = [f.strip() for f in input().split(',')]
    
    print("\\nDatabases (comma-separated, optional):")
    databases_input = input().strip()
    databases = [d.strip() for d in databases_input.split(',')] if databases_input else []
    
    # Architecture
    print("\\nArchitecture style:")
    print("  1. Clean Architecture")
    print("  2. Layered Architecture")
    print("  3. Hexagonal Architecture")
    print("  4. MVC")
    architecture_choice = input("Choose (1-4): ").strip()
    
    architecture_map = {
        '1': 'clean_architecture',
        '2': 'layered',
        '3': 'hexagonal',
        '4': 'mvc'
    }
    architecture = architecture_map.get(architecture_choice, 'clean_architecture')
    
    # Create schema
    schema = ProjectSchema(
        project_name=project_name,
        project_type=project_type,
        description=description,
        languages=languages,
        frameworks=frameworks,
        databases=databases,
        architecture_style=architecture,
        design_patterns=['repository', 'dependency_injection'],
        features=[],
        authentication=True,
        logging=True,
        testing=True,
        documentation=True,
        containerization='docker'
    )
    
    # Save schema
    output_path = f"{project_name}_schema.yaml"
    schema.to_yaml(output_path)
    
    print(f"\\n✅ Project schema saved to: {output_path}")
    print(f"\\n📝 Next steps:")
    print(f"   1. Review and edit {output_path}")
    print(f"   2. Run: project-gen generate --project {output_path}")


def resume_command(checkpoint_dir: str):
    '''Resume generation from checkpoint'''
    from ..workflow.checkpoints import CheckpointManager
    
    logger = setup_logging("INFO")
    
    checkpoint_path = Path(checkpoint_dir)
    if not checkpoint_path.exists():
        logger.error(f"❌ Checkpoint not found: {checkpoint_dir}")
        return
    
    logger.info(f"📂 Loading checkpoint from {checkpoint_dir}...")
    
    state = CheckpointManager.load(str(checkpoint_path))
    
    if not state:
        logger.error("❌ Failed to load checkpoint")
        return
    
    logger.info(f"✅ Checkpoint loaded")
    logger.info(f"   Phase: {state['current_phase']}")
    logger.info(f"   Files generated: {len(state['files_generated'])}")
    logger.info(f"   Files remaining: {len(state['files_to_generate']) - len(state['files_generated'])}")
    
    # TODO: Implement resume logic
    logger.info("⚠️  Resume functionality coming soon")


def validate_command(project_path: str):
    '''Validate project schema'''
    logger = setup_logging("INFO")
    
    if not os.path.exists(project_path):
        logger.error(f"❌ Project schema not found: {project_path}")
        return
    
    try:
        schema = ProjectSchema.from_yaml(project_path)
        errors = ConfigValidator.validate_project_schema(schema)
        
        if errors:
            logger.error("❌ Validation failed:")
            for error in errors:
                logger.error(f"   - {error}")
        else:
            logger.info(f"✅ Valid project schema: {schema.project_name}")
            logger.info(f"   Type: {schema.project_type}")
            logger.info(f"   Languages: {', '.join(schema.languages)}")
            logger.info(f"   Architecture: {schema.architecture_style}")
            
    except Exception as e:
        logger.error(f"❌ Failed to load schema: {e}")


def examples_command():
    '''Generate example configuration files'''
    from ..core.schemas import ProjectSchema
    from ..core.config import ClusterConfig, AgentConfig
    
    print("📝 Generating example configurations...")
    
    # Create config directory
    config_dir = Path("config/examples")
    config_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate cluster config
    cluster = ClusterConfig(
        architect=AgentConfig(
            role="architect",
            model="qwen2.5-coder:7b",
            base_url="http://localhost:11434"
        ),
        coder=AgentConfig(
            role="coder",
            model="qwen2.5-coder:7b",
            base_url="http://localhost:11434"
        ),
        reviewer=AgentConfig(
            role="reviewer",
            model="qwen2.5-coder:7b",
            base_url="http://localhost:11434"
        )
    )
    cluster.to_yaml("config/cluster_config.yaml")
    print("   ✅ config/cluster_config.yaml")
    
    # Generate Go microservice example
    go_service = ProjectSchema(
        project_name="auth-service",
        project_type="microservice",
        description="Authentication service with JWT",
        languages=["go"],
        frameworks=["chi"],
        databases=["redis"],
        architecture_style="clean_architecture",
        design_patterns=["repository", "dependency_injection"],
        features=["login", "register", "jwt_auth"],
        authentication=True,
        logging=True,
        testing=True,
        documentation=True
    )
    go_service.to_yaml("config/examples/go_microservice.yaml")
    print("   ✅ config/examples/go_microservice.yaml")
    
    print("\\n✨ Examples generated! Run with:")
    print("   project-gen generate --project config/examples/go_microservice.yaml")
"""

# ============================================================================
# QUICK START CHECKLIST
# ============================================================================

"""
□ Step 1: Create directory structure
  mkdir -p universal-project-generator/src/{core,clients,validators,formatters,generators,templates,workflow,agents,utils,cli}
  cd universal-project-generator

□ Step 2: Copy Layer 0 files (no dependencies)
  - src/core/constants.py
  - src/utils/logger.py
  - src/utils/json_parser.py
  - src/utils/file_utils.py (optional)
  - src/utils/progress.py (optional)

□ Step 3: Copy Layer 1 files
  - src/core/schemas.py
  - src/core/config.py

□ Step 4: Copy Layer 2 files
  - src/core/state.py
  - src/validators/base.py (create empty ABC)
  - src/formatters/base.py (create empty ABC)
  - src/generators/base.py (create empty ABC)

□ Step 5: Copy Layer 3 files
  - src/clients/ollama_client.py
  - src/validators/syntax_validator.py
  - src/formatters/code_formatter.py
  - src/generators/dependency_gen.py
  - src/generators/deployment_gen.py

□ Step 6: Copy Layer 4 files
  - src/workflow/checkpoints.py
  - src/agents/base.py

□ Step 7: Copy Layer 5 files (agents)
  - src/agents/architect.py
  - src/agents/coder.py
  - src/agents/reviewer.py
  - src/agents/writer.py

□ Step 8: Copy Layer 6 files
  - src/workflow/builder.py

□ Step 9: Copy Layer 7 files (CLI)
  - src/cli/commands.py
  - src/cli/main.py

□ Step 10: Create __init__.py files in all directories
  find src -type d -exec touch {}/__init__.py \\;

□ Step 11: Create requirements.txt and setup.py

□ Step 12: Test imports
  python -c "from src.core.schemas import ProjectSchema; print('✅ Imports work!')"

□ Step 13: Create example configs
  python -m src.cli.main examples

□ Step 14: Test generation
  python -m src.cli.main generate --project config/examples/go_microservice.yaml
"""