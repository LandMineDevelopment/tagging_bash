#!/usr/bin/env bash
#
# integration/add_command_tests.sh - Integration tests for add command
#

source "$(dirname "$0")/../test_framework.sh"
source "$(dirname "$0")/../../tagg"

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

# Test single file tagging
test_add_single_file() {
    local temp_file=$(mktemp)
    echo "test" > "$temp_file"

    # Capture output
    local output
    output=$(cmd_add "$temp_file" "test_tag" 2>&1)

    assert_contains "$output" "Added tags to" "Should show success message"
    assert_contains "$output" "test_tag" "Should show added tag"

    rm -f "$temp_file"
}

# Test multiple files tagging
test_add_multiple_files() {
    local temp_file1=$(mktemp)
    local temp_file2=$(mktemp)
    echo "test1" > "$temp_file1"
    echo "test2" > "$temp_file2"

    local output
    output=$(cmd_add "$temp_file1" "$temp_file2" "multi_tag" 2>&1)

    assert_contains "$output" "Tagged 2 files" "Should show multiple files message"
    assert_contains "$output" "multi_tag" "Should show tag"

    rm -f "$temp_file1" "$temp_file2"
}

# Test duplicate tag rejection
test_add_duplicate_tag() {
    # Mock existing tags
    load_tags() {
        declare -gA file_tags=()
        declare -gA tag_files=()
        file_tags["/tmp/test_dup"]="existing_tag"
        tag_files["existing_tag"]="/tmp/test_dup"
        return 0;
    }

    local temp_file=$(mktemp)
    echo "test" > "$temp_file"

    local output
    output=$(cmd_add "$temp_file" "existing_tag" 2>&1)

    assert_contains "$output" "already exists" "Should reject duplicate"

    rm -f "$temp_file"
}

# Test invalid tag rejection
test_add_invalid_tag() {
    local temp_file=$(mktemp)
    echo "test" > "$temp_file"

    local output
    output=$(cmd_add "$temp_file" "invalid tag" 2>&1)

    assert_contains "$output" "Invalid tag name" "Should reject invalid tag"

    rm -f "$temp_file"
}

# Run integration tests
run_integration_add_tests() {
    run_test "add_single_file" test_add_single_file
    run_test "add_multiple_files" test_add_multiple_files
    run_test "add_duplicate_tag" test_add_duplicate_tag
    run_test "add_invalid_tag" test_add_invalid_tag
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_integration_add_tests
fi

# Export for test runner
export -f run_integration_add_tests