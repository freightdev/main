#!/bin/bash
# ============================================================================
# PHASE 2: Core Modules
# Creates schemas, config, state, and constants
# ============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  PHASE 2: Core Modules${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# ============================================================================
# Create src/core/constants.py
# ============================================================================
echo -e "${GREEN}[1/4]${NC} Creating core/constants.py..."

cat > src/core/constants.py << 'EOF'
"""Project constants and enums"""
from enum import Enum

class ProjectType(Enum):
    MICROSERVICE = "microservice"
    REST_API = "rest_api"
    MOBILE_APP = "mobile_app"
    WEB_APP = "web_app"
    CLI_TOOL = "cli_tool"
    LIBRARY = "library"
    FULLSTACK = "fullstack"

class ArchitectureStyle(Enum):
    CLEAN_ARCHITECTURE = "clean_architecture"
    HEXAGONAL = "hexagonal"
    LAYERED = "layered"
    MVC = "mvc"
    MVVM = "mvvm"
    BLOC = "bloc_pattern"
    EVENT_DRIVEN = "event_driven"

SUPPORTED_LANGUAGES = {
    'go', 'python', 'dart', 'javascript', 
    'typescript', 'rust', 'java', 'kotlin'
}

SUPPORTED_DATABASES = {
    'postgres', 'mysql', 'mongodb', 'redis', 
    'surrealdb', 'sqlite', 'cassandra', 'dynamodb'
}

SUPPORTED_FRAMEWORKS = {
    'go': {'chi', 'gin', 'echo', 'fiber', 'gorilla'},
    'python': {'fastapi', 'flask', 'django', 'tornado'},
    'dart': {'flutter'},
    'javascript': {'express', 'react', 'vue', 'nextjs', 'nestjs'},
    'typescript': {'nestjs', 'express', 'react', 'nextjs', 'angular'},
    'rust': {'actix', 'rocket', 'axum'},
    'java': {'spring', 'quarkus', 'micronaut'},
    'kotlin': {'ktor', 'spring'}
}

# File generation priorities
PRIORITY_CRITICAL = 1
PRIORITY_HIGH = 2
PRIORITY_MEDIUM = 3
PRIORITY_LOW = 4

# Job queue priorities
QUEUE_PRIORITY_ENTERPRISE = 0
QUEUE_PRIORITY_PRO = 1
QUEUE_PRIORITY_INDIE = 2
QUEUE_PRIORITY_FREE = 3
EOF

echo -e "  ${GREEN}✓${NC} constants.py created"

# ============================================================================
# Create src/core/schemas.py
# ============================================================================
echo -e "${GREEN}[2/4]${NC} Creating core/schemas.py..."

cat > src/core/schemas.py << 'EOF'
"""Project schema definitions"""
from dataclasses import dataclass, field, asdict
from typing import List, Dict, Any, Optional
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
    template_path: Optional[str] = None

@dataclass
class APIEndpoint:
    """API endpoint definition"""
    method: str
    path: str
    description: str
    request_body: Optional[Dict[str, Any]] = None
    response: Optional[Dict[str, Any]] = None
    auth_required: bool = True

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
    
    # Metadata
    version: str = "1.0.0"
    author: str = ""
    license: str = "MIT"
    
    @classmethod
    def from_yaml(cls, path: str) -> 'ProjectSchema':
        """Load schema from YAML file"""
        with open(path, 'r') as f:
            data = yaml.safe_load(f)
        return cls(**data)
    
    def to_yaml(self, path: str):
        """Save schema to YAML file"""
        with open(path, 'w') as f:
            yaml.dump(asdict(self), f, default_flow_style=False, sort_keys=False)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return asdict(self)
    
    def validate(self) -> List[str]:
        """Validate schema and return list of errors"""
        errors = []
        
        if not self.project_name:
            errors.append("project_name is required")
        
        if not self.languages:
            errors.append("At least one language is required")
        
        if not self.architecture_style:
            errors.append("architecture_style is required")
        
        return errors
