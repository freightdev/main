#!/usr/bin/env python3
"""
Advanced Flutter Import Fixer - Intelligently fixes all imports in a Flutter project
Analyzes code usage, removes unused imports, adds missing imports, and fixes paths
"""

import os
import re
from pathlib import Path
from typing import Dict, Set, List, Tuple, Optional
import argparse
from collections import defaultdict


class DartAnalyzer:
    """Analyzes Dart code to extract classes, methods, and usage"""
    
    def __init__(self, content: str):
        self.content = content
        # Remove comments and strings to avoid false positives
        self.clean_content = self._remove_comments_and_strings(content)
    
    def _remove_comments_and_strings(self, content: str) -> str:
        """Remove comments and string literals to avoid false matches"""
        # Remove single-line comments
        content = re.sub(r'//.*?$', '', content, flags=re.MULTILINE)
        # Remove multi-line comments
        content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
        # Remove string literals
        content = re.sub(r'"(?:[^"\\]|\\.)*"', '""', content)
        content = re.sub(r"'(?:[^'\\]|\\.)*'", "''", content)
        return content
    
    def get_defined_symbols(self) -> Set[str]:
        """Extract all symbols defined in this file"""
        symbols = set()
        
        patterns = [
            r'class\s+(\w+)',
            r'abstract\s+class\s+(\w+)',
            r'mixin\s+(\w+)',
            r'enum\s+(\w+)',
            r'extension\s+(\w+)',
            r'typedef\s+(\w+)',
            r'const\s+(\w+)\s*=',
            r'final\s+(\w+)\s*=',
            r'var\s+(\w+)\s*=',
        ]
        
        for pattern in patterns:
            matches = re.finditer(pattern, self.content)
            symbols.update(match.group(1) for match in matches)
        
        return symbols
    
    def get_used_symbols(self) -> Set[str]:
        """Extract all symbols used in this file"""
        symbols = set()
        
        # Find all identifiers that look like class names (PascalCase)
        # This includes constructors, static calls, type annotations, etc.
        pascal_case = re.finditer(r'\b([A-Z][a-zA-Z0-9_]*)\b', self.clean_content)
        symbols.update(match.group(1) for match in pascal_case)
        
        return symbols


