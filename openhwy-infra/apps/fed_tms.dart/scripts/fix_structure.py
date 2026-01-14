import os
import shutil
import re
from pathlib import Path
from typing import Dict, List, Set, Tuple

class FlutterRestructure:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.lib_path = self.project_root / "lib"
        self.backup_path = self.project_root / "lib_backup"
        
        # Feature mapping - maps old files to new feature locations
        self.feature_mapping = {
            'auth': {
                'screens': ['login_screen.dart', 'onboarding_screen.dart', 'splash_screen.dart'],
                'services': ['auth_service.dart'],
                'providers': ['auth_provider.dart'],
                'models': ['user.dart', 'user.g.dart'],
                'widgets': []
            },
            'loads': {
                'screens': [
                    'loadboard_screen.dart', 'load_detail_screen.dart', 
                    'load_details_screen.dart', 'loads_list_screen.dart',
                    'loads_screen.dart', 'create_load_screen.dart', 'tracking_screen.dart'
                ],
                'services': ['load_service.dart'],
                'providers': ['load_provider.dart'],
                'models': ['load.dart'],
                'widgets': ['load_card.dart', 'load_status_badge.dart', 'tms_load_card.dart', 'rate_confirmation_form.dart']
            },
            'drivers': {
                'screens': [
                    'drivers_screen.dart', 'driver_details_screen.dart',
                    'hos_screen.dart', 'hos_tracking_screen.dart', 'eld_screen.dart'
                ],
                'services': ['driver_service.dart'],
                'providers': ['driver_provider.dart'],
                'models': ['driver.dart'],
                'widgets': ['driver_card.dart', 'driver_detail_card.dart']
            },
            'invoicing': {
                'screens': [
                    'invoices_screen.dart', 'invoicing_screen.dart',
                    'invoices_list_screen.dart', 'invoice_details_screen.dart',
                    'payments_screen.dart'
                ],
                'services': ['invoice_service.dart', 'payment_service.dart'],
                'providers': ['invoice_provider.dart', 'payment_provider.dart'],
                'models': ['invoice.dart', 'invoice.g.dart', 'payment.dart', 'payment.g.dart'],
                'widgets': []
            },
            'messaging': {
                'screens': ['messages_screen.dart', 'messaging_screen.dart'],
                'services': ['message_service.dart'],
                'providers': ['message_provider.dart'],
                'models': ['message.dart', 'message.g.dart', 'conversation.dart', 'conversation.g.dart'],
                'widgets': []
            },
            'documents': {
                'screens': ['documents_screen.dart', 'documents_manager_screen.dart'],
                'services': ['document_service.dart', 'cloud_storage_service.dart'],
                'providers': ['document_provider.dart'],
                'models': ['document.dart', 'document.g.dart'],
                'widgets': []
            },
            'analytics': {
                'screens': ['analytics_screen.dart', 'reports_screen.dart'],
                'services': [],
                'providers': [],
                'models': [],
                'widgets': []
            },
            'compliance': {
                'screens': ['courses_screen.dart', 'training_screen.dart'],
                'services': [],
                'providers': [],
                'models': [],
                'widgets': ['video_card.dart']
            },
            'dashboard': {
                'screens': ['dashboard_screen.dart'],
                'services': [],
                'providers': [],
                'models': [],
                'widgets': ['app_stat_card.dart', 'setup_card.dart']
            },
            'calendar': {
                'screens': ['calendar_screen.dart', 'calendar_dispatch_screen.dart'],
                'services': [],
                'providers': [],
                'models': [],
                'widgets': []
            },
            'notifications': {
                'screens': ['notifications_screen.dart'],
                'services': [],
                'providers': [],
                'models': [],
                'widgets': ['notification_tile.dart']
            },
            'settings': {
                'screens': ['settings_screen.dart', 'settings_main_screen.dart', 'profile_screen.dart'],
                'services': [],
                'providers': ['user_provider.dart'],
                'models': [],
                'widgets': []
            },
            'company': {
                'screens': ['company_screen.dart'],
                'services': [],
                'providers': [],
                'models': ['company.dart', 'company.g.dart'],
                'widgets': []
            }
        }
        
        # Core services that stay in core
        self.core_services = [
            'api_client.dart', 'http_client.dart', 'storage_service.dart',
            'logger_service.dart', 'local_storage_service.dart', 'database_service.dart'
        ]
        
        # Core widgets that stay in core
        self.core_widgets = [
            'app_button.dart', 'app_card.dart', 'app_drawer.dart',
            'app_empty_state.dart', 'app_icon.dart', 'app_loader.dart',
            'app_search_bar.dart', 'app_text_field.dart', 'detail_card.dart',
            'main_navigation.dart'
        ]
        
        # Track all file movements for import updates
        self.file_movements: Dict[str, str] = {}
        
    def backup_project(self):
        """Create a backup of the lib folder"""
        print("📦 Creating backup...")
        if self.backup_path.exists():
            shutil.rmtree(self.backup_path)
        shutil.copytree(self.lib_path, self.backup_path)
        print("✅ Backup created at lib_backup/")
    
    def create_new_structure(self):
        """Create the new directory structure"""
        print("\n🏗️  Creating new directory structure...")
        
        # Create core directories
        core_dirs = [
            'core/configs',
            'core/errors',
            'core/router',
            'core/services',
            'core/styles',
            'core/widgets',
        ]
        
        for dir_path in core_dirs:
            (self.lib_path / dir_path).mkdir(parents=True, exist_ok=True)
            print(f"  ✓ Created {dir_path}")
        
        # Create feature directories
        for feature in self.feature_mapping.keys():
            feature_dirs = [
                f'features/{feature}/data/models',
                f'features/{feature}/data/services',
                f'features/{feature}/providers',
                f'features/{feature}/presentation/screens',
                f'features/{feature}/presentation/widgets',
            ]
            
            for dir_path in feature_dirs:
                (self.lib_path / dir_path).mkdir(parents=True, exist_ok=True)
            
            print(f"  ✓ Created features/{feature}/")
    
    def move_files(self):
        """Move files to their new locations"""
        print("\n📁 Moving files...")
        
        # Move core configs
        self._move_directory('configs', 'core/configs')
        
        # Move core errors
        self._move_directory('errors', 'core/errors')
        
        # Move core styles
        self._move_directory('styles', 'core/styles')
        
        # Move router
        self._move_file('router.dart', 'core/router/router.dart')
        
        # Move core services
        for service in self.core_services:
            self._move_file(f'services/{service}', f'core/services/{service}')
        
        # Move core widgets
        for widget in self.core_widgets:
            self._move_file(f'widgets/{widget}', f'core/widgets/{widget}')
        
        # Move feature-specific files
        for feature, files in self.feature_mapping.items():
            # Move screens
            for screen in files['screens']:
                self._move_file(
                    f'screens/{screen}',
                    f'features/{feature}/presentation/screens/{screen}'
                )
            
            # Move services
            for service in files['services']:
                self._move_file(
                    f'services/{service}',
                    f'features/{feature}/data/services/{service}'
                )
            
            # Move providers
            for provider in files['providers']:
                self._move_file(
                    f'providers/{provider}',
                    f'features/{feature}/providers/{provider}'
                )
            
            # Move models
            for model in files['models']:
                self._move_file(
                    f'models/{model}',
                    f'features/{feature}/data/models/{model}'
                )
            
            # Move widgets
            for widget in files['widgets']:
                self._move_file(
                    f'widgets/{widget}',
                    f'features/{feature}/presentation/widgets/{widget}'
                )
        
        # Move remaining provider files to core
        self._move_remaining_files('providers', 'core/providers')
        
        # Move tms_models.dart and tms_providers.dart to core
        if (self.lib_path / 'models/tms_models.dart').exists():
            self._move_file('models/tms_models.dart', 'core/models/tms_models.dart')
        if (self.lib_path / 'providers/tms_providers.dart').exists():
            self._move_file('providers/tms_providers.dart', 'core/providers/tms_providers.dart')
        if (self.lib_path / 'providers/app_providers.dart').exists():
            self._move_file('providers/app_providers.dart', 'core/providers/app_providers.dart')
        
        print("\n✅ All files moved!")
    
    def _move_file(self, old_path: str, new_path: str):
        """Move a single file and track the movement"""
        old_full = self.lib_path / old_path
        new_full = self.lib_path / new_path
        
        if old_full.exists():
            new_full.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(old_full), str(new_full))
            
            # Track movement for import updates
            old_import = old_path.replace('/', '/').replace('.dart', '')
            new_import = new_path.replace('/', '/').replace('.dart', '')
            self.file_movements[old_import] = new_import
            
            print(f"  ✓ Moved {old_path} → {new_path}")
    
    def _move_directory(self, old_dir: str, new_dir: str):
        """Move entire directory"""
        old_full = self.lib_path / old_dir
        new_full = self.lib_path / new_dir
        
        if old_full.exists():
            new_full.parent.mkdir(parents=True, exist_ok=True)
            if new_full.exists():
                shutil.rmtree(new_full)
            shutil.move(str(old_full), str(new_full))
            print(f"  ✓ Moved directory {old_dir}/ → {new_dir}/")
            
            # Track all files in directory
            for file in new_full.rglob('*.dart'):
                rel_old = old_dir + '/' + str(file.relative_to(new_full))
                rel_new = new_dir + '/' + str(file.relative_to(new_full))
                old_import = rel_old.replace('.dart', '')
                new_import = rel_new.replace('.dart', '')
                self.file_movements[old_import] = new_import
    
    def _move_remaining_files(self, old_dir: str, new_dir: str):
        """Move any remaining files from a directory"""
        old_full = self.lib_path / old_dir
        
        if old_full.exists():
            for file in old_full.glob('*.dart'):
                new_path = f"{new_dir}/{file.name}"
                self._move_file(f"{old_dir}/{file.name}", new_path)
    
    def update_imports(self):
        """Update all import statements in all Dart files"""
        print("\n🔄 Updating imports...")
        
        dart_files = list(self.lib_path.rglob('*.dart'))
        total_files = len(dart_files)
        updated_count = 0
        
        for i, dart_file in enumerate(dart_files, 1):
            if self._update_file_imports(dart_file):
                updated_count += 1
            
            # Progress indicator
            if i % 10 == 0:
                print(f"  Processing... {i}/{total_files} files")
        
        print(f"\n✅ Updated imports in {updated_count} files!")
    
    def _update_file_imports(self, file_path: Path) -> bool:
        """Update imports in a single file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Update package imports
            for old_path, new_path in self.file_movements.items():
                # Handle various import patterns
                patterns = [
                    (f"import 'package:fed_tms/{old_path}.dart'", f"import 'package:fed_tms/{new_path}.dart'"),
                    (f'import "package:fed_tms/{old_path}.dart"', f'import "package:fed_tms/{new_path}.dart"'),
                    (f"from '{old_path}.dart'", f"from '{new_path}.dart'"),
                    (f'from "{old_path}.dart"', f'from "{new_path}.dart"'),
                ]
                
                for old_pattern, new_pattern in patterns:
                    content = content.replace(old_pattern, new_pattern)
            
            # Update relative imports if the file itself moved
            content = self._fix_relative_imports(file_path, content)
            
            # Only write if content changed
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                return True
            
            return False
            
        except Exception as e:
            print(f"  ⚠️  Error updating {file_path}: {e}")
            return False
    
    def _fix_relative_imports(self, file_path: Path, content: str) -> str:
        """Fix relative imports based on new file location"""
        # This is a simplified version - you might need to enhance this
        # based on your specific relative import patterns
        return content
    
    def create_barrel_files(self):
        """Create barrel files (index.dart) for easier imports"""
        print("\n📦 Creating barrel files...")
        
        # Create barrel file for each feature
        for feature in self.feature_mapping.keys():
            feature_path = self.lib_path / 'features' / feature
            
            # Data models barrel
            models_path = feature_path / 'data/models'
            if models_path.exists() and any(models_path.glob('*.dart')):
                self._create_barrel(models_path)
            
            # Providers barrel
            providers_path = feature_path / 'providers'
            if providers_path.exists() and any(providers_path.glob('*.dart')):
                self._create_barrel(providers_path)
            
            # Presentation widgets barrel
            widgets_path = feature_path / 'presentation/widgets'
            if widgets_path.exists() and any(widgets_path.glob('*.dart')):
                self._create_barrel(widgets_path)
        
        # Create core barrels
        core_widgets_path = self.lib_path / 'core/widgets'
        if core_widgets_path.exists():
            self._create_barrel(core_widgets_path)
        
        print("✅ Barrel files created!")
    
    def _create_barrel(self, directory: Path):
        """Create a barrel file (index.dart) in a directory"""
        dart_files = [f for f in directory.glob('*.dart') if f.name != 'index.dart']
        
        if not dart_files:
            return
        
        barrel_content = "// Auto-generated barrel file\n\n"
        for dart_file in sorted(dart_files):
            barrel_content += f"export '{dart_file.name}';\n"
        
        barrel_path = directory / 'index.dart'
        with open(barrel_path, 'w', encoding='utf-8') as f:
            f.write(barrel_content)
        
        print(f"  ✓ Created barrel at {directory.relative_to(self.lib_path)}/index.dart")
    
    def cleanup_empty_directories(self):
        """Remove empty directories from the old structure"""
        print("\n🧹 Cleaning up empty directories...")
        
        old_dirs = ['screens', 'services', 'providers', 'models', 'widgets']
        
        for dir_name in old_dirs:
            dir_path = self.lib_path / dir_name
            if dir_path.exists() and not any(dir_path.iterdir()):
                shutil.rmtree(dir_path)
                print(f"  ✓ Removed empty {dir_name}/")
    
    def create_readme(self):
        """Create README files explaining the new structure"""
        print("\n📝 Creating README files...")
        
        # Main architecture README
        main_readme = """# TMS Flutter App Architecture

