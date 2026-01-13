#!/bin/bash

# Flutter Auto-Wire Generator
# Scans lib/ and generates main.dart, app.dart, router.dart, and updates pubspec.yaml

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Flutter Auto-Wire Generator${NC}"
echo "================================================"

# Check if we're in a Flutter project
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: pubspec.yaml not found. Run this from your Flutter project root.${NC}"
    exit 1
fi

if [ ! -d "lib" ]; then
    echo -e "${RED}❌ Error: lib/ directory not found.${NC}"
    exit 1
fi

PROJECT_NAME=$(grep '^name:' pubspec.yaml | awk '{print $2}')
echo -e "📦 Project: ${GREEN}$PROJECT_NAME${NC}"

# ============================================
# STEP 1: Discover all screens
# ============================================
echo -e "\n${YELLOW}🔍 Discovering screens...${NC}"

SCREENS=()
while IFS= read -r file; do
    # Extract class name from file
    class_name=$(basename "$file" .dart | sed -r 's/(^|_)([a-z])/\U\2/g')
    
    # Get relative import path
    import_path="${file#lib/}"
    
    SCREENS+=("$class_name|$import_path")
    echo "  ✓ Found: $class_name"
done < <(find lib -type f -name "*_screen.dart" -o -name "*_page.dart" | sort)

echo -e "${GREEN}Found ${#SCREENS[@]} screens${NC}"

# ============================================
# STEP 2: Discover all providers
# ============================================
echo -e "\n${YELLOW}🔍 Discovering providers...${NC}"

PROVIDERS=()
while IFS= read -r file; do
    class_name=$(basename "$file" .dart | sed -r 's/(^|_)([a-z])/\U\2/g')
    import_path="${file#lib/}"
    
    PROVIDERS+=("$class_name|$import_path")
    echo "  ✓ Found: $class_name"
done < <(find lib -type f -name "*_provider.dart" | sort)

echo -e "${GREEN}Found ${#PROVIDERS[@]} providers${NC}"

# ============================================
# STEP 3: Discover required dependencies
# ============================================
echo -e "\n${YELLOW}🔍 Analyzing dependencies...${NC}"

REQUIRED_DEPS=()

# Check for common imports
if grep -r "package:provider" lib/ &>/dev/null; then
    REQUIRED_DEPS+=("provider")
fi

if grep -r "package:go_router" lib/ &>/dev/null; then
    REQUIRED_DEPS+=("go_router")
fi

if grep -r "package:flutter_riverpod" lib/ &>/dev/null; then
    REQUIRED_DEPS+=("flutter_riverpod")
fi

if grep -r "package:dio" lib/ &>/dev/null; then
    REQUIRED_DEPS+=("dio")
fi

if grep -r "package:shared_preferences" lib/ &>/dev/null; then
    REQUIRED_DEPS+=("shared_preferences")
fi

if grep -r "package:flutter_secure_storage" lib/ &>/dev/null; then
    REQUIRED_DEPS+=("flutter_secure_storage")
fi

if grep -r "package:flutter_form_builder" lib/ &>/dev/null; then
    REQUIRED_DEPS+=("flutter_form_builder" "form_builder_validators")
fi

echo -e "${GREEN}Found ${#REQUIRED_DEPS[@]} required dependencies${NC}"

# ============================================
# STEP 4: Update pubspec.yaml
# ============================================
echo -e "\n${YELLOW}📝 Updating pubspec.yaml...${NC}"

# Backup existing pubspec
cp pubspec.yaml pubspec.yaml.backup

# Check which dependencies are missing
MISSING_DEPS=()
for dep in "${REQUIRED_DEPS[@]}"; do
    if ! grep -q "^  $dep:" pubspec.yaml; then
        MISSING_DEPS+=("$dep")
    fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "${YELLOW}  Adding missing dependencies:${NC}"
    for dep in "${MISSING_DEPS[@]}"; do
        echo "    - $dep"
    done
    
    # Add dependencies using flutter pub add
    for dep in "${MISSING_DEPS[@]}"; do
        flutter pub add "$dep" &>/dev/null || echo "    ⚠️  Failed to add $dep"
    done
else
    echo -e "${GREEN}  All dependencies already present${NC}"
fi

# ============================================
# STEP 5: Generate main.dart
# ============================================
echo -e "\n${YELLOW}📝 Generating lib/main.dart...${NC}"

cat > lib/main.dart << 'MAINEOF'
import 'package:flutter/material.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Initialize your services here
  // await initializeServices();
  
  runApp(const MyApp());
}
MAINEOF

echo -e "${GREEN}  ✓ Generated lib/main.dart${NC}"

# ============================================
# STEP 6: Generate app.dart
# ============================================
echo -e "\n${YELLOW}📝 Generating lib/app.dart...${NC}"

cat > lib/app.dart << 'APPEOF'
import 'package:flutter/material.dart';
import 'router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
APPEOF

echo -e "${GREEN}  ✓ Generated lib/app.dart${NC}"

# ============================================
# STEP 7: Generate router.dart
# ============================================
echo -e "\n${YELLOW}📝 Generating lib/router.dart...${NC}"

