-- fdart/lua/ai/agent.lua
-- High-level AI agent that orchestrates tools and conversations

local ollama = require("ai.ollama")
local tool_registry = require("ai.tool_registry")
local config = require("config")
local utils = require("utils")

local M = {}

M.state = {
  initialized = false,
  interactive = false,
  auto_execute = false,
  max_iterations = 5
}

-- Initialize the AI agent
function M.init(options)
  options = options or {}
  
  -- Initialize Ollama client
  ollama.init(options)
  
  -- Check if Ollama is available
  if not ollama.is_available() then
    return false, "Ollama is not available. Please start Ollama service."
  end
  
  -- Load all tool modules
  local tool_modules = {
    require("ai.tools.file_tools"),
    require("ai.tools.project_tools")
  }
  
  for _, module in ipairs(tool_modules) do
    local success, err = pcall(module.init)
    if not success then
      print("Warning: Failed to load tool module: " .. tostring(err))
    end
  end
  
  -- Configure agent
  M.state.interactive = options.interactive or false
  M.state.auto_execute = options.auto_execute or false
  M.state.max_iterations = options.max_iterations or 5
  
  -- Enhance system prompt with tool descriptions
  M.enhance_system_prompt()
  
  M.state.initialized = true
  return true
end

-- Enhance system prompt with tool information
function M.enhance_system_prompt()
  local base_prompt = config.get("ollama.system_prompt", "")
  local tool_desc = tool_registry.get_tool_descriptions()
  
  local enhanced = base_prompt .. "\n\n" .. [[

# Available Tools

You have access to the following tools. To use a tool, respond with:
TOOL_CALL: tool_name(param1="value1", param2=value2)

You can chain multiple tool calls by including multiple TOOL_CALL lines in your response.

]] .. tool_desc .. [[


# Tool Usage Guidelines

1. **Always explain your reasoning** before calling tools
2. **Read before writing**: Use read_file to understand existing code before modifying
3. **Make backups**: Most file modification tools create backups automatically
4. **Be specific**: Provide exact paths and clear parameters
5. **Verify results**: Check tool execution results before proceeding
6. **Batch operations**: When possible, group related operations together
7. **Safety first**: For dangerous operations, explain the impact clearly

# Response Format

When asked to perform tasks, structure your response as:

1. **Analysis**: Briefly explain what you understand from the request
2. **Plan**: Outline the steps you'll take
3. **Execution**: Call the necessary tools
4. **Summary**: Explain what was done and any important notes

Example:
```
I'll help you refactor the user service. Based on your request, I need to:
1. Read the current implementation
2. Identify the issues
3. Propose improvements

TOOL_CALL: read_file(path="lib/services/user_service.dart")
```
]]
  
  config.set("ollama.system_prompt", enhanced)
end

-- Process a single query
function M.query(prompt, options)
  options = options or {}
  
  if not M.state.initialized then
    return nil, "Agent not initialized. Call M.init() first."
  end
  
  local iteration = 0
  local results = {
    prompt = prompt,
    iterations = {},
    final_response = nil
  }
  
  while iteration < M.state.max_iterations do
    iteration = iteration + 1
    
    -- Get AI response
    local response, err
    if options.stream then
      response = ollama.generate_stream(prompt, options.callback, options)
    else
      response, err = ollama.generate(prompt, options)
    end
    
    if not response then
      return nil, err or "Failed to get response from AI"
    end
    
    local iteration_result = {
      iteration = iteration,
      response = response,
      tools_executed = {}
    }
    
    -- Check for tool calls in response
    local tool_results = tool_registry.execute_from_response(response, {
      skip_confirmation = M.state.auto_execute
    })
    
    if #tool_results > 0 then
      iteration_result.tools_executed = tool_results
      
      -- Build feedback for next iteration
      local feedback_parts = {"\n## Tool Execution Results:\n"}
      
      for i, result in ipairs(tool_results) do
        if result.success then
          table.insert(feedback_parts, string.format(
            "\n✓ %s: Success\nResult: %s",
            result.tool,
            M.format_result(result.result)
          ))
        else
          table.insert(feedback_parts, string.format(
            "\n✗ %s: Failed\nError: %s",
            result.tool,
            result.error or "Unknown error"
          ))
        end
      end
      
      local feedback = table.concat(feedback_parts, "\n")
      
      -- Continue conversation with tool results
      prompt = feedback .. "\n\nBased on these results, continue with the next steps or provide your final answer."
      
      -- Save to history so context is maintained
      options.save_history = true
      
    else
      -- No more tool calls, this is the final response
      results.final_response = response
      table.insert(results.iterations, iteration_result)
      break
    end
    
    table.insert(results.iterations, iteration_result)
    
    -- In interactive mode, ask user to continue
    if M.state.interactive and iteration < M.state.max_iterations then
      print("\nContinue to next iteration? (y/N): ")
      local answer = io.read()
      if not answer or answer:lower() ~= "y" then
        results.final_response = response
        break
      end
    end
  end
  
  if iteration >= M.state.max_iterations then
    results.max_iterations_reached = true
  end
  
  return results
