-- fdart/examples/ai_usage.lua
-- Examples of using the AI agent system

local agent = require("ai.agent")
local config = require("config")

-- Example 1: Initialize and use the agent
function example_basic()
  print("=== Example 1: Basic Usage ===\n")
  
  -- Initialize with custom options
  local success, err = agent.init({
    model = "codellama:13b",
    temperature = 0.7,
    auto_execute = false, -- Require confirmation for tool execution
    interactive = false
  })
  
  if not success then
    print("Failed to initialize:", err)
    return
  end
  
  -- Simple query
  local result = agent.query("What files are in the lib directory?")
  
  if result then
    print("Response:", result.final_response)
    print("Iterations:", #result.iterations)
  end
end

-- Example 2: Code review with context
function example_code_review()
  print("\n=== Example 2: Code Review ===\n")
  
  agent.init()
  
  -- Review a specific file
  local result = agent.review_code("lib/services/user_service.dart")
  
  if result then
    print(result.final_response)
  end
end

-- Example 3: Multi-step refactoring task
function example_refactoring()
  print("\n=== Example 3: Refactoring Task ===\n")
  
  agent.init({auto_execute = true}) -- Auto-approve tool executions
  
  local task = [[
Refactor the authentication flow:
1. Read the current auth_service.dart
2. Identify security issues
3. Propose improvements
4. Create a new improved version with proper error handling
]]
  
  local result = agent.execute_task(task, {
    "lib/services/auth_service.dart",
    "lib/models/user.dart"
  })
  
  if result then
    print("Task completed in", #result.iterations, "iterations")
    for i, iteration in ipairs(result.iterations) do
      print(string.format("\nIteration %d:", i))
      print("Tools used:", #iteration.tools_executed)
      for _, tool_result in ipairs(iteration.tools_executed) do
        print(string.format("  - %s: %s", 
          tool_result.tool, 
          tool_result.success and "✓" or "✗"
        ))
      end
    end
    print("\nFinal response:", result.final_response)
  end
end

-- Example 4: Project-wide operations
function example_project_operations()
  print("\n=== Example 4: Project Operations ===\n")
  
  agent.init()
  
  local task = [[
Analyze the project and:
1. List all services in lib/services
2. Check if they follow consistent naming patterns
3. Identify any services missing tests
4. Create a summary report
]]
  
  local result = agent.query(task)
  print(result.final_response)
end

-- Example 5: Interactive mode
function example_interactive()
  print("\n=== Example 5: Interactive Mode ===\n")
  
  -- This starts an interactive REPL
  agent.interactive()
end

-- Example 6: Using specific tools directly
function example_direct_tool_usage()
  print("\n=== Example 6: Direct Tool Usage ===\n")
  
  local tool_registry = require("ai.tool_registry")
  local file_tools = require("ai.tools.file_tools")
  local project_tools = require("ai.tools.project_tools")
  
  -- Initialize tools
  file_tools.init()
  project_tools.init()
  
  -- Execute a tool directly
  local result, err = tool_registry.execute("read_file", {
    path = "lib/main.dart",
    max_lines = 50
  })
  
  if result then
    print("File content (first 50 lines):")
    print(result.content)
  else
    print("Error:", err)
  end
  
  -- Execute another tool
  local analysis = tool_registry.execute("analyze_project", {
    path = "."
  })
  
  if analysis then
    print("\nProject:", analysis.name)
    print("Version:", analysis.version)
    print("Dependencies:", table.concat(analysis.dependencies, ", "))
    print("Dart files:", analysis.dart_files.count)
    print("Total lines:", analysis.dart_files.total_lines)
  end
end

-- Example 7: Custom workflow
function example_custom_workflow()
  print("\n=== Example 7: Custom Workflow ===\n")
  
  agent.init()
  
  -- Step 1: Analyze project
  print("Step 1: Analyzing project structure...")
  local analysis = agent.query("Analyze the project structure and identify the main components")
  
  -- Step 2: Based on analysis, ask for improvements
  print("\nStep 2: Getting improvement suggestions...")
  local improvements = agent.query(
    "Based on the project structure, suggest architectural improvements and best practices"
  )
  
  -- Step 3: Generate implementation plan
  print("\nStep 3: Creating implementation plan...")
  local plan = agent.query(
    "Create a detailed, step-by-step plan to implement the suggested improvements"
  )
  
  print("\n=== Workflow Complete ===")
  print(plan.final_response)
end

-- Example 8: Error handling and safety
function example_safety()
  print("\n=== Example 8: Safety Features ===\n")
  
  config.set("ollama.allow_command_execution", true)
  config.set("dry_run", false) -- Enable for testing without actual changes
  
  agent.init({
    auto_execute = false, -- Always ask for confirmation
    interactive = true
  })
  
  -- This will require user confirmation before executing
  local result = agent.query("Delete all .backup files in the project")
  
  -- Check execution log
  local tool_registry = require("ai.tool_registry")
  local log = tool_registry.get_log(5)
  
  print("\nRecent tool executions:")
  for i, entry in ipairs(log) do
    print(string.format("%d. %s [%s] - %s",
      i,
      entry.tool,
      entry.safety_level,
      entry.success and "Success" or "Failed"
    ))
  end
end

-- Example 9: Context management
function example_context_management()
  print("\n=== Example 9: Context Management ===\n")
  
  local ollama = require("ai.ollama")
  agent.init()
  
  -- Add multiple files to context
  print("Adding files to context...")
  ollama.add_file_context("lib/main.dart")
  ollama.add_file_context("lib/app.dart")
  ollama.add_file_context("pubspec.yaml")
  
  -- Now queries will automatically include this context
  local result = agent.query(
    "Based on the project files, explain the app's entry point and main structure"
  )
  
  print(result.final_response)
  
  -- Clear context when done
  ollama.clear_context()
  print("\nContext cleared.")
end

-- Example 10: Streaming responses
function example_streaming()
  print("\n=== Example 10: Streaming Responses ===\n")
  
  agent.init()
  
  print("Generating response (streaming)...\n")
  
  local result = agent.query(
    "Explain the benefits of using Flutter for mobile development",
    {
      stream = true,
      callback = function(chunk, done)
        io.write(chunk)
        io.flush()
        if done then
          print("\n\n[Stream complete]")
        end
      end
    }
  )
end

-- Run all examples
function run_all_examples()
  -- Check if Ollama is available
  local ollama = require("ai.ollama")
  if not ollama.is_available() then
    print("Error: Ollama is not running. Please start Ollama first.")
    print("Run: ollama serve")
    return
  end
  
  local examples = {
    {"Basic Usage", example_basic},
    {"Code Review", example_code_review},
    {"Refactoring Task", example_refactoring},
    {"Project Operations", example_project_operations},
    {"Direct Tool Usage", example_direct_tool_usage},
    {"Custom Workflow", example_custom_workflow},
    {"Context Management", example_context_management},
    {"Streaming", example_streaming},
    -- Skip interactive and safety examples in batch mode
  }
  
  for i, example in ipairs(examples) do
    print(string.format("\n\n%s\n%s", string.rep("=", 60), example[1]))
    print(string.rep("=", 60))
    
    local success, err = pcall(example[2])
    if not success then
      print("Example failed:", err)
    end
    
    -- Small delay between examples
    os.execute("sleep 2")
  end
  
  print("\n\nAll examples completed!")
end

-- Main execution
if arg[1] == "all" then
  run_all_examples()
elseif arg[1] and _G["example_" .. arg[1]] then
  _G["example_" .. arg[1]]()
else
  print("Usage: lua ai_usage.lua [example_name|all]")
  print("\nAvailable examples:")
  print("  basic, code_review, refactoring, project_operations,")
  print("  interactive, direct_tool_usage, custom_workflow,")
  print("  safety, context_management, streaming, all")
end