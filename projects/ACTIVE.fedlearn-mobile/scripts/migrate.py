#!/usr/bin/env python3
"""
FedLearn TMS - Project Reorganization Script
Migrates existing flat structure to feature-first clean architecture
"""

import os
import shutil
from pathlib import Path
from typing import Dict, List

# Color codes for terminal output
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def print_header(msg):
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{msg}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.ENDC}\n")

def print_success(msg):
    print(f"{Colors.OKGREEN}✓ {msg}{Colors.ENDC}")

def print_warning(msg):
    print(f"{Colors.WARNING}⚠ {msg}{Colors.ENDC}")

def print_error(msg):
    print(f"{Colors.FAIL}✗ {msg}{Colors.ENDC}")

def print_info(msg):
    print(f"{Colors.OKCYAN}→ {msg}{Colors.ENDC}")

# Define the new structure
NEW_STRUCTURE = {
    'core': [
        'core/config',
        'core/theme',
        'core/constants',
        'core/utils',
        'core/errors',
        'core/services',
    ],
    'features': {
        'auth': ['data/models', 'data/repositories', 'data/datasources', 
                 'domain/entities', 'domain/repositories', 'domain/usecases',
                 'presentation/providers', 'presentation/screens', 'presentation/widgets'],
        'onboarding': ['data/models', 'data/repositories', 'domain/entities', 
                      'domain/repositories', 'domain/usecases',
                      'presentation/providers', 'presentation/screens', 'presentation/widgets'],
        'dashboard': ['data/models', 'data/repositories', 'domain/entities',
                     'domain/repositories', 'domain/usecases',
                     'presentation/providers', 'presentation/screens', 'presentation/widgets'],
        'loads': ['data/models', 'data/repositories', 'data/datasources',
                 'domain/entities', 'domain/repositories', 'domain/usecases',
                 'presentation/providers', 'presentation/screens', 'presentation/widgets'],
        'drivers': ['data/models', 'data/repositories', 'data/datasources',
                   'domain/entities', 'domain/repositories', 'domain/usecases',
                   'presentation/providers', 'presentation/screens', 'presentation/widgets'],
        'dispatch': ['data/models', 'data/repositories', 'domain/entities',
                    'domain/repositories', 'domain/usecases',
                    'presentation/providers', 'presentation/screens', 'presentation/widgets'],
        'compliance': ['data/models', 'data/repositories', 'data/datasources',
                      'domain/entities', 'domain/repositories', 'domain/usecases',
                      'presentation/providers', 'presentation/screens', 'presentation/widgets'],
        'invoicing': ['data/models', 'data/repositories', 'domain/entities',
                     'domain/repositories', 'domain/usecases',
                     'presentation/providers', 'presentation/screens', 'presentation/widgets'],
        'messaging': ['data/models', 'data/repositories', 'data/datasources',
                     'domain/entities', 'domain/repositories', 'domain/usecases',
                     'presentation/providers', 'presentation/screens', 'presentation/widgets'],
        'accounting': ['data/models', 'data/repositories', 'domain/entities',
                      'domain/repositories', 'domain/usecases',
                      'presentation/providers', 'presentation/screens', 'presentation/widgets'],
        'settings': ['data/models', 'data/repositories', 'domain/entities',
                    'domain/repositories', 'domain/usecases',
                    'presentation/providers', 'presentation/screens', 'presentation/widgets'],
        'training': ['data/models', 'data/repositories', 'data/datasources',
                    'domain/entities', 'domain/repositories', 'domain/usecases',
                    'presentation/providers', 'presentation/screens', 'presentation/widgets'],
        'gamification': ['data/models', 'data/repositories', 'data/datasources',
                        'domain/entities', 'domain/repositories', 'domain/usecases',
                        'presentation/providers', 'presentation/screens', 'presentation/widgets'],
        'ai_assistant': ['data/models', 'data/repositories', 'data/datasources',
                        'domain/entities', 'domain/repositories', 'domain/usecases',
                        'presentation/providers', 'presentation/screens', 'presentation/widgets'],
        'marketplace': ['data/models', 'data/repositories', 'data/datasources',
                       'domain/entities', 'domain/repositories', 'domain/usecases',
                       'presentation/providers', 'presentation/screens', 'presentation/widgets'],
        'iap': ['data/models', 'data/repositories', 'data/datasources',
               'domain/entities', 'domain/repositories', 'domain/usecases',
               'presentation/providers', 'presentation/screens', 'presentation/widgets'],
    },
    'shared': ['shared/widgets'],
}

