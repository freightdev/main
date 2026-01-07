#!/bin/bash
# ============================================================================
# PHASE 3: Utilities
# Creates logger, JSON parser, file utils, and progress indicators
# ============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  PHASE 3: Utilities${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# ============================================================================
# Create src/utils/logger.py
# ============================================================================
echo -e "${GREEN}[1/4]${NC} Creating utils/logger.py..."

cat > src/utils/logger.py << 'EOF'
"""Logging configuration"""
import logging
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional

def setup_logging(
    level: str = "INFO",
    log_file: Optional[str] = None,
    log_to_console: bool = True
) -> logging.Logger:
    """Setup logging with console and file handlers"""
    
    logger = logging.getLogger("ProjectGenerator")
    logger.setLevel(getattr(logging, level.upper()))
    logger.handlers.clear()
    
    # Create formatter
    formatter = logging.Formatter(
        '%(asctime)s [%(levelname)s] %(message)s',
        datefmt='%H:%M:%S'
    )
    
    detailed_formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(funcName)s:%(lineno)d - %(message)s'
    )
    
    # Console handler
    if log_to_console:
        console = logging.StreamHandler(sys.stdout)
        console.setLevel(getattr(logging, level.upper()))
        console.setFormatter(formatter)
        logger.addHandler(console)
    
    # File handler
    if log_file is None:
        log_file = f"generation_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
    
    file_handler = logging.FileHandler(log_file)
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(detailed_formatter)
    logger.addHandler(file_handler)
    
    return logger

def get_logger(name: str) -> logging.Logger:
    """Get a logger instance"""
    return logging.getLogger(f"ProjectGenerator.{name}")
EOF

echo -e "  ${GREEN}✓${NC} logger.py created"

# ============================================================================
# Create src/utils/json_parser.py
# ============================================================================
echo -e "${GREEN}[2/4]${NC} Creating utils/json_parser.py..."

cat > src/utils/json_parser.py << 'EOF'
"""Robust JSON parsing from LLM responses"""
import json
import re
from typing import Optional, Dict, Any

