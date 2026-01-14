# FED_TMS - Import Guide

## 🎯 How This Project is Organized

Every directory has an `index.dart` file that exports everything in that directory.
This means you can import entire features or layers with a single import!

## 📦 Using Barrel Files

### Old Way (DON'T DO THIS):
```dart
import 'package:fed_tms/features/loads/data/models/load.dart';
import 'package:fed_tms/features/loads/data/models/load_status.dart';
import 'package:fed_tms/features/loads/presentation/widgets/load_card.dart';
```

### New Way (DO THIS):
```dart
// Import all models
import 'package:fed_tms/features/loads/data/models/index.dart';

// Or import the entire feature!
import 'package:fed_tms/features/loads/index.dart';
```

## 🚀 Quick Examples

### Example 1: Dashboard Screen
```dart
import 'package:flutter/material.dart';

// Import entire loads feature
import 'package:fed_tms/features/loads/index.dart';

// Import core widgets
import 'package:fed_tms/core/widgets/index.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LoadCard(load: myLoad),      // From loads feature
        AppButton(text: 'Click'),    // From core widgets
      ],
    );
  }
}
```

### Example 2: Multiple Features
```dart
// Import multiple features at once
import 'package:fed_tms/features/loads/index.dart' as loads;
import 'package:fed_tms/features/drivers/index.dart' as drivers;

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
4. Project imports (package:fed_tms)
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
