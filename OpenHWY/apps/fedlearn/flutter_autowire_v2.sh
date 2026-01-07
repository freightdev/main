#!/bin/bash

# Flutter Missing Files Generator
# Creates all missing stub files to fix compilation errors

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🔧 Flutter Missing Files Generator${NC}"
echo "================================================"

if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: Run from Flutter project root${NC}"
    exit 1
fi

PROJECT_NAME=$(grep '^name:' pubspec.yaml | awk '{print $2}')
echo -e "📦 Project: ${GREEN}$PROJECT_NAME${NC}"

FILES_CREATED=0

# ============================================
# CORE UTILITIES
# ============================================
echo -e "\n${BLUE}📁 Creating core utilities...${NC}"

# 1. Theme/Colors
mkdir -p lib/utils lib/shared/theme
cat > lib/utils/theme.dart << 'EOF'
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    useMaterial3: true,
  );
  
  static ThemeData get darkTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );
}

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF03DAC6);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  
  // Brand colors
  static const Color blue = Color(0xFF2196F3);
  static const Color purple = Color(0xFF9C27B0);
  static const Color orange = Color(0xFFFF9800);
  static const Color green = Color(0xFF4CAF50);
  
  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  
  // Background colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surface = Color(0xFFFAFAFA);
  
  // Border colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFBDBDBD);
}
EOF
echo -e "  ${GREEN}✓${NC} lib/utils/theme.dart"
((FILES_CREATED++))

cat > lib/shared/theme/colors.dart << 'EOF'
export '../../utils/theme.dart';
EOF
echo -e "  ${GREEN}✓${NC} lib/shared/theme/colors.dart"
((FILES_CREATED++))

# 2. Logger Service
mkdir -p lib/core/services
cat > lib/core/services/logger.dart << 'EOF'
enum LogLevel { debug, info, warning, error }

class Logger {
  static LogLevel _currentLevel = LogLevel.info;
  static bool _isInitialized = false;
  
  static void init(bool isDevelopment, LogLevel level) {
    _currentLevel = level;
    _isInitialized = true;
    log('Logger initialized (isDevelopment: $isDevelopment, level: $level)');
  }
  
  static void log(String message, {LogLevel level = LogLevel.info}) {
    if (!_isInitialized) return;
    if (level.index < _currentLevel.index) return;
    
    final prefix = _getPrefix(level);
    print('$prefix $message');
  }
  
  static void debug(String message) => log(message, level: LogLevel.debug);
  static void info(String message) => log(message, level: LogLevel.info);
  static void warning(String message) => log(message, level: LogLevel.warning);
  static void error(String message) => log(message, level: LogLevel.error);
  
  static String _getPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍 [DEBUG]';
      case LogLevel.info:
        return 'ℹ️  [INFO]';
      case LogLevel.warning:
        return '⚠️  [WARN]';
      case LogLevel.error:
        return '❌ [ERROR]';
    }
  }
}
EOF
echo -e "  ${GREEN}✓${NC} lib/core/services/logger.dart"
((FILES_CREATED++))

# 3. Storage Services
cat > lib/core/services/local_storage_service.dart << 'EOF'
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static SharedPreferences? _prefs;
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  static Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }
  
  static String? getString(String key) {
    return _prefs?.getString(key);
  }
  
  static Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }
  
  static bool? getBool(String key) {
    return _prefs?.getBool(key);
  }
  
  static Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }
  
  static Future<void> clear() async {
    await _prefs?.clear();
  }
}
EOF
echo -e "  ${GREEN}✓${NC} lib/core/services/local_storage_service.dart"
((FILES_CREATED++))

cat > lib/core/services/secure_storage_service.dart << 'EOF'
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  
  static Future<void> init() async {
    // Secure storage doesn't need initialization
  }
  
  static Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
  
  static Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }
  
  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
  
  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
EOF
echo -e "  ${GREEN}✓${NC} lib/core/services/secure_storage_service.dart"
((FILES_CREATED++))

# ============================================
# DATA MODELS
# ============================================
echo -e "\n${BLUE}📁 Creating data models...${NC}"

mkdir -p lib/data/models

# Company Model
cat > lib/data/models/company.dart << 'EOF'
class Company {
  final String id;
  final String name;
  final String? dotNumber;
  final String? mcNumber;
  final String? address;
  final String? phone;
  final String? email;
  
  Company({
    required this.id,
    required this.name,
    this.dotNumber,
    this.mcNumber,
    this.address,
    this.phone,
    this.email,
  });
  
  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String,
      name: json['name'] as String,
      dotNumber: json['dotNumber'] as String?,
      mcNumber: json['mcNumber'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dotNumber': dotNumber,
      'mcNumber': mcNumber,
      'address': address,
      'phone': phone,
      'email': email,
    };
  }
}
EOF
echo -e "  ${GREEN}✓${NC} lib/data/models/company.dart"
((FILES_CREATED++))