end

-- Format tool result for display
function M.format_result(result)
  if type(result) == "table" then
    local parts = {}
    for k, v in pairs(result) do
      if type(v) ~= "table" then
        table.insert(parts, string.format("%s: %s", k, tostring(v)))
      end
    end
    return table.concat(parts, ", ")
  else
    return tostring(result)
  end
end

-- Interactive mode
function M.interactive()
  if not M.state.initialized then
    local success, err = M.init({interactive = true})
    if not success then
      print("Error: " .. err)
      return
    end
  end
  
  print("=== fdart AI Assistant ===")
  print("Type 'exit' or 'quit' to end the session")
  print("Type 'clear' to clear conversation history")
  print("Type 'tools' to list available tools")
  print("Type 'help' for more commands\n")
  
  while true do
    io.write("\n> ")
    local input = io.read()
    
    if not input or input == "exit" or input == "quit" then
      break
    end
    
    if input == "clear" then
      ollama.clear_history()
      ollama.clear_context()
      print("History and context cleared.")
      goto continue
    end
    
    if input == "tools" then
      local tools = tool_registry.list()
      print("\nAvailable tools:")
      for _, tool in ipairs(tools) do
        print(string.format("  - %s [%s]: %s", tool.name, tool.safety_level, tool.description))
      end
      goto continue
    end
    
    if input == "help" then
      print([[
Commands:
  exit, quit  - Exit interactive mode
  clear       - Clear conversation history
  tools       - List available tools
  help        - Show this help
  
You can ask questions or request tasks. The AI will use available tools to help you.
Examples:
  - "Read the main.dart file and explain its structure"
  - "Create a new service class for user authentication"
  - "Refactor the widget tree in home_screen.dart"
]])
      goto continue
    end
    
    -- Process query
    print("\nProcessing...")
    local results, err = M.query(input, {stream = false})
    
    if not results then
      print("\nError: " .. (err or "Unknown error"))
    else
      print("\n" .. (results.final_response or "No response"))
      
      if results.max_iterations_reached then
        print("\n⚠️  Maximum iterations reached. Task may be incomplete.")
      end
    end
    
    ::continue::
  end
  
  print("\nGoodbye!")
end

-- Task execution with context
function M.execute_task(task_description, context_files, options)
  options = options or {}
  
  -- Add context files
  if context_files then
    for _, file in ipairs(context_files) do
      ollama.add_file_context(file, options)
    end
  end
  
  -- Build enhanced prompt
  local prompt = task_description
  if options.additional_context then
    prompt = prompt .. "\n\n## Additional Context:\n" .. options.additional_context
  end
  
  -- Execute
  return M.query(prompt, options)
end

-- Quick helpers for common tasks
function M.review_code(file_path)
  return M.execute_task(
    "Review this code for potential issues, best practices, and improvement opportunities. Provide specific, actionable feedback.",
    {file_path}
  )
end

function M.explain_code(file_path)
  return M.execute_task(
    "Explain what this code does, its purpose, and how it works. Include any important patterns or techniques used.",
    {file_path}
  )
end

function M.refactor(file_path, instructions)
  return M.execute_task(
    string.format("Refactor this code according to these instructions: %s", instructions),
    {file_path}
  )
end

function M.generate_tests(file_path)
  return M.execute_task(
    "Generate comprehensive unit tests for this code. Include edge cases and error scenarios.",
    {file_path}
  )
end

-- Get agent statistics
function M.stats()
  return {
    initialized = M.state.initialized,
    tools_registered = #tool_registry.list(),
    conversation_length = #ollama.conversation_history,
    context_files = #ollama.context_window,
    execution_log = #tool_registry.get_log()
  }
end

return M