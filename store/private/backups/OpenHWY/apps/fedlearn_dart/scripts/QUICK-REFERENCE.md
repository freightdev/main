# FedLearn TMS - Architecture Quick Reference

## 🎯 Quick Start

### Running the Migration

1. **Save the Python script:**
```bash
cd ~/ws/OpenHWY/apps/fedlearn
# Copy the Python migration script to migrate.py
```

2. **Make the bash script executable:**
```bash
chmod +x migrate_and_fix.sh
```

3. **Run the migration:**
```bash
./migrate_and_fix.sh
```

---

## 📁 New Project Structure

```
lib/
├── core/              # Shared infrastructure
├── features/          # Feature modules (13 total)
├── shared/            # Reusable UI components
├── main.dart          # App entry point
├── app.dart           # App widget
└── router.dart        # Navigation
```

---

## 🏗️ Feature Structure (Clean Architecture)

Each feature follows this pattern:

```
features/my_feature/
├── data/              # Data layer
│   ├── models/        # DTOs (Data Transfer Objects)
│   ├── repositories/  # Repository implementations
│   └── datasources/   # API/Local data sources
├── domain/            # Business logic layer
│   ├── entities/      # Business objects
│   ├── repositories/  # Repository interfaces
│   └── usecases/      # Application business rules
└── presentation/      # UI layer
    ├── providers/     # State management
    ├── screens/       # Full-page views
    └── widgets/       # Reusable components
```

---

## 🎮 Your 13 Features

### TMS Core (Product)
1. **auth** - Login, signup, authentication
2. **onboarding** - Company setup, initial configuration
3. **dashboard** - Overview, analytics, calendar
4. **loads** - Freight management (create, track, manage)
5. **drivers** - Driver roster management
6. **dispatch** - Active dispatching operations
7. **compliance** - ELD, HOS, documents, reports
8. **invoicing** - Billing, invoices, payments
9. **messaging** - Driver communication
10. **accounting** - Financial management
11. **settings** - User/company preferences

### Learning System
12. **training** - Courses, lessons, quizzes, TMS simulator
13. **gamification** - Hearts, XP, badges, crates, streaks

### Ecosystem
14. **ai_assistant** - AI-powered help and suggestions
15. **marketplace** - Connect dispatchers ↔ drivers
16. **iap** - In-app purchases

---

## 💻 Code Examples

### Creating a New Use Case

```dart
// features/loads/domain/usecases/create_load_usecase.dart

import '../entities/load.dart';
import '../repositories/load_repository.dart';

class CreateLoadUseCase {
  final LoadRepository repository;
  
  CreateLoadUseCase(this.repository);
  
  Future<Load> call(Load load) async {
    // Validation
    if (load.pickupLocation.isEmpty) {
      throw Exception('Pickup location is required');
    }
    
    if (load.rate <= 0) {
      throw Exception('Rate must be positive');
    }
    
    // Business logic
    return await repository.createLoad(load);
  }
}
```

### Creating a Provider

```dart
// features/loads/presentation/providers/load_provider.dart

import 'package:flutter/foundation.dart';
import '../../domain/entities/load.dart';
import '../../domain/usecases/get_loads_usecase.dart';
import '../../domain/usecases/create_load_usecase.dart';

class LoadProvider with ChangeNotifier {
  final GetLoadsUseCase getLoadsUseCase;
  final CreateLoadUseCase createLoadUseCase;
  
  LoadProvider({
    required this.getLoadsUseCase,
    required this.createLoadUseCase,
  });
  
  List<Load> _loads = [];
  bool _isLoading = false;
  String? _error;
  
  List<Load> get loads => _loads;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> loadLoads() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _loads = await getLoadsUseCase();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> createLoad(Load load) async {
    try {
      final newLoad = await createLoadUseCase(load);
      _loads.add(newLoad);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
```

### Using in a Screen

```dart
// features/loads/presentation/screens/loads_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/load_provider.dart';
import '../widgets/load_card.dart';

class LoadsScreen extends StatefulWidget {
  @override
  _LoadsScreenState createState() => _LoadsScreenState();
}

class _LoadsScreenState extends State<LoadsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoadProvider>().loadLoads();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Loads')),
      body: Consumer<LoadProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }
          
          if (provider.loads.isEmpty) {
            return Center(child: Text('No loads found'));
          }
          
          return ListView.builder(
            itemCount: provider.loads.length,
            itemBuilder: (context, index) {
              return LoadCard(load: provider.loads[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateLoadDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
  
  void _showCreateLoadDialog() {
    // Show dialog to create new load
  }
}
```

---

## 🔄 Data Flow

```
User Interaction (Screen)
    ↓
Provider calls Use Case
    ↓
Use Case applies business logic
    ↓
Use Case calls Repository Interface
    ↓
Repository Implementation calls Data Source
    ↓
Data Source makes API call
    ↓
Response flows back up
    ↓
Provider updates state
    ↓
UI rebuilds
```

