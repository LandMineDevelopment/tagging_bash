#!/usr/bin/env bash
#
# integration/remove_command_tests.sh - Integration tests for remove command
#

source "$(dirname "${BASH_SOURCE[0]}")/../test_framework.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../tagg"

# Mock functions for testing
validate_file_path() { return 0; }  # Allow temp files
load_tags() {
    declare -gA file_tags=()
    declare -gA tag_files=()
    return 0;
}
save_tags() { return 0; }
acquire_lock() { return 0; }
release_lock() { return 0; }

# Test remove single tag from file
test_remove_single_tag() {
    # Mock existing tags
    load_tags() {
        declare -gA file_tags=()
        declare -gA tag_files=()
        file_tags["/tmp/test_remove"]="tag1|tag2|tag3"
        tag_files["tag1"]="/tmp/test_remove"
        tag_files["tag2"]="/tmp/test_remove"
        tag_files["tag3"]="/tmp/test_remove"
        return 0;
    }

    local output
    output=$(cmd_remove "/tmp/test_remove" "tag2" 2>&1)

    assert_contains "$output" "Removed tag 'tag2'" "Should show removal confirmation"
    assert_contains "$output" "from /tmp/test_remove" "Should show file path"
}

# Test remove non-existent tag
test_remove_non_existent_tag() {
    # Mock existing tags
    load_tags() {
        declare -gA file_tags=()
        declare -gA tag_files=()
        file_tags["/tmp/test_remove"]="tag1|tag2"
        tag_files["tag1"]="/tmp/test_remove"
        tag_files["tag2"]="/tmp/test_remove"
        return 0;
    }

    local output
    output=$(cmd_remove "/tmp/test_remove" "nonexistent" 2>&1)

    assert_contains "$output" "Tag 'nonexistent' not found" "Should show error for non-existent tag"
}

# Run integration tests
run_integration_remove_tests() {
    run_test "remove_single_tag" test_remove_single_tag
    run_test "remove_non_existent_tag" test_remove_non_existent_tag
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_integration_remove_tests
fi

# Export for test runner
export -f run_integration_remove_tests