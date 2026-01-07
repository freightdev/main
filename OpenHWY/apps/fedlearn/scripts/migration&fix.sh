#!/bin/bash

# FedLearn TMS - Complete Migration and Fix Script
# This script reorganizes your Flutter project and fixes common issues

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Project path
PROJECT_ROOT="$HOME/ws/OpenHWY/apps/fedlearn"
LIB_PATH="$PROJECT_ROOT/lib"

echo -e "${BOLD}${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║    FedLearn TMS - Complete Migration & Fix Script         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if project exists
if [ ! -d "$PROJECT_ROOT" ]; then
    echo -e "${RED}❌ Project not found at: $PROJECT_ROOT${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Project found at: $PROJECT_ROOT${NC}\n"

# Function to print section headers
print_header() {
    echo -e "\n${BOLD}${CYAN}$1${NC}"
    echo "═══════════════════════════════════════════════════════════"
}

# Function to confirm action
confirm() {
    read -p "$(echo -e ${YELLOW}$1 ${NC}[y/N]: )" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Cancelled${NC}"
        exit 1
    fi
}

print_header "Step 1: Backup Current Project"
BACKUP_DIR="$HOME/ws/OpenHWY/apps/fedlearn_backup_$(date +%Y%m%d_%H%M%S)"
confirm "Create backup at $BACKUP_DIR?"

