#!/usr/bin/env python3
"""
Ultimate Flutter Project Auto-Fixer
Fixes imports, creates barrel files, and keeps everything in sync automatically.
Run this anytime you move files around or add new ones.
"""

import os
import re
import time
from pathlib import Path
from typing import Dict, List, Set, Optional
from dataclasses import dataclass
from collections import defaultdict

@dataclass
class DartFile:
    path: Path
    relative_path: str
    import_path: str
    name: str
    is_generated: bool

class UltimateFlutterFixer:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root).resolve()
        self.lib_path = self.project_root / "lib"
        self.package_name = self._get_package_name()
        
        # File tracking
        self.all_files: Dict[str, DartFile] = {}
        self.directory_files: Dict[str, List[DartFile]] = defaultdict(list)
        
        print("🚀 Ultimate Flutter Auto-Fixer")
        print("=" * 70)
        print(f"📁 Project: {self.project_root}")
        print(f"📦 Package: {self.package_name}")
        print("=" * 70)
    
    def _get_package_name(self) -> str:
        """Get package name from pubspec.yaml"""
        pubspec = self.project_root / "pubspec.yaml"
        if pubspec.exists():
            with open(pubspec, 'r') as f:
                for line in f:
                    if line.startswith('name:'):
                        return line.split(':')[1].strip()
        return "fed_tms"
    
    def scan_all_files(self):
        """Scan and catalog all Dart files"""
        print("\n🔍 Step 1: Scanning all Dart files...")
        
        for dart_file in self.lib_path.rglob('*.dart'):
            # Skip certain files
            if 'test' in str(dart_file) or '.dart_tool' in str(dart_file):
                continue
            
            rel_path = dart_file.relative_to(self.lib_path)
            rel_str = str(rel_path).replace('\\', '/')
            
            # Determine import path
            import_path = f"package:{self.package_name}/{rel_str}"
            
            # Check if generated file
            is_generated = (
                dart_file.name.endswith('.g.dart') or
                dart_file.name.endswith('.freezed.dart') or
                dart_file.name == 'index.dart'
            )
            
            file_info = DartFile(
                path=dart_file,
                relative_path=rel_str,
                import_path=import_path,
                name=dart_file.stem,
                is_generated=is_generated
            )
            
            # Store by name and full path
            self.all_files[dart_file.stem] = file_info
            self.all_files[rel_str.replace('.dart', '')] = file_info
            
            # Track by directory
            dir_key = str(dart_file.parent.relative_to(self.lib_path)).replace('\\', '/')
            self.directory_files[dir_key].append(file_info)
        
        print(f"   ✅ Found {len(self.all_files)} Dart files")
        print(f"   ✅ Scanned {len(self.directory_files)} directories")
    
    def create_all_barrel_files(self):
        """Create index.dart barrel files at every level"""
        print("\n📦 Step 2: Creating hierarchical barrel files...")
        
        created = 0
        updated = 0
        
        # Get all directories sorted by depth (deepest first)
        all_dirs = sorted(
            [d for d in self.lib_path.rglob('*') if d.is_dir()],
            key=lambda x: len(x.parts),
            reverse=True
        )
        
        for directory in all_dirs:
            # Skip certain directories
            if any(skip in str(directory) for skip in ['.dart_tool', 'test', '__pycache__']):
                continue
            
            result = self._create_barrel_for_directory(directory)
            if result == 'created':
                created += 1
            elif result == 'updated':
                updated += 1
        
        print(f"   ✅ Created {created} new barrel files")
        print(f"   ✅ Updated {updated} existing barrel files")
    
    def _create_barrel_for_directory(self, directory: Path) -> Optional[str]:
        """Create or update a barrel file for a directory"""
        
        # Find all non-generated dart files in this directory (not subdirs)
        dart_files = [
            f for f in directory.glob('*.dart')
            if f.name != 'index.dart' 
            and not f.name.endswith('.g.dart')
            and not f.name.endswith('.freezed.dart')
        ]
        
        # Find all subdirectories with index.dart
        subdirs_with_index = [
            d for d in directory.iterdir()
            if d.is_dir() and (d / 'index.dart').exists()
        ]
        
        # Nothing to export
        if not dart_files and not subdirs_with_index:
            return None
        
        # Build barrel content
        exports = []
        
        # Export files in this directory
        for dart_file in sorted(dart_files, key=lambda x: x.name):
            exports.append(f"export '{dart_file.name}';")
        
        # Export subdirectory barrels
        for subdir in sorted(subdirs_with_index, key=lambda x: x.name):
            exports.append(f"export '{subdir.name}/index.dart';")
        
        if not exports:
            return None
        
        # Create barrel content
        rel_path = directory.relative_to(self.lib_path)
        barrel_content = f"""// Auto-generated barrel file for {rel_path}
// Generated by Ultimate Flutter Auto-Fixer
// Do not manually edit - changes will be overwritten

"""
        barrel_content += '\n'.join(exports) + '\n'
        
        # Write barrel file
        index_path = directory / 'index.dart'
        
        # Check if it exists and has same content
        if index_path.exists():
            with open(index_path, 'r', encoding='utf-8') as f:
                existing = f.read()
            if existing == barrel_content:
                return None
        
        with open(index_path, 'w', encoding='utf-8') as f:
            f.write(barrel_content)
        
        status = 'updated' if index_path.exists() else 'created'
        print(f"   ✓ {status.title()}: {rel_path}/index.dart")
        return status
    
    def fix_all_imports(self):
        """Fix all imports in all Dart files"""
        print("\n🔧 Step 3: Fixing all imports...")
        
        dart_files = [
            f for f in self.lib_path.rglob('*.dart')
            if not f.name.endswith('.g.dart')
            and not f.name.endswith('.freezed.dart')
            and 'test' not in str(f)
        ]
        
        total = len(dart_files)
        fixed = 0
        errors = 0
        
        for i, dart_file in enumerate(dart_files, 1):
            try:
                if self._fix_file_imports(dart_file):
                    fixed += 1
                
                if i % 20 == 0 or i == total:
                    print(f"   Progress: {i}/{total} ({fixed} fixed, {errors} errors)")
            
            except Exception as e:
                errors += 1
                print(f"   ⚠️  Error in {dart_file.name}: {str(e)[:50]}")
        
        print(f"   ✅ Fixed {fixed} files")
        if errors > 0:
            print(f"   ⚠️  {errors} files had errors (check manually)")
    
    def _fix_file_imports(self, file_path: Path) -> bool:
        """Fix imports in a single file"""
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        new_lines = []
        changed = False
        
        for line in lines:
            new_line = line
            
            # Match import statements
            import_match = re.match(r"^(\s*)import\s+(['\"])(.+?)\2", line)
            if import_match:
                indent = import_match.group(1)
                quote = import_match.group(2)
                old_import = import_match.group(3)
                
                new_import = self._convert_import_path(old_import, file_path)
                
                if new_import != old_import:
                    new_line = f"{indent}import {quote}{new_import}{quote};\n"
                    changed = True
            
            # Match export statements
            export_match = re.match(r"^(\s*)export\s+(['\"])(.+?)\2", line)
            if export_match:
                indent = export_match.group(1)
                quote = export_match.group(2)
                old_export = export_match.group(3)
                
                new_export = self._convert_import_path(old_export, file_path)
                
                if new_export != old_export:
                    new_line = f"{indent}export {quote}{new_export}{quote};\n"
                    changed = True
            
            new_lines.append(new_line)
        
        if changed:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.writelines(new_lines)
            return True
        
        return False
    
    def _convert_import_path(self, import_path: str, current_file: Path) -> str:
        """Convert an import path to the correct new location"""
        
        # Skip external packages and dart: imports
        if import_path.startswith('dart:'):
            return import_path
        
        if import_path.startswith('package:') and not import_path.startswith(f'package:{self.package_name}/'):
            return import_path
        
        # Handle our package imports
        if import_path.startswith(f'package:{self.package_name}/'):
            internal_path = import_path.replace(f'package:{self.package_name}/', '').replace('.dart', '')
            
            # Check if this file exists
            target = self.lib_path / f"{internal_path}.dart"
            if target.exists():
                return import_path  # Already correct
            
            # Try to find where it moved
            new_location = self._find_file_location(internal_path)
            if new_location:
                return f"package:{self.package_name}/{new_location}.dart"
            
            return import_path
        
        # Handle relative imports
        if import_path.startswith('../') or import_path.startswith('./'):
            try:
                # Resolve to absolute path
                resolved = (current_file.parent / import_path).resolve()
                
                # Check if it exists
                if resolved.exists():
                    # Convert to package import
                    rel_to_lib = resolved.relative_to(self.lib_path)
                    return f"package:{self.package_name}/{str(rel_to_lib).replace(chr(92), '/')}"
                
                # Try to find it
                filename = Path(import_path).stem
                new_location = self._find_file_location(filename)
                if new_location:
                    return f"package:{self.package_name}/{new_location}.dart"
                
            except (ValueError, OSError):
                pass
        
        # Try to find by filename
        new_location = self._find_file_location(import_path.replace('.dart', ''))
        if new_location:
            return f"package:{self.package_name}/{new_location}.dart"
        
        return import_path
    
    def _find_file_location(self, filename: str) -> Optional[str]:
        """Find where a file is located"""
        filename = filename.replace('.dart', '')
        
        # Try exact matches first
        if filename in self.all_files:
            return self.all_files[filename].relative_path.replace('.dart', '')
        
        # Try just the basename
        basename = filename.split('/')[-1]
        if basename in self.all_files:
            return self.all_files[basename].relative_path.replace('.dart', '')
        
        # Search all files
        for file_info in self.all_files.values():
            if file_info.name == basename:
                return file_info.relative_path.replace('.dart', '')
        
        return None
    
    def organize_imports(self):
        """Organize imports in all files (dart, flutter, package, relative)"""
        print("\n📋 Step 4: Organizing imports...")
        
        dart_files = [
            f for f in self.lib_path.rglob('*.dart')
            if not f.name.endswith('.g.dart')
            and not f.name.endswith('.freezed.dart')
        ]
        
        organized = 0
        
        for dart_file in dart_files:
            if self._organize_file_imports(dart_file):
                organized += 1
        
        print(f"   ✅ Organized imports in {organized} files")
    
    def _organize_file_imports(self, file_path: Path) -> bool:
        """Organize imports in a single file by category"""
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        # Find import section
        import_start = None
        import_end = None
        
        for i, line in enumerate(lines):
            if line.strip().startswith('import '):
                if import_start is None:
                    import_start = i
                import_end = i
            elif line.strip().startswith('export '):
                if import_start is None:
                    import_start = i
                import_end = i
            elif import_start is not None and line.strip() and not line.strip().startswith('//'):
                break
        
        if import_start is None:
            return False
        
        # Extract imports
        imports = lines[import_start:import_end + 1]
        
        # Categorize
        dart_imports = []
        flutter_imports = []
        package_imports = []
        project_imports = []
        relative_imports = []
        
        for imp in imports:
            imp = imp.strip()
            if not imp:
                continue
            
            if "import 'dart:" in imp or 'import "dart:' in imp:
                dart_imports.append(imp)
            elif "import 'package:flutter" in imp or 'import "package:flutter' in imp:
                flutter_imports.append(imp)
            elif f"import 'package:{self.package_name}/" in imp or f'import "package:{self.package_name}/' in imp:
                project_imports.append(imp)
            elif "import 'package:" in imp or 'import "package:' in imp:
                package_imports.append(imp)
            else:
                relative_imports.append(imp)
        
        # Sort each category
        dart_imports.sort()
        flutter_imports.sort()
        package_imports.sort()
        project_imports.sort()
        relative_imports.sort()
        
        # Build organized imports
        organized = []
        
        if dart_imports:
            organized.extend([imp + '\n' for imp in dart_imports])
        
        if flutter_imports:
            if organized:
                organized.append('\n')
            organized.extend([imp + '\n' for imp in flutter_imports])
        
        if package_imports:
            if organized:
                organized.append('\n')
            organized.extend([imp + '\n' for imp in package_imports])
        
        if project_imports:
            if organized:
                organized.append('\n')
            organized.extend([imp + '\n' for imp in project_imports])
        
        if relative_imports:
            if organized:
                organized.append('\n')
            organized.extend([imp + '\n' for imp in relative_imports])
        
        # Check if changed
        if organized != imports:
            # Rebuild file
            new_lines = lines[:import_start] + organized + ['\n'] + lines[import_end + 1:]
            
            with open(file_path, 'w', encoding='utf-8') as f:
                f.writelines(new_lines)
            
            return True
        
        return False
    
    def create_documentation(self):
        """Create helpful documentation"""
        print("\n📚 Step 5: Creating documentation...")
        
        doc = f"""# {self.package_name.upper()} - Import Guide

## 🎯 How This Project is Organized

Every directory has an `index.dart` file that exports everything in that directory.
This means you can import entire features or layers with a single import!

## 📦 Using Barrel Files

### Old Way (DON'T DO THIS):
```dart
import 'package:{self.package_name}/features/loads/data/models/load.dart';
import 'package:{self.package_name}/features/loads/data/models/load_status.dart';
import 'package:{self.package_name}/features/loads/presentation/widgets/load_card.dart';
```

### New Way (DO THIS):
```dart
// Import all models
import 'package:{self.package_name}/features/loads/data/models/index.dart';

// Or import the entire feature!
import 'package:{self.package_name}/features/loads/index.dart';
```

## 🚀 Quick Examples

### Example 1: Dashboard Screen
```dart
import 'package:flutter/material.dart';

// Import entire loads feature
import 'package:{self.package_name}/features/loads/index.dart';

// Import core widgets
import 'package:{self.package_name}/core/widgets/index.dart';

class DashboardScreen extends StatelessWidget {{
  @override
  Widget build(BuildContext context) {{
    return Column(
      children: [
        LoadCard(load: myLoad),      // From loads feature
        AppButton(text: 'Click'),    // From core widgets
      ],
    );
  }}
}}
```

### Example 2: Multiple Features
```dart
// Import multiple features at once
import 'package:{self.package_name}/features/loads/index.dart' as loads;
import 'package:{self.package_name}/features/drivers/index.dart' as drivers;

// Use with namespace
loads.LoadCard(load: myLoad);
drivers.DriverCard(driver: myDriver);
```

## 🛠️ Maintenance

### After Moving/Adding Files:

Run the auto-fixer:
```bash
python3 ultimate_fixer.py .
```

This will:
- ✅ Recreate all barrel files
- ✅ Fix all imports
- ✅ Organize imports by category
- ✅ Verify everything is correct

### Import Organization:

Imports are automatically organized in this order:
1. Dart imports (dart:)
2. Flutter imports (package:flutter)
3. External packages (package:other)
4. Project imports (package:{self.package_name})
5. Relative imports (../)

## 💡 Pro Tips

1. **Always use barrel files** - Never import individual files unless absolutely necessary
2. **Use namespaces** - Prefix imports to avoid conflicts: `as loads`, `as drivers`
3. **Run the fixer** - After any file moves or additions: `python3 ultimate_fixer.py .`
4. **Keep it clean** - Let the auto-fixer handle organization

## 🔥 The Ultimate Rule

When in doubt, run:
```bash
python3 ultimate_fixer.py .
```

It fixes everything automatically!
"""
        
        doc_path = self.lib_path / 'IMPORT_GUIDE.md'
        with open(doc_path, 'w', encoding='utf-8') as f:
            f.write(doc)
        
        print(f"   ✅ Created lib/IMPORT_GUIDE.md")
    
    def verify_everything(self):
        """Final verification"""
        print("\n✅ Step 6: Verifying everything...")
        
        # Check for broken imports
        broken = []
        dart_files = [
            f for f in self.lib_path.rglob('*.dart')
            if not f.name.endswith('.g.dart')
        ]
        
        for dart_file in dart_files:
            with open(dart_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Find package imports
            imports = re.findall(f"import ['\"]package:{self.package_name}/(.+?)['\"]", content)
            
            for imp in imports:
                target = self.lib_path / imp
                if not target.exists():
                    broken.append((dart_file.name, imp))
        
        if broken:
            print(f"   ⚠️  Found {len(broken)} potentially broken imports")
            print("   💡 Some might be generated files (.g.dart) - that's OK")
        else:
            print("   ✅ All imports verified!")
        
        # Count barrel files
        barrels = len(list(self.lib_path.rglob('index.dart')))
        print(f"   ✅ {barrels} barrel files created")
    
    def run(self):
        """Run the complete auto-fix process"""
        start_time = time.time()
        
        try:
            self.scan_all_files()
            self.create_all_barrel_files()
            self.fix_all_imports()
            self.organize_imports()
            self.create_documentation()
            self.verify_everything()
            
            elapsed = time.time() - start_time
            
            print("\n" + "=" * 70)
            print("✨ AUTO-FIX COMPLETE! ✨")
            print("=" * 70)
            print(f"⏱️  Completed in {elapsed:.2f} seconds")
            print("\n📋 Next Steps:")
            print("  1. Run: flutter pub get")
            print("  2. Run: flutter pub run build_runner build --delete-conflicting-outputs")
            print("  3. Test your app")
            print("  4. Read: lib/IMPORT_GUIDE.md")
            print("\n💡 Run this script anytime you move or add files!")
            print("=" * 70 + "\n")
            
        except Exception as e:
            print(f"\n❌ Error: {e}")
            import traceback
            traceback.print_exc()
            raise

def main():
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python3 ultimate_fixer.py <project_path>")
        print("Example: python3 ultimate_fixer.py .")
        print("         python3 ultimate_fixer.py /path/to/project")
        sys.exit(1)
    
    project_path = sys.argv[1]
    
    if not os.path.exists(project_path):
        print(f"❌ Path does not exist: {project_path}")
        sys.exit(1)
    
    fixer = UltimateFlutterFixer(project_path)
    fixer.run()

if __name__ == "__main__":
    main()
