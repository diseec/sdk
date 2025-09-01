# AI Module Documentation

This module provides abstracted AI operations for the kit, with all functions prefixed with `ai_`. It handles OpenAI API calls with proper error handling, fallbacks, and flexible configuration.

## Module Structure

The AI module is now organized into focused, single-responsibility files:

### Files Overview

- **`index.sh`** - Main module entry point, loads all components
- **`config.sh`** - Configuration constants and initialization
- **`utils.sh`** - Utility functions (JSON escaping, response parsing, fallbacks)
- **`api.sh`** - API communication layer (HTTP requests, AI generation)
- **`generators.sh`** - High-level content generators (commit messages, insights)
- **`core.sh`** - Legacy compatibility layer (backward compatibility)

### Modular Design Benefits

1. **Separation of Concerns**: Each file has a single responsibility
2. **Easier Maintenance**: Changes to API logic don't affect utility functions
3. **Better Testing**: Individual components can be tested in isolation
4. **Improved Readability**: Smaller, focused files are easier to understand
5. **Flexible Loading**: Components can be loaded independently if needed

## Functions

### Configuration Functions (`config.sh`)

#### `fac_ai_init_interactive()`

Initialize AI module and validate API key.

- **Returns**: 0 if successful, 1 if failed
- **Usage**: Called automatically when module is sourced

#### `fac_ai_is_available()`

Check if AI is available (API key and curl).

- **Returns**: 0 if available, 1 if not
- **Usage**: `if fac_ai_is_available; then ... fi`

### API Functions (`api.sh`)

#### `fac_ai_generate(prompt, model, temperature, fallback)`

Generate a completion using AI with error handling.

- **Parameters**:
  - `prompt`: The prompt to send to AI
  - `model`: Model to use (default: gpt-4)
  - `temperature`: Temperature setting (default: 0.3)
  - `fallback`: Fallback message if AI fails
- **Returns**: AI-generated content or fallback message
- **Usage**: `result=$(fac_ai_generate "Your prompt here")`

#### `fac_ai_call_openai(prompt, model, temperature)`

Make a raw OpenAI API call.

- **Parameters**:
  - `prompt`: The prompt to send
  - `model`: Model to use
  - `temperature`: Temperature setting
- **Output**: Raw API response
- **Usage**: `response=$(fac_ai_call_openai "$prompt" "gpt-4" "0.3")`

### Utility Functions (`utils.sh`)

#### `fac_ai_escape_json(string)`

Escape a string for JSON format.

- **Parameters**: `string` - String to escape
- **Output**: JSON-escaped string
- **Usage**: `escaped=$(fac_ai_escape_json "$input")`

#### `fac_ai_extract_response(response)`

Extract content from OpenAI API response.

- **Parameters**: `response` - Raw API response JSON
- **Output**: Extracted content
- **Usage**: `content=$(fac_ai_extract_response "$response")`

#### `fac_ai_has_error(response)`

Check if OpenAI API response contains an error.

- **Parameters**: `response` - Raw API response JSON
- **Returns**: 0 if error found, 1 if no error
- **Usage**: `if fac_ai_has_error "$response"; then ... fi`

#### `fac_ai_fallback_commit_message(files_changed)`

Generate fallback commit message when AI is not available.

- **Parameters**: `files_changed` - List of changed files
- **Output**: Simple commit message
- **Usage**: `msg=$(fac_ai_fallback_commit_message "$files")`

### Generator Functions (`generators.sh`)

#### `fac_ai_generate_commit_message(diff_summary, diff_preview)`

Generate a commit message from git diff data.

- **Parameters**:
  - `diff_summary`: Git diff --stat output
  - `diff_preview`: Git diff content preview
- **Output**: AI-generated commit message
- **Usage**: `msg=$(fac_ai_generate_commit_message "$summary" "$preview")`

#### `fac_ai_generate_daily_insight(analysis_data)`

Generate a daily development insight report.

- **Parameters**: `analysis_data` - Development activity data
- **Output**: AI-generated insight report
- **Usage**: `insight=$(fac_ai_generate_daily_insight "$data")`

## Configuration Constants

- `FAC_AI_MODEL_GPT35`: "gpt-3.5-turbo"
- `FAC_AI_MODEL_GPT4`: "gpt-4"
- `FAC_AI_DEFAULT_TEMPERATURE`: "0.3"
- `FAC_AI_CREATIVE_TEMPERATURE`: "0.7"
- `FAC_AI_API_ENDPOINT`: "https://api.openai.com/v1/chat/completions"

## Usage Examples

### Basic AI Generation

```bash
# Source the AI module
$KIT_SRC_DIR/facades/ai/index.sh

# Generate content
if fac_ai_is_available; then
    result=$(fac_ai_generate "Explain what this code does: $code")
    echo "$result"
else
    echo "AI not available"
fi
```

### Commit Message Generation

```bash
# Get git diff data
diff_summary="$(_git diff --staged --stat)"
diff_preview="$(_git diff --staged | head -n 300)"

# Generate commit message
if fac_ai_is_available; then
    commit_msg=$(fac_ai_generate_commit_message "$diff_summary" "$diff_preview")
else
    files_changed=$(_git diff --staged --name-only)
    commit_msg=$(fac_ai_fallback_commit_message "$files_changed")
fi

echo "$commit_msg"
```

### Custom AI Call

```bash
# Use specific model and temperature
prompt="Write a technical summary of these changes"
result=$(fac_ai_generate "$prompt" "$FAC_AI_MODEL_GPT4o" "$FAC_AI_CREATIVE_TEMPERATURE" "Unable to generate summary")
```

## Error Handling

The module provides comprehensive error handling:

1. **API Key Validation**: Checks for OPENAI_API_KEY availability
2. **Dependency Checking**: Verifies curl is available
3. **API Error Detection**: Parses API responses for errors
4. **Fallback Mechanisms**: Provides fallback functions when AI is unavailable
5. **Content Extraction**: Handles both jq and grep/sed for JSON parsing

## Dependencies

- **curl**: Required for API calls
- **jq**: Preferred for JSON parsing (falls back to grep/sed if not available)
- **Secret management module**: For API key handling

## Integration

This module is designed to integrate seamlessly with existing kit commands:

1. Source the module: `$KIT_SRC_DIR/facades/ai/index.sh`
2. Check availability: `fac_ai_is_available`
3. Use appropriate functions for your use case
4. Handle errors gracefully with provided fallbacks

## Migration Notes

When migrating existing code to use this module:

1. Replace direct OpenAI API calls with `fac_ai_generate()` or `fac_ai_call_openai()`
2. Remove manual JSON escaping and use `fac_ai_escape_json()`
3. Replace custom error checking with `fac_ai_has_error()`
4. Use specialized functions like `fac_ai_generate_commit_message()` for common use cases
5. Implement fallback mechanisms using the provided fallback functions

### Backward Compatibility

The existing `core.sh` file is maintained as a compatibility layer that simply sources the main module. Existing code that sources `core.sh` will continue to work without changes.