---

## 📦 Import Conventions

### ✅ Good: Use barrel files
```dart
// Import entire feature
import 'package:fedlearn/features/loads/loads.dart';

// Import from core
import 'package:fedlearn/core/theme/app_theme.dart';

// Import shared widgets
import 'package:fedlearn/shared/widgets/app_button.dart';
```

### ❌ Bad: Deep imports
```dart
// Don't do this
import 'package:fedlearn/features/loads/presentation/screens/loads_screen.dart';
import 'package:fedlearn/features/loads/domain/entities/load.dart';
```

---

## 🎯 Priority Implementation Order

### Phase 1: Core TMS (Weeks 1-4)
1. Fix **auth** feature
2. Fix **loads** feature
3. Fix **drivers** feature
4. Fix **dispatch** feature

### Phase 2: Supporting Features (Weeks 5-6)
5. Fix **dashboard** feature
6. Fix **messaging** feature
7. Fix **invoicing** feature

### Phase 3: Learning System (Weeks 7-10)
8. Build **training** feature from scratch
9. Build **gamification** feature from scratch
10. Build **ai_assistant** feature

### Phase 4: Marketplace (Weeks 11-12)
11. Build **marketplace** feature
12. Integrate **iap** for monetization

---

## 🐛 Common Issues After Migration

### Import Errors
**Problem:** `Error: Cannot find import 'package:fedlearn/models/load.dart'`

**Solution:** Update to use feature imports:
```dart
import 'package:fedlearn/features/loads/loads.dart';
```

### Provider Not Found
**Problem:** `ProviderNotFoundException: Error: Could not find LoadProvider`

**Solution:** Add provider in main.dart:
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => LoadProvider(...)),
    // ... other providers
  ],
  child: MyApp(),
)
```

### Missing Repository Implementation
**Problem:** Repository interface defined but no implementation

**Solution:** Create implementation in `data/repositories/`:
```dart
class LoadRepositoryImpl implements LoadRepository {
  final LoadRemoteDataSource remoteDataSource;
  
  LoadRepositoryImpl(this.remoteDataSource);
  
  @override
  Future<List<Load>> getLoads() async {
    final models = await remoteDataSource.getLoads();
    return models.map((m) => m.toEntity()).toList();
  }
}
```

---

## 🧪 Testing Structure

```
test/
├── core/
├── features/
│   └── loads/
│       ├── data/
│       │   └── repositories/
│       │       └── load_repository_impl_test.dart
│       ├── domain/
│       │   └── usecases/
│       │       └── create_load_usecase_test.dart
│       └── presentation/
│           └── providers/
│               └── load_provider_test.dart
└── widget_test.dart
```

---

## 🚀 Running the App

```bash
# Development
flutter run --flavor dev -t lib/main.dart

# Production
flutter run --flavor prod -t lib/main.dart

# Web
flutter run -d chrome

# Clean build
flutter clean && flutter pub get && flutter run
```

---

## 📝 Next Steps After Migration

1. **Fix Import Errors**
   - Run `flutter analyze`
   - Update all imports to use barrel files
   - Remove unused imports

2. **Implement Missing Repositories**
   - Check each feature's data/repositories/
   - Implement repository interfaces
   - Connect to API data sources

3. **Add Use Cases**
   - Identify business operations for each feature
   - Create use case classes
   - Wire them up in providers

4. **Test Each Feature**
   - Start with auth
   - Then loads, drivers, dispatch
   - Test end-to-end workflows

5. **Build Training Features**
   - Implement gamification system
   - Create quiz engine
   - Build TMS simulator

6. **Add AI Integration**
   - Set up AI API calls
   - Create suggestion system
   - Integrate with training

---

## 🤝 Need Help?

**Common Commands:**
```bash
# Analyze code
flutter analyze

# Run tests
flutter test

# Check for outdated packages
flutter pub outdated

# Format code
dart format lib/

# Generate coverage
flutter test --coverage
```

**Helpful Resources:**
- Clean Architecture: https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
- Provider docs: https://pub.dev/packages/provider
- Flutter architecture: https://docs.flutter.dev/development/data-and-backend/state-mgmt/options

---

## ✅ Migration Checklist

- [ ] Backup created
- [ ] Python migration script ran successfully
- [ ] Bash script completed all steps
- [ ] All imports updated
- [ ] `flutter pub get` runs without errors
- [ ] `flutter analyze` shows no blocking errors
- [ ] App launches without crashing
- [ ] Auth flow works
- [ ] At least one feature fully functional
- [ ] Tests passing (when written)

---

**Good luck! You've got a solid foundation now. Build feature by feature, test as you go, and ship! 🚀**