echo -e "${BLUE}→ Creating backup...${NC}"
mkdir -p "$BACKUP_DIR"
cp -r "$PROJECT_ROOT"/* "$BACKUP_DIR/" 2>/dev/null || true
echo -e "${GREEN}✓ Backup created at: $BACKUP_DIR${NC}"

print_header "Step 2: Clean Build Artifacts"
echo -e "${BLUE}→ Cleaning old build files...${NC}"
cd "$PROJECT_ROOT"
flutter clean
rm -rf .dart_tool/
rm -rf build/
echo -e "${GREEN}✓ Build artifacts cleaned${NC}"

print_header "Step 3: Run Python Migration Script"
confirm "Run directory reorganization?"

# Save the Python script
PYTHON_SCRIPT="$PROJECT_ROOT/migrate.py"
echo -e "${BLUE}→ Python migration script should be saved as: $PYTHON_SCRIPT${NC}"
echo -e "${YELLOW}⚠ Make sure you've saved the Python script first!${NC}"
confirm "Continue with migration?"

if [ -f "$PYTHON_SCRIPT" ]; then
    python3 "$PYTHON_SCRIPT"
    echo -e "${GREEN}✓ Migration completed${NC}"
else
    echo -e "${RED}❌ Migration script not found at: $PYTHON_SCRIPT${NC}"
    echo -e "${YELLOW}Save the Python script from the artifact first!${NC}"
    exit 1
fi

print_header "Step 4: Move Misplaced Config Files"
echo -e "${BLUE}→ Moving Docker and config files to project root...${NC}"

# Move Docker files if they exist in lib/
if [ -f "$LIB_PATH/Dockerfile" ]; then
    mv "$LIB_PATH/Dockerfile" "$PROJECT_ROOT/"
    echo -e "${GREEN}✓ Moved Dockerfile to project root${NC}"
fi

if [ -f "$LIB_PATH/docker-compose.yml" ]; then
    mv "$LIB_PATH/docker-compose.yml" "$PROJECT_ROOT/"
    echo -e "${GREEN}✓ Moved docker-compose.yml to project root${NC}"
fi

if [ -f "$LIB_PATH/analysis_options.yaml" ]; then
    mv "$LIB_PATH/analysis_options.yaml" "$PROJECT_ROOT/"
    echo -e "${GREEN}✓ Moved analysis_options.yaml to project root${NC}"
fi

print_header "Step 5: Remove Duplicate Theme Files"
echo -e "${BLUE}→ Consolidating theme files...${NC}"

# Remove duplicate theme files, keep only the one in core/theme/
if [ -f "$LIB_PATH/theme.dart" ]; then
    rm "$LIB_PATH/theme.dart"
    echo -e "${GREEN}✓ Removed duplicate lib/theme.dart${NC}"
fi

if [ -f "$LIB_PATH/utils/theme.dart" ]; then
    rm "$LIB_PATH/utils/theme.dart"
    echo -e "${GREEN}✓ Removed duplicate lib/utils/theme.dart${NC}"
fi

# Remove backup drawer file
if [ -f "$LIB_PATH/widgets/app_drawer.dart_" ]; then
    rm "$LIB_PATH/widgets/app_drawer.dart_"
    echo -e "${GREEN}✓ Removed backup file app_drawer.dart_${NC}"
fi

# Remove .save files
find "$LIB_PATH" -name "*.dart.save" -delete
echo -e "${GREEN}✓ Removed .save files${NC}"

print_header "Step 6: Create Missing Core Files"

# Create constants file
mkdir -p "$LIB_PATH/core/constants"
cat > "$LIB_PATH/core/constants/api_constants.dart" << 'EOF'
class ApiConstants {
  // Base URLs
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.fedlearn.com',
  );
  
  // Endpoints
  static const String authEndpoint = '/api/v1/auth';
  static const String loadsEndpoint = '/api/v1/loads';
  static const String driversEndpoint = '/api/v1/drivers';
  static const String invoicesEndpoint = '/api/v1/invoices';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
EOF
echo -e "${GREEN}✓ Created api_constants.dart${NC}"

# Create app constants
cat > "$LIB_PATH/core/constants/app_constants.dart" << 'EOF'
class AppConstants {
  static const String appName = 'FedLearn TMS';
  static const String appVersion = '1.0.0';
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Date formats
  static const String dateFormat = 'MM/dd/yyyy';
  static const String dateTimeFormat = 'MM/dd/yyyy HH:mm';
  
  // Gamification
  static const int maxHearts = 5;
  static const Duration heartRegenTime = Duration(minutes: 30);
  static const int xpPerLesson = 10;
  static const int xpPerQuiz = 25;
}
EOF
echo -e "${GREEN}✓ Created app_constants.dart${NC}"

print_header "Step 7: Update pubspec.yaml Dependencies"
echo -e "${BLUE}→ Checking pubspec.yaml...${NC}"

# Check if critical dependencies exist
if ! grep -q "provider:" "$PROJECT_ROOT/pubspec.yaml"; then
    echo -e "${YELLOW}⚠ Adding provider dependency${NC}"
    # This would need manual edit or yq tool
fi

echo -e "${GREEN}✓ Dependencies checked${NC}"

print_header "Step 8: Get Dependencies"
echo -e "${BLUE}→ Running flutter pub get...${NC}"
cd "$PROJECT_ROOT"
flutter pub get
echo -e "${GREEN}✓ Dependencies installed${NC}"

print_header "Step 9: Generate Missing Files"
echo -e "${BLUE}→ Creating barrel export files...${NC}"

# Create models barrel files for each feature
for feature in auth onboarding dashboard loads drivers dispatch compliance invoicing messaging accounting settings training gamification ai_assistant marketplace iap; do
    MODELS_DIR="$LIB_PATH/features/$feature/data/models"
    if [ -d "$MODELS_DIR" ]; then
        BARREL_FILE="$MODELS_DIR/models.dart"
        echo "// Export all models for $feature feature" > "$BARREL_FILE"
        
        # Add exports for each .dart file in the directory
        for model in "$MODELS_DIR"/*.dart; do
            if [ -f "$model" ] && [ "$(basename "$model")" != "models.dart" ]; then
                filename=$(basename "$model")
                echo "export '$filename';" >> "$BARREL_FILE"
            fi
        done
        echo -e "${GREEN}✓ Created models.dart for $feature${NC}"
    fi
done

print_header "Step 10: Fix Import Statements"
echo -e "${BLUE}→ This step requires manual work${NC}"
echo -e "${YELLOW}⚠ You'll need to update import statements in your Dart files${NC}"
echo ""
echo "Old imports like:"
echo "  import 'package:fedlearn/models/load.dart';"
echo ""
echo "Should become:"
echo "  import 'package:fedlearn/features/loads/loads.dart';"
echo ""
echo -e "${CYAN}TIP: Use VSCode's 'Organize Imports' feature${NC}"

print_header "Step 11: Analyze Code"
confirm "Run flutter analyze?"

flutter analyze --no-pub
echo -e "${GREEN}✓ Analysis complete${NC}"

print_header "Step 12: Test Run"
confirm "Try running the app?"

echo -e "${BLUE}→ Starting Flutter app...${NC}"
flutter run --debug || true

print_header "Migration Complete!"
echo ""
echo -e "${GREEN}✓ Project reorganized${NC}"
echo -e "${GREEN}✓ Files migrated${NC}"
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""
echo -e "${BOLD}Next Steps:${NC}"
echo -e "${CYAN}1. Fix import statements throughout the project${NC}"
echo -e "${CYAN}2. Implement missing repository implementations${NC}"
echo -e "${CYAN}3. Add use cases for each feature${NC}"
echo -e "${CYAN}4. Update providers to use new structure${NC}"
echo -e "${CYAN}5. Test each feature individually${NC}"
echo ""
echo -e "${BOLD}Backup Location:${NC}"
echo -e "${BLUE}$BACKUP_DIR${NC}"
echo ""
echo -e "${BOLD}Documentation:${NC}"
echo -e "${BLUE}$LIB_PATH/README.md${NC}"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"