# File migration mapping
FILE_MIGRATIONS = {
    # Core files
    'config/env.dart': 'core/config/env.dart',
    'config/zitadel_config.dart': 'core/config/zitadel_config.dart',
    'configs/env.dart': 'core/config/env.dart',
    'configs/flavors.dart': 'core/config/flavors.dart',
    'errors/exception.dart': 'core/errors/exceptions.dart',
    'errors/failure.dart': 'core/errors/failures.dart',
    
    # Theme files (consolidate)
    'styles/app_theme.dart': 'core/theme/app_theme.dart',
    'styles/colors.dart': 'core/theme/colors.dart',
    'styles/typography.dart': 'core/theme/typography.dart',
    'styles/theme.dart': 'core/theme/theme.dart',
    
    # Services
    'services/api_client.dart': 'core/services/api_client.dart',
    'services/http_client.dart': 'core/services/http_client.dart',
    'services/logger.dart': 'core/services/logger.dart',
    'services/local_storage_service.dart': 'core/services/local_storage_service.dart',
    'services/secure_storage_service.dart': 'core/services/secure_storage_service.dart',
    'services/cloud_storage_service.dart': 'core/services/cloud_storage_service.dart',
    'services/database_service.dart': 'core/services/database_service.dart',
    
    # Auth feature
    'models/user.dart': 'features/auth/data/models/user_model.dart',
    'providers/auth_provider.dart': 'features/auth/presentation/providers/auth_provider.dart',
    'services/auth_service.dart': 'features/auth/data/datasources/auth_remote_datasource.dart',
    'services/zitadel_auth_service.dart': 'features/auth/data/datasources/zitadel_auth_datasource.dart',
    'screens/auth/login_screen.dart': 'features/auth/presentation/screens/login_screen.dart',
    'screens/auth/home_screen.dart': 'features/auth/presentation/screens/home_screen.dart',
    
    # Onboarding feature
    'models/company.dart': 'features/onboarding/data/models/company_model.dart',
    'screens/onboarding/company_screen.dart': 'features/onboarding/presentation/screens/company_screen.dart',
    'pages/onboarding_page.dart': 'features/onboarding/presentation/screens/onboarding_page.dart',
    
    # Dashboard feature
    'screens/dashboard/dashboard_screen.dart': 'features/dashboard/presentation/screens/dashboard_screen.dart',
    'screens/dashboard/dashboardv2_screen.dart': 'features/dashboard/presentation/screens/dashboardv2_screen.dart',
    'screens/dashboard/analytics_screen.dart': 'features/dashboard/presentation/screens/analytics_screen.dart',
    'screens/dashboard/calendar_screen.dart': 'features/dashboard/presentation/screens/calendar_screen.dart',
    
    # Loads feature
    'models/load.dart': 'features/loads/data/models/load_model.dart',
    'providers/load_provider.dart': 'features/loads/presentation/providers/load_provider.dart',
    'services/load_service.dart': 'features/loads/data/datasources/load_remote_datasource.dart',
    'screens/dashboard/loads_screen.dart': 'features/loads/presentation/screens/loads_screen.dart',
    'screens/dashboard/loads_list_screen.dart': 'features/loads/presentation/screens/loads_list_screen.dart',
    'screens/dashboard/load_details_screen.dart': 'features/loads/presentation/screens/load_details_screen.dart',
    'screens/dashboard/load_detail_screen.dart': 'features/loads/presentation/screens/load_detail_screen.dart',
    'screens/dashboard/create_load_screen.dart': 'features/loads/presentation/screens/create_load_screen.dart',
    'screens/dashboard/loadboard_screen.dart': 'features/loads/presentation/screens/loadboard_screen.dart',
    'screens/dashboard/tracking_screen.dart': 'features/loads/presentation/screens/tracking_screen.dart',
    'widgets/load_card.dart': 'features/loads/presentation/widgets/load_card.dart',
    'widgets/load_status_badge.dart': 'features/loads/presentation/widgets/load_status_badge.dart',
    'widgets/rate_confirmation_form.dart': 'features/loads/presentation/widgets/rate_confirmation_form.dart',
    
    # Drivers feature
    'models/driver.dart': 'features/drivers/data/models/driver_model.dart',
    'providers/driver_provider.dart': 'features/drivers/presentation/providers/driver_provider.dart',
    'services/driver_service.dart': 'features/drivers/data/datasources/driver_remote_datasource.dart',
    'screens/dashboard/drivers_screen.dart': 'features/drivers/presentation/screens/drivers_screen.dart',
    'screens/dashboard/driver_details_screen.dart': 'features/drivers/presentation/screens/driver_details_screen.dart',
    'widgets/driver_card.dart': 'features/drivers/presentation/widgets/driver_card.dart',
    'widgets/driver_detail_card.dart': 'features/drivers/presentation/widgets/driver_detail_card.dart',
    
    # Dispatch feature
    'pages/dispatch_page.dart': 'features/dispatch/presentation/screens/dispatch_page.dart',
    'screens/dashboard/calendar_dispatch_screen.dart': 'features/dispatch/presentation/screens/calendar_dispatch_screen.dart',
    
    # Compliance feature
    'models/document.dart': 'features/compliance/data/models/document_model.dart',
    'providers/document_provider.dart': 'features/compliance/presentation/providers/document_provider.dart',
    'services/document_service.dart': 'features/compliance/data/datasources/document_remote_datasource.dart',
    'pages/compliance_page.dart': 'features/compliance/presentation/screens/compliance_page.dart',
    'screens/compliance/documents_screen.dart': 'features/compliance/presentation/screens/documents_screen.dart',
    'screens/compliance/documents_manager_screen.dart': 'features/compliance/presentation/screens/documents_manager_screen.dart',
    'screens/compliance/eld_screen.dart': 'features/compliance/presentation/screens/eld_screen.dart',
    'screens/compliance/hos_screen.dart': 'features/compliance/presentation/screens/hos_screen.dart',
    'screens/compliance/hos_tracking_screen.dart': 'features/compliance/presentation/screens/hos_tracking_screen.dart',
    'screens/compliance/reports_screen.dart': 'features/compliance/presentation/screens/reports_screen.dart',
    
    # Invoicing feature
    'models/invoice.dart': 'features/invoicing/data/models/invoice_model.dart',
    'models/payment.dart': 'features/invoicing/data/models/payment_model.dart',
    'providers/invoice_provider.dart': 'features/invoicing/presentation/providers/invoice_provider.dart',
    'providers/payment_provider.dart': 'features/invoicing/presentation/providers/payment_provider.dart',
    'services/invoice_service.dart': 'features/invoicing/data/datasources/invoice_remote_datasource.dart',
    'services/payment_service.dart': 'features/invoicing/data/datasources/payment_remote_datasource.dart',
    'screens/invocing/invoicing_screen.dart': 'features/invoicing/presentation/screens/invoicing_screen.dart',
    'screens/invocing/invoices_screen.dart': 'features/invoicing/presentation/screens/invoices_screen.dart',
    'screens/invocing/invoices_list_screen.dart': 'features/invoicing/presentation/screens/invoices_list_screen.dart',
    'screens/invocing/invoice_details_screen.dart': 'features/invoicing/presentation/screens/invoice_details_screen.dart',
    'screens/invocing/payments_screen.dart': 'features/invoicing/presentation/screens/payments_screen.dart',
    
    # Messaging feature
    'models/message.dart': 'features/messaging/data/models/message_model.dart',
    'providers/message_provider.dart': 'features/messaging/presentation/providers/message_provider.dart',
    'services/message_service.dart': 'features/messaging/data/datasources/message_remote_datasource.dart',
    'screens/messaging/messaging_screen.dart': 'features/messaging/presentation/screens/messaging_screen.dart',
    'screens/messaging/messages_screen.dart': 'features/messaging/presentation/screens/messages_screen.dart',
    'screens/messaging/notifications_screen.dart': 'features/messaging/presentation/screens/notifications_screen.dart',
    'widgets/notification_tile.dart': 'features/messaging/presentation/widgets/notification_tile.dart',
    
    # Accounting feature
    'pages/accounting_page.dart': 'features/accounting/presentation/screens/accounting_page.dart',
    
    # Settings feature
    'pages/settings_page.dart': 'features/settings/presentation/screens/settings_page.dart',
    'screens/setting/settings_main_screen.dart': 'features/settings/presentation/screens/settings_main_screen.dart',
    'screens/setting/profile_screen.dart': 'features/settings/presentation/screens/profile_screen.dart',
    'screens/setting/company_screen.dart': 'features/settings/presentation/screens/company_screen.dart',
    
    # Training feature
    'pages/training_page.dart': 'features/training/presentation/screens/training_page.dart',
    'screens/training/courses_screen.dart': 'features/training/presentation/screens/courses_screen.dart',
    'widgets/video_card.dart': 'features/training/presentation/widgets/video_card.dart',
    
    # Shared widgets
    'widgets/app_button.dart': 'shared/widgets/app_button.dart',
    'widgets/app_card.dart': 'shared/widgets/app_card.dart',
    'widgets/app_drawer.dart': 'shared/widgets/app_drawer.dart',
    'widgets/app_empty_state.dart': 'shared/widgets/app_empty_state.dart',
    'widgets/app_icon.dart': 'shared/widgets/app_icon.dart',
    'widgets/app_loader.dart': 'shared/widgets/app_loader.dart',
    'widgets/app_search_bar.dart': 'shared/widgets/app_search_bar.dart',
    'widgets/app_stat_card.dart': 'shared/widgets/app_stat_card.dart',
    'widgets/app_text_field.dart': 'shared/widgets/app_text_field.dart',
    'widgets/detail_card.dart': 'shared/widgets/detail_card.dart',
    'widgets/setup_card.dart': 'shared/widgets/setup_card.dart',
    'widgets/main_navigation.dart': 'shared/widgets/main_navigation.dart',
}

