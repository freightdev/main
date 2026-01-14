# TMS Flutter App Architecture

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