# Driver Model
cat > lib/data/models/driver_model.dart << 'EOF'
enum DriverStatus { available, onTrip, offDuty, onBreak, maintenance, inactive }
enum TruckType { dryVan, reefer, flatbed, tanker, stepDeck, other }

class Driver {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final DriverStatus status;
  final TruckType? truckType;
  
  Driver({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.status = DriverStatus.available,
    this.truckType,
  });
  
  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      status: DriverStatus.values.byName(json['status'] ?? 'available'),
      truckType: json['truckType'] != null 
        ? TruckType.values.byName(json['truckType'])
        : null,
    );
  }
}
EOF
echo -e "  ${GREEN}✓${NC} lib/data/models/driver_model.dart"
((FILES_CREATED++))

# Load Model
cat > lib/data/models/loadboard_model.dart << 'EOF'
enum LoadStatus { available, booked, inTransit, delivered, cancelled }

class Load {
  final String id;
  final String origin;
  final String destination;
  final double rate;
  final LoadStatus status;
  final DateTime? pickupDate;
  final DateTime? deliveryDate;
  
  Load({
    required this.id,
    required this.origin,
    required this.destination,
    required this.rate,
    this.status = LoadStatus.available,
    this.pickupDate,
    this.deliveryDate,
  });
  
  factory Load.fromJson(Map<String, dynamic> json) {
    return Load(
      id: json['id'] as String,
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      rate: (json['rate'] as num).toDouble(),
      status: LoadStatus.values.byName(json['status'] ?? 'available'),
      pickupDate: json['pickupDate'] != null 
        ? DateTime.parse(json['pickupDate'])
        : null,
      deliveryDate: json['deliveryDate'] != null
        ? DateTime.parse(json['deliveryDate'])
        : null,
    );
  }
}
EOF
echo -e "  ${GREEN}✓${NC} lib/data/models/loadboard_model.dart"
((FILES_CREATED++))

# ============================================
# PROVIDERS (STATE MANAGEMENT)
# ============================================
echo -e "\n${BLUE}📁 Creating providers...${NC}"

mkdir -p lib/features/providers

cat > lib/features/providers/auth_provider.dart << 'EOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final currentUserProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.userId;
});

class AuthState {
  final String? userId;
  final bool isAuthenticated;
  final bool isLoading;
  
  AuthState({
    this.userId,
    this.isAuthenticated = false,
    this.isLoading = false,
  });
  
  AuthState copyWith({
    String? userId,
    bool? isAuthenticated,
    bool? isLoading,
  }) {
    return AuthState(
      userId: userId ?? this.userId,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());
  
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    // TODO: Implement actual login
    await Future.delayed(const Duration(seconds: 1));
    state = state.copyWith(
      userId: 'user123',
      isAuthenticated: true,
      isLoading: false,
    );
  }
  
  Future<void> logout() async {
    state = AuthState();
  }
}
EOF
echo -e "  ${GREEN}✓${NC} lib/features/providers/auth_provider.dart"
((FILES_CREATED++))

cat > lib/features/providers/driver_provider.dart << 'EOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';

final driverProvider = Provider((ref) => DriverProvider());

class DriverProvider {
  // TODO: Implement driver state management
}
EOF
echo -e "  ${GREEN}✓${NC} lib/features/providers/driver_provider.dart"
((FILES_CREATED++))

cat > lib/features/providers/invoice_provider.dart << 'EOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';

final invoiceProvider = Provider((ref) => InvoiceProvider());

class InvoiceProvider {
  // TODO: Implement invoice state management
}
EOF
echo -e "  ${GREEN}✓${NC} lib/features/providers/invoice_provider.dart"
((FILES_CREATED++))

# ============================================
# MISSING SCREENS (STUBS)
# ============================================
echo -e "\n${BLUE}📁 Creating missing screens...${NC}"

# Create directory structure
mkdir -p lib/features/{auth,dispatch,loads,training,settings,onboarding}/presentation/screens

# Stub screens
STUB_SCREENS=(
  "lib/features/auth/presentation/screens/forgot_password_screen.dart:ForgetPasswordScreen"
  "lib/features/dispatch/presentation/screens/loads_list_screen.dart:LoadsListScreen"
  "lib/features/loads/presentation/screens/loadboard_screen.dart:LoadboardScreen"
  "lib/features/training/presentation/screens/training_page.dart:TrainingPage"
  "lib/features/training/presentation/screens/course_screen.dart:CourseScreen"
  "lib/features/training/presentation/screens/course_detail_screen.dart:CourseDetailScreen"
  "lib/features/settings/presentation/screens/settings_page.dart:SettingsPage"
  "lib/features/settings/presentation/screens/company_screen.dart:CompanyScreen"
  "lib/features/onboarding/presentation/screens/onboarding_page.dart:OnboardingPage"
)