def create_directory_structure(base_path: Path):
    """Create the new directory structure"""
    print_header("Creating New Directory Structure")
    
    # Create core directories
    for core_dir in NEW_STRUCTURE['core']:
        dir_path = base_path / core_dir
        dir_path.mkdir(parents=True, exist_ok=True)
        print_success(f"Created: {core_dir}/")
    
    # Create feature directories
    for feature, subdirs in NEW_STRUCTURE['features'].items():
        for subdir in subdirs:
            dir_path = base_path / 'features' / feature / subdir
            dir_path.mkdir(parents=True, exist_ok=True)
        print_success(f"Created: features/{feature}/")
    
    # Create shared directories
    for shared_dir in NEW_STRUCTURE['shared']:
        dir_path = base_path / shared_dir
        dir_path.mkdir(parents=True, exist_ok=True)
        print_success(f"Created: {shared_dir}/")

def migrate_files(base_path: Path):
    """Migrate files to new locations"""
    print_header("Migrating Files")
    
    migrated = 0
    skipped = 0
    errors = 0
    
    for old_path, new_path in FILE_MIGRATIONS.items():
        old_file = base_path / old_path
        new_file = base_path / new_path
        
        if old_file.exists():
            try:
                new_file.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(old_file, new_file)
                print_success(f"Migrated: {old_path} → {new_path}")
                migrated += 1
            except Exception as e:
                print_error(f"Failed to migrate {old_path}: {e}")
                errors += 1
        else:
            print_warning(f"Not found: {old_path}")
            skipped += 1
    
    print(f"\n{Colors.BOLD}Summary:{Colors.ENDC}")
    print_success(f"Migrated: {migrated} files")
    print_warning(f"Skipped: {skipped} files")
    if errors > 0:
        print_error(f"Errors: {errors} files")

