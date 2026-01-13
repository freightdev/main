"""
Type Definitions and Enums
Ensures type safety and standardized file/component handling
"""

from enum import Enum
from dataclasses import dataclass
from typing import Optional, Dict, Any, List
from pathlib import Path


class SetupPhase(Enum):
    """Setup execution phases"""
    VALIDATION = "validation"
    SYSTEM_PREP = "system_prep"
    CUDA_SETUP = "cuda_setup"
    PYTORCH_BUILD = "pytorch_build"
    VENV_CREATION = "venv_creation"
    PACKAGE_INSTALL = "package_install"
    JUPYTER_SETUP = "jupyter_setup"
    TEMPLATE_GENERATION = "template_generation"
    DOCUMENTATION = "documentation"
    CLEANUP = "cleanup"
    COMPLETE = "complete"


class FileType(Enum):
    """File type definitions"""
    PYTHON = "py"
    SHELL = "sh"
    ZSHELL = "zsh"
    YAML = "yaml"
    MARKDOWN = "md"
    JSON = "json"
    LOG = "log"
    CONFIG = "conf"
    TEMPLATE = "template"
    TEXT = "txt"


class PackageManager(Enum):
    """Supported package managers"""
    APT = "apt"          # Debian/Ubuntu
    DNF = "dnf"          # Fedora/RHEL/CentOS
    PACMAN = "pacman"    # Arch Linux
    APK = "apk"          # Alpine Linux
    BREW = "brew"        # macOS (not supported, but listed)
    

class PythonEnvironment(Enum):
    """Python environment types"""
    TRAINING = "pytorch-training"
    TUNING = "pytorch-tuning"
    EXPERIMENTS = "pytorch-experiments"
    RUNTIME = "pytorch-runtime"
    TESTING = "pytorch-testing"


@dataclass
class FileSpec:
    """File specification for generation"""
    name: str
    file_type: FileType
    path: Path
    template: Optional[str] = None
    executable: bool = False
    content: Optional[str] = None
    description: Optional[str] = None
    
    def __post_init__(self):
        if self.path:
            self.path = Path(self.path)
    
    @property
    def full_path(self) -> Path:
        """Get full file path with extension"""
        ext = f".{self.file_type.value}"
        if str(self.path).endswith(ext):
            return self.path
        return Path(str(self.path) + ext)


@dataclass
class SystemRequirements:
    """System requirements specification"""
    min_ram_gb: int = 8
    min_disk_gb: int = 50
    min_gpu_vram_gb: int = 4
    required_cuda: str = "12.4"
    required_python: str = "3.8"
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "min_ram_gb": self.min_ram_gb,
            "min_disk_gb": self.min_disk_gb,
            "min_gpu_vram_gb": self.min_gpu_vram_gb,
            "required_cuda": self.required_cuda,
            "required_python": self.required_python,
        }


@dataclass
class Package:
    """Package specification"""
    name: str
    version: Optional[str] = None
    manager: Optional[PackageManager] = None
    optional: bool = False
    description: Optional[str] = None
    
    def __repr__(self) -> str:
        ver = f"=={self.version}" if self.version else ""
        return f"{self.name}{ver}"


@dataclass
class SetupCheckpoint:
    """Setup checkpoint for resuming"""
    phase: SetupPhase
    timestamp: str
    status: str  # "completed", "failed", "partial"
    details: Dict[str, Any]
    
    def is_recoverable(self) -> bool:
        """Check if setup can be resumed from this point"""
        return self.status in ["completed", "partial"]


@dataclass
class SetupResult:
    """Setup execution result"""
    success: bool
    phase: SetupPhase
    message: str
    details: Dict[str, Any]
    elapsed_seconds: float
    errors: List[str]
    warnings: List[str]
    
    def __repr__(self) -> str:
        status = "✅ SUCCESS" if self.success else "❌ FAILED"
        return f"{status} ({self.phase.value}): {self.message}"


class ValidationError(Exception):
    """Custom validation error"""
    pass


class SetupError(Exception):
    """Custom setup error"""
    pass


class PackageNotFoundError(Exception):
    """Package not found error"""
    pass