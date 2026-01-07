# FedLearn TMS - Feature-First Architecture

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
