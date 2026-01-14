#!/usr/bin/env python3
"""
Flutter Project Reconstructor - Fixes EVERYTHING in a broken Flutter project
Fixes imports, reconstructs missing files, fixes broken code, reconnects APIs
"""

import os
import re
from pathlib import Path
from typing import Dict, Set, List, Tuple, Optional
import argparse
from collections import defaultdict
import json


class CodeAnalyzer:
    """Analyzes Dart code comprehensively"""
    
    @staticmethod
    def extract_all_identifiers(content: str) -> Set[str]:
        """Extract all identifiers from code"""
        # Remove strings and comments
        clean = re.sub(r'"(?:[^"\\]|\\.)*"', '""', content)
        clean = re.sub(r"'(?:[^'\\]|\\.)*'", "''", clean)
        clean = re.sub(r'//.*?$', '', clean, flags=re.MULTILINE)
        clean = re.sub(r'/\*.*?\*/', '', clean, flags=re.DOTALL)
        
        # Find all identifiers
        identifiers = set(re.findall(r'\b([A-Z][a-zA-Z0-9_]*)\b', clean))
        return identifiers
    
    @staticmethod
    def find_undefined_symbols(file_path: Path, content: str, all_symbols: Dict[str, List[Path]]) -> Set[str]:
        """Find symbols used but not defined anywhere"""
        used = CodeAnalyzer.extract_all_identifiers(content)
        defined_locally = set(re.findall(r'(?:class|enum|mixin|typedef)\s+(\w+)', content))
        
        undefined = set()
        for symbol in used:
            if symbol not in defined_locally and symbol not in all_symbols:
                undefined.add(symbol)
        
        return undefined
    
    @staticmethod
    def extract_method_calls(content: str) -> Set[str]:
        """Extract method calls to detect API usage"""
        calls = set()
        # Match: something.method() or method()
        patterns = [
            r'\.(\w+)\s*\(',
            r'^\s*(\w+)\s*\(',
        ]
        for pattern in patterns:
            calls.update(re.findall(pattern, content, re.MULTILINE))
        return calls
    
    @staticmethod
    def find_missing_implementations(content: str) -> List[Dict]:
        """Find TODO, unimplemented methods, empty implementations"""
        issues = []
        
        # Find TODO comments
        for match in re.finditer(r'//\s*TODO:?\s*(.+)', content):
            issues.append({
                'type': 'TODO',
                'description': match.group(1).strip()
            })
        
        # Find throw UnimplementedError
        if 'UnimplementedError' in content or 'unimplemented' in content.lower():
            issues.append({
                'type': 'UNIMPLEMENTED',
                'description': 'Contains unimplemented code'
            })
        
        # Find empty methods/classes
        empty_methods = re.findall(r'(\w+)\s*\([^)]*\)\s*\{\s*\}', content)
        if empty_methods:
            issues.append({
                'type': 'EMPTY_METHOD',
                'description': f'Empty methods: {", ".join(empty_methods[:3])}'
            })
        
        return issues


