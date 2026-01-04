"""
Package Management Module
Centralized package definitions for all distros - EDIT THIS FOR PACKAGE CHANGES
"""

from typing import Dict, List, Set
from core.types import Package, PackageManager


class PackageRegistry:
    """Registry for all required and optional packages"""
    
    # === SYSTEM PACKAGES (distro-independent names) ===
    SYSTEM_PACKAGES = {
        # Build essentials
        "build-essential": Package(
            name="build-essential",
            description="C/C++ compiler, make, and related tools"
        ),
        "git": Package(
            name="git",
            description="Version control system"
        ),
        "cmake": Package(
            name="cmake",
            version="3.18+",
            description="Build system"
        ),
        "ninja-build": Package(
            name="ninja-build",
            description="Fast build system"
        ),
        
        # Python development
        "python3-dev": Package(
            name="python3-dev",
            description="Python development headers"
        ),
        "python3-pip": Package(
            name="python3-pip",
            description="Python package manager"
        ),
        "python3-venv": Package(
            name="python3-venv",
            description="Python virtual environment"
        ),
        
        # Math/Science libraries
        "libopenblas-dev": Package(
            name="libopenblas-dev",
            description="OpenBLAS linear algebra library"
        ),
        "libomp-dev": Package(
            name="libomp-dev",
            optional=True,
            description="OpenMP for parallel computing"
        ),
        "liblapack-dev": Package(
            name="liblapack-dev",
            description="LAPACK linear algebra library"
        ),
        
        # GPU/CUDA
        "cuda-toolkit": Package(
            name="cuda-toolkit",
            version="13.0",
            description="NVIDIA CUDA Toolkit"
        ),
        "libcudnn": Package(
            name="libcudnn",
            version="9-cuda-13",
            description="NVIDIA cuDNN deep learning library"
        ),
        
        # System utilities
        "wget": Package(
            name="wget",
            description="File downloader"
        ),
        "curl": Package(
            name="curl",
            description="Command line HTTP client"
        ),
        "htop": Package(
            name="htop",
            optional=True,
            description="System monitoring tool"
        ),
        "nvtop": Package(
            name="nvtop",
            optional=True,
            description="NVIDIA GPU monitoring"
        ),
        
        # Text editors (optional)
        "nano": Package(
            name="nano",
            optional=True,
            description="Text editor"
        ),
        "vim": Package(
            name="vim",
            optional=True,
            description="Advanced text editor"
        ),
        
        # Development
        "ccache": Package(
            name="ccache",
            description="Compiler cache for faster builds"
        ),
        "pkg-config": Package(
            name="pkg-config",
            description="Package configuration utility"
        ),
    }
    
    # === PYTHON PACKAGES (PIP) ===
    PYTHON_PACKAGES = {
        # Core ML frameworks
        "torch": Package(
            name="torch",
            version="2.5.1",
            description="PyTorch deep learning framework"
        ),
        "transformers": Package(
            name="transformers",
            version="4.40.0+",
            description="Hugging Face transformers library"
        ),
        "accelerate": Package(
            name="accelerate",
            version="0.27.0+",
            description="Distributed training acceleration"
        ),
        
        # Fine-tuning
        "peft": Package(
            name="peft",
            description="Parameter Efficient Fine-Tuning (LoRA/QLoRA)"
        ),
        "bitsandbytes": Package(
            name="bitsandbytes",
            description="8-bit optimizers and quantization"
        ),
        "trl": Package(
            name="trl",
            description="Transformer Reinforcement Learning"
        ),
        
        # Quantization
        "auto-gptq": Package(
            name="auto-gptq",
            description="GPTQ quantization tool"
        ),
        "autoawq": Package(
            name="autoawq",
            description="AWQ quantization tool"
        ),
        "gguf": Package(
            name="gguf",
            description="GGUF format utilities"
        ),
        "optimum": Package(
            name="optimum",
            description="Optimization for inference"
        ),
        
        # Data processing
        "datasets": Package(
            name="datasets",
            description="Hugging Face datasets library"
        ),
        "pandas": Package(
            name="pandas",
            description="Data manipulation library"
        ),
        "numpy": Package(
            name="numpy",
            description="Numerical computing"
        ),
        "scipy": Package(
            name="scipy",
            description="Scientific computing"
        ),
        
        # NLP utilities
        "tokenizers": Package(
            name="tokenizers",
            description="Fast tokenization library"
        ),
        "sentencepiece": Package(
            name="sentencepiece",
            description="Subword tokenizer"
        ),
        "protobuf": Package(
            name="protobuf",
            description="Protocol buffers"
        ),
        
        # Utilities
        "huggingface-hub": Package(
            name="huggingface-hub",
            description="Hugging Face hub API"
        ),
        "safetensors": Package(
            name="safetensors",
            description="Safe tensor serialization"
        ),
        "pyyaml": Package(
            name="pyyaml",
            description="YAML parser"
        ),
        
        # Monitoring & Logging
        "wandb": Package(
            name="wandb",
            optional=True,
            description="Weights & Biases experiment tracking"
        ),
        "tensorboard": Package(
            name="tensorboard",
            optional=True,
            description="TensorFlow monitoring tool"
        ),
        
        # Development
        "jupyter": Package(
            name="jupyter",
            description="Jupyter notebook"
        ),
        "jupyterlab": Package(
            name="jupyterlab",
            version="4.0.0+",
            description="JupyterLab IDE"
        ),
        "ipython": Package(
            name="ipython",
            description="Interactive Python shell"
        ),
        
        # Performance
        "xformers": Package(
            name="xformers",
            optional=True,
            description="Efficient attention implementations"
        ),
        "triton": Package(
            name="triton",
            optional=True,
            description="GPU programming language"
        ),
        "deepspeed": Package(
            name="deepspeed",
            optional=True,
            description="Distributed training framework"
        ),
        
        # Utilities
        "click": Package(
            name="click",
            description="CLI framework"
        ),
        "pydantic": Package(
            name="pydantic",
            description="Data validation"
        ),
        "jinja2": Package(
            name="jinja2",
            description="Template engine"
        ),
        "rich": Package(
            name="rich",
            description="Rich terminal output"
        ),
        "python-dotenv": Package(
            name="python-dotenv",
            description="Environment variable loader"
        ),
    }
    
    # === DISTRO-SPECIFIC MAPPINGS ===
    DISTRO_PACKAGE_MAPS = {
        PackageManager.APT: {  # Debian/Ubuntu
            "ninja-build": "ninja",
            "python3-dev": "python3-dev",
            "libcudnn": "libcudnn9-cuda-13",
        },
        PackageManager.DNF: {  # Fedora/RHEL/CentOS
            "python3-dev": "python3-devel",
            "libopenblas-dev": "openblas-devel",
            "ninja-build": "ninja-build",
            "libcudnn": "libcudnn-devel",
        },
        PackageManager.PACMAN: {  # Arch Linux
            "build-essential": "base-devel",
            "python3-dev": "python",
            "libopenblas-dev": "openblas",
            "ninja-build": "ninja",
        },
        PackageManager.APK: {  # Alpine Linux
            "build-essential": "build-base",
            "python3-dev": "python3-dev",
            "libopenblas-dev": "openblas-dev",
            "ninja-build": "ninja",
        },
    }
    
    @classmethod
    def get_system_packages(
        cls,
        package_manager: PackageManager,
        optional: bool = False
    ) -> List[Package]:
        """Get system packages for given package manager"""
        packages = []
        for pkg in cls.SYSTEM_PACKAGES.values():
            if pkg.optional == optional:
                packages.append(pkg)
        return packages
    
    @classmethod
    def get_python_packages(
        cls,
        optional: bool = False
    ) -> List[Package]:
        """Get Python packages"""
        packages = []
        for pkg in cls.PYTHON_PACKAGES.values():
            if pkg.optional == optional:
                packages.append(pkg)
        return packages
    
    @classmethod
    def get_mapped_name(
        cls,
        package_name: str,
        package_manager: PackageManager
    ) -> str:
        """Get distro-specific package name"""
        distro_map = cls.DISTRO_PACKAGE_MAPS.get(package_manager, {})
        return distro_map.get(package_name, package_name)
    
    @classmethod
    def get_all_required_names(
        cls,
        package_manager: PackageManager
    ) -> Set[str]:
        """Get all required package names for distro"""
        names = set()
        for pkg in cls.get_system_packages(optional=False):
            mapped = cls.get_mapped_name(pkg.name, package_manager)
            names.add(mapped)
        return names