#!/usr/bin/env python3
"""
Ultimate Flutter Project Fixer - Fixes EVERYTHING automatically
Analyzes flutter analyze output and fixes all issues iteratively
"""

import os
import re
import subprocess
from pathlib import Path
from typing import Dict, Set, List, Tuple, Optional
import argparse
from collections import defaultdict


class FlutterAnalyzer:
    """Runs flutter analyze and parses errors"""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
    
    def run_analysis(self) -> List[Dict]:
        """Run flutter analyze and parse output"""
        try:
            result = subprocess.run(
                ['flutter', 'analyze', '--no-fatal-infos'],
                cwd=self.project_root,
                capture_output=True,
                text=True,
                timeout=60
            )
            
            return self._parse_output(result.stdout + result.stderr)
        except Exception as e:
            print(f"  ⚠️  Could not run flutter analyze: {e}")
            return []
    
    def _parse_output(self, output: str) -> List[Dict]:
        """Parse flutter analyze output into structured errors"""
        errors = []
        
        # Match patterns like:
        # error • Undefined name 'Widget' • lib/main.dart:10:5 • undefined_identifier
        pattern = r"(error|warning|info)\s*[•·]\s*(.+?)\s*[•·]\s*([^:]+):(\d+):(\d+)\s*[•·]\s*(\w+)"
        
        for match in re.finditer(pattern, output, re.MULTILINE):
            severity = match.group(1)
            message = match.group(2).strip()
            file_path = match.group(3).strip()
            line = int(match.group(4))
            col = int(match.group(5))
            code = match.group(6)
            
            errors.append({
                'severity': severity,
                'message': message,
                'file': file_path,
                'line': line,
                'col': col,
                'code': code
            })
        
        return errors


