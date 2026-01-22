#!/usr/bin/env bash
#
# integration/add_command_tests.sh - Integration tests for add command
#

source "$(dirname "${BASH_SOURCE[0]}")/../test_framework.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../tagg"

# Test setup and teardown
setup_test() {
    # Mock functions for testing - these will be restored in teardown
    mock_function "save_tags" "return 0
    mock_function "acquire_lock" "return 0
    mock_function "release_lock" "return 0
}

teardown_test() {
    # Restore mocked functions
    restore_function "save_tags"
    restore_function "acquire_lock"
    restore_function "release_lock"
}

# Test single file tagging
test_add_single_file() {
    # Mock empty database
    mock_function "load_tags" "
        declare -gA file_tags=()
        declare -gA tag_files=()
        return 0
    "

    local temp_file=$(mktemp)
    echo "test" > "$temp_file"

    # Capture output
    local output
    output=$(cmd_add "$temp_file" "test_tag" 2>&1)

    assert_contains "$output" "Added tags to" "Should show success message"
    assert_contains "$output" "test_tag" "Should show added tag"

    rm -f "$temp_file"
    restore_function "load_tags"
}

# Test multiple files tagging
test_add_multiple_files() {
    # Mock empty database
    mock_function "load_tags" "
        declare -gA file_tags=()
        declare -gA tag_files=()
        return 0
    "

    local temp_file1=$(mktemp)
    local temp_file2=$(mktemp)
    echo "test1" > "$temp_file1"
    echo "test2" > "$temp_file2"

    local output
    output=$(cmd_add "$temp_file1" "$temp_file2" "multi_tag" 2>&1)

    assert_contains "$output" "Tagged 2 files" "Should show multiple files message"
    assert_contains "$output" "multi_tag" "Should show tag"

    rm -f "$temp_file1" "$temp_file2"
    restore_function "load_tags"
}

# Test duplicate tag rejection
test_add_duplicate_tag() {
    local temp_file=$(mktemp)
    echo "test" > "$temp_file"

    # Mock existing tags with the temp_file having existing_tag
    mock_function "load_tags" "
    declare -gA file_tags=()
    declare -gA tag_files=()
    file_tags["$temp_file"]="existing_tag"
    tag_files["existing_tag"]="$temp_file"
    return 0

    local output
    output=$(cmd_add "$temp_file" "existing_tag" 2>&1)

    assert_contains "$output" "already exists" "Should reject duplicate"

    rm -f "$temp_file"
    restore_function "load_tags"
}

# Test duplicate tag in input (should deduplicate)
test_add_duplicate_in_input() {
    # Mock empty database
    mock_function "load_tags" "
        declare -gA file_tags=()
        declare -gA tag_files=()
        return 0
    "

    local temp_file=$(mktemp)
    echo "test" > "$temp_file"

    local output
    output=$(cmd_add "$temp_file" "dup_tag" "dup_tag" "other_tag" 2>&1)

    assert_contains "$output" "Added tags to" "Should succeed"
    assert_contains "$output" "dup_tag" "Should have dup_tag"
    assert_contains "$output" "other_tag" "Should have other_tag"

    rm -f "$temp_file"
    restore_function "load_tags"
}

# Test invalid tag rejection
test_add_invalid_tag() {
    # Mock empty database
    mock_function "load_tags" "
        declare -gA file_tags=()
        declare -gA tag_files=()
        return 0
    "

    local temp_file=$(mktemp)
    echo "test" > "$temp_file"

    local output
    output=$(set +e; cmd_add "$temp_file" "invalid tag" 2>&1)

    assert_contains "$output" "Invalid tag name" "Should reject invalid tag"

    rm -f "$temp_file"
    restore_function "load_tags"
}

# Run integration tests
run_integration_add_tests() {
    run_test_with_isolation "add_single_file" test_add_single_file
    run_test_with_isolation "add_multiple_files" test_add_multiple_files
    run_test_with_isolation "add_duplicate_tag" test_add_duplicate_tag
    run_test_with_isolation "add_duplicate_in_input" test_add_duplicate_in_input
    run_test_with_isolation "add_invalid_tag" test_add_invalid_tag
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_integration_add_tests
fi

# Export for test runner
export -f run_integration_add_tests