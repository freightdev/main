import os
import re
from pathlib import Path
from typing import Dict, List, Set, Tuple
import json

class ImportFixer:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.lib_path = self.project_root / "lib"
        
        # Build a complete file map of where everything is now
        self.file_map: Dict[str, str] = {}
        self.package_name = self._get_package_name()
        
    def _get_package_name(self) -> str:
        """Extract package name from pubspec.yaml"""
        pubspec_path = self.project_root / "pubspec.yaml"
        if pubspec_path.exists():
            with open(pubspec_path, 'r') as f:
                for line in f:
                    if line.startswith('name:'):
                        return line.split(':')[1].strip()
        return "fed_tms"  # fallback
    
    def scan_project(self):
        """Scan the entire lib/ directory and build a map of all dart files"""
        print("🔍 Scanning project structure...")
        
        for dart_file in self.lib_path.rglob('*.dart'):
            # Get relative path from lib/
            rel_path = dart_file.relative_to(self.lib_path)
            
            # Get filename without extension
            filename = dart_file.stem
            
            # Store both full path and just filename for matching
            full_import_path = str(rel_path).replace('\\', '/').replace('.dart', '')
            
            # Map filename to its new location
            self.file_map[filename] = full_import_path
            
            # Also map the full old-style path if it follows old structure
            self.file_map[full_import_path] = full_import_path
        
        print(f"✅ Found {len(self.file_map)} Dart files")
        
        # Print some examples for debugging
        print("\n📋 Sample file mappings:")
        for i, (key, value) in enumerate(list(self.file_map.items())[:10]):
            print(f"  {key} → {value}")
    
    def fix_all_imports(self):
        """Fix imports in all Dart files"""
        print("\n🔧 Fixing imports...")
        
        dart_files = list(self.lib_path.rglob('*.dart'))
        total = len(dart_files)
        fixed_count = 0
        error_count = 0
        
        for i, dart_file in enumerate(dart_files, 1):
            try:
                if self._fix_file_imports(dart_file):
                    fixed_count += 1
                
                # Progress
                if i % 10 == 0 or i == total:
                    print(f"  Progress: {i}/{total} files ({fixed_count} fixed, {error_count} errors)")
                    
            except Exception as e:
                error_count += 1
                print(f"  ❌ Error in {dart_file.name}: {e}")
        
        print(f"\n✅ Fixed imports in {fixed_count} files!")
        if error_count > 0:
            print(f"⚠️  {error_count} files had errors")
    
    def _fix_file_imports(self, file_path: Path) -> bool:
        """Fix imports in a single file"""
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        lines = content.split('\n')
        new_lines = []
        changed = False
        
        for line in lines:
            new_line = line
            
            # Match import statements
            import_match = re.match(r"^import\s+['\"](.+?)['\"];?", line)
            if import_match:
                old_import = import_match.group(1)
                new_import = self._convert_import(old_import, file_path)
                
                if new_import != old_import:
                    # Preserve the quote style
                    quote = "'" if "'" in line else '"'
                    new_line = f"import {quote}{new_import}{quote};"
                    changed = True
            
            # Match export statements
            export_match = re.match(r"^export\s+['\"](.+?)['\"];?", line)
            if export_match:
                old_export = export_match.group(1)
                new_export = self._convert_import(old_export, file_path)
                
                if new_export != old_export:
                    quote = "'" if "'" in line else '"'
                    new_line = f"export {quote}{new_export}{quote};"
                    changed = True
            
            # Match part statements
            part_match = re.match(r"^part\s+['\"](.+?)['\"];?", line)
            if part_match:
                old_part = part_match.group(1)
                new_part = self._convert_import(old_part, file_path)
                
                if new_part != old_part:
                    quote = "'" if "'" in line else '"'
                    new_line = f"part {quote}{new_part}{quote};"
                    changed = True
            
            new_lines.append(new_line)
        
        if changed:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write('\n'.join(new_lines))
            return True
        
        return False
    
    def _convert_import(self, import_path: str, current_file: Path) -> str:
        """Convert an old import path to the new structure"""
        
        # Skip dart: and package: imports that aren't our package
        if import_path.startswith('dart:'):
            return import_path
        
        if import_path.startswith('package:') and not import_path.startswith(f'package:{self.package_name}/'):
            return import_path
        
        # Handle our package imports
        if import_path.startswith(f'package:{self.package_name}/'):
            # Extract the path after package:fed_tms/
            internal_path = import_path.replace(f'package:{self.package_name}/', '')
            
            # Try to find the new location
            new_path = self._find_new_location(internal_path)
            if new_path:
                return f'package:{self.package_name}/{new_path}.dart'
            
            return import_path
        
        # Handle relative imports
        if import_path.startswith('../') or import_path.startswith('./'):
            # Resolve relative to absolute, then find new location
            current_dir = current_file.parent
            resolved = (current_dir / import_path).resolve()
            
            try:
                rel_to_lib = resolved.relative_to(self.lib_path)
                internal_path = str(rel_to_lib).replace('\\', '/').replace('.dart', '')
                new_path = self._find_new_location(internal_path)
                
                if new_path:
                    return f'package:{self.package_name}/{new_path}.dart'
            except ValueError:
                pass
            
            return import_path
        
        # Handle bare imports (just filename)
        new_path = self._find_new_location(import_path.replace('.dart', ''))
        if new_path:
            return f'package:{self.package_name}/{new_path}.dart'
        
        return import_path
    
    def _find_new_location(self, old_path: str) -> str:
        """Find where a file moved to in the new structure"""
        old_path = old_path.replace('.dart', '')
        
        # Direct match
        if old_path in self.file_map:
            return self.file_map[old_path]
        
        # Try just the filename
        filename = old_path.split('/')[-1]
        if filename in self.file_map:
            return self.file_map[filename]
        
        # Try old-style paths (screens/dashboard_screen -> features/dashboard/presentation/screens/dashboard_screen)
        old_patterns = {
            'screens/': ['features/*/presentation/screens/', 'core/'],
            'widgets/': ['features/*/presentation/widgets/', 'core/widgets/'],
            'services/': ['features/*/data/services/', 'core/services/'],
            'providers/': ['features/*/providers/', 'core/providers/'],
            'models/': ['features/*/data/models/', 'core/models/'],
        }
        
        for old_prefix, new_prefixes in old_patterns.items():
            if old_path.startswith(old_prefix):
                filename = old_path.replace(old_prefix, '')
                
                # Search for this file in any of the new locations
                for dart_file in self.lib_path.rglob(f'{filename}.dart'):
                    rel_path = dart_file.relative_to(self.lib_path)
                    return str(rel_path).replace('\\', '/').replace('.dart', '')
        
        return None
    
    def create_index_files(self):
        """Create barrel/index files for clean imports"""
        print("\n📦 Creating index.dart barrel files...")
        
        created = 0
        
        # Create index files for each feature
        features_path = self.lib_path / 'features'
        if features_path.exists():
            for feature_dir in features_path.iterdir():
                if feature_dir.is_dir():
                    # Create barrel for models
                    models_dir = feature_dir / 'data' / 'models'
                    if self._create_barrel_file(models_dir):
                        created += 1
                    
                    # Create barrel for providers
                    providers_dir = feature_dir / 'providers'
                    if self._create_barrel_file(providers_dir):
                        created += 1
                    
                    # Create barrel for widgets
                    widgets_dir = feature_dir / 'presentation' / 'widgets'
                    if self._create_barrel_file(widgets_dir):
                        created += 1
                    
                    # Create barrel for screens
                    screens_dir = feature_dir / 'presentation' / 'screens'
                    if self._create_barrel_file(screens_dir):
                        created += 1
        
        # Create index for core widgets
        core_widgets = self.lib_path / 'core' / 'widgets'
        if self._create_barrel_file(core_widgets):
            created += 1
        
        print(f"✅ Created {created} barrel files!")
    
    def _create_barrel_file(self, directory: Path) -> bool:
        """Create an index.dart barrel file in a directory"""
        if not directory.exists():
            return False
        
        # Find all dart files except index.dart and *.g.dart
        dart_files = [
            f for f in directory.glob('*.dart')
            if f.name != 'index.dart' and not f.name.endswith('.g.dart')
        ]
        
        if not dart_files:
            return False
        
        # Create barrel content
        exports = []
        for dart_file in sorted(dart_files):
            exports.append(f"export '{dart_file.name}';")
        
        barrel_content = "// Auto-generated barrel file\n"
        barrel_content += "// This file exports all files in this directory for easier imports\n\n"
        barrel_content += '\n'.join(exports) + '\n'
        
        # Write barrel file
        index_path = directory / 'index.dart'
        with open(index_path, 'w', encoding='utf-8') as f:
            f.write(barrel_content)
        
        rel_path = directory.relative_to(self.lib_path)
        print(f"  ✓ Created {rel_path}/index.dart")
        return True
    
    def generate_import_guide(self):
        """Generate a guide showing how to use the new imports"""
        guide = """# Import Guide - How to Use Barrel Files (index.dart)

## What are Barrel Files?

Barrel files (index.dart) are files that re-export other files from a directory.
They make imports cleaner and easier to manage.

## Without Barrel Files (OLD WAY - Don't do this):

```dart
import 'package:fed_tms/features/loads/data/models/load.dart';
import 'package:fed_tms/features/loads/data/models/load_status.dart';
import 'package:fed_tms/features/loads/data/models/load_type.dart';
import 'package:fed_tms/features/loads/presentation/widgets/load_card.dart';
import 'package:fed_tms/features/loads/presentation/widgets/load_status_badge.dart';
```

## With Barrel Files (NEW WAY - Do this):

```dart
// Import all models from loads feature
import 'package:fed_tms/features/loads/data/models/index.dart';

// Import all widgets from loads feature
import 'package:fed_tms/features/loads/presentation/widgets/index.dart';
```

## Real Examples:

### Example 1: Using Load Models in a Screen

```dart
// screens/loads/load_details_screen.dart

// Import models barrel
import 'package:fed_tms/features/loads/data/models/index.dart';

// Now you can use Load, LoadStatus, LoadType, etc.
class LoadDetailsScreen extends StatelessWidget {
  final Load load;  // ✅ Available from barrel
  
  // ...
}
```

### Example 2: Using Widgets in Another Feature

```dart
// features/dashboard/presentation/screens/dashboard_screen.dart

// Import load widgets
import 'package:fed_tms/features/loads/presentation/widgets/index.dart';

// Import core widgets
import 'package:fed_tms/core/widgets/index.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LoadCard(load: myLoad),      // ✅ From loads widgets barrel
        AppButton(onTap: () {}),     // ✅ From core widgets barrel
      ],
    );
  }
}
```

### Example 3: Using Multiple Feature Models

```dart
// features/invoicing/presentation/screens/invoice_screen.dart

// Import multiple feature models
import 'package:fed_tms/features/loads/data/models/index.dart';
import 'package:fed_tms/features/drivers/data/models/index.dart';
import 'package:fed_tms/features/invoicing/data/models/index.dart';

class InvoiceScreen extends StatelessWidget {
  final Load load;        // ✅ From loads
  final Driver driver;    // ✅ From drivers
  final Invoice invoice;  // ✅ From invoicing
  
  // ...
}
```

## Available Barrel Files:

### Features:
- `package:fed_tms/features/loads/data/models/index.dart`
- `package:fed_tms/features/loads/presentation/widgets/index.dart`
- `package:fed_tms/features/drivers/data/models/index.dart`
- `package:fed_tms/features/drivers/presentation/widgets/index.dart`
- `package:fed_tms/features/invoicing/data/models/index.dart`
- (etc. for each feature)

### Core:
- `package:fed_tms/core/widgets/index.dart`

## Pro Tips:

1. **Always use barrel files for importing multiple files from the same directory**
2. **Use 'as' for namespace conflicts**:
   ```dart
   import 'package:fed_tms/features/loads/data/models/index.dart' as loads;
   import 'package:fed_tms/features/drivers/data/models/index.dart' as drivers;
   
   loads.Load myLoad;
   drivers.Driver myDriver;
   ```

3. **Show/Hide specific exports if needed**:
   ```dart
   import 'package:fed_tms/features/loads/data/models/index.dart' show Load, LoadStatus;
   ```

4. **Barrel files are auto-generated** - don't manually edit them

## When NOT to use barrel files:

- When importing just ONE file - import it directly
- When importing from outside your project (packages)
- For generated files (*.g.dart, *.freezed.dart)

```dart
// ✅ Good - single file
import 'package:fed_tms/features/loads/data/models/load.dart';

// ❌ Bad - barrel for one file is overkill
import 'package:fed_tms/features/loads/data/models/index.dart' show Load;
```
"""
        
        guide_path = self.lib_path / 'IMPORT_GUIDE.md'
        with open(guide_path, 'w', encoding='utf-8') as f:
            f.write(guide)
        
        print(f"\n📖 Import guide created at: lib/IMPORT_GUIDE.md")
    
    def verify_imports(self):
        """Verify all imports are valid"""
        print("\n✅ Verifying imports...")
        
        broken_imports = []
        dart_files = list(self.lib_path.rglob('*.dart'))
        
        for dart_file in dart_files:
            with open(dart_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Find all imports
            imports = re.findall(r"import\s+['\"]package:fed_tms/(.+?)['\"];", content)
            
            for imp in imports:
                # Check if the file exists
                target_file = self.lib_path / imp
                if not target_file.exists():
                    broken_imports.append((dart_file.name, imp))
        
        if broken_imports:
            print(f"\n⚠️  Found {len(broken_imports)} potentially broken imports:")
            for file, imp in broken_imports[:20]:  # Show first 20
                print(f"  {file}: {imp}")
            if len(broken_imports) > 20:
                print(f"  ... and {len(broken_imports) - 20} more")
        else:
            print("✅ All imports look good!")
    
    def run(self):
        """Run the complete import fixing process"""
        print("=" * 70)
        print("🔧 IMPORT FIXER - Fixing all imports in your restructured project")
        print("=" * 70)
        
        try:
            # Step 1: Scan project
            self.scan_project()
            
            # Step 2: Fix imports
            self.fix_all_imports()
            
            # Step 3: Create barrel files
            self.create_index_files()
            
            # Step 4: Generate guide
            self.generate_import_guide()
            
            # Step 5: Verify
            self.verify_imports()
            
            print("\n" + "=" * 70)
            print("✨ IMPORT FIXING COMPLETE!")
            print("=" * 70)
            print("\n📋 Next Steps:")
            print("  1. Read: lib/IMPORT_GUIDE.md")
            print("  2. Run: flutter pub get")
            print("  3. Run: flutter pub run build_runner build --delete-conflicting-outputs")
            print("  4. Test your app!")
            print("\n💡 Use barrel files (index.dart) for cleaner imports!")
            print("=" * 70)
            
        except Exception as e:
            print(f"\n❌ Error: {e}")
            raise

def main():
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python fix_imports.py <path_to_flutter_project>")
        print("Example: python fix_imports.py /Users/me/projects/fed_tms")
        print("         python fix_imports.py .")
        sys.exit(1)
    
    project_path = sys.argv[1]
    
    if not os.path.exists(project_path):
        print(f"❌ Error: Path does not exist: {project_path}")
        sys.exit(1)
    
    print(f"\n📍 Project: {os.path.abspath(project_path)}")
    
    fixer = ImportFixer(project_path)
    fixer.run()

if __name__ == "__main__":
    main()