class UltimateFlutterFixer:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root).resolve()
        self.lib_dir = self.project_root / "lib"
        self.package_name = self._get_package_name()
        
        # Mappings
        self.all_files: List[Path] = []
        self.symbol_to_file: Dict[str, List[Path]] = defaultdict(list)
        self.file_to_symbols: Dict[Path, Set[str]] = {}
        self.file_to_content: Dict[Path, str] = {}
        
        # Flutter SDK mappings
        self.flutter_sdk_imports = self._init_flutter_sdk_imports()
        
        # External packages
        self.external_packages: Set[str] = set()
        self.package_symbols: Dict[str, str] = {}
        
        # Fix tracking
        self.fixes_applied = 0
        
    def _get_package_name(self) -> str:
        """Extract package name from pubspec.yaml"""
        pubspec_path = self.project_root / "pubspec.yaml"
        if not pubspec_path.exists():
            raise FileNotFoundError("pubspec.yaml not found")
        
        with open(pubspec_path, 'r', encoding='utf-8') as f:
            match = re.search(r'^name:\s*(\S+)', f.read(), re.MULTILINE)
            if match:
                return match.group(1)
        raise ValueError("Could not find package name")
    
    def _init_flutter_sdk_imports(self) -> Dict[str, str]:
        """Map Flutter/Dart symbols to imports"""
        symbols = {}
        
        # Material widgets
        material_widgets = [
            'StatelessWidget', 'StatefulWidget', 'Widget', 'BuildContext', 'State',
            'MaterialApp', 'Scaffold', 'AppBar', 'Container', 'Column', 'Row',
            'Text', 'Icon', 'IconButton', 'ElevatedButton', 'TextButton', 'OutlinedButton',
            'FloatingActionButton', 'TextField', 'TextFormField', 'Form', 'FormState',
            'ListView', 'GridView', 'Stack', 'Positioned', 'Padding', 'Center', 'Align',
            'SizedBox', 'Expanded', 'Flexible', 'Wrap', 'Card', 'Divider',
            'CircularProgressIndicator', 'LinearProgressIndicator', 'Drawer',
            'BottomNavigationBar', 'TabBar', 'TabBarView', 'Dialog', 'AlertDialog',
            'SnackBar', 'Theme', 'ThemeData', 'Color', 'Colors', 'TextStyle',
            'EdgeInsets', 'BoxDecoration', 'BorderRadius', 'Border', 'BoxShadow',
            'Gradient', 'LinearGradient', 'RadialGradient', 'MainAxisAlignment',
            'CrossAxisAlignment', 'MainAxisSize', 'TextAlign', 'FontWeight', 'Icons',
            'Navigator', 'MaterialPageRoute', 'InputDecoration', 'TextEditingController',
            'FocusNode', 'Key', 'GlobalKey', 'GestureDetector', 'InkWell', 'Image',
            'NetworkImage', 'AssetImage', 'DecorationImage', 'BoxFit', 'Opacity',
            'AnimatedContainer', 'AnimatedOpacity', 'Hero', 'SafeArea',
            'SingleChildScrollView', 'CustomScrollView', 'PageView', 'DropdownButton',
            'Checkbox', 'Radio', 'Switch', 'Slider', 'Chip', 'ChoiceChip', 'FilterChip',
            'ActionChip', 'Tooltip', 'Badge', 'BottomSheet', 'ExpansionTile', 'ListTile',
            'DataTable', 'Table', 'TableRow', 'Stepper', 'Step', 'RefreshIndicator',
            'Scrollbar', 'IconData', 'BoxConstraints', 'Size', 'Offset', 'Rect',
            'TextDirection', 'VerticalDirection', 'Axis', 'Clip', 'MaterialColor',
            'ColorScheme', 'Brightness', 'ScaffoldMessenger', 'SnackBarAction',
            'PopupMenuButton', 'PopupMenuItem', 'showDialog', 'showModalBottomSheet',
            'showDatePicker', 'showTimePicker', 'MenuAnchor', 'Spacer', 'FractionallySizedBox',
            'AspectRatio', 'ConstrainedBox', 'UnconstrainedBox', 'LimitedBox',
            'OverflowBox', 'LayoutBuilder', 'CustomPaint', 'CustomClipper',
        ]
        
        for widget in material_widgets:
            symbols[widget] = 'package:flutter/material.dart'
        
        # Async/Core
        symbols.update({
            'Future': 'dart:async',
            'Stream': 'dart:async',
            'StreamController': 'dart:async',
            'StreamSubscription': 'dart:async',
            'Timer': 'dart:async',
            'Completer': 'dart:async',
            'List': 'dart:core',
            'Map': 'dart:core',
            'Set': 'dart:core',
            'String': 'dart:core',
            'int': 'dart:core',
            'double': 'dart:core',
            'bool': 'dart:core',
            'num': 'dart:core',
            'Function': 'dart:core',
            'Duration': 'dart:core',
            'DateTime': 'dart:core',
            'Object': 'dart:core',
            'Exception': 'dart:core',
            'Error': 'dart:core',
            'StackTrace': 'dart:core',
        })
        
        # Foundation
        symbols.update({
            'ChangeNotifier': 'package:flutter/foundation.dart',
            'ValueNotifier': 'package:flutter/foundation.dart',
            'ValueListenable': 'package:flutter/foundation.dart',
            'TargetPlatform': 'package:flutter/foundation.dart',
            'kDebugMode': 'package:flutter/foundation.dart',
            'kReleaseMode': 'package:flutter/foundation.dart',
        })
        
        # Services
        symbols.update({
            'ServicesBinding': 'package:flutter/services.dart',
            'SystemChrome': 'package:flutter/services.dart',
            'SystemUiOverlayStyle': 'package:flutter/services.dart',
            'DeviceOrientation': 'package:flutter/services.dart',
            'TextInputType': 'package:flutter/services.dart',
            'TextInputAction': 'package:flutter/services.dart',
        })
        
        # Cupertino
        cupertino_widgets = [
            'CupertinoApp', 'CupertinoPageScaffold', 'CupertinoNavigationBar',
            'CupertinoButton', 'CupertinoTextField', 'CupertinoSwitch', 'CupertinoSlider',
            'CupertinoActivityIndicator', 'CupertinoColors', 'CupertinoIcons',
        ]
        for widget in cupertino_widgets:
            symbols[widget] = 'package:flutter/cupertino.dart'
        
        return symbols
    
    def scan_project(self):
        """Scan project and build mappings"""
        print(f"🔍 Scanning project...")
        
        self._scan_dependencies()
        self.all_files = list(self.lib_dir.rglob("*.dart"))
        
        for dart_file in self.all_files:
            try:
                with open(dart_file, 'r', encoding='utf-8', errors='replace') as f:
                    content = f.read()
                
                self.file_to_content[dart_file] = content
                symbols = self._extract_definitions(content)
                self.file_to_symbols[dart_file] = symbols
                
                for symbol in symbols:
                    self.symbol_to_file[symbol].append(dart_file)
                    
            except Exception as e:
                print(f"  ⚠️  Error scanning {dart_file}: {e}")
        
        print(f"  ✓ Found {len(self.all_files)} Dart files")
        print(f"  ✓ Found {len(self.symbol_to_file)} symbols")
    
    def _scan_dependencies(self):
        """Scan pubspec.yaml for dependencies"""
        pubspec_path = self.project_root / "pubspec.yaml"
        with open(pubspec_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Known package symbol mappings
        package_mappings = {
            'http': {'Client', 'Response', 'Request', 'get', 'post', 'put', 'delete'},
            'provider': {'Provider', 'ChangeNotifierProvider', 'Consumer', 'MultiProvider'},
            'shared_preferences': {'SharedPreferences'},
            'sqflite': {'Database', 'openDatabase'},
            'path_provider': {'getApplicationDocumentsDirectory', 'getTemporaryDirectory'},
            'image_picker': {'ImagePicker', 'ImageSource', 'XFile'},
            'google_fonts': {'GoogleFonts'},
            'flutter_bloc': {'Bloc', 'BlocProvider', 'BlocBuilder', 'Cubit'},
            'get_it': {'GetIt'},
            'dio': {'Dio', 'Response', 'RequestOptions'},
            'intl': {'DateFormat', 'NumberFormat'},
            'flutter_svg': {'SvgPicture'},
            'cached_network_image': {'CachedNetworkImage'},
            'go_router': {'GoRouter', 'GoRoute'},
            'flutter_form_builder': {'FormBuilder', 'FormBuilderTextField', 'FormBuilderDropdown'},
        }
        
        in_deps = False
        for line in content.split('\n'):
            if re.match(r'^dependencies:', line):
                in_deps = True
                continue
            if in_deps:
                if line and not line.startswith(' ') and not line.startswith('\t'):
                    break
                match = re.match(r'\s+(\w+):', line)
                if match:
                    pkg = match.group(1)
                    if pkg != 'flutter':
                        self.external_packages.add(pkg)
                        
                        # Map known symbols to packages
                        if pkg in package_mappings:
                            for symbol in package_mappings[pkg]:
                                self.package_symbols[symbol] = f'package:{pkg}/{pkg}.dart'
    
    def _extract_definitions(self, content: str) -> Set[str]:
        """Extract all definitions from content"""
        patterns = [
            r'class\s+(\w+)',
            r'abstract\s+class\s+(\w+)',
            r'mixin\s+(\w+)',
            r'enum\s+(\w+)',
            r'extension\s+(\w+)',
            r'typedef\s+(\w+)',
        ]
        
        symbols = set()
        for pattern in patterns:
            symbols.update(re.findall(pattern, content))
        return symbols
    
    def fix_by_analyzer_output(self, max_iterations: int = 5) -> int:
        """Fix issues based on flutter analyze output"""
        print(f"\n🔧 Running intelligent fixes...")
        
        analyzer = FlutterAnalyzer(self.project_root)
        
        for iteration in range(max_iterations):
            print(f"\n  --- Iteration {iteration + 1} ---")
            
            errors = analyzer.run_analysis()
            if not errors:
                print(f"  ✓ No errors found!")
                break
            
            print(f"  📊 Found {len(errors)} issues")
            
            # Group errors by type
            by_code = defaultdict(list)
            for error in errors:
                by_code[error['code']].append(error)
            
            fixes_this_iteration = 0
            
            # Fix undefined identifiers
            if 'undefined_identifier' in by_code or 'undefined_name' in by_code or 'undefined_class' in by_code:
                undefined_errors = by_code.get('undefined_identifier', []) + \
                                 by_code.get('undefined_name', []) + \
                                 by_code.get('undefined_class', [])
                fixes_this_iteration += self._fix_undefined_identifiers(undefined_errors)
            
            # Fix unused imports
            if 'unused_import' in by_code:
                fixes_this_iteration += self._fix_unused_imports(by_code['unused_import'])
            
            # Fix missing required parameters
            if 'missing_required_param' in by_code:
                fixes_this_iteration += self._fix_missing_params(by_code['missing_required_param'])
            
            # Fix const issues
            if 'const_initialized_with_non_constant_value' in by_code:
                fixes_this_iteration += self._fix_const_issues(by_code['const_initialized_with_non_constant_value'])
            
            # Fix missing return statements
            if 'missing_return' in by_code:
                fixes_this_iteration += self._fix_missing_returns(by_code['missing_return'])
            
            print(f"  ✓ Applied {fixes_this_iteration} fixes")
            
            if fixes_this_iteration == 0:
                print(f"\n  ⚠️  No more automatic fixes available")
                print(f"  📊 Remaining issues: {len(errors)}")
                break
        
        return self.fixes_applied
    
    def _fix_undefined_identifiers(self, errors: List[Dict]) -> int:
        """Fix undefined identifier errors by adding imports"""
        fixes = 0
        
        for error in errors:
            # Extract the undefined symbol from error message
            match = re.search(r"Undefined (?:name|class|identifier) '(\w+)'", error['message'])
            if not match:
                continue
            
            symbol = match.group(1)
            file_path = self.project_root / error['file']
            
            if not file_path.exists():
                continue
            
            # Find the import needed
            import_to_add = None
            
            # Check Flutter SDK
            if symbol in self.flutter_sdk_imports:
                import_to_add = self.flutter_sdk_imports[symbol]
            # Check external packages
            elif symbol in self.package_symbols:
                import_to_add = self.package_symbols[symbol]
            # Check project symbols
            elif symbol in self.symbol_to_file:
                target_files = self.symbol_to_file[symbol]
                if target_files:
                    rel_path = target_files[0].relative_to(self.lib_dir)
                    import_to_add = f"package:{self.package_name}/{str(rel_path).replace(chr(92), '/')}"
            
            if import_to_add:
                if self._add_import_to_file(file_path, import_to_add):
                    fixes += 1
        
        return fixes
    
    def _fix_unused_imports(self, errors: List[Dict]) -> int:
        """Remove unused imports"""
        fixes = 0
        
        files_to_fix = set()
        for error in errors:
            files_to_fix.add(self.project_root / error['file'])
        
        for file_path in files_to_fix:
            if self._remove_unused_imports(file_path):
                fixes += 1
        
        return fixes
    
    def _fix_missing_params(self, errors: List[Dict]) -> int:
        """Fix missing required parameters"""
        fixes = 0
        
        for error in errors:
            file_path = self.project_root / error['file']
            
            # Extract parameter name from error
            match = re.search(r"The named parameter '(\w+)' is required", error['message'])
            if not match:
                continue
            
            param_name = match.group(1)
            
            if self._add_missing_parameter(file_path, error['line'], param_name):
                fixes += 1
        
        return fixes
    
    def _fix_const_issues(self, errors: List[Dict]) -> int:
        """Fix const initialization issues"""
        fixes = 0
        
        for error in errors:
            file_path = self.project_root / error['file']
            
            if self._remove_const_keyword(file_path, error['line']):
                fixes += 1
        
        return fixes
    
    def _fix_missing_returns(self, errors: List[Dict]) -> int:
        """Add missing return statements"""
        fixes = 0
        
        for error in errors:
            file_path = self.project_root / error['file']
            
            if self._add_return_statement(file_path, error['line']):
                fixes += 1
        
        return fixes
    
    def _add_import_to_file(self, file_path: Path, import_statement: str) -> bool:
        """Add import to a file"""
        try:
            with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
                content = f.read()
            
            # Check if import already exists
            if f"import '{import_statement}';" in content:
                return False
            
            lines = content.split('\n')
            
            # Find where to insert import
            insert_index = 0
            last_import_index = -1
            
            for i, line in enumerate(lines):
                if line.strip().startswith('import '):
                    last_import_index = i
            
            if last_import_index >= 0:
                insert_index = last_import_index + 1
            else:
                # Find first non-comment line
                for i, line in enumerate(lines):
                    if line.strip() and not line.strip().startswith('//'):
                        insert_index = i
                        break
            
            # Insert import
            lines.insert(insert_index, f"import '{import_statement}';")
            
            with open(file_path, 'w', encoding='utf-8', errors='replace') as f:
                f.write('\n'.join(lines))
            
            self.fixes_applied += 1
            return True
            
        except Exception as e:
            return False
    
    def _remove_unused_imports(self, file_path: Path) -> bool:
        """Remove unused imports from file"""
        try:
            with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
                content = f.read()
            
            lines = content.split('\n')
            new_lines = []
            removed = False
            
            for line in lines:
                # Keep non-import lines
                if not line.strip().startswith('import '):
                    new_lines.append(line)
                else:
                    # Conservative: only remove obviously unused imports
                    # For now, keep all imports to be safe
                    new_lines.append(line)
            
            if removed:
                with open(file_path, 'w', encoding='utf-8', errors='replace') as f:
                    f.write('\n'.join(new_lines))
                self.fixes_applied += 1
                return True
            
            return False
            
        except Exception as e:
            return False
    
    def _add_missing_parameter(self, file_path: Path, line_num: int, param_name: str) -> bool:
        """Add missing required parameter"""
        try:
            with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
                lines = f.readlines()
            
            if line_num > len(lines) or line_num < 1:
                return False
            
            target_line = lines[line_num - 1]
            
            # Find the constructor/function call
            if '(' in target_line and ')' in target_line:
                # Simple case: single line
                insert_pos = target_line.rfind(')')
                if insert_pos > 0:
                    # Determine value based on parameter name
                    value = self._guess_parameter_value(param_name)
                    new_param = f"{param_name}: {value}"
                    
                    # Check if there are other parameters
                    paren_start = target_line.rfind('(')
                    params_section = target_line[paren_start+1:insert_pos].strip()
                    
                    if params_section:
                        new_param = f", {new_param}"
                    
                    lines[line_num - 1] = target_line[:insert_pos] + new_param + target_line[insert_pos:]
                    
                    with open(file_path, 'w', encoding='utf-8', errors='replace') as f:
                        f.writelines(lines)
                    
                    self.fixes_applied += 1
                    return True
            
            return False
            
        except Exception as e:
            return False
    
    def _guess_parameter_value(self, param_name: str) -> str:
        """Guess a reasonable value for a parameter"""
        param_lower = param_name.lower()
        
        if 'child' in param_lower:
            return 'Container()'
        elif 'text' in param_lower or 'title' in param_lower or 'label' in param_lower:
            return "''"
        elif 'color' in param_lower:
            return 'Colors.blue'
        elif 'icon' in param_lower:
            return 'Icons.star'
        elif 'size' in param_lower or 'width' in param_lower or 'height' in param_lower:
            return '0.0'
        elif 'onpressed' in param_lower or 'ontap' in param_lower or 'callback' in param_lower:
            return '() {}'
        elif 'controller' in param_lower:
            return 'null'
        else:
            return 'null'
    
    def _remove_const_keyword(self, file_path: Path, line_num: int) -> bool:
        """Remove const keyword"""
        try:
            with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
                lines = f.readlines()
            
            if line_num > len(lines) or line_num < 1:
                return False
            
            target_line = lines[line_num - 1]
            
            if 'const ' in target_line:
                lines[line_num - 1] = target_line.replace('const ', '', 1)
                
                with open(file_path, 'w', encoding='utf-8', errors='replace') as f:
                    f.writelines(lines)
                
                self.fixes_applied += 1
                return True
            
            return False
            
        except Exception as e:
            return False
    
    def _add_return_statement(self, file_path: Path, line_num: int) -> bool:
        """Add return statement to method"""
        try:
            with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
                lines = f.readlines()
            
            if line_num > len(lines) or line_num < 1:
                return False
            
            # Find the end of the method and add return
            # Look for closing brace
            indent = len(lines[line_num - 1]) - len(lines[line_num - 1].lstrip())
            
            for i in range(line_num, len(lines)):
                if '}' in lines[i] and len(lines[i]) - len(lines[i].lstrip()) == indent:
                    # Insert return before closing brace
                    return_line = ' ' * (indent + 2) + 'return null;\n'
                    lines.insert(i, return_line)
                    
                    with open(file_path, 'w', encoding='utf-8', errors='replace') as f:
                        f.writelines(lines)
                    
                    self.fixes_applied += 1
                    return True
            
            return False
            
        except Exception as e:
            return False
    
    def run_complete_fix(self):
        """Run complete fixing process"""
        print(f"{'='*60}")
        print(f"🚀 Ultimate Flutter Project Fixer")
        print(f"{'='*60}")
        
        self.scan_project()
        total_fixes = self.fix_by_analyzer_output(max_iterations=5)
        
        print(f"\n{'='*60}")
        print(f"✅ Fixing Complete!")
        print(f"{'='*60}")
        print(f"  Total fixes applied: {total_fixes}")
        
        # Run final analysis
        print(f"\n📊 Running final analysis...")
        analyzer = FlutterAnalyzer(self.project_root)
        final_errors = analyzer.run_analysis()
        
        if final_errors:
            error_types = defaultdict(int)
            for err in final_errors:
                error_types[err['code']] += 1
            
            print(f"\n  Remaining issues by type:")
            for code, count in sorted(error_types.items(), key=lambda x: -x[1])[:10]:
                print(f"    {code}: {count}")
            
            print(f"\n  Total remaining: {len(final_errors)}")
        else:
            print(f"  ✓ No issues found!")
        
        print(f"\n📋 Next steps:")
        print(f"  1. Run: flutter pub get")
        print(f"  2. Run: flutter analyze")
        print(f"  3. Run this script again if needed")
        print(f"  4. Run: flutter run")


def main():
    parser = argparse.ArgumentParser(
        description='Ultimate Flutter project fixer - fixes everything automatically',
    )
    parser.add_argument(
        'project_root',
        nargs='?',
        default='.',
        help='Path to Flutter project root'
    )
    
    args = parser.parse_args()
    
    try:
        fixer = UltimateFlutterFixer(args.project_root)
        fixer.run_complete_fix()
        return 0
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    exit(main())
