#!/bin/bash

# Fix Flutter imports - Convert relative imports to package imports
# Usage: ./fix_imports.sh

PACKAGE_NAME="playground"
LIB_DIR="lib"

echo "🔧 Fixing imports in $LIB_DIR/ directory..."
echo "📦 Package name: $PACKAGE_NAME"
echo ""

# Counter for tracking changes
total_files=0
modified_files=0

# Find all .dart files recursively
find "$LIB_DIR" -type f -name "*.dart" | while read -r file; do
    total_files=$((total_files + 1))
    
    # Create backup
    cp "$file" "$file.bak"
    
    # Use sed to fix imports
    # This handles multiple patterns:
    # 1. import '../path/file.dart' 
    # 2. import '../../path/file.dart'
    # 3. import './file.dart'
    # 4. import 'file.dart' (same directory, not already package:)
    
    # Get the file's directory relative to lib/
    file_dir=$(dirname "$file")
    rel_path="${file_dir#$LIB_DIR/}"
    
    # Use Python for more reliable path resolution
    python3 - "$file" "$rel_path" "$PACKAGE_NAME" << 'PYTHON_SCRIPT'
import sys
import re
import os

file_path = sys.argv[1]
rel_path = sys.argv[2]
package_name = sys.argv[3]

if rel_path == "lib":
    rel_path = ""

with open(file_path, 'r') as f:
    content = f.read()

original_content = content
lines = content.split('\n')
new_lines = []

for line in lines:
    # Match import statements with relative paths
    match = re.match(r"^(\s*import\s+['\"])((\.\.?/)+[^'\"]+\.dart)(['\"];?.*)$", line)
    
    if match:
        prefix = match.group(1)
        relative_import = match.group(2)
        suffix = match.group(4)
        
        # Calculate absolute path from lib/
        current_dir = rel_path
        remaining = relative_import
        
        # Handle ../ navigation
        while remaining.startswith('../'):
            if current_dir:
                current_dir = os.path.dirname(current_dir)
            remaining = remaining[3:]
        
        # Handle ./ (same directory)
        if remaining.startswith('./'):
            remaining = remaining[2:]
        
        # Combine paths
        if current_dir:
            absolute_path = os.path.join(current_dir, remaining).replace('\\', '/')
        else:
            absolute_path = remaining
        
        # Create new import line
        new_line = f"{prefix}package:{package_name}/{absolute_path}{suffix}"
        new_lines.append(new_line)
    
    # Match same-directory imports (no path, no package:, no dart:)
    elif re.match(r"^\s*import\s+['\"]([^/:'\"]+\.dart)['\"]", line) and 'package:' not in line and 'dart:' not in line:
        match = re.match(r"^(\s*import\s+['\"])([^/:'\"]+\.dart)(['\"];?.*)$", line)
        if match:
            prefix = match.group(1)
            filename = match.group(2)
            suffix = match.group(3)
            
            if rel_path:
                absolute_path = f"{rel_path}/{filename}"
            else:
                absolute_path = filename
            
            new_line = f"{prefix}package:{package_name}/{absolute_path}{suffix}"
            new_lines.append(new_line)
    else:
        new_lines.append(line)

new_content = '\n'.join(new_lines)

# Write back if changed
if new_content != original_content:
    with open(file_path, 'w') as f:
        f.write(new_content)
    sys.exit(1)  # Signal that file was modified
else:
    sys.exit(0)  # Signal no changes
PYTHON_SCRIPT
    
    if [ $? -eq 1 ]; then
        modified_files=$((modified_files + 1))
        echo "✅ Fixed: $file"
        rm "$file.bak"
    else
        echo "⏭️  Skipped: $file (no changes needed)"
        mv "$file.bak" "$file"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Import fixing complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🚀 Next steps:"
echo "   1. Run: flutter pub get"
echo "   2. Run: flutter analyze"
echo "   3. Run: flutter run"