class FlutterImportFixer:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root).resolve()
        self.lib_dir = self.project_root / "lib"
        self.package_name = self._get_package_name()
        
        # Maps: filename -> full path
        self.file_map: Dict[str, List[Path]] = defaultdict(list)
        
        # Maps: symbol (class/enum/etc) -> file path(s) where it's defined
        self.symbol_to_file: Dict[str, List[Path]] = defaultdict(list)
        
        # Maps: file path -> symbols defined in that file
        self.file_to_symbols: Dict[Path, Set[str]] = {}
        
        # Track external packages from pubspec
        self.external_packages: Set[str] = set()
        
    def _get_package_name(self) -> str:
        """Extract package name from pubspec.yaml"""
        pubspec_path = self.project_root / "pubspec.yaml"
        if not pubspec_path.exists():
            raise FileNotFoundError("pubspec.yaml not found. Are you in a Flutter project?")
        
        with open(pubspec_path, 'r', encoding='utf-8') as f:
            content = f.read()
            match = re.search(r'^name:\s*(\S+)', content, re.MULTILINE)
            if match:
                return match.group(1)
        
        raise ValueError("Could not find package name in pubspec.yaml")
    
    def _get_external_packages(self):
        """Extract external package names from pubspec.yaml"""
        pubspec_path = self.project_root / "pubspec.yaml"
        
        with open(pubspec_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Find dependencies section
        in_dependencies = False
        for line in content.split('\n'):
            if re.match(r'^dependencies:', line):
                in_dependencies = True
                continue
            if in_dependencies:
                # Stop at next top-level section
                if line and not line.startswith(' ') and not line.startswith('\t'):
                    break
                # Extract package name
                match = re.match(r'\s+(\w+):', line)
                if match:
                    pkg = match.group(1)
                    # Skip flutter itself
                    if pkg != 'flutter':
                        self.external_packages.add(pkg)
    
    def scan_project(self):
        """Scan lib/ directory and build comprehensive mappings"""
        print(f"Scanning {self.lib_dir}...")
        
        dart_files = list(self.lib_dir.rglob("*.dart"))
        
        for dart_file in dart_files:
            if dart_file.is_file():
                # Map filename to path(s)
                self.file_map[dart_file.name].append(dart_file)
                
                # Extract symbols defined in this file
                try:
                    with open(dart_file, 'r', encoding='utf-8', errors='replace') as f:
                        content = f.read()
                    
                    analyzer = DartAnalyzer(content)
                    symbols = analyzer.get_defined_symbols()
                    
                    self.file_to_symbols[dart_file] = symbols
                    
                    # Map each symbol to this file
                    for symbol in symbols:
                        self.symbol_to_file[symbol].append(dart_file)
                        
                except Exception as e:
                    print(f"  Warning: Could not analyze {dart_file}: {e}")
        
        self._get_external_packages()
        
        print(f"Found {len(dart_files)} Dart files")
        print(f"Identified {len(self.symbol_to_file)} unique symbols")
        print(f"Found {len(self.external_packages)} external packages")
    
    def _get_package_import(self, file_path: Path) -> str:
        """Convert file path to package import statement"""
        rel_path = file_path.relative_to(self.lib_dir)
        import_path = str(rel_path).replace('\\', '/')
        return f"package:{self.package_name}/{import_path}"
    
    def _resolve_import_path(self, import_path: str, current_file: Path) -> Optional[str]:
        """Resolve an import path to the correct package import"""
        
        # Already correct package import
        if import_path.startswith(f'package:{self.package_name}/'):
            return import_path
        
        # Flutter/Dart SDK imports - keep as is
        if import_path.startswith('dart:'):
            return import_path
        
        # External package imports - keep as is
        if import_path.startswith('package:'):
            pkg_name = import_path.split('/')[0].replace('package:', '')
            if pkg_name in self.external_packages or pkg_name == 'flutter':
                return import_path
            # Malformed package import - try to fix
            import_path = import_path.replace(':', '/', 1)
        
        # Handle relative imports
        if import_path.startswith('../') or import_path.startswith('./'):
            try:
                resolved = (current_file.parent / import_path).resolve()
                if resolved.exists() and self.lib_dir in resolved.parents:
                    return self._get_package_import(resolved)
            except:
                pass
        
        # Try to find by filename
        filename = import_path.split('/')[-1]
        if not filename.endswith('.dart'):
            filename += '.dart'
        
        if filename in self.file_map:
            files = self.file_map[filename]
            if len(files) == 1:
                return self._get_package_import(files[0])
            # Multiple files with same name - try to find best match
            for f in files:
                if import_path in str(f):
                    return self._get_package_import(f)
            # Just use the first one
            return self._get_package_import(files[0])
        
        return None
    
    def _find_import_for_symbol(self, symbol: str, current_file: Path) -> Optional[str]:
        """Find the correct import for a symbol used in the code"""
        
        # Don't import symbols defined in current file
        if symbol in self.file_to_symbols.get(current_file, set()):
            return None
        
        # Find files that define this symbol
        if symbol in self.symbol_to_file:
            files = self.symbol_to_file[symbol]
            if len(files) == 1:
                return self._get_package_import(files[0])
            # Multiple definitions - prefer files in same directory
            current_dir = current_file.parent
            for f in files:
                if f.parent == current_dir:
                    return self._get_package_import(f)
            # Just use first one
            return self._get_package_import(files[0])
        
        return None
    
    def fix_file_imports(self, file_path: Path) -> Tuple[int, int, int]:
        """
        Analyze and fix imports in a file
        Returns: (fixed_count, removed_count, added_count)
        """
        try:
            with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
                content = f.read()
        except Exception as e:
            print(f"  Error reading {file_path}: {e}")
            return 0, 0, 0
        
        lines = content.split('\n')
        
        # Extract existing imports
        existing_imports = []
        import_line_indices = []
        last_import_index = -1
        
        for i, line in enumerate(lines):
            import_match = re.match(r"^\s*import\s+['\"](.+?)['\"];?\s*$", line)
            if import_match:
                existing_imports.append(import_match.group(1))
                import_line_indices.append(i)
                last_import_index = i
        
        # Analyze what symbols are used in this file
        analyzer = DartAnalyzer(content)
        used_symbols = analyzer.get_used_symbols()
        defined_symbols = self.file_to_symbols.get(file_path, set())
        
        # Remove symbols that are defined locally
        used_symbols -= defined_symbols
        
        # Build set of needed imports
        needed_imports = set()
        
        # First, try to fix existing imports
        for import_path in existing_imports:
            resolved = self._resolve_import_path(import_path, file_path)
            if resolved:
                needed_imports.add(resolved)
        
        # Find imports for used symbols that aren't imported
        for symbol in used_symbols:
            import_for_symbol = self._find_import_for_symbol(symbol, file_path)
            if import_for_symbol:
                needed_imports.add(import_for_symbol)
        
        # Categorize and sort imports
        dart_imports = sorted([i for i in needed_imports if i.startswith('dart:')])
        flutter_imports = sorted([i for i in needed_imports if i.startswith('package:flutter/')])
        external_imports = sorted([i for i in needed_imports if i.startswith('package:') 
                                   and not i.startswith(f'package:{self.package_name}/')
                                   and not i.startswith('package:flutter/')])
        local_imports = sorted([i for i in needed_imports if i.startswith(f'package:{self.package_name}/')])
        
        # Build new import lines
        new_import_lines = []
        
        if dart_imports:
            new_import_lines.extend([f"import '{imp}';" for imp in dart_imports])
            new_import_lines.append('')
        
        if flutter_imports:
            new_import_lines.extend([f"import '{imp}';" for imp in flutter_imports])
            new_import_lines.append('')
        
        if external_imports:
            new_import_lines.extend([f"import '{imp}';" for imp in external_imports])
            new_import_lines.append('')
        
        if local_imports:
            new_import_lines.extend([f"import '{imp}';" for imp in local_imports])
            new_import_lines.append('')
        
        # Remove trailing empty line if present
        if new_import_lines and new_import_lines[-1] == '':
            new_import_lines.pop()
        
        # Reconstruct file
        new_lines = []
        
        # Find where to insert imports (after any leading comments/license)
        insert_index = 0
        for i, line in enumerate(lines):
            if line.strip() and not line.strip().startswith('//') and not line.strip().startswith('/*'):
                insert_index = i
                break
        
        # If file starts with import, use index 0
        if import_line_indices and import_line_indices[0] < insert_index:
            insert_index = 0
        
        # Add lines before imports
        new_lines.extend(lines[:insert_index])
        
        # Add new imports
        if new_import_lines:
            new_lines.extend(new_import_lines)
            if insert_index < len(lines):
                new_lines.append('')
        
        # Add lines after imports, skipping old import lines
        skip_until = last_import_index + 1 if last_import_index >= 0 else insert_index
        
        # Skip empty lines after last import
        while skip_until < len(lines) and not lines[skip_until].strip():
            skip_until += 1
        
        new_lines.extend(lines[skip_until:])
        
        # Calculate changes
        old_import_count = len(existing_imports)
        new_import_count = len(needed_imports)
        
        fixed_count = 0
        added_count = max(0, new_import_count - old_import_count)
        removed_count = max(0, old_import_count - new_import_count)
        
        # Count actual fixes (changed paths)
        old_imports_set = set(existing_imports)
        if old_imports_set != needed_imports:
            fixed_count = len(old_imports_set.symmetric_difference(needed_imports))
        
        # Write back if changed
        new_content = '\n'.join(new_lines)
        if new_content != content:
            try:
                with open(file_path, 'w', encoding='utf-8', errors='replace') as f:
                    f.write(new_content)
            except Exception as e:
                print(f"  Error writing {file_path}: {e}")
                return 0, 0, 0
        
        return fixed_count, removed_count, added_count
    
    def fix_all_imports(self, iterations: int = 3):
        """
        Fix imports in all files, running multiple iterations
        to resolve transitive dependencies
        """
        print(f"\nFixing imports (will run up to {iterations} iterations)...")
        
        dart_files = list(self.lib_dir.rglob("*.dart"))
        
        for iteration in range(iterations):
            print(f"\n--- Iteration {iteration + 1} ---")
            
            total_fixed = 0
            total_removed = 0
            total_added = 0
            files_modified = 0
            
            for dart_file in dart_files:
                if dart_file.is_file():
                    fixed, removed, added = self.fix_file_imports(dart_file)
                    
                    if fixed > 0 or removed > 0 or added > 0:
                        rel_path = dart_file.relative_to(self.project_root)
                        changes = []
                        if fixed > 0:
                            changes.append(f"{fixed} fixed")
                        if removed > 0:
                            changes.append(f"{removed} removed")
                        if added > 0:
                            changes.append(f"{added} added")
                        
                        print(f"  {rel_path}: {', '.join(changes)}")
                        files_modified += 1
                        total_fixed += fixed
                        total_removed += removed
                        total_added += added
            
            print(f"\nIteration {iteration + 1} summary:")
            print(f"  Files modified: {files_modified}")
            print(f"  Imports fixed: {total_fixed}")
            print(f"  Imports removed: {total_removed}")
            print(f"  Imports added: {total_added}")
            
            # If nothing changed, we're done
            if files_modified == 0:
                print(f"\n✓ Converged after {iteration + 1} iteration(s)")
                break
        
        print(f"\n{'='*60}")
        print(f"Final Summary:")
        print(f"  Package name: {self.package_name}")
        print(f"  Total files: {len(dart_files)}")
        print(f"{'='*60}")


def main():
    parser = argparse.ArgumentParser(
        description='Intelligently fix all imports in a Flutter project',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
This script:
- Analyzes code to find what symbols are actually used
- Removes unused/broken imports
- Adds missing imports
- Fixes import paths (relative -> package:)
- Runs multiple iterations to resolve dependencies

Examples:
  python flutter_import_fixer.py
  python flutter_import_fixer.py /path/to/flutter/project
  python flutter_import_fixer.py --iterations 5
        """
    )
    parser.add_argument(
        'project_root',
        nargs='?',
        default='.',
        help='Path to Flutter project root (default: current directory)'
    )
    parser.add_argument(
        '--iterations',
        type=int,
        default=3,
        help='Number of iterations to run (default: 3)'
    )
    
    args = parser.parse_args()
    
    try:
        fixer = FlutterImportFixer(args.project_root)
        fixer.scan_project()
        fixer.fix_all_imports(iterations=args.iterations)
        
        print("\n✓ Import fixing complete!")
        print("\nNext steps:")
        print("  1. Run: flutter pub get")
        print("  2. Run: flutter analyze")
        print("  3. Fix any remaining manual issues")
        print("  4. Run this script again if needed")
        
    except FileNotFoundError as e:
        print(f"Error: {e}")
        return 1
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0


if __name__ == "__main__":
    exit(main())