cat > lib/router.dart << 'ROUTEREOF'
import 'package:go_router/go_router.dart';

// TODO: Import your screens here
// import 'features/home/presentation/screens/home_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        // TODO: Replace with your actual home screen
        return const Placeholder(); // HomeScreen()
      },
    ),
    
    // TODO: Add more routes here
    // GoRoute(
    //   path: '/profile',
    //   builder: (context, state) => ProfileScreen(),
    // ),
  ],
  
  errorBuilder: (context, state) {
    return const Placeholder(); // ErrorScreen()
  },
);
ROUTEREOF

echo -e "${GREEN}  ✓ Generated lib/router.dart${NC}"

# ============================================
# STEP 8: Generate discovered routes (advanced)
# ============================================
if [ ${#SCREENS[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}📝 Generating lib/router_generated.dart with discovered routes...${NC}"
    
    cat > lib/router_generated.dart << 'GENROUTEREOF'
import 'package:go_router/go_router.dart';

GENROUTEREOF

    # Add imports
    for screen in "${SCREENS[@]}"; do
        IFS='|' read -r class_name import_path <<< "$screen"
        echo "import '$import_path';" >> lib/router_generated.dart
    done
    
    cat >> lib/router_generated.dart << 'GENROUTER2EOF'

// Auto-generated routes based on discovered screens
final generatedRoutes = <GoRoute>[
GENROUTER2EOF

    # Add routes
    for screen in "${SCREENS[@]}"; do
        IFS='|' read -r class_name import_path <<< "$screen"
        
        # Convert class name to route path
        route_path=$(echo "$class_name" | sed 's/Screen$//' | sed 's/Page$//' | sed 's/\([A-Z]\)/-\L\1/g' | sed 's/^-//')
        
        cat >> lib/router_generated.dart << ROUTEEOF
  GoRoute(
    path: '/$route_path',
    builder: (context, state) => const $class_name(),
  ),
ROUTEEOF
    done
    
    cat >> lib/router_generated.dart << 'GENROUTER3EOF'
];
GENROUTER3EOF

    echo -e "${GREEN}  ✓ Generated lib/router_generated.dart with ${#SCREENS[@]} routes${NC}"
fi

# ============================================
# STEP 9: Create a comprehensive README
# ============================================
echo -e "\n${YELLOW}📝 Generating AUTO_WIRE_README.md...${NC}"

cat > AUTO_WIRE_README.md << 'READMEEOF'
# Auto-Wire Generator Results

This file was automatically generated by the Flutter Auto-Wire script.

## What Was Generated

1. **lib/main.dart** - Entry point
2. **lib/app.dart** - App widget with router
3. **lib/router.dart** - Manual route configuration
4. **lib/router_generated.dart** - Auto-discovered routes
5. **pubspec.yaml** - Updated with required dependencies

## Next Steps

### 1. Review Generated Files
Check the generated files and customize as needed.

### 2. Update router.dart
Replace the Placeholder widgets with your actual screens:

```dart
import 'features/home/presentation/screens/home_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    
    // Add discovered routes
    ...generatedRoutes,
  ],
);
```

### 3. Initialize Services
Update `main.dart` to initialize your services:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await LocalStorageService.init();
  await SecureStorageService.init();
  
  runApp(const MyApp());
}
```

### 4. Add Providers (if using Provider package)
Wrap your app with MultiProvider:

```dart
return MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    // Add more providers
  ],
  child: MaterialApp.router(
    routerConfig: router,
  ),
);
```

## Convention-Based File Discovery

The script discovered:
- Screens: Files ending with `_screen.dart` or `_page.dart`
- Providers: Files ending with `_provider.dart`

## Re-run the Script

Run `./flutter_autowire.sh` anytime you:
- Add new screens
- Add new providers
- Need to regenerate boilerplate

## Backup

Your original `pubspec.yaml` was backed up to `pubspec.yaml.backup`
READMEEOF

echo -e "${GREEN}  ✓ Generated AUTO_WIRE_README.md${NC}"

# ============================================
# FINAL SUMMARY
# ============================================
echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}✅ Auto-Wire Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo -e "\n📊 Summary:"
echo -e "  • Screens discovered: ${#SCREENS[@]}"
echo -e "  • Providers discovered: ${#PROVIDERS[@]}"
echo -e "  • Dependencies added: ${#MISSING_DEPS[@]}"
echo -e "\n📝 Generated files:"
echo -e "  • lib/main.dart"
echo -e "  • lib/app.dart"
echo -e "  • lib/router.dart"
[ ${#SCREENS[@]} -gt 0 ] && echo -e "  • lib/router_generated.dart"
echo -e "  • AUTO_WIRE_README.md"
echo -e "\n${YELLOW}⚠️  Next Steps:${NC}"
echo -e "  1. Review generated files"
echo -e "  2. Replace Placeholder widgets with actual screens"
echo -e "  3. Run: ${GREEN}flutter pub get${NC}"
echo -e "  4. Run: ${GREEN}flutter run${NC}"
echo -e "\n${GREEN}Happy coding! 🎉${NC}\n"