EOF

echo -e "  ${GREEN}✓${NC} schemas.py created"

# ============================================================================
# Create src/core/config.py
# ============================================================================
echo -e "${GREEN}[3/4]${NC} Creating core/config.py..."

cat > src/core/config.py << 'EOF'
"""Cluster and agent configuration"""
from dataclasses import dataclass, asdict
from typing import Optional
import yaml
import os

@dataclass
class AgentConfig:
    """Configuration for a single Ollama agent"""
    role: str
    model: str
    base_url: str
    temperature: float = 0.7
    timeout: int = 300
    max_retries: int = 3
    context_window: int = 32768
    num_gpu: int = 0
    
    @classmethod
    def from_env(cls, role: str) -> 'AgentConfig':
        """Load agent config from environment variables"""
        prefix = f"OLLAMA_{role.upper()}"
        return cls(
            role=role,
            model=os.getenv(f"{prefix}_MODEL", "qwen2.5-coder:7b"),
            base_url=os.getenv(f"{prefix}_URL", "http://localhost:11434"),
            temperature=float(os.getenv(f"{prefix}_TEMPERATURE", "0.7")),
            timeout=int(os.getenv(f"{prefix}_TIMEOUT", "300")),
            max_retries=int(os.getenv(f"{prefix}_MAX_RETRIES", "3")),
        )

@dataclass
class ClusterConfig:
    """Configuration for the entire 3-agent cluster"""
    architect: AgentConfig
    coder: AgentConfig
    reviewer: AgentConfig
    
    # Directories
    output_dir: str = "./generated"
    checkpoint_dir: str = "./.checkpoint"
    template_dir: str = "./src/templates"
    
    # Processing
    logging_level: str = "INFO"
    save_intermediate: bool = True
    validate_syntax: bool = True
    format_code: bool = True
    
    # Queue settings
    max_concurrent_jobs: int = 3
    job_timeout_seconds: int = 3600
    
    # Redis settings
    redis_host: str = "localhost"
    redis_port: int = 6379
    redis_db: int = 0
    
    @classmethod
    def from_yaml(cls, path: str) -> 'ClusterConfig':
        """Load cluster config from YAML file"""
        with open(path, 'r') as f:
            data = yaml.safe_load(f)
        
        return cls(
            architect=AgentConfig(**data['architect']),
            coder=AgentConfig(**data['coder']),
            reviewer=AgentConfig(**data['reviewer']),
            output_dir=data.get('output_dir', './generated'),
            checkpoint_dir=data.get('checkpoint_dir', './.checkpoint'),
            template_dir=data.get('template_dir', './src/templates'),
            logging_level=data.get('logging_level', 'INFO'),
            save_intermediate=data.get('save_intermediate', True),
            validate_syntax=data.get('validate_syntax', True),
            format_code=data.get('format_code', True),
            max_concurrent_jobs=data.get('max_concurrent_jobs', 3),
            job_timeout_seconds=data.get('job_timeout_seconds', 3600),
            redis_host=data.get('redis_host', 'localhost'),
            redis_port=data.get('redis_port', 6379),
            redis_db=data.get('redis_db', 0),
        )
    
    @classmethod
    def from_env(cls) -> 'ClusterConfig':
        """Load cluster config from environment variables"""
        return cls(
            architect=AgentConfig.from_env("architect"),
            coder=AgentConfig.from_env("coder"),
            reviewer=AgentConfig.from_env("reviewer"),
            output_dir=os.getenv("OUTPUT_DIR", "./generated"),
            checkpoint_dir=os.getenv("CHECKPOINT_DIR", "./.checkpoint"),
            logging_level=os.getenv("LOG_LEVEL", "INFO"),
            max_concurrent_jobs=int(os.getenv("MAX_CONCURRENT_JOBS", "3")),
            redis_host=os.getenv("REDIS_HOST", "localhost"),
            redis_port=int(os.getenv("REDIS_PORT", "6379")),
            redis_db=int(os.getenv("REDIS_DB", "0")),
        )
    
    def to_yaml(self, path: str):
        """Save cluster config to YAML file"""
        data = {
            'architect': asdict(self.architect),
            'coder': asdict(self.coder),
            'reviewer': asdict(self.reviewer),
            'output_dir': self.output_dir,
            'checkpoint_dir': self.checkpoint_dir,
            'template_dir': self.template_dir,
            'logging_level': self.logging_level,
            'save_intermediate': self.save_intermediate,
            'validate_syntax': self.validate_syntax,
            'format_code': self.format_code,
            'max_concurrent_jobs': self.max_concurrent_jobs,
            'job_timeout_seconds': self.job_timeout_seconds,
            'redis_host': self.redis_host,
            'redis_port': self.redis_port,
            'redis_db': self.redis_db,
        }
        with open(path, 'w') as f:
            yaml.dump(data, f, default_flow_style=False)
