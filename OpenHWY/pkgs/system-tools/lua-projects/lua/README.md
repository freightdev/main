# fdart - Flutter Dart Development Toolkit v5.0.0

Complete documentation for the modular Flutter/Dart development CLI with AI integration.

## Table of Contents

1. [Installation](#installation)
2. [Quick Start](#quick-start)
3. [Configuration](#configuration)
4. [Commands Reference](#commands-reference)
5. [AI Integration (Ollama)](#ai-integration-ollama)
6. [Project Structure](#project-structure)
7. [Examples](#examples)
8. [Security Considerations](#security-considerations)
9. [Troubleshooting](#troubleshooting)

---

## Installation

### Prerequisites

- Lua 5.1 or higher
- LuaFileSystem (lfs) library
- Optional: dkjson or cjson for JSON support
- Optional: Ollama for AI features

### Install Dependencies

```bash
# Ubuntu/Debian
sudo apt-get install lua5.3 lua-filesystem lua-json

# macOS (using Homebrew)
brew install lua luarocks
luarocks install luafilesystem
luarocks install dkjson

# Install Ollama (for AI features)
curl -fsSL https://ollama.com/install.sh | sh
```

### Install fdart

```bash
# Clone or download fdart
git clone https://github.com/yourusername/fdart.git
cd fdart

# Make executable
chmod +x init.lua

# Create symlink (optional)
sudo ln -s $(pwd)/init.lua /usr/local/bin/fdart

# Verify installation
fdart version
```

### Directory Structure

```
fdart/
├── init.lua                    # Main entry point
└── lua/
    └── fdart/
        ├── config.lua          # Configuration manager
        ├── logger.lua          # Logging system
        ├── cli.lua             # CLI parser
        ├── utils.lua           # Utility functions
        ├── commands.lua        # Command registry
        ├── indexer.lua         # Symbol indexer
        ├── analyzer.lua        # Code analyzer
        ├── fixer.lua           # Import fixer
        ├── ai/
        │   └── ollama.lua      # Ollama AI integration
        └── commands/
            ├── init.lua        # Init command
            ├── fix.lua         # Fix command
            ├── debug.lua       # Debug command
            ├── ai.lua          # AI commands
            ├── barrel.lua      # Barrel commands
            └── ...             # Other commands
```

---

## Quick Start

### Initialize in Your Project

```bash
cd your-flutter-project
fdart init
```

This creates a `.fdart.yaml` configuration file in your project.

### Basic Usage

```bash
# Auto-fix all import issues
fdart fix --dir lib

# Run health check
fdart doctor

# Debug and auto-fix build errors
fdart debug --verbose

# Get project statistics
fdart stats
```

### With AI Assistant

```bash
# Ask AI for help
fdart ai "Why is my Flutter build failing?"

# Let AI analyze and suggest fixes
fdart ai-fix

# Interactive chat with AI
fdart ai-chat
```

---

## Configuration

### Configuration Files

fdart looks for configuration in these files (in order):

1. `.fdart.yaml` (recommended)
2. `.fdart.yml`
3. `.fdart.json`
4. `fdart.config.lua`

### Example: `.fdart.yaml`

```yaml
# General settings
project_root: .
lib_dir: lib
deep_scan: true
backup: true
verbose: false
log_level: info

# File patterns
include_patterns:
  - "%.dart$"

exclude_patterns:
  - "%.g%.dart$"
  - "%.freezed%.dart$"
  - "%.mocks%.dart$"

exclude_dirs:
  - "%.git"
  - "%.dart_tool"
  - build
  - test

# Analysis settings
max_file_size: 500
max_fix_iterations: 5
auto_pubget: true
auto_format: true

# Barrel settings
barrel_filename: index.dart
auto_barrel: true

# AI/Ollama settings
ollama:
  enabled: true
  host: localhost
  port: 11434
  model: codellama:13b
  timeout: 300
  max_context_lines: 100

  # SECURITY: Enable with caution!
  allow_command_execution: false

  allowed_commands:
    - fdart
    - flutter
    - dart
    - git
    - tree
    - cat
    - grep
    - find

  system_prompt: |
    You are an expert Flutter/Dart developer assistant.
    You help fix code issues, suggest improvements, and can execute safe commands.
    Always explain your reasoning and be precise with code suggestions.
    When suggesting commands, use the format: fdart cmd <command>

# Import organization
import_order:
  - "dart:"
  - "package:flutter/"
  - "package:"
  - relative

# Cache settings
use_cache: true
cache_file: .fdart_cache.json
cache_ttl: 3600

# Output settings
output_format: pretty
color: true
icons: true
```

### Example: `.fdart.json`

```json
{
  "ollama": {
    "enabled": true,
    "host": "192.168.1.100",
    "port": 11434,
    "model": "codellama:13b",
    "allow_command_execution": false
  },
  "deep_scan": true,
  "auto_pubget": true,
  "max_fix_iterations": 5
}
```

### Example: `fdart.config.lua`

```lua
return {
  deep_scan = true,
  auto_pubget = true,

  ollama = {
    enabled = true,
    host = "localhost",
    model = "codellama:13b",
    allow_command_execution = false
  },

  exclude_dirs = {
    "%.git", "%.dart_tool", "build"
  }
}
```

---

## Commands Reference

### Core Commands

#### `fdart init`

Initialize fdart in your project. Creates configuration file.

```bash
fdart init
fdart init --config .fdart.yaml
```

#### `fdart config`

Manage configuration settings.

```bash
# Show current configuration
fdart config show

# Set a value
fdart config set ollama.model codellama:13b

# Get a value
fdart config get ollama.host
```

#### `fdart doctor`

Run comprehensive health check on your project.

```bash
fdart doctor
fdart doctor --verbose
```

### Code Analysis

#### `fdart analyze`

Analyze code quality and patterns.

```bash
fdart analyze --dir lib
fdart analyze --verbose
```

#### `fdart index`

Build symbol index from barrel files.

```bash
fdart index --dir lib
fdart index --output json > symbols.json
```

#### `fdart stats`

Show project statistics.

```bash
fdart stats
fdart stats --output json
```

#### `fdart tree`

Display project structure.

```bash
fdart tree
fdart tree --no-deep  # Only top level
```

#### `fdart find <query>`

Find symbols by name.

```bash
fdart find UserModel
fdart find "Button" --dir lib/widgets
```

### Code Fixing

#### `fdart fix`

Auto-fix missing imports.

```bash
fdart fix --dir lib
fdart fix --verbose
fdart fix --no-backup
```

#### `fdart check`

Check imports without modifying files (dry-run).

```bash
fdart check --dir lib
```

#### `fdart format`

Format Dart code using `dart format`.

```bash
fdart format --dir lib
```

#### `fdart organize-imports`

Organize and sort imports according to Dart style guide.

```bash
fdart organize-imports --dir lib
```

### Barrel Management

#### `fdart barrel-create`

Generate `index.dart` barrel files.

```bash
fdart barrel-create --dir lib
fdart barrel-create --force  # Overwrite existing
```

#### `fdart barrel-update`

Update existing barrel files.

```bash
fdart barrel-update --dir lib
```

#### `fdart barrel-clean`

Remove unused exports from barrels.

```bash
fdart barrel-clean --dir lib
```

### Building & Debugging

#### `fdart debug`

Auto-debug and fix build errors with iterative fixing.

```bash
fdart debug --verbose
fdart debug --max-iterations 10
```

#### `fdart run`

Run app with auto-fixing enabled.

```bash
fdart run
fdart run --verbose
```

#### `fdart build`

Build project with diagnostics.

```bash
fdart build
fdart build --release
```

#### `fdart clean`

Clean build artifacts.

```bash
fdart clean
fdart clean --force  # Also remove generated files
```

### AI Assistant Commands

#### `fdart ai <prompt>`

Ask AI for help with a specific question.

```bash
fdart ai "Why is my Flutter build failing?"
fdart ai "How do I implement state management with Riverpod?"
fdart ai "Explain this error: $(flutter run 2>&1 | head -10)"
```

**With custom model:**

```bash
fdart ai "Fix my imports" --model deepseek-coder:33b
fdart ai "Review this code" --model qwen2.5-coder:32b
```

#### `fdart ai-fix`

Let AI analyze errors and suggest/execute fixes.

```bash
fdart ai-fix
fdart ai-fix --allow-commands  # Let AI execute fixes
fdart ai-fix --model codellama:34b
```

**Example workflow:**

```bash
# AI analyzes errors and suggests commands
fdart ai-fix

# Output:
# Found 3 errors
# AI Analysis:
# 1. Missing import for 'BuildContext'
#    Fix: fdart cmd flutter pub add flutter_sdk
# 2. Undefined symbol 'UserModel'
#    Fix: fdart fix --dir lib
# ...
```

#### `fdart ai-review`

Get AI code review for your project.

```bash
fdart ai-review
fdart ai-review --dir lib/features/auth
```

#### `fdart ai-chat`

Interactive chat session with AI.

```bash
fdart ai-chat
fdart ai-chat --model deepseek-coder:33b
```

**Chat commands:**

- `exit` or `quit` - End session
- `context` - Refresh project context
- `execute <cmd>` - Run a command

**Example session:**

```
You: Why am I getting "The method 'X' isn't defined"?
AI: This error typically means... [analysis]
    Try running: fdart cmd flutter pub get

You: execute fdart fix --dir lib
Executed: fdart fix --dir lib
[Output shown]

You: Thanks! Now how do I add tests?
AI: To add tests for Flutter... [explanation]
```

### Utility Commands

#### `fdart deps`

Analyze project dependencies.

```bash
fdart deps
fdart deps --output json
```

#### `fdart scaffold`

Create recommended project structure.

```bash
fdart scaffold
fdart scaffold --dry-run
```

#### `fdart watch`

Watch for changes and auto-fix.

```bash
fdart watch --dir lib
fdart watch --verbose
```

#### `fdart cmd <command>`

Execute shell command (primarily for AI use).

```bash
fdart cmd flutter pub get
fdart cmd tree -L 2 lib
```

**Note:** This command respects the `allowed_commands` configuration for security.

---

## AI Integration (Ollama)

### Setup Ollama

#### 1. Install Ollama

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

#### 2. Download Models

```bash
# Recommended for Flutter/Dart
ollama pull codellama:13b

# Alternative models
ollama pull deepseek-coder:33b
ollama pull qwen2.5-coder:32b
ollama pull mistral:latest
```

#### 3. Configure fdart

Edit `.fdart.yaml`:

```yaml
ollama:
  enabled: true
  host: localhost
  port: 11434
  model: codellama:13b
  allow_command_execution: false
```

#### 4. Test Connection

```bash
fdart ai "Hello, can you help me with Flutter?"
```

### Remote Ollama Setup

If running Ollama on a different machine:

```yaml
ollama:
  enabled: true
  host: 192.168.1.100 # Your Ollama server IP
  port: 11434
  model: codellama:13b
```

```bash
# Or via command line
fdart ai "Help me" --host 192.168.1.100 --port 11434
```

### AI Command Execution

**⚠️ SECURITY WARNING:** Enabling command execution allows AI to run commands on your system.

#### Enable Command Execution

In `.fdart.yaml`:

```yaml
ollama:
  allow_command_execution: true
  allowed_commands:
    - fdart
    - flutter
    - dart
    - git
    - tree
    - cat
    - grep
    - find
    # Add only commands you trust
```

Or via command line:

```bash
fdart ai-fix --allow-commands
```

#### How It Works

1. **AI analyzes** your project and errors
2. **AI suggests** commands in the format: `fdart cmd <command>`
3. **fdart checks** if command is in `allowed_commands`
4. **Command executes** if allowed, output returned to AI
5. **AI refines** suggestions based on results

#### Example Flow

```bash
$ fdart ai-fix --allow-commands

🧠 Gathering project context...
🐛 Found 2 errors:
  - lib/main.dart:15 - Undefined name 'HomePage'
  - lib/main.dart:20 - Missing import

🤖 Consulting AI...

AI Analysis:
You're missing imports and barrel files. Here's the fix:

1. Create barrel files for better imports:
   fdart cmd fdart barrel-create --dir lib

2. Fix missing imports:
   fdart cmd fdart fix --dir lib

3. Run pub get to ensure dependencies:
   fdart cmd flutter pub get

Executing commands...
✔ Command 1 succeeded: Created 3 barrel files
✔ Command 2 succeeded: Added 2 imports
✔ Command 3 succeeded: Dependencies updated

Try building again: flutter run
```

### Prompting Best Practices

#### Provide Context

```bash
# Include error output
fdart ai "I'm getting this error: $(flutter run 2>&1 | grep ERROR)"

# Include file contents
fdart ai "Review this file: $(cat lib/main.dart)"

# Include structure
fdart ai "I have this structure: $(tree -L 2 lib)"
```

#### Be Specific

```bash
# Good
fdart ai "How do I fix 'The method isEmpty isn't defined for the type String?' in Dart 3.0?"

# Better
fdart ai "I'm getting 'isEmpty isn't defined' on line 45 of lib/utils/validator.dart. Here's the code: [paste code]. Using Dart 3.0."
```

#### Use AI for Learning

```bash
fdart ai "Explain the difference between StatelessWidget and StatefulWidget"
fdart ai "Show me best practices for folder structure in Flutter"
fdart ai "How should I organize imports in Dart?"
```

---

## Project Structure

### Recommended Flutter Structure

```
your_project/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── index.dart
│   │   │   ├── app_constants.dart
│   │   │   └── api_constants.dart
│   │   ├── theme/
│   │   │   ├── index.dart
│   │   │   └── app_theme.dart
│   │   ├── utils/
│   │   │   ├── index.dart
│   │   │   └── helpers.dart
│   │   └── extensions/
│   │       ├── index.dart
│   │       └── string_extensions.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── index.dart
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   └── home/
│   │       └── ...
│   ├── models/
│   │   ├── index.dart
│   │   └── user_model.dart
│   ├── services/
│   │   ├── index.dart
│   │   ├── api_service.dart
│   │   └── auth_service.dart
│   ├── widgets/
│   │   ├── common/
│   │   │   ├── index.dart
│   │   │   ├── custom_button.dart
│   │   │   └── loading_indicator.dart
│   │   └── index.dart
│   ├── screens/
│   │   ├── index.dart
│   │   ├── home_screen.dart
│   │   └── login_screen.dart
│   └── main.dart
├── test/
├── .fdart.yaml
└── pubspec.yaml
```

Use `fdart scaffold` to create this structure automatically.

---

## Examples

### Example 1: Complete Workflow

```bash
# 1. Initialize
cd your-flutter-project
fdart init

# 2. Set up AI
nano .fdart.yaml  # Configure Ollama

# 3. Run health check
fdart doctor

# 4. Generate barrels
fdart barrel-create --dir lib

# 5. Fix imports
fdart fix --dir lib --verbose

# 6. Check for issues
fdart analyze

# 7. Try building with auto-fix
fdart debug

# 8. Ask AI for help if needed
fdart ai "How can I improve my project structure?"
```

### Example 2: AI-Powered Debugging

```bash
# Capture errors and send to AI
ERROR_OUTPUT=$(flutter run 2>&1 | grep -A 5 ERROR)
fdart ai "Fix this error: $ERROR_OUTPUT"

# Let AI automatically fix
fdart ai-fix --allow-commands

# Or interactive session
fdart ai-chat
> I'm getting build errors
> [AI provides analysis]
> execute fdart debug
> [Errors fixed]
> Thanks!
```

### Example 3: Code Review

```bash
# Get AI review of specific file
fdart ai "Review lib/features/auth/presentation/login_screen.dart for best practices"

# Get project-wide review
fdart ai-review

# Review specific feature
fdart ai-review --dir lib/features/payment
```

### Example 4: Import Management

```bash
# Check what needs fixing
fdart check --dir lib --verbose

# Fix all imports
fdart fix --dir lib

# Organize imports
fdart organize-imports --dir lib

# Update barrels
fdart barrel-update --dir lib
```

### Example 5: Watch Mode

```bash
# Terminal 1: Watch for changes
fdart watch --dir lib --verbose

# Terminal 2: Make changes
# fdart automatically fixes imports as you code
```

---

## Security Considerations

### Command Execution

**NEVER enable `allow_command_execution: true` on untrusted AI models or networks.**

#### Safe Configuration

```yaml
ollama:
  allow_command_execution: false # Always default to false

  # When enabling, restrict commands
  allowed_commands:
    - fdart
    - flutter
    - dart
    # NO: rm, sudo, curl to unknown URLs, etc.
```

#### What NOT to Allow

❌ `rm`, `sudo`, `chmod`, `dd`
❌ Network commands to untrusted sources: `curl`, `wget`
❌ Package managers: `apt`, `brew` (unless you understand risks)
❌ Shell execution: `bash`, `sh`, `eval`

#### Safe Workflow

1. **Dry-run first:**

   ```bash
   fdart ai-fix  # Without --allow-commands
   ```

2. **Review suggested commands** carefully

3. **Execute manually** if unsure:
   ```bash
   # AI suggested: fdart cmd flutter pub get
   # Run manually: flutter pub get
   ```

### Network Security

#### Local Ollama

```yaml
ollama:
  host: localhost # Safest
  port: 11434
```

#### Remote Ollama

```yaml
ollama:
  host: 192.168.1.100 # Internal network only
  port: 11434
  # Consider using SSH tunnel for internet access
```

### Data Privacy

- AI requests send code context to Ollama
- With local Ollama, data stays on your machine
- Remote Ollama: ensure trusted network
- Avoid sending sensitive credentials, API keys

---

## Troubleshooting

### Ollama Connection Issues

**Problem:** `AI request failed: Request failed`

**Solutions:**

```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# Start Ollama
ollama serve

# Check model is available
ollama list
ollama pull codellama:13b

# Test with fdart
fdart ai "test" --verbose
```

### Model Not Found

**Problem:** `Model 'xxx' not found`

**Solution:**

```bash
# List available models
ollama list

# Pull the model
ollama pull codellama:13b

# Update config
fdart config set ollama.model codellama:13b
```

### Permission Denied

**Problem:** `Command execution failed: Permission denied`

**Solution:**

```bash
# Check allowed_commands in config
fdart config get ollama.allowed_commands

# Add command to allowed list
nano .fdart.yaml
```

### Import Fixes Not Working

**Problem:** `No symbols found` or `Imports not added`

**Solutions:**

```bash
# 1. Ensure barrel files exist
fdart barrel-create --dir lib

# 2. Rebuild index
fdart index --dir lib

# 3. Try fixing with verbose
fdart fix --dir lib --verbose

# 4. Check pubspec.yaml has correct name
cat pubspec.yaml | grep name:
```

### Slow Performance

**Solutions:**

```bash
# 1. Disable deep scanning for large projects
fdart fix --dir lib --no-deep

# 2. Use cache
fdart config set use_cache true

# 3. Exclude test directories
fdart fix --dir lib  # lib only, not test/

# 4. Use faster AI model
fdart config set ollama.model codellama:7b
```

### Build Errors Not Detected

**Problem:** `fdart debug` doesn't find errors

**Solution:**

```bash
# Ensure Flutter is in PATH
which flutter

# Try verbose mode
fdart debug --verbose

# Manually check Flutter errors
flutter analyze
flutter run --verbose
```

---

## Advanced Configuration

### Custom Error Patterns

Create `fdart.config.lua`:

```lua
return {
  custom_error_patterns = {
    {
      pattern = "CustomError: (.+)",
      type = "custom",
      fix = function(match, file_path)
        return {
          description = "Custom error: " .. match,
          action = "custom_fix",
          data = match
        }
      end
    }
  }
}
```

### Integration with CI/CD

```yaml
# .github/workflows/flutter-check.yml
name: Flutter Check

on: [push, pull_request]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Setup Lua
        run: |
          sudo apt-get install lua5.3 lua-filesystem lua-json

      - name: Setup fdart
        run: |
          git clone https://github.com/yourusername/fdart.git
          echo "$PWD/fdart" >> $GITHUB_PATH

      - name: Check imports
        run: fdart check --dir lib

      - name: Run analysis
        run: fdart analyze --dir lib
```

### VSCode Integration

Create `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "fdart: Fix Imports",
      "type": "shell",
      "command": "fdart fix --dir lib",
      "problemMatcher": []
    },
    {
      "label": "fdart: AI Fix",
      "type": "shell",
      "command": "fdart ai-fix",
      "problemMatcher": []
    }
  ]
}
```

---

## Contributing

Contributions welcome! Areas for improvement:

- Additional error patterns
- More AI prompts and workflows
- Support for other AI models (OpenAI, Claude API)
- Better Windows support
- Additional language support (Kotlin, Swift for Flutter)

---

## License

MIT License - See LICENSE file

---

## Support

- GitHub Issues: https://github.com/yourusername/fdart/issues
- Documentation: https://github.com/yourusername/fdart/wiki
- Discord: [Your Discord Server]

---

**Happy Flutter Development! 🚀📱**