## Structure Overview

This project follows a **feature-first architecture** with clear separation of concerns.

### Directory Structure
```
lib/
├── core/                 # Shared code across all features
│   ├── configs/         # App configuration
│   ├── errors/          # Error handling
│   ├── router/          # Navigation/routing
│   ├── services/        # Shared services (API, storage, etc.)
│   ├── styles/          # Theme and typography
│   └── widgets/         # Reusable UI components
│
├── features/            # Feature modules
│   ├── auth/           # Authentication
│   ├── loads/          # Load management
│   ├── drivers/        # Driver management
│   ├── invoicing/      # Invoicing & payments
│   ├── messaging/      # Messaging system
│   ├── documents/      # Document management
│   ├── analytics/      # Analytics & reports
│   ├── compliance/     # Compliance & training
│   ├── dashboard/      # Dashboard
│   ├── calendar/       # Calendar & scheduling
│   ├── notifications/  # Notifications
│   ├── settings/       # Settings & profile
│   └── company/        # Company management
│
└── main.dart
```

### Feature Structure

Each feature follows this internal structure:
```
feature_name/
├── data/
│   ├── models/         # Data models
│   └── services/       # Feature-specific services
├── providers/          # State management (Riverpod)
└── presentation/
    ├── screens/        # UI screens
    └── widgets/        # Feature-specific widgets
```