EOF

echo -e "  ${GREEN}✓${NC} config.py created"

# ============================================================================
# Create src/core/state.py
# ============================================================================
echo -e "${GREEN}[4/4]${NC} Creating core/state.py..."

cat > src/core/state.py << 'EOF'
"""Generation state definition for LangGraph"""
from typing import TypedDict, Annotated, Sequence, Dict, Any, List
from langchain_core.messages import BaseMessage
import operator

from .schemas import ProjectSchema
from .config import ClusterConfig

class GenerationState(TypedDict):
    """State passed through the generation workflow"""
    
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
    
    # Quality Assurance
    review_results: Dict[str, Any]
    issues_found: List[Dict[str, Any]]
    syntax_errors: List[Dict[str, Any]]
    
    # Progress Tracking
    current_phase: str
    files_to_generate: List[str]
    files_generated: List[str]
    files_failed: List[str]
    
    # Resumption Support
    can_resume: bool
    checkpoint_path: str
    last_checkpoint: str
    
    # Communication
    messages: Annotated[Sequence[BaseMessage], operator.add]
    errors: List[Dict[str, Any]]
    warnings: List[Dict[str, Any]]
    
    # Timestamps
    started_at: str
    updated_at: str
    completed_at: str
    
    # Job metadata (for queue system)
    job_id: str
    user_id: str
    tier: str
    priority: int

def create_initial_state(
    project_schema: ProjectSchema,
    cluster_config: ClusterConfig,
    job_id: str = "",
    user_id: str = "",
    tier: str = "free"
) -> GenerationState:
    """Create initial state for generation"""
    from datetime import datetime
    
    return {
        "project_schema": project_schema,
        "cluster_config": cluster_config,
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
        "checkpoint_path": f"{cluster_config.checkpoint_dir}/{job_id}",
        "last_checkpoint": "",
        "messages": [],
        "errors": [],
        "warnings": [],
        "started_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
        "completed_at": "",
        "job_id": job_id,
        "user_id": user_id,
        "tier": tier,
        "priority": 3,
    }
EOF

echo -e "  ${GREEN}✓${NC} state.py created"

# ============================================================================
# Summary
# ============================================================================
echo
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ Phase 2 Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo -e "${YELLOW}Created Core Modules:${NC}"
echo "  ✓ core/constants.py    (Enums and constants)"
echo "  ✓ core/schemas.py      (ProjectSchema, FileTemplate)"
echo "  ✓ core/config.py       (ClusterConfig, AgentConfig)"
echo "  ✓ core/state.py        (GenerationState)"
echo
echo -e "${YELLOW}Next Steps:${NC}"
echo "  Run: ../setup-phase3-utilities.sh"
echo
echo -e "${GREEN}Ready for Phase 3! 🚀${NC}"
echo