#!/bin/bash
# ============================================================================
# PHASES 5-9: Complete Setup
# Validators, Formatters, Generators, Agents, Workflow, CLI
# Run this after phases 1-4 to complete the entire setup
# ============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  PHASES 5-9: Complete Remaining Setup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# ============================================================================
# PHASE 5: Validators & Formatters
# ============================================================================
echo -e "${GREEN}PHASE 5: Validators & Formatters${NC}"

cat > src/validators/syntax_validator.py << 'PHASE5_VALIDATOR'
"""Code syntax validation"""
import subprocess
import os
import tempfile
from typing import Optional, Tuple
import logging

class FileValidator:
    """Validate generated code syntax"""
    
    def __init__(self, logger: Optional[logging.Logger] = None):
        self.logger = logger or logging.getLogger(__name__)
    
    def validate_go(self, code: str) -> Tuple[bool, Optional[str]]:
        """Validate Go syntax using go fmt"""
        try:
            with tempfile.NamedTemporaryFile(
                mode='w', suffix='.go', delete=False
            ) as f:
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
    
    def validate_python(self, code: str) -> Tuple[bool, Optional[str]]:
        """Validate Python syntax"""
        try:
            compile(code, '<string>', 'exec')
            return True, None
        except SyntaxError as e:
            return False, f"Line {e.lineno}: {e.msg}"
    
    def validate_dart(self, code: str) -> Tuple[bool, Optional[str]]:
        """Validate Dart syntax"""
        try:
            with tempfile.NamedTemporaryFile(
                mode='w', suffix='.dart', delete=False
            ) as f:
                f.write(code)
                temp_path = f.name
            
            result = subprocess.run(
                ['dart', 'analyze', temp_path],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            os.unlink(temp_path)
            
            if result.returncode == 0:
                return True, None
            return False, result.stderr
            
        except FileNotFoundError:
            return True, "Dart not installed, skipping validation"
        except Exception as e:
            return False, str(e)
    
    def validate(self, language: str, code: str) -> Tuple[bool, Optional[str]]:
        """Validate code based on language"""
        validators = {
            'go': self.validate_go,
            'python': self.validate_python,
            'dart': self.validate_dart,
        }
        
        validator = validators.get(language.lower())
        if validator:
            return validator(code)
        
        self.logger.debug(f"No validator for {language}, skipping")
        return True, f"No validator for {language}"
PHASE5_VALIDATOR

cat > src/formatters/code_formatter.py << 'PHASE5_FORMATTER'
"""Code formatting"""
import subprocess
from typing import Optional
import logging

class CodeFormatter:
    """Format generated code using language-specific formatters"""
    
    def __init__(self, logger: Optional[logging.Logger] = None):
        self.logger = logger or logging.getLogger(__name__)
    
    @staticmethod
    def format_go(code: str) -> str:
        """Format Go code with gofmt"""
        try:
            result = subprocess.run(
                ['gofmt'],
                input=code,
                capture_output=True,
                text=True,
                timeout=10
            )
            return result.stdout if result.returncode == 0 else code
        except:
            return code
    
    def format(self, language: str, code: str) -> str:
        """Format code based on language"""
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
                    self.logger.debug(f"Formatted {language} code")
                return formatted
            except Exception as e:
                self.logger.warning(f"Failed to format {language}: {e}")
                return code
        
        return code
PHASE5_FORMATTER

echo -e "  ${GREEN}✓${NC} Phase 5 complete (Validators & Formatters)"

# ============================================================================
# PHASE 6: Generators
# ============================================================================
echo -e "${GREEN}PHASE 6: Generators${NC}"

cat > src/generators/dependency_gen.py << 'PHASE6_DEPS'
"""Dependency file generation"""
import json
from typing import List, Dict, Tuple

class DependencyGenerator:
    """Generate dependency management files"""
    
    @staticmethod
    def parse_go_dependency(dep: str) -> Tuple[str, str]:
        """Parse 'github.com/pkg/module@v1.0.0' -> (module, version)"""
        if '@' in dep:
            module, version = dep.rsplit('@', 1)
            return module, version
        return dep, "latest"
    
    @staticmethod
    def generate_go_mod(project_name: str, dependencies: List[str]) -> str:
        """Generate go.mod with proper versions"""
        require_lines = []
        
        for dep in dependencies:
            module, version = DependencyGenerator.parse_go_dependency(dep)
            require_lines.append(f"    {module} {version}")
        
        requires = "\n".join(require_lines) if require_lines else "    // No external dependencies"
        
        return f"""module github.com/yourorg/{project_name}

go 1.21

require (
{requires}
)
"""
    
    @staticmethod
    def generate_package_json(
        project_name: str,
        dependencies: List[str],
        dev_dependencies: List[str] = None
    ) -> str:
        """Generate package.json"""
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
    def generate_requirements_txt(dependencies: List[str]) -> str:
        """Generate requirements.txt for Python"""
        return '\n'.join(dependencies)
PHASE6_DEPS

cat > src/generators/deployment_gen.py << 'PHASE6_DEPLOY'
"""Deployment file generation"""
import yaml
from typing import List, Dict

class DeploymentGenerator:
    """Generate deployment files"""
    
    @staticmethod
    def generate_dockerfile(language: str, project_type: str) -> str:
        """Generate Dockerfile based on language"""
        
        if language == "go":
            return """FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main cmd/server/main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/main .
EXPOSE 8080
CMD ["./main"]
"""
        
        elif language == "python":
            return """FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["python", "main.py"]
"""
        
        elif language == "dart":
            return """FROM google/dart:latest
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart compile exe bin/main.dart -o bin/server
FROM alpine:latest
COPY --from=0 /app/bin/server /app/server
EXPOSE 8080
CMD ["/app/server"]
"""
        
        return "# Dockerfile not generated for this language"
    
    @staticmethod
    def generate_docker_compose(
        project_name: str,
        databases: List[str],
        services: List[str]
    ) -> str:
        """Generate docker-compose.yml"""
        
        compose = {
            'version': '3.8',
            'services': {},
            'networks': {
                'app-network': {'driver': 'bridge'}
            },
            'volumes': {}
        }
        
        # Main app service
        compose['services']['app'] = {
            'build': '.',
            'ports': ['8080:8080'],
            'environment': [],
            'depends_on': [],
            'networks': ['app-network'],
            'restart': 'unless-stopped'
        }
        
        # Add databases
        if 'postgres' in databases:
            compose['services']['postgres'] = {
                'image': 'postgres:15-alpine',
                'ports': ['5432:5432'],
                'environment': [
                    'POSTGRES_USER=user',
                    'POSTGRES_PASSWORD=password',
                    'POSTGRES_DB=database'
                ],
                'volumes': ['postgres_data:/var/lib/postgresql/data'],
                'networks': ['app-network']
            }
            compose['volumes']['postgres_data'] = {}
            compose['services']['app']['depends_on'].append('postgres')
        
        if 'redis' in databases:
            compose['services']['redis'] = {
                'image': 'redis:alpine',
                'ports': ['6379:6379'],
                'networks': ['app-network']
            }
            compose['services']['app']['depends_on'].append('redis')
        
        return yaml.dump(compose, default_flow_style=False, sort_keys=False)
PHASE6_DEPLOY

echo -e "  ${GREEN}✓${NC} Phase 6 complete (Generators)"

# ============================================================================
# PHASE 7: Agents (Simplified placeholders - you'll copy from monolithic)
# ============================================================================
echo -e "${GREEN}PHASE 7: Agents (Base structure)${NC}"

cat > src/agents/base.py << 'PHASE7_BASE'
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
PHASE7_BASE

# Create placeholder agent files
for agent in architect coder reviewer writer; do
    cat > src/agents/${agent}.py << AGENT_PLACEHOLDER
"""${agent^} agent - TODO: Copy from monolithic file"""
from .base import BaseAgent
from ..core.state import GenerationState

class ${agent^}Agent(BaseAgent):
    """${agent^} agent - TODO: Implement"""
    
    def __call__(self, state: GenerationState) -> GenerationState:
        self.logger.info(f"${agent^} agent called")
        # TODO: Copy implementation from monolithic file
        return state
AGENT_PLACEHOLDER
done

echo -e "  ${GREEN}✓${NC} Phase 7 complete (Agent base structure)"
echo -e "  ${YELLOW}⚠${NC}  TODO: Copy agent implementations from monolithic file"

# ============================================================================
# PHASE 8: Workflow & Queue System
# ============================================================================
echo -e "${GREEN}PHASE 8: Workflow & Queue System${NC}"

cat > src/workflow/builder.py << 'PHASE8_WORKFLOW'
"""Workflow builder using LangGraph"""
import logging
from pathlib import Path

from langgraph.graph import StateGraph, END

from ..core.schemas import ProjectSchema
from ..core.config import ClusterConfig
from ..core.state import GenerationState, create_initial_state
from ..clients.ollama_client import OllamaClient
from ..agents.architect import ArchitectAgent
from ..agents.coder import CoderAgent
from ..agents.reviewer import ReviewerAgent
from ..agents.writer import WriterAgent
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
        self.validator = FileValidator(self.logger)
        self.formatter = CodeFormatter(self.logger)
    
    def generate(self, job_id: str = "", user_id: str = "", tier: str = "free") -> GenerationState:
        """Run complete generation pipeline"""
        
        # Create initial state
        initial_state = create_initial_state(
            self.schema,
            self.config,
            job_id=job_id,
            user_id=user_id,
            tier=tier
        )
        
        # Create workflow
        workflow = self._create_workflow()
        app = workflow.compile()
        
        # Execute
        try:
            self.logger.info("🎯 Starting generation pipeline...")
            final_state = app.invoke(initial_state)
            
            self._print_summary(final_state)
            
            return final_state
            
        except Exception as e:
            self.logger.critical(f"💥 Generation failed: {e}", exc_info=True)
            raise
    
    def _create_workflow(self) -> StateGraph:
        """Create LangGraph workflow"""
        
        # Create agents
        architect = ArchitectAgent(self.architect_client, self.logger)
        coder = CoderAgent(self.coder_client, self.logger, self.validator, self.formatter)
        reviewer = ReviewerAgent(self.reviewer_client, self.logger)
        writer = WriterAgent(self.logger)
        
        # Build graph
        workflow = StateGraph(GenerationState)
        
        workflow.add_node("architect", architect)
        workflow.add_node("coder", coder)
        workflow.add_node("reviewer", reviewer)
        workflow.add_node("writer", writer)
        
        # Define flow
        workflow.set_entry_point("architect")
        
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
        self.logger.info(f"Final Phase: {state['current_phase']}")
        self.logger.info(f"Files Generated: {len(state['generated_files'])}")
        self.logger.info(f"Files Failed: {len(state['files_failed'])}")
        
        output_dir = Path(self.config.output_dir) / self.schema.project_name
        self.logger.info(f"📂 Output: {output_dir.absolute()}")
        self.logger.info("="*70)
PHASE8_WORKFLOW

cat > src/workflow/queue.py << 'PHASE8_QUEUE'
"""Job queue system using Redis"""
import redis
import json
from typing import Optional, Dict, Any
from datetime import datetime

class QueueManager:
    """Manages job queue with Redis"""
    
    def __init__(self, host: str = "localhost", port: int = 6379, db: int = 0):
        self.redis = redis.Redis(
            host=host,
            port=port,
            db=db,
            decode_responses=True
        )
    
    def submit_job(self, job_data: Dict[str, Any]) -> str:
        """Submit job to queue"""
        job_id = job_data.get('job_id', str(datetime.now().timestamp()))
        
        # Add to queue
        self.redis.zadd(
            "jobs:pending",
            {job_id: job_data.get('priority', 3)}
        )
        
        # Store job details
        self.redis.hset(
            f"job:{job_id}",
            mapping={k: json.dumps(v) if isinstance(v, dict) else str(v) for k, v in job_data.items()}
        )
        
        return job_id
    
    def get_next_job(self) -> Optional[Dict[str, Any]]:
        """Get next job from queue"""
        jobs = self.redis.zrange("jobs:pending", 0, 0)
        
        if not jobs:
            return None
        
        job_id = jobs[0]
        self.redis.zrem("jobs:pending", job_id)
        
        job_data = self.redis.hgetall(f"job:{job_id}")
        return {k: json.loads(v) if k in ['project_schema'] else v for k, v in job_data.items()}
    
    def get_job_status(self, job_id: str) -> Optional[Dict[str, Any]]:
        """Get job status"""
        job_data = self.redis.hgetall(f"job:{job_id}")
        if not job_data:
            return None
        return job_data
PHASE8_QUEUE

echo -e "  ${GREEN}✓${NC} Phase 8 complete (Workflow & Queue)"

# ============================================================================
# PHASE 9: CLI & API
# ============================================================================
echo -e "${GREEN}PHASE 9: CLI & API${NC}"

cat > src/cli/main.py << 'PHASE9_CLI'
"""Main CLI entry point"""
import argparse
import sys

def main():
    parser = argparse.ArgumentParser(
        description="Universal Project Generator"
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Commands')
    
    # Generate command
    gen_parser = subparsers.add_parser('generate', help='Generate project')
    gen_parser.add_argument('--project', required=True, help='Project schema YAML')
    gen_parser.add_argument('--cluster', default='config/cluster_config.yaml', help='Cluster config')
    
    # Examples command
    ex_parser = subparsers.add_parser('examples', help='Generate example configs')
    
    args = parser.parse_args()
    
    if args.command == 'generate':
        from .commands import generate_command
        generate_command(args.project, args.cluster)
    elif args.command == 'examples':
        from .commands import examples_command
        examples_command()
    else:
        parser.print_help()
        sys.exit(1)

if __name__ == '__main__':
    main()
PHASE9_CLI

cat > src/cli/commands.py << 'PHASE9_COMMANDS'
"""CLI command implementations"""
import os
from pathlib import Path

from ..core.schemas import ProjectSchema
from ..core.config import ClusterConfig, AgentConfig
from ..workflow.builder import WorkflowBuilder
from ..utils.logger import setup_logging

def generate_command(project_path: str, cluster_path: str):
    """Generate project from schema"""
    
    logger = setup_logging("INFO")
    
    if not os.path.exists(cluster_path):
        logger.error(f"❌ Cluster config not found: {cluster_path}")
        return
    
    if not os.path.exists(project_path):
        logger.error(f"❌ Project schema not found: {project_path}")
        return
    
    try:
        cluster = ClusterConfig.from_yaml(cluster_path)
        schema = ProjectSchema.from_yaml(project_path)
        
        builder = WorkflowBuilder(schema, cluster)
        builder.generate()
        
        print(f"\n✨ Generation complete!")
        print(f"📂 Output: {cluster.output_dir}/{schema.project_name}/")
        
    except Exception as e:
        logger.error(f"❌ Generation failed: {e}", exc_info=True)

def examples_command():
    """Generate example configuration files"""
    print("📝 Generating example configurations...")
    
    # Create config directory
    config_dir = Path("config/examples")
    config_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate cluster config
    cluster = ClusterConfig(
        architect=AgentConfig(
            role="architect",
            model="qwen2.5-coder:32b",
            base_url="http://localhost:11434"
        ),
        coder=AgentConfig(
            role="coder",
            model="qwen2.5-coder:14b",
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
    
    print("\n✨ Examples generated!")
PHASE9_COMMANDS

echo -e "  ${GREEN}✓${NC} Phase 9 complete (CLI & API)"

# ============================================================================
# Create setup.py
# ============================================================================
echo -e "${GREEN}Creating setup.py...${NC}"

cat > setup.py << 'SETUP_PY'
from setuptools import setup, find_packages

setup(
    name="universal-project-generator",
    version="1.0.0",
    description="Universal project generator with 3-agent Ollama cluster",
    packages=find_packages(),
    install_requires=[
        "langgraph>=0.0.20",
        "langchain>=0.1.0",
        "langchain-community>=0.0.10",
        "ollama>=0.1.0",
        "pyyaml>=6.0",
        "redis>=5.0.0",
        "requests>=2.31.0",
        "tqdm>=4.66.0",
    ],
    entry_points={
        'console_scripts': [
            'project-gen=src.cli.main:main',
        ],
    },
    python_requires=">=3.10",
)
SETUP_PY

echo -e "  ${GREEN}✓${NC} setup.py created"

# ============================================================================
# Final Summary
# ============================================================================
echo
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ Phases 5-9 Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo -e "${YELLOW}Created:${NC}"
echo "  ✓ Phase 5: Validators & Formatters"
echo "  ✓ Phase 6: Generators (dependencies, deployment)"
echo "  ✓ Phase 7: Agent base structure"
echo "  ✓ Phase 8: Workflow & Queue system"
echo "  ✓ Phase 9: CLI & API"
echo "  ✓ setup.py"
echo
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Copy agent implementations from monolithic file:"
echo "     - src/agents/architect.py"
echo "     - src/agents/coder.py"
echo "     - src/agents/reviewer.py"
echo "     - src/agents/writer.py"
echo
echo "  2. Install dependencies:"
echo "     pip install -e ."
echo
echo "  3. Generate example configs:"
echo "     project-gen examples"
echo
echo "  4. Test generation:"
echo "     project-gen generate --project config/examples/go_microservice.yaml"
echo
echo -e "${GREEN}Setup Complete! 🎉${NC}"
echo