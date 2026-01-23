#!/usr/bin/env bash
#
# integration/remove_command_tests.sh - Integration tests for remove command
#

source "$(dirname "${BASH_SOURCE[0]}")/../test_framework.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../tagg"

# Test setup and teardown
setup_test() {
    # Mock functions for testing - these will be restored in teardown
    mock_function "save_tags" "return 0"
    mock_function "acquire_lock" "return 0"
    mock_function "release_lock" "return 0"
}

teardown_test() {
    # Restore mocked functions
    restore_function "save_tags"
    restore_function "acquire_lock"
    restore_function "release_lock"

    # Clean up any test files created
    rm -f "/tmp/test_remove_"* 2>/dev/null || true
}

# Mock helper functions
mock_load_tags_simple() {
    declare -gA file_tags=()
    declare -gA tag_files=()
    return 0
}

mock_load_tags_with_data() {
    declare -gA file_tags=()
    declare -gA tag_files=()
    file_tags['/tmp/test_remove']='tag1|tag2|tag3'
    tag_files['tag1']='/tmp/test_remove'
    tag_files['tag2']='/tmp/test_remove'
    tag_files['tag3']='/tmp/test_remove'
    return 0
}

mock_load_tags_partial() {
    declare -gA file_tags=()
    declare -gA tag_files=()
    file_tags['/tmp/test_remove']='tag1|tag2'
    tag_files['tag1']='/tmp/test_remove'
    tag_files['tag2']='/tmp/test_remove'
    return 0
}

teardown_test() {
    # Restore mocked functions
    restore_function "save_tags"
    restore_function "acquire_lock"
    restore_function "release_lock"
}

# Test remove single tag from file
test_remove_single_tag() {
    # Mock existing tags
    mock_function "load_tags" "mock_load_tags_with_data"

    local output
    output=$(cmd_remove "/tmp/test_remove" "tag2" 2>&1)

    assert_contains "$output" "Removed tag 'tag2'" "Should show removal confirmation"
    assert_contains "$output" "from /tmp/test_remove" "Should show file path"

    restore_function "load_tags"
}

# Test remove non-existent tag
test_remove_non_existent_tag() {
    # Mock existing tags
    mock_function "load_tags" "mock_load_tags_partial"

    local output
    output=$(cmd_remove "/tmp/test_remove" "nonexistent" 2>&1)

    assert_contains "$output" "Tag 'nonexistent' not found" "Should show error for non-existent tag"

    restore_function "load_tags"
}

# Test remove with invalid tag name
test_remove_invalid_tag() {
    # Mock empty database
    mock_function "load_tags" "mock_load_tags_simple"

    local output
    output=$(set +e; cmd_remove "/tmp/test_remove" "invalid tag" 2>&1)

    assert_contains "$output" "Invalid tag name" "Should reject invalid tag"

    restore_function "load_tags"
}

# Run integration tests
run_integration_remove_tests() {
    run_test_with_isolation "remove_single_tag" test_remove_single_tag
    run_test_with_isolation "remove_non_existent_tag" test_remove_non_existent_tag
    run_test_with_isolation "remove_invalid_tag" test_remove_invalid_tag
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_integration_remove_tests
fi

# Export for test runner
export -f run_integration_remove_tests