for stub in "${STUB_SCREENS[@]}"; do
  IFS=':' read -r filepath classname <<< "$stub"
  mkdir -p "$(dirname "$filepath")"
  
  cat > "$filepath" << EOF
import 'package:flutter/material.dart';

class $classname extends StatelessWidget {
  const $classname({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$classname'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '$classname',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('TODO: Implement this screen'),
          ],
        ),
      ),
    );
  }
}
EOF
  echo -e "  ${GREEN}✓${NC} $filepath"
  ((FILES_CREATED++))
done

# ============================================
# BARREL FILES (exports)
# ============================================
echo -e "\n${BLUE}📁 Creating barrel files...${NC}"

BARREL_DIRS=(
  "lib/features/onboarding/data/models"
  "lib/features/onboarding/data/repositories"
  "lib/features/onboarding/domain/entities"
  "lib/features/onboarding/domain/repositories"
  "lib/features/onboarding/domain/usecases"
  "lib/features/onboarding/presentation/providers"
  "lib/features/onboarding/presentation/screens"
  "lib/features/onboarding/presentation/widgets"
  "lib/features/training/data/models"
  "lib/features/training/data/repositories"
  "lib/features/training/domain/entities"
  "lib/features/training/domain/repositories"
  "lib/features/training/domain/usecases"
  "lib/features/training/presentation/providers"
  "lib/features/training/presentation/screens"
  "lib/features/training/presentation/widgets"
  "lib/features/settings/data/models"
  "lib/features/settings/data/repositories"
  "lib/features/settings/domain/entities"
  "lib/features/settings/domain/repositories"
  "lib/features/settings/domain/usecases"
  "lib/features/settings/presentation/providers"
  "lib/features/settings/presentation/screens"
  "lib/features/settings/presentation/widgets"
)

for dir in "${BARREL_DIRS[@]}"; do
  mkdir -p "$dir"
  barrel_file="$dir/$(basename "$dir").dart"
  
  cat > "$barrel_file" << 'EOF'
// Barrel file - export all files in this directory
// TODO: Add exports as you create files
// Example: export 'my_file.dart';
EOF
  echo -e "  ${GREEN}✓${NC} $barrel_file"
  ((FILES_CREATED++))
done

# ============================================
# CREATE ASSETS
# ============================================
echo -e "\n${BLUE}📁 Creating asset directories...${NC}"

mkdir -p assets/images assets/icons
touch .env

cat > .env << 'EOF'
# Environment variables
API_URL=https://api.example.com
DEBUG_MODE=true
EOF

echo -e "  ${GREEN}✓${NC} .env"
echo -e "  ${GREEN}✓${NC} assets/images/"
echo -e "  ${GREEN}✓${NC} assets/icons/"
((FILES_CREATED+=3))

# ============================================
# UPDATE MAIN FILES
# ============================================
echo -e "\n${BLUE}📝 Updating main files...${NC}"

cat > lib/main.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/services/logger.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/secure_storage_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize logger
  final isDevelopment = dotenv.env['DEBUG_MODE'] == 'true';
  Logger.init(isDevelopment, isDevelopment ? LogLevel.debug : LogLevel.info);
  
  // Initialize storage services
  await LocalStorageService.init();
  await SecureStorageService.init();
  
  Logger.info('App initialized successfully');
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
EOF
echo -e "  ${GREEN}✓${NC} lib/main.dart"

cat > lib/app.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'utils/theme.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'FreightLearn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
EOF
echo -e "  ${GREEN}✓${NC} lib/app.dart"

# ============================================
# SUMMARY
# ============================================
echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}✅ Scaffold Generation Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo -e "\n📊 Summary:"
echo -e "  • Files created: ${GREEN}$FILES_CREATED${NC}"
echo -e "\n${YELLOW}⚠️  Next Steps:${NC}"
echo -e "  1. Run: ${GREEN}flutter pub get${NC}"
echo -e "  2. Run: ${GREEN}flutter analyze${NC}"
echo -e "  3. Fix remaining issues manually"
echo -e "  4. Run: ${GREEN}flutter run${NC}"
echo -e "\n${BLUE}💡 Tip:${NC} Review the generated stub files and implement them as needed."
echo -e ""