### Key Principles

1. **Feature Independence**: Each feature is self-contained
2. **Clear Boundaries**: Core vs Feature code is separated
3. **Easy Testing**: Features can be tested in isolation
4. **Scalability**: Easy to add/remove features
5. **Team Collaboration**: Multiple developers can work on different features

### Import Guidelines

- Use barrel files (index.dart) for cleaner imports
- Import from `package:fed_tms/` for all internal imports
- Keep feature imports within their own feature when possible

### Adding New Features

1. Create feature directory under `features/`
2. Follow the standard feature structure
3. Add routes to `core/router/router.dart`
4. Register providers if needed
5. Create barrel files for exports
"""
        
        readme_path = self.lib_path / 'README.md'
        with open(readme_path, 'w', encoding='utf-8') as f:
            f.write(main_readme)
        
        print(f"  ✓ Created {readme_path.relative_to(self.project_root)}")
    
    def run(self):
        """Execute the full restructuring process"""
        print("=" * 60)
        print("🚀 TMS Flutter Project Restructuring")
        print("=" * 60)
        
        try:
            # Step 1: Backup
            self.backup_project()
            
            # Step 2: Create new structure
            self.create_new_structure()
            
            # Step 3: Move files
            self.move_files()
            
            # Step 4: Update imports
            self.update_imports()
            
            # Step 5: Create barrel files
            self.create_barrel_files()
            
            # Step 6: Cleanup
            self.cleanup_empty_directories()
            
            # Step 7: Documentation
            self.create_readme()
            
            print("\n" + "=" * 60)
            print("✨ RESTRUCTURING COMPLETE! ✨")
            print("=" * 60)
            print("\n📋 Next Steps:")
            print("  1. Run: flutter pub get")
            print("  2. Run: flutter clean")
            print("  3. Run: flutter pub run build_runner build --delete-conflicting-outputs")
            print("  4. Test the app thoroughly")
            print("  5. If issues arise, restore from lib_backup/")
            print("\n💡 Tip: Check lib/README.md for architecture details")
            print("\n" + "=" * 60)
            
        except Exception as e:
            print(f"\n❌ Error during restructuring: {e}")
            print("💡 Restore from lib_backup/ if needed")
            raise

def main():
    """Main entry point"""
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python restructure.py <path_to_flutter_project>")
        print("Example: python restructure.py /Users/me/projects/fed_tms")
        sys.exit(1)
    
    project_path = sys.argv[1]
    
    if not os.path.exists(project_path):
        print(f"❌ Error: Project path does not exist: {project_path}")
        sys.exit(1)
    
    lib_path = os.path.join(project_path, 'lib')
    if not os.path.exists(lib_path):
        print(f"❌ Error: lib/ directory not found in {project_path}")
        sys.exit(1)
    
    print(f"\n📍 Project: {project_path}")
    response = input("\n⚠️  This will restructure your project. Continue? (yes/no): ")
    
    if response.lower() != 'yes':
        print("❌ Aborted")
        sys.exit(0)
    
    restructure = FlutterRestructure(project_path)
    restructure.run()

if __name__ == "__main__":
    main()