def parse_json_robust(response: str) -> Optional[Dict[str, Any]]:
    """
    Parse JSON from LLM response with multiple fallback strategies
    
    Args:
        response: Raw LLM response that may contain JSON
        
    Returns:
        Parsed JSON dict or None if parsing fails
    """
    
    if not response:
        return None
    
    # Strategy 1: Remove markdown code blocks
    if "```" in response:
        patterns = [
            r'```json\s*(.*?)\s*```',  # ```json ... ```
            r'```\s*(.*?)\s*```',       # ``` ... ```
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
    except json.JSONDecodeError:
        pass
    
    # Strategy 3: Find JSON array boundaries
    try:
        start = response.find('[')
        end = response.rfind(']') + 1
        if start != -1 and end > start:
            json_str = response[start:end]
            return json.loads(json_str)
    except json.JSONDecodeError:
        pass
    
    # Strategy 4: Try parsing entire response
    try:
        return json.loads(response.strip())
    except json.JSONDecodeError:
        pass
    
    return None

def extract_code_block(response: str, language: str = "") -> Optional[str]:
    """
    Extract code from markdown code block
    
    Args:
        response: LLM response containing code block
        language: Optional language identifier
        
    Returns:
        Extracted code or None
    """
    
    if language:
        pattern = rf'```{language}\s*(.*?)\s*```'
    else:
        pattern = r'```\w*\s*(.*?)\s*```'
    
    match = re.search(pattern, response, re.DOTALL)
    if match:
        return match.group(1).strip()
    
    return None
EOF

echo -e "  ${GREEN}✓${NC} json_parser.py created"

# ============================================================================
# Create src/utils/file_utils.py
# ============================================================================
echo -e "${GREEN}[3/4]${NC} Creating utils/file_utils.py..."

cat > src/utils/file_utils.py << 'EOF'
"""File and directory utilities"""
import os
import shutil
from pathlib import Path
from typing import List, Optional
import hashlib

def ensure_directory(path: str) -> Path:
    """Ensure directory exists, create if needed"""
    dir_path = Path(path)
    dir_path.mkdir(parents=True, exist_ok=True)
    return dir_path

def safe_write_file(path: str, content: str, backup: bool = False):
    """
    Safely write file with optional backup
    
    Args:
        path: File path to write
        content: Content to write
        backup: Create backup if file exists
    """
    file_path = Path(path)
    
    # Create parent directories
    file_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Backup existing file
    if backup and file_path.exists():
        backup_path = file_path.with_suffix(file_path.suffix + '.bak')
        shutil.copy2(file_path, backup_path)
    
    # Write file
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def read_file_safe(path: str) -> Optional[str]:
    """
    Safely read file, return None if not exists
    
    Args:
        path: File path to read
        
    Returns:
        File content or None
    """
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        return None
    except Exception as e:
        raise Exception(f"Error reading file {path}: {e}")

def get_file_hash(path: str) -> str:
    """Calculate MD5 hash of file"""
    hasher = hashlib.md5()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hasher.update(chunk)
    return hasher.hexdigest()

def list_files_recursive(
    directory: str,
    extensions: Optional[List[str]] = None
) -> List[Path]:
    """
    List all files in directory recursively
    
    Args:
        directory: Directory to search
        extensions: Filter by extensions (e.g., ['.py', '.go'])
        
    Returns:
        List of file paths
    """
    dir_path = Path(directory)
    
    if not dir_path.exists():
        return []
    
    files = []
    for item in dir_path.rglob('*'):
        if item.is_file():
            if extensions is None or item.suffix in extensions:
                files.append(item)
    
    return files

def clean_directory(path: str, keep_hidden: bool = True):
    """
    Remove all files in directory
    
    Args:
        path: Directory to clean
        keep_hidden: Keep hidden files/folders
    """
    dir_path = Path(path)
    
    if not dir_path.exists():
        return
    
    for item in dir_path.iterdir():
        if keep_hidden and item.name.startswith('.'):
            continue
        
        if item.is_file():
            item.unlink()
        elif item.is_dir():
            shutil.rmtree(item)

def get_directory_size(path: str) -> int:
    """Get total size of directory in bytes"""
    total = 0
    for item in Path(path).rglob('*'):
        if item.is_file():
            total += item.stat().st_size
    return total

def format_bytes(size: int) -> str:
    """Format bytes to human-readable string"""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size < 1024.0:
            return f"{size:.2f} {unit}"
        size /= 1024.0
    return f"{size:.2f} PB"
EOF

echo -e "  ${GREEN}✓${NC} file_utils.py created"

# ============================================================================
# Create src/utils/progress.py
# ============================================================================
echo -e "${GREEN}[4/4]${NC} Creating utils/progress.py..."

cat > src/utils/progress.py << 'EOF'
"""Progress indicators and status tracking"""
try:
    from tqdm import tqdm
    HAS_TQDM = True
except ImportError:
    HAS_TQDM = False

from typing import Iterable, Optional, Any
import sys

class ProgressBar:
    """Wrapper for progress bar with fallback"""
    
    def __init__(
        self,
        iterable: Optional[Iterable] = None,
        total: Optional[int] = None,
        desc: str = "",
        disable: bool = False
    ):
        self.desc = desc
        self.total = total
        self.current = 0
        self.disable = disable
        
        if HAS_TQDM and not disable:
            self.bar = tqdm(
                iterable=iterable,
                total=total,
                desc=desc,
                ncols=80,
                bar_format='{l_bar}{bar}| {n_fmt}/{total_fmt} [{elapsed}<{remaining}]'
            )
        else:
            self.bar = None
            self.iterable = iterable
    
    def update(self, n: int = 1):
        """Update progress"""
        self.current += n
        
        if self.bar:
            self.bar.update(n)
        elif not self.disable:
            # Fallback: print simple progress
            if self.total:
                pct = (self.current / self.total) * 100
                print(f"\r{self.desc}: {self.current}/{self.total} ({pct:.1f}%)", end='')
                sys.stdout.flush()
    
    def set_description(self, desc: str):
        """Update description"""
        self.desc = desc
        if self.bar:
            self.bar.set_description(desc)
    
    def close(self):
        """Close progress bar"""
        if self.bar:
            self.bar.close()
        elif not self.disable and self.total:
            print()  # New line after progress
    
    def __enter__(self):
        return self
    
    def __exit__(self, *args):
        self.close()
    
    def __iter__(self):
        if self.bar:
            return iter(self.bar)
        return iter(self.iterable)

def create_progress_bar(
    total: int,
    desc: str = "Processing",
    disable: bool = False
) -> ProgressBar:
    """Create a progress bar"""
    return ProgressBar(total=total, desc=desc, disable=disable)

class SpinnerContext:
    """Simple spinner for long-running tasks"""
    
    def __init__(self, message: str = "Processing"):
        self.message = message
        self.spinner_chars = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
        self.idx = 0
        self.running = False
    
    def __enter__(self):
        self.running = True
        return self
    
    def __exit__(self, *args):
        self.running = False
        print("\r" + " " * (len(self.message) + 5) + "\r", end='')
        sys.stdout.flush()
    
    def spin(self):
        """Show next spinner frame"""
        if not self.running:
            return
        
        char = self.spinner_chars[self.idx % len(self.spinner_chars)]
        print(f"\r{char} {self.message}...", end='')
        sys.stdout.flush()
        self.idx += 1

def print_status(message: str, status: str = "info"):
    """
    Print colored status message
    
    Args:
        message: Message to print
        status: One of: info, success, warning, error
    """
    colors = {
        'info': '\033[0;34m',     # Blue
        'success': '\033[0;32m',  # Green
        'warning': '\033[1;33m',  # Yellow
        'error': '\033[0;31m',    # Red
    }
    
    symbols = {
        'info': 'ℹ',
        'success': '✓',
        'warning': '⚠',
        'error': '✗',
    }
    
    color = colors.get(status, '')
    symbol = symbols.get(status, '')
    reset = '\033[0m'
    
    print(f"{color}{symbol} {message}{reset}")
EOF

echo -e "  ${GREEN}✓${NC} progress.py created"

# ============================================================================
# Summary
# ============================================================================
echo
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ Phase 3 Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo -e "${YELLOW}Created Utilities:${NC}"
echo "  ✓ utils/logger.py        (Logging setup)"
echo "  ✓ utils/json_parser.py   (Robust JSON parsing)"
echo "  ✓ utils/file_utils.py    (File operations)"
echo "  ✓ utils/progress.py      (Progress indicators)"
echo
echo -e "${YELLOW}Next Steps:${NC}"
echo "  Run: ../setup-phase4-clients.sh"
echo
echo -e "${GREEN}Ready for Phase 4! 🚀${NC}"
echo