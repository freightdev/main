"""
Path Management Module
All path definitions and resolution - EDIT THIS IF PATHS CHANGE
"""

from pathlib import Path
from typing import Dict, Optional


class Paths:
    """Centralized path management"""
    
    def __init__(self, config):
        self.config = config
        self._paths = self._initialize_paths()
    
    def _initialize_paths(self) -> Dict[str, Path]:
        """Initialize all path mappings"""
        return {
            # Framework directories
            "framework_root": self.config.FRAMEWORK_ROOT,
            "workspace_root": self.config.WORKSPACE_ROOT,
            "core_dir": self.config.FRAMEWORK_ROOT / "core",
            "src_dir": self.config.FRAMEWORK_ROOT / "src",
            "templates_dir": self.config.TEMPLATES_DIR,
            "logs_dir": self.config.LOGS_DIR,
            "docs_dir": self.config.DOCS_DIR,
            
            # Python/PyTorch directories
            "pytorch_source": self.config.PYTORCH_SOURCE,
            "pytorch_build": self.config.PYTORCH_SOURCE / "build",
            "venv_root": self.config.VENV_ROOT,
            
            # Python environments
            "venv_training": self.config.VENV_ROOT / "pytorch-training",
            "venv_tuning": self.config.VENV_ROOT / "pytorch-tuning",
            "venv_experiments": self.config.VENV_ROOT / "pytorch-experiments",
            "venv_runtime": self.config.VENV_ROOT / "pytorch-runtime",
            "venv_testing": self.config.VENV_ROOT / "pytorch-testing",
            
            # System paths
            "cuda_home": self.config.CUDA_HOME,
            "cuda_bin": self.config.CUDA_HOME / "bin",
            "cuda_lib": self.config.CUDA_HOME / "lib64",
            
            # Configuration files
            "frameworkrc": self.config.FRAMEWORK_ROOT / ".frameworkrc",
            "checkpoint_file": self.logs_dir / ".last_checkpoint",
            
            # Generated files
            "commands_md": self.config.DOCS_DIR / "COMMANDS.md",
            "activate_script": self.config.FRAMEWORK_ROOT / "activate.zsh",
            "environment_file": self.config.FRAMEWORK_ROOT / ".env",
        }
    
    def get(self, name: str) -> Optional[Path]:
        """Get path by name"""
        return self._paths.get(name.lower())
    
    def get_venv(self, name: str) -> Optional[Path]:
        """Get venv path by name"""
        key = f"venv_{name}"
        return self._paths.get(key)
    
    def ensure_exists(self, name: str, create: bool = True) -> Path:
        """Ensure path exists, optionally create it"""
        path = self.get(name)
        if path is None:
            raise ValueError(f"Path '{name}' not defined")
        
        if create:
            path.mkdir(parents=True, exist_ok=True)
        
        return path
    
    def ensure_all_exist(self):
        """Ensure all framework directories exist"""
        for name in [
            "framework_root", "core_dir", "src_dir",
            "templates_dir", "logs_dir", "docs_dir", "venv_root"
        ]:
            self.ensure_exists(name, create=True)
    
    def get_all(self) -> Dict[str, Path]:
        """Get all paths as dictionary"""
        return self._paths.copy()
    
    def __repr__(self) -> str:
        return f"<Paths: {self.config.FRAMEWORK_ROOT}>"