def create_barrel_files(base_path: Path):
    """Create barrel export files for each feature"""
    print_header("Creating Barrel Export Files")
    
    for feature in NEW_STRUCTURE['features'].keys():
        # Create feature barrel file
        feature_path = base_path / 'features' / feature
        barrel_file = feature_path / f'{feature}.dart'
        
        with open(barrel_file, 'w') as f:
            f.write(f"// {feature.title()} Feature Barrel File\n")
            f.write(f"// Export all public APIs for the {feature} feature\n\n")
            f.write(f"// Data Layer\n")
            f.write(f"export 'data/models/models.dart';\n")
            f.write(f"export 'data/repositories/repositories.dart';\n\n")
            f.write(f"// Domain Layer\n")
            f.write(f"export 'domain/entities/entities.dart';\n")
            f.write(f"export 'domain/repositories/repositories.dart';\n")
            f.write(f"export 'domain/usecases/usecases.dart';\n\n")
            f.write(f"// Presentation Layer\n")
            f.write(f"export 'presentation/providers/providers.dart';\n")
            f.write(f"export 'presentation/screens/screens.dart';\n")
            f.write(f"export 'presentation/widgets/widgets.dart';\n")
        
        print_success(f"Created: features/{feature}/{feature}.dart")

def create_readme_files(base_path: Path):
    """Create README files for documentation"""
    print_header("Creating Documentation")
    
    # Main README
    readme_content = """# FedLearn TMS - Feature-First Architecture

## Project Structure

This project follows Clean Architecture principles with a feature-first approach.

### Core Layer (`core/`)
Shared functionality used across all features:
- `config/`: App configuration and environment setup
- `theme/`: UI theming (colors, typography, etc.)
- `constants/`: App-wide constants
- `utils/`: Utility functions and helpers
- `errors/`: Error handling (exceptions, failures)
- `services/`: Infrastructure services (API, storage, etc.)

### Features Layer (`features/`)
Each feature is self-contained with its own:
- `data/`: Data layer (models, repositories, datasources)
- `domain/`: Business logic (entities, repositories interfaces, use cases)
- `presentation/`: UI layer (providers, screens, widgets)

#### TMS Features (Core Product)
1. **auth** - Authentication & authorization
2. **onboarding** - User/company setup
3. **dashboard** - Main overview
4. **loads** - Freight/load management
5. **drivers** - Driver management
6. **dispatch** - Active dispatching
7. **compliance** - ELD, HOS, documents
8. **invoicing** - Billing and payments
9. **messaging** - Communication
10. **accounting** - Financial management
11. **settings** - User/company settings

#### Learning System Features
12. **training** - Courses, lessons, quizzes
13. **gamification** - Hearts, XP, badges, crates
14. **ai_assistant** - AI-powered help and suggestions

#### Marketplace Features
15. **marketplace** - Connect dispatchers with drivers/loads

#### Monetization Features
16. **iap** - In-app purchases

### Shared Layer (`shared/`)
Reusable widgets and components used across multiple features.

## Import Convention

```dart
// ✅ Good: Import from feature barrel files
import 'package:fedlearn/features/loads/loads.dart';

// ❌ Bad: Import from specific files
import 'package:fedlearn/features/loads/presentation/screens/loads_screen.dart';
```

## Adding a New Feature

1. Create feature directory structure:
```
features/my_feature/
├── data/
│   ├── models/
│   ├── repositories/
│   └── datasources/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── providers/
    ├── screens/
    └── widgets/
```

2. Create barrel export file: `my_feature.dart`
3. Implement your feature following clean architecture
4. Export public APIs through barrel files

## Data Flow

```
Presentation (UI) 
    ↓ calls
Domain (Use Cases)
    ↓ calls
Data (Repositories)
    ↓ calls
Data Sources (API/Local Storage)
```

## State Management

Using Provider for state management. Each feature has its own providers in:
`features/{feature}/presentation/providers/`

## Running the App

```bash
# Development
flutter run --flavor dev

# Production
flutter run --flavor prod
```

## Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
```
"""
    
    with open(base_path / 'README.md', 'w') as f:
        f.write(readme_content)
    
    print_success("Created: README.md")

def create_gitkeep_files(base_path: Path):
    """Create .gitkeep files in empty directories"""
    print_header("Creating .gitkeep Files")
    
    count = 0
    for feature, subdirs in NEW_STRUCTURE['features'].items():
        for subdir in subdirs:
            dir_path = base_path / 'features' / feature / subdir
            gitkeep = dir_path / '.gitkeep'
            if not any(dir_path.iterdir()):
                gitkeep.touch()
                count += 1
    
    print_success(f"Created {count} .gitkeep files")

def create_example_files(base_path: Path):
    """Create example implementation files"""
    print_header("Creating Example Implementation Files")
    
    # Example entity
    entity_example = """// Example Entity (Domain Layer)
// Entities are business objects with business rules

class Load {
  final String id;
  final String pickupLocation;
  final String deliveryLocation;
  final DateTime pickupDate;
  final DateTime deliveryDate;
  final double rate;
  final LoadStatus status;
  
  Load({
    required this.id,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.pickupDate,
    required this.deliveryDate,
    required this.rate,
    required this.status,
  });
  
  // Business logic methods
  bool isOverdue() {
    return DateTime.now().isAfter(deliveryDate) && 
           status != LoadStatus.delivered;
  }
  
  bool canBeAssigned() {
    return status == LoadStatus.pending || status == LoadStatus.available;
  }
}

enum LoadStatus {
  pending,
  available,
  assigned,
  inTransit,
  delivered,
  cancelled,
}
"""
    
    entity_file = base_path / 'features' / 'loads' / 'domain' / 'entities' / 'load.dart'
    entity_file.parent.mkdir(parents=True, exist_ok=True)
    with open(entity_file, 'w') as f:
        f.write(entity_example)
    print_success("Created: features/loads/domain/entities/load.dart")
    
    # Example use case
    usecase_example = """// Example Use Case (Domain Layer)
// Use cases contain application-specific business rules

import '../entities/load.dart';
import '../repositories/load_repository.dart';

class GetLoadsUseCase {
  final LoadRepository repository;
  
  GetLoadsUseCase(this.repository);
  
  Future<List<Load>> call({
    LoadStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final loads = await repository.getLoads(
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
      
      // Apply business logic/filtering if needed
      return loads;
    } catch (e) {
      throw Exception('Failed to fetch loads: $e');
    }
  }
}
"""
    
    usecase_file = base_path / 'features' / 'loads' / 'domain' / 'usecases' / 'get_loads_usecase.dart'
    usecase_file.parent.mkdir(parents=True, exist_ok=True)
    with open(usecase_file, 'w') as f:
        f.write(usecase_example)
    print_success("Created: features/loads/domain/usecases/get_loads_usecase.dart")
    
    # Example repository interface
    repo_interface = """// Example Repository Interface (Domain Layer)
// Defines the contract for data operations

import '../entities/load.dart';

abstract class LoadRepository {
  Future<List<Load>> getLoads({
    LoadStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  Future<Load> getLoadById(String id);
  
  Future<Load> createLoad(Load load);
  
  Future<Load> updateLoad(Load load);
  
  Future<void> deleteLoad(String id);
  
  Future<Load> assignDriver(String loadId, String driverId);
}
"""
    
    repo_file = base_path / 'features' / 'loads' / 'domain' / 'repositories' / 'load_repository.dart'
    repo_file.parent.mkdir(parents=True, exist_ok=True)
    with open(repo_file, 'w') as f:
        f.write(repo_interface)
    print_success("Created: features/loads/domain/repositories/load_repository.dart")

def backup_old_structure(base_path: Path):
    """Create backup of old structure"""
    print_header("Creating Backup")
    
    backup_dir = base_path.parent / 'fedlearn_backup'
    if backup_dir.exists():
        print_warning(f"Backup already exists at {backup_dir}")
        response = input("Overwrite? (y/n): ")
        if response.lower() != 'y':
            print_info("Skipping backup")
            return
        shutil.rmtree(backup_dir)
    
    shutil.copytree(base_path, backup_dir, ignore=shutil.ignore_patterns(
        'build', '.dart_tool', '.idea', '*.iml', '.git'
    ))
    print_success(f"Backup created at: {backup_dir}")

def main():
    """Main migration script"""
    print(f"{Colors.BOLD}{Colors.OKBLUE}")
    print("╔════════════════════════════════════════════════════════════╗")
    print("║       FedLearn TMS - Project Reorganization Script        ║")
    print("║              Feature-First Clean Architecture             ║")
    print("╚════════════════════════════════════════════════════════════╝")
    print(f"{Colors.ENDC}\n")
    
    # Get project path
    default_path = Path.home() / 'ws' / 'OpenHWY' / 'apps' / 'fedlearn' / 'lib'
    print_info(f"Default project path: {default_path}")
    path_input = input(f"Enter project lib/ path (press Enter for default): ").strip()
    
    if path_input:
        base_path = Path(path_input)
    else:
        base_path = default_path
    
    if not base_path.exists():
        print_error(f"Path does not exist: {base_path}")
        return
    
    print_success(f"Using path: {base_path}\n")
    
    # Confirm before proceeding
    print_warning("This will reorganize your entire project structure!")
    response = input("Continue? (y/n): ")
    if response.lower() != 'y':
        print_info("Migration cancelled")
        return
    
    try:
        # Step 1: Backup
        backup_old_structure(base_path)
        
        # Step 2: Create new structure
        create_directory_structure(base_path)
        
        # Step 3: Migrate files
        migrate_files(base_path)
        
        # Step 4: Create barrel files
        create_barrel_files(base_path)
        
        # Step 5: Create .gitkeep files
        create_gitkeep_files(base_path)
        
        # Step 6: Create example files
        create_example_files(base_path)
        
        # Step 7: Create documentation
        create_readme_files(base_path)
        
        print_header("Migration Complete!")
        print_success("✓ Directory structure created")
        print_success("✓ Files migrated")
        print_success("✓ Barrel files created")
        print_success("✓ Documentation created")
        print_success("✓ Example implementations added")
        
        print(f"\n{Colors.BOLD}Next Steps:{Colors.ENDC}")
        print_info("1. Review migrated files and update imports")
        print_info("2. Run: flutter pub get")
        print_info("3. Fix any import errors")
        print_info("4. Implement missing repository implementations")
        print_info("5. Run: flutter analyze")
        print_info("6. Run: flutter test")
        
        print(f"\n{Colors.BOLD}Old structure backed up at:{Colors.ENDC}")
        print_info(str(base_path.parent / 'fedlearn_backup'))
        
    except Exception as e:
        print_error(f"Migration failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    main()
