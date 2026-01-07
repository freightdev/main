# fdart AI System Architecture

## Overview

The fdart AI system provides a safe, extensible framework for giving AI assistants (via Ollama) controlled access to project operations. It follows a layered architecture with clear separation of concerns.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│                   User Interface                     │
│              (CLI, Interactive REPL)                 │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│                 ai/agent.lua                         │
│         (Orchestration & Task Management)            │
│  • Query processing                                  │
│  • Multi-step workflows                              │
│  • Context management                                │
│  • Helper functions                                  │
└────────────┬───────────────────┬────────────────────┘
             │                   │
    ┌────────▼──────┐   ┌───────▼──────────────┐
    │ ai/ollama.lua │   │ ai/tool_registry.lua │
    │  (AI Client)  │   │  (Tool Management)   │
    └────────┬──────┘   └───────┬──────────────┘
             │                   │
             │          ┌────────▼────────────┐
             │          │   ai/tools/*.lua    │
             │          │  (Tool Modules)     │
             │          │  • file_tools       │
             │          │  • project_tools    │
             │          │  • [custom tools]   │
             │          └─────────────────────┘
             │
┌────────────▼────────────────────────────────────────┐
│              Ollama API (Local LLM)                  │
│         http://localhost:11434/api/chat              │
└──────────────────────────────────────────────────────┘
```

## Component Description

### 1. Core Components

#### `ai/ollama.lua` - LLM Client

- **Purpose**: Interface with Ollama API
- **Responsibilities**:
  - Send requests to Ollama
  - Handle streaming responses
  - Manage conversation history
  - Build context from files
  - Rate limiting
- **Key Functions**:
  - `init()` - Configure connection
  - `generate()` - Non-streaming request
  - `generate_stream()` - Streaming request
  - `add_file_context()` - Add files to context
  - `clear_history()` - Reset conversation

#### `ai/tool_registry.lua` - Tool Management

- **Purpose**: Central registry for all AI tools
- **Responsibilities**:
  - Register/unregister tools
  - Validate parameters
  - Execute tools safely
  - Log all executions
  - Parse tool calls from AI responses
- **Security Features**:
  - Permission checking
  - Dry-run mode support
  - Confirmation for dangerous operations
  - Execution logging
- **Key Functions**:
  - `register(tool)` - Add new tool
  - `execute(name, params)` - Run tool with validation
  - `parse_tool_call(text)` - Extract tool calls from AI response

#### `ai/agent.lua` - Orchestrator

- **Purpose**: High-level interface for AI interactions
- **Responsibilities**:
  - Process user queries
  - Multi-step task execution
  - Tool result feedback loop
  - Interactive mode
  - Common task helpers
- **Key Functions**:
  - `init()` - Initialize agent
  - `query()` - Process single query
  - `execute_task()` - Execute with context
  - `interactive()` - Start REPL
  - Helper methods: `review_code()`, `refactor()`, etc.

### 2. Tool Modules

#### `ai/tools/file_tools.lua`

File system operations with safety checks:

- `read_file` - Read file contents
- `write_file` - Write/overwrite file (with backup)
- `append_file` - Append to file
- `delete_file` - Delete file (with backup)
- `move_file` - Move/rename file
- `copy_file` - Copy file
- `list_directory` - List directory contents
- `create_directory` - Create directory
- `search_in_files` - Search for patterns

#### `ai/tools/project_tools.lua`

Flutter/Dart specific operations:

- `analyze_project` - Analyze project structure
- `run_flutter_command` - Execute Flutter CLI commands
- `create_barrel` - Generate barrel files
- `organize_imports` - Sort and organize imports
- `rename_symbol` - Refactor symbol names project-wide

### 3. Supporting Components

#### `config.lua`

- Configuration management
- YAML/JSON/Lua config files
- Default settings
- Ollama settings
- Tool permissions

#### `utils.lua`

- File I/O operations
- Directory scanning
- Path manipulation
- Command execution
- Pubspec parsing

## Data Flow

### 1. Simple Query Flow

```
User Query
  ↓
agent.query()
  ↓
ollama.generate() ← System prompt + Tools description
  ↓
Ollama API
  ↓
AI Response
  ↓
tool_registry.parse_tool_call()
  ↓
tool_registry.execute()
  ↓
Tool Module
  ↓
Result → User
```

### 2. Multi-Step Task Flow

```
User Task + Context Files
  ↓
agent.execute_task()
  ↓
ollama.add_file_context() (for each file)
  ↓
LOOP (until complete or max iterations):
  ├─ ollama.generate()
  ├─ Parse response for tool calls
  ├─ Execute tools
  ├─ Collect results
  ├─ Build feedback
  └─ Continue if more tools needed
  ↓
Final Response → User
```

## Tool Definition Structure

```lua
{
  name = "tool_name",
  description = "What the tool does",
  category = "file" | "project" | "custom",
  safety_level = "safe" | "caution" | "dangerous",
  requires_confirmation = true/false,
  parameters = {
    {
      name = "param_name",
      type = "string" | "number" | "boolean" | "path",
      required = true/false,
      default = <value>,
      description = "Parameter description"
    }
  },
  execute = function(params, options)
    -- Tool implementation
    return result or nil, error
  end
}
```

## Safety Mechanisms

### 1. Permission System

- `allow_command_execution` - Master switch in config
- `dry_run` - Test mode, no actual changes
- `requires_confirmation` - User approval for dangerous ops
- `safety_level` - Tool classification

### 2. Parameter Validation

- Type checking
- Required parameter enforcement
- Path validation
- Default value assignment

### 3. Execution Logging

- All tool executions logged
- Timestamps and parameters
- Success/failure tracking
- Queryable history

### 4. Backup System

- Automatic backups for destructive operations
- `.backup` file creation
- Configurable backup behavior

### 5. Sandboxing

- Allowed commands whitelist
- No root/sudo operations
- Path restrictions (future enhancement)
- Command injection prevention

## Configuration

### Config File Locations

1. `.fdart.yaml`
2. `.fdart.yml`
3. `.fdart.json`
4. `fdart.config.lua`

### Key Configuration Options

```yaml
ollama:
  enabled: true
  host: localhost
  port: 11434
  model: codellama:13b
  timeout: 300
  max_context_lines: 100
  allow_command_execution: false # Security: disabled by default
  auto_approve_tools: false # Require confirmation
  allowed_commands:
    - fdart
    - flutter
    - dart
    - git
```

## Extending the System

### Adding New Tools

1. **Create tool module**: `ai/tools/my_tools.lua`

```lua
local M = {}
local tool_registry = require("ai.tool_registry")

function M.init()
  tool_registry.register({
    name = "my_tool",
    description = "What it does",
    category = "custom",
    safety_level = "safe",
    parameters = {...},
    execute = function(params)
      -- Implementation
    end
  })
end

return M
```

2. **Load in agent**: Add to `ai/agent.lua` tool_modules list

```lua
local tool_modules = {
  require("ai.tools.file_tools"),
  require("ai.tools.project_tools"),
  require("ai.tools.my_tools"),  -- Add here
}
```

3. **Test**: Tools automatically appear in AI's tool list

### Adding New AI Providers

To support providers beyond Ollama:

1. Create `ai/providers/provider_name.lua`
2. Implement standard interface:
   - `init()`
   - `generate()`
   - `generate_stream()`
3. Update `ai/agent.lua` to support provider selection
4. Add provider-specific config options

## Best Practices

### For Tool Developers

1. ✅ Always validate parameters
2. ✅ Set appropriate safety_level
3. ✅ Provide clear descriptions
4. ✅ Handle errors gracefully
5. ✅ Return structured results
6. ✅ Create backups for destructive ops
7. ✅ Test edge cases

### For Users

1. ✅ Start with `allow_command_execution = false`
2. ✅ Use `dry_run = true` for testing
3. ✅ Review tool calls before approving
4. ✅ Keep conversation history reasonable
5. ✅ Clear context between unrelated tasks
6. ✅ Back up important files manually
7. ✅ Monitor execution logs

## Security Considerations

### Threats Mitigated

- ✅ Arbitrary command execution
- ✅ Unauthorized file access (partial)
- ✅ Accidental data loss (via backups)
- ✅ Command injection
- ✅ Privilege escalation

### Remaining Risks

- ⚠️ AI hallucinations leading to incorrect changes
- ⚠️ Path traversal (needs additional validation)
- ⚠️ Resource exhaustion (long-running tasks)
- ⚠️ Sensitive data in prompts/logs

### Recommendations

1. Never run with elevated privileges
2. Review AI suggestions before approval
3. Use version control (git)
4. Limit max_iterations for complex tasks
5. Regularly review execution logs
6. Don't include secrets in prompts

## Performance Considerations

### Optimization Strategies

1. **Context Management**: Limit context window size
2. **Caching**: Use cached responses when possible
3. **Batch Operations**: Group related tool calls
4. **Streaming**: Use streaming for long responses
5. **Rate Limiting**: Prevent API overload

### Resource Usage

- **Memory**: Conversation history grows linearly
- **Network**: One HTTP request per AI query
- **Disk**: Backups can accumulate quickly
- **CPU**: Tool execution varies by operation

## Troubleshooting

### Common Issues

**AI not responding**

- Check Ollama is running: `curl http://localhost:11434/api/tags`
- Verify model is pulled: `ollama list`
- Check network connectivity

**Tools not executing**

- Verify `allow_command_execution = true`
- Check tool is registered: `agent.stats()`
- Review execution log: `tool_registry.get_log()`

**Context issues**

- Clear history: `ollama.clear_history()`
- Reduce context files
- Lower `max_context_lines`

**Performance problems**

- Reduce `max_iterations`
- Use smaller model
- Clear cache
- Limit conversation history

## Future Enhancements

### Planned Features

- [ ] Multi-provider support (OpenAI, Anthropic)
- [ ] Advanced path validation
- [ ] Resource usage limits
- [ ] Tool marketplace
- [ ] Web UI
- [ ] Collaborative sessions
- [ ] Undo/redo system
- [ ] Enhanced caching
- [ ] Plugin system
- [ ] Remote execution

### Community Contributions

See `CONTRIBUTING.md` for guidelines on adding tools, providers, and features.

## License & Credits

This architecture is part of the fdart project. See LICENSE file for details.