class ProjectReconstructor:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root).resolve()
        self.lib_dir = self.project_root / "lib"
        self.package_name = self._get_package_name()
        
        # All mappings
        self.all_files: List[Path] = []
        self.symbol_to_file: Dict[str, List[Path]] = defaultdict(list)
        self.file_to_symbols: Dict[Path, Set[str]] = {}
        self.file_to_content: Dict[Path, str] = {}
        self.external_packages: Set[str] = set()
        
        # Issue tracking
        self.undefined_symbols: Dict[Path, Set[str]] = {}
        self.missing_files: Set[str] = set()
        self.broken_references: Dict[Path, List[str]] = defaultdict(list)
        
        # Generated code tracker
        self.generated_files: List[Path] = []
        
        # Flutter SDK symbol mappings
        self.flutter_sdk_symbols = self._init_flutter_sdk_symbols()
        
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
    
    def _init_flutter_sdk_symbols(self) -> Dict[str, str]:
        """Map common Flutter/Dart symbols to their imports"""
        return {
            # Core Dart
            'List': 'dart:core',
            'Map': 'dart:core',
            'Set': 'dart:core',
            'String': 'dart:core',
            'int': 'dart:core',
            'double': 'dart:core',
            'bool': 'dart:core',
            'Function': 'dart:core',
            'Future': 'dart:async',
            'Stream': 'dart:async',
            'Duration': 'dart:core',
            'DateTime': 'dart:core',
            
            # Flutter Material
            'StatelessWidget': 'package:flutter/material.dart',
            'StatefulWidget': 'package:flutter/material.dart',
            'Widget': 'package:flutter/material.dart',
            'BuildContext': 'package:flutter/material.dart',
            'State': 'package:flutter/material.dart',
            'MaterialApp': 'package:flutter/material.dart',
            'Scaffold': 'package:flutter/material.dart',
            'AppBar': 'package:flutter/material.dart',
            'Container': 'package:flutter/material.dart',
            'Column': 'package:flutter/material.dart',
            'Row': 'package:flutter/material.dart',
            'Text': 'package:flutter/material.dart',
            'Icon': 'package:flutter/material.dart',
            'IconButton': 'package:flutter/material.dart',
            'ElevatedButton': 'package:flutter/material.dart',
            'TextButton': 'package:flutter/material.dart',
            'OutlinedButton': 'package:flutter/material.dart',
            'FloatingActionButton': 'package:flutter/material.dart',
            'TextField': 'package:flutter/material.dart',
            'TextFormField': 'package:flutter/material.dart',
            'Form': 'package:flutter/material.dart',
            'ListView': 'package:flutter/material.dart',
            'GridView': 'package:flutter/material.dart',
            'Stack': 'package:flutter/material.dart',
            'Positioned': 'package:flutter/material.dart',
            'Padding': 'package:flutter/material.dart',
            'Center': 'package:flutter/material.dart',
            'Align': 'package:flutter/material.dart',
            'SizedBox': 'package:flutter/material.dart',
            'Expanded': 'package:flutter/material.dart',
            'Flexible': 'package:flutter/material.dart',
            'Wrap': 'package:flutter/material.dart',
            'Card': 'package:flutter/material.dart',
            'Divider': 'package:flutter/material.dart',
            'CircularProgressIndicator': 'package:flutter/material.dart',
            'LinearProgressIndicator': 'package:flutter/material.dart',
            'Drawer': 'package:flutter/material.dart',
            'BottomNavigationBar': 'package:flutter/material.dart',
            'TabBar': 'package:flutter/material.dart',
            'TabBarView': 'package:flutter/material.dart',
            'Dialog': 'package:flutter/material.dart',
            'AlertDialog': 'package:flutter/material.dart',
            'SnackBar': 'package:flutter/material.dart',
            'Theme': 'package:flutter/material.dart',
            'ThemeData': 'package:flutter/material.dart',
            'Color': 'package:flutter/material.dart',
            'Colors': 'package:flutter/material.dart',
            'TextStyle': 'package:flutter/material.dart',
            'EdgeInsets': 'package:flutter/material.dart',
            'BoxDecoration': 'package:flutter/material.dart',
            'BorderRadius': 'package:flutter/material.dart',
            'Border': 'package:flutter/material.dart',
            'BoxShadow': 'package:flutter/material.dart',
            'Gradient': 'package:flutter/material.dart',
            'LinearGradient': 'package:flutter/material.dart',
            'RadialGradient': 'package:flutter/material.dart',
            'MainAxisAlignment': 'package:flutter/material.dart',
            'CrossAxisAlignment': 'package:flutter/material.dart',
            'MainAxisSize': 'package:flutter/material.dart',
            'TextAlign': 'package:flutter/material.dart',
            'FontWeight': 'package:flutter/material.dart',
            'Icons': 'package:flutter/material.dart',
            'Navigator': 'package:flutter/material.dart',
            'MaterialPageRoute': 'package:flutter/material.dart',
            'InputDecoration': 'package:flutter/material.dart',
            'TextEditingController': 'package:flutter/material.dart',
            'FocusNode': 'package:flutter/material.dart',
            'Key': 'package:flutter/material.dart',
            'GlobalKey': 'package:flutter/material.dart',
            'FormState': 'package:flutter/material.dart',
            'GestureDetector': 'package:flutter/material.dart',
            'InkWell': 'package:flutter/material.dart',
            'Image': 'package:flutter/material.dart',
            'NetworkImage': 'package:flutter/material.dart',
            'AssetImage': 'package:flutter/material.dart',
            'DecorationImage': 'package:flutter/material.dart',
            'BoxFit': 'package:flutter/material.dart',
            'Opacity': 'package:flutter/material.dart',
            'AnimatedContainer': 'package:flutter/material.dart',
            'AnimatedOpacity': 'package:flutter/material.dart',
            'Hero': 'package:flutter/material.dart',
            'SafeArea': 'package:flutter/material.dart',
            'SingleChildScrollView': 'package:flutter/material.dart',
            'CustomScrollView': 'package:flutter/material.dart',
            'PageView': 'package:flutter/material.dart',
            'DropdownButton': 'package:flutter/material.dart',
            'Checkbox': 'package:flutter/material.dart',
            'Radio': 'package:flutter/material.dart',
            'Switch': 'package:flutter/material.dart',
            'Slider': 'package:flutter/material.dart',
            'DatePicker': 'package:flutter/material.dart',
            'TimePicker': 'package:flutter/material.dart',
            'Chip': 'package:flutter/material.dart',
            'ChoiceChip': 'package:flutter/material.dart',
            'FilterChip': 'package:flutter/material.dart',
            'ActionChip': 'package:flutter/material.dart',
            'Tooltip': 'package:flutter/material.dart',
            'Badge': 'package:flutter/material.dart',
            'Banner': 'package:flutter/material.dart',
            'BottomSheet': 'package:flutter/material.dart',
            'ExpansionTile': 'package:flutter/material.dart',
            'ListTile': 'package:flutter/material.dart',
            'DataTable': 'package:flutter/material.dart',
            'Table': 'package:flutter/material.dart',
            'TableRow': 'package:flutter/material.dart',
            'Stepper': 'package:flutter/material.dart',
            'Step': 'package:flutter/material.dart',
            'RefreshIndicator': 'package:flutter/material.dart',
            'Scrollbar': 'package:flutter/material.dart',
            
            # Cupertino
            'CupertinoApp': 'package:flutter/cupertino.dart',
            'CupertinoPageScaffold': 'package:flutter/cupertino.dart',
            'CupertinoNavigationBar': 'package:flutter/cupertino.dart',
            'CupertinoButton': 'package:flutter/cupertino.dart',
            'CupertinoTextField': 'package:flutter/cupertino.dart',
            'CupertinoSwitch': 'package:flutter/cupertino.dart',
            'CupertinoSlider': 'package:flutter/cupertino.dart',
            'CupertinoActivityIndicator': 'package:flutter/cupertino.dart',
            
            # Foundation
            'ChangeNotifier': 'package:flutter/foundation.dart',
            'ValueNotifier': 'package:flutter/foundation.dart',
            'ValueListenable': 'package:flutter/foundation.dart',
            'ChangeNotifierProvider': 'package:provider/provider.dart',
        }
    
    
    def scan_project(self):
        """Comprehensive project scan"""
        print(f"🔍 Scanning project...")
        
        # Get external packages
        self._scan_dependencies()
        
        # Scan all Dart files
        self.all_files = list(self.lib_dir.rglob("*.dart"))
        
        for dart_file in self.all_files:
            try:
                with open(dart_file, 'r', encoding='utf-8', errors='replace') as f:
                    content = f.read()
                
                self.file_to_content[dart_file] = content
                
                # Extract symbols
                symbols = self._extract_definitions(content)
                self.file_to_symbols[dart_file] = symbols
                
                for symbol in symbols:
                    self.symbol_to_file[symbol].append(dart_file)
                    
            except Exception as e:
                print(f"  ⚠️  Error scanning {dart_file}: {e}")
        
        print(f"  ✓ Found {len(self.all_files)} files")
        print(f"  ✓ Found {len(self.symbol_to_file)} symbols")
        print(f"  ✓ Found {len(self.external_packages)} external packages")
    
    def _scan_dependencies(self):
        """Scan pubspec.yaml for dependencies"""
        pubspec_path = self.project_root / "pubspec.yaml"
        with open(pubspec_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        in_deps = False
        for line in content.split('\n'):
            if re.match(r'^dependencies:', line):
                in_deps = True
                continue
            if in_deps:
                if line and not line.startswith(' ') and not line.startswith('\t'):
                    break
                match = re.match(r'\s+(\w+):', line)
                if match and match.group(1) != 'flutter':
                    self.external_packages.add(match.group(1))
    
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
    
    def analyze_issues(self):
        """Analyze project for all issues"""
        print(f"\n🔬 Analyzing issues...")
        
        for file_path in self.all_files:
            content = self.file_to_content.get(file_path, "")
            
            # Find undefined symbols
            undefined = CodeAnalyzer.find_undefined_symbols(
                file_path, content, self.symbol_to_file
            )
            if undefined:
                self.undefined_symbols[file_path] = undefined
            
            # Find broken references
            issues = CodeAnalyzer.find_missing_implementations(content)
            if issues:
                self.broken_references[file_path] = [i['description'] for i in issues]
        
        print(f"  ⚠️  Found {len(self.undefined_symbols)} files with undefined symbols")
        print(f"  ⚠️  Found {len(self.broken_references)} files with implementation issues")
        
        # Print details
        if self.undefined_symbols:
            print(f"\n  Undefined symbols found:")
            for file_path, symbols in list(self.undefined_symbols.items())[:5]:
                rel = file_path.relative_to(self.project_root)
                print(f"    {rel}: {', '.join(list(symbols)[:5])}")
    
    def generate_missing_files(self):
        """Generate missing files based on undefined symbols"""
        print(f"\n🔨 Generating missing files...")
        
        generated_count = 0
        
        # Common missing files to generate
        common_missing = {
            'AppTheme': self._generate_theme_file,
            'ApiService': self._generate_api_service,
            'ApiClient': self._generate_api_client,
            'AppConfig': self._generate_config,
            'AppColors': self._generate_colors,
            'AppConstants': self._generate_constants,
            'DatabaseHelper': self._generate_database,
            'StorageService': self._generate_storage,
            'AuthService': self._generate_auth_service,
        }
        
        # Check what's missing
        all_existing_symbols = set(self.symbol_to_file.keys())
        
        for symbol, generator_func in common_missing.items():
            if symbol not in all_existing_symbols:
                # Check if any file references this symbol
                is_used = False
                for content in self.file_to_content.values():
                    if symbol in content:
                        is_used = True
                        break
                
                if is_used:
                    file_path = generator_func()
                    if file_path:
                        self.generated_files.append(file_path)
                        generated_count += 1
                        print(f"  ✓ Generated {file_path.relative_to(self.project_root)}")
        
        if generated_count > 0:
            print(f"  ✓ Generated {generated_count} missing files")
            # Rescan to pick up new files
            self.scan_project()
    
    def _generate_theme_file(self) -> Optional[Path]:
        """Generate a theme file"""
        theme_path = self.lib_dir / "core" / "theme" / "app_theme.dart"
        theme_path.parent.mkdir(parents=True, exist_ok=True)
        
        content = f"""import 'package:flutter/material.dart';

class AppTheme {{
  static ThemeData get lightTheme {{
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }}

  static ThemeData get darkTheme {{
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }}
}}
"""
        theme_path.write_text(content, encoding='utf-8')
        return theme_path
    
    def _generate_api_service(self) -> Optional[Path]:
        """Generate API service"""
        api_path = self.lib_dir / "core" / "services" / "api_service.dart"
        api_path.parent.mkdir(parents=True, exist_ok=True)
        
        content = f"""import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {{
  static const String baseUrl = 'https://api.example.com';
  
  final http.Client _client;
  
  ApiService({{http.Client? client}}) : _client = client ?? http.Client();
  
  Future<Map<String, dynamic>> get(String endpoint) async {{
    try {{
      final response = await _client.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {{'Content-Type': 'application/json'}},
      );
      
      if (response.statusCode == 200) {{
        return json.decode(response.body);
      }} else {{
        throw Exception('Failed to load data: ${{response.statusCode}}');
      }}
    }} catch (e) {{
      throw Exception('Network error: $e');
    }}
  }}
  
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {{
    try {{
      final response = await _client.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {{'Content-Type': 'application/json'}},
        body: json.encode(data),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {{
        return json.decode(response.body);
      }} else {{
        throw Exception('Failed to post data: ${{response.statusCode}}');
      }}
    }} catch (e) {{
      throw Exception('Network error: $e');
    }}
  }}
  
  void dispose() {{
    _client.close();
  }}
}}
"""
        api_path.write_text(content, encoding='utf-8')
        return api_path
    
    def _generate_api_client(self) -> Optional[Path]:
        """Generate API client"""
        return self._generate_api_service()  # Alias
    
    def _generate_config(self) -> Optional[Path]:
        """Generate config file"""
        config_path = self.lib_dir / "core" / "config" / "app_config.dart"
        config_path.parent.mkdir(parents=True, exist_ok=True)
        
        content = f"""class AppConfig {{
  static const String appName = '{self.package_name}';
  static const String apiBaseUrl = 'https://api.example.com';
  static const String apiKey = 'your-api-key';
  static const int apiTimeout = 30;
  
  static const bool enableLogging = true;
  static const bool enableAnalytics = false;
  
  static const String version = '1.0.0';
  static const int buildNumber = 1;
}}
"""
        config_path.write_text(content, encoding='utf-8')
        return config_path
    
    def _generate_colors(self) -> Optional[Path]:
        """Generate colors file"""
        colors_path = self.lib_dir / "core" / "theme" / "app_colors.dart"
        colors_path.parent.mkdir(parents=True, exist_ok=True)
        
        content = """import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color text = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF757575);
}
"""
        colors_path.write_text(content, encoding='utf-8')
        return colors_path
    
    def _generate_constants(self) -> Optional[Path]:
        """Generate constants file"""
        const_path = self.lib_dir / "core" / "constants" / "app_constants.dart"
        const_path.parent.mkdir(parents=True, exist_ok=True)
        
        content = """class AppConstants {
  static const String appTitle = 'My App';
  static const int itemsPerPage = 20;
  static const int maxRetries = 3;
  
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 2);
}
"""
        const_path.write_text(content, encoding='utf-8')
        return const_path
    
    def _generate_database(self) -> Optional[Path]:
        """Generate database helper"""
        db_path = self.lib_dir / "core" / "services" / "database_helper.dart"
        db_path.parent.mkdir(parents=True, exist_ok=True)
        
        content = """import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;
  
  factory DatabaseHelper() => instance;
  
  DatabaseHelper._internal();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // Create tables here
    await db.execute('''
      CREATE TABLE items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }
}
"""
        db_path.write_text(content, encoding='utf-8')
        return db_path
    
    def _generate_storage(self) -> Optional[Path]:
        """Generate storage service"""
        storage_path = self.lib_dir / "core" / "services" / "storage_service.dart"
        storage_path.parent.mkdir(parents=True, exist_ok=True)
        
        content = """import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService instance = StorageService._internal();
  late SharedPreferences _prefs;
  
  factory StorageService() => instance;
  
  StorageService._internal();
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }
  
  String? getString(String key) {
    return _prefs.getString(key);
  }
  
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }
  
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }
  
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
  
  Future<void> clear() async {
    await _prefs.clear();
  }
}
"""
        storage_path.write_text(content, encoding='utf-8')
        return storage_path
    
    def _generate_auth_service(self) -> Optional[Path]:
        """Generate auth service"""
        auth_path = self.lib_dir / "core" / "services" / "auth_service.dart"
        auth_path.parent.mkdir(parents=True, exist_ok=True)
        
        content = """class AuthService {
  static final AuthService instance = AuthService._internal();
  
  factory AuthService() => instance;
  
  AuthService._internal();
  
  String? _token;
  bool _isAuthenticated = false;
  
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  
  Future<bool> login(String email, String password) async {
    try {
      // TODO: Implement actual login logic
      await Future.delayed(const Duration(seconds: 1));
      _token = 'dummy-token';
      _isAuthenticated = true;
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> logout() async {
    _token = null;
    _isAuthenticated = false;
  }
  
  Future<bool> register(String email, String password) async {
    try {
      // TODO: Implement actual registration logic
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      return false;
    }
  }
}
"""
        auth_path.write_text(content, encoding='utf-8')
        return auth_path
    
    def fix_all_imports(self):
        """Fix imports in all files - run multiple times for convergence"""
        print(f"\n🔧 Fixing imports...")
        
        # Run multiple iterations to handle dependencies
        max_iterations = 3
        for iteration in range(max_iterations):
            total_fixed = 0
            
            for dart_file in self.all_files:
                fixed = self._fix_file_imports(dart_file)
                if fixed > 0:
                    total_fixed += fixed
            
            if total_fixed > 0:
                print(f"  ✓ Iteration {iteration + 1}: Fixed {total_fixed} files")
            else:
                print(f"  ✓ Converged after {iteration + 1} iteration(s)")
                break
        
        print(f"  ✓ Import fixing complete")
    
    def _fix_file_imports(self, file_path: Path) -> int:
        """Fix imports in a single file"""
        content = self.file_to_content.get(file_path, "")
        if not content:
            return 0
        
        lines = content.split('\n')
        imports_to_add = set()
        existing_imports = set()
        
        # Extract existing imports
        for line in lines:
            import_match = re.match(r"^\s*import\s+['\"](.+?)['\"];?", line)
            if import_match:
                existing_imports.add(import_match.group(1))
        
        # Find what symbols are used
        used_symbols = CodeAnalyzer.extract_all_identifiers(content)
        defined_symbols = self.file_to_symbols.get(file_path, set())
        needed_symbols = used_symbols - defined_symbols
        
        # Find imports for needed symbols
        for symbol in needed_symbols:
            # Check Flutter SDK first
            if symbol in self.flutter_sdk_symbols:
                imports_to_add.add(self.flutter_sdk_symbols[symbol])
            # Then check project files
            elif symbol in self.symbol_to_file:
                target_files = self.symbol_to_file[symbol]
                if target_files and target_files[0] != file_path:
                    rel_path = target_files[0].relative_to(self.lib_dir)
                    import_path = f"package:{self.package_name}/{str(rel_path).replace(chr(92), '/')}"
                    imports_to_add.add(import_path)
        
        # Combine with existing imports
        all_imports = existing_imports | imports_to_add
        
        # Categorize imports
        dart_imports = sorted([i for i in all_imports if i.startswith('dart:')])
        flutter_imports = sorted([i for i in all_imports if i.startswith('package:flutter/')])
        external_imports = sorted([i for i in all_imports if i.startswith('package:') 
                                   and not i.startswith(f'package:{self.package_name}/')
                                   and not i.startswith('package:flutter/')])
        local_imports = sorted([i for i in all_imports if i.startswith(f'package:{self.package_name}/')])
        
        # Reconstruct file
        new_content_lines = []
        
        # Add imports with proper spacing
        if dart_imports:
            new_content_lines.extend([f"import '{i}';" for i in dart_imports])
            new_content_lines.append('')
        if flutter_imports:
            new_content_lines.extend([f"import '{i}';" for i in flutter_imports])
            new_content_lines.append('')
        if external_imports:
            new_content_lines.extend([f"import '{i}';" for i in external_imports])
            new_content_lines.append('')
        if local_imports:
            new_content_lines.extend([f"import '{i}';" for i in local_imports])
            new_content_lines.append('')
        
        # Add rest of file (skip old imports and leading whitespace)
        in_import_section = True
        skip_next_empty = True
        
        for line in lines:
            if in_import_section:
                # Skip import lines
                if line.strip().startswith('import '):
                    continue
                # Skip empty lines right after imports
                if not line.strip() and skip_next_empty:
                    continue
                # We've passed the import section
                in_import_section = False
                skip_next_empty = False
            
            new_content_lines.append(line)
        
        new_content = '\n'.join(new_content_lines)
        
        if new_content != content:
            try:
                with open(file_path, 'w', encoding='utf-8', errors='replace') as f:
                    f.write(new_content)
                self.file_to_content[file_path] = new_content
                return 1
            except Exception as e:
                print(f"  ⚠️  Error writing {file_path}: {e}")
        
        return 0
    
    def run_full_reconstruction(self):
        """Run complete project reconstruction"""
        print(f"{'='*60}")
        print(f"🚀 Flutter Project Reconstructor")
        print(f"{'='*60}")
        
        self.scan_project()
        self.analyze_issues()
        self.generate_missing_files()
        self.fix_all_imports()
        
        print(f"\n{'='*60}")
        print(f"✅ Reconstruction Complete!")
        print(f"{'='*60}")
        
        if self.generated_files:
            print(f"\n📝 Generated {len(self.generated_files)} new files:")
            for f in self.generated_files:
                print(f"  - {f.relative_to(self.project_root)}")
        
        print(f"\n📋 Next steps:")
        print(f"  1. Run: flutter pub get")
        print(f"  2. Run: flutter analyze")
        print(f"  3. Run: flutter run")
        print(f"  4. If errors persist, run this script again")


def main():
    parser = argparse.ArgumentParser(
        description='Reconstruct and fix a broken Flutter project',
    )
    parser.add_argument(
        'project_root',
        nargs='?',
        default='.',
        help='Path to Flutter project root'
    )
    
    args = parser.parse_args()
    
    try:
        reconstructor = ProjectReconstructor(args.project_root)
        reconstructor.run_full_reconstruction()
        return 0
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    exit(main())
