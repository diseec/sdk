#!/bin/bash
# AI Module Test Script
# Test the AI module functionality

# Source the AI module
# source_module "$KIT_SRC_DIR/utils/ai/index.sh"
source_module $KIT_SRC_DIR/utils/ai/config.sh
source_module $KIT_SRC_DIR/utils/ai/utils.sh
source_module $KIT_SRC_DIR/utils/ai/api.sh
source_module $KIT_SRC_DIR/utils/ai/generators.sh

test_section "AI Module Tests"

# Test 1: Check if AI functions are loaded
test_case "AI Function Availability"
assert_function_exists "ai_is_available function exists" "ai_is_available"
assert_function_exists "ai_escape_json function exists" "ai_escape_json" 
assert_function_exists "ai_generate function exists" "ai_generate"
assert_function_exists "ai_fallback_commit_message function exists" "ai_fallback_commit_message"

# # Test 2: Check if AI is available
# test_case "AI Service Availability"
# if ai_is_available; then
#     test_info "AI is available (API key and curl found)"
# else
#     test_warn "AI is not available (missing API key or curl)"
# fi

# Test 3: Test JSON escaping
test_case "JSON Escaping Function"
test_string='This is a "test" string'
escaped=$(ai_escape_json "$test_string")
assert_contains "JSON escaping works" "$escaped" "This is a \\\"test\\\" string"

test_string_newlines=$'Line 1\nLine 2'
escaped_newlines=$(ai_escape_json "$test_string_newlines")
assert_contains "Newlines are escaped" "$escaped_newlines" "\\n"

# # Test 4: Test fallback commit message
# test_case "Fallback Commit Message Generation"
# test_files="src/file1.js
# src/file2.ts
# README.md"
# fallback_msg=$(ai_fallback_commit_message "$test_files")
# assert_contains "Multi-file message contains count" "$fallback_msg" "3 files"
# assert_contains "Multi-file message lists files" "$fallback_msg" "file1.js"

# single_file="src/single.js"
# single_msg=$(ai_fallback_commit_message "$single_file")
# assert_contains "Single file message" "$single_msg" "Update src/single.js"

# # Test 5: Test AI generation (if available)
# test_case "AI Generation (Live Test)"
# if ai_is_available; then
#     test_info "Testing AI generation with simple prompt..."
#     test_prompt="Say 'Hello from AI module test' in exactly those words"
#     result=$(ai_generate "$test_prompt" "$AI_MODEL_GPT4o" "0.1" "AI test failed")
    
#     if [ "$result" != "AI test failed" ]; then
#         test_info "AI Response: $result"
#         assert_success "AI generation returned a response" true
#     else
#         test_warn "AI generation failed"
#         assert_failure "AI generation should succeed when available" false
#     fi
# else
#     test_skip "AI not available for live testing"
# fi

# # Test 6: Test commit message generation 
# test_case "Commit Message Generation"
# test_diff_summary=" src/ai/index.sh | 150 ++++++++++++++++++++++++++++++++++++++++++++++++
#  src/git/commit.sh |  45 ++++++---------
#  2 files changed, 170 insertions(+), 25 deletions(-)"

# test_diff_preview="diff --git a/src/ai/index.sh b/src/ai/index.sh
# new file mode 100644
# index 0000000..abc1234
# --- /dev/null
# +++ b/src/ai/index.sh
# @@ -0,0 +1,150 @@
# +#!/bin/bash
# +# AI Module - Abstracted AI operations"

# if ai_is_available; then
#     test_info "Testing commit message generation..."
#     commit_msg=$(ai_generate_commit_message "$test_diff_summary" "$test_diff_preview")
#     test_info "Generated commit message: $commit_msg"
#     assert_success "Commit message generation works" [ -n "$commit_msg" ]
# else
#     test_info "Testing fallback commit message..."
#     test_files="src/ai/index.sh
# src/git/commit.sh"
#     commit_msg=$(ai_fallback_commit_message "$test_files")
#     test_info "Fallback commit message: $commit_msg"
#     assert_contains "Fallback message contains file count" "$commit_msg" "2 files"
# fi

test_section "AI Module Tests Complete"
