#!/usr/bin/env bash
#
# integration/list_command_tests.sh - Integration tests for list command
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

# Test listing all tags globally when no tags exist
test_list_no_tags() {
    # Mock empty tags
    mock_function "load_tags" "
        declare -gA file_tags=()
        declare -gA tag_files=()
        return 0
    "

    local output
    output=$(cmd_list 2>&1)

    assert_contains "$output" "No tags found" "Should show no tags message"

    restore_function "load_tags"
}

# Test listing all distinct tags globally
test_list_all_tags() {
    # Mock existing tags
    mock_function "load_tags" "
        declare -gA file_tags=()
        declare -gA tag_files=()
        file_tags['/tmp/file1']='bash|utility'
        file_tags['/tmp/file2']='bash|script'
        tag_files['bash']='/tmp/file1|/tmp/file2'
        tag_files['utility']='/tmp/file1'
        tag_files['script']='/tmp/file2'
        return 0
    "

    local output
    output=$(cmd_list 2>&1)

    assert_contains "$output" "All distinct tags:" "Should show header"
    assert_contains "$output" "bash" "Should contain bash tag"
    assert_contains "$output" "script" "Should contain script tag"
    assert_contains "$output" "utility" "Should contain utility tag"

    restore_function "load_tags"
}

# Test listing tags for a specific file with no tags
test_list_file_no_tags() {
    local temp_file=$(mktemp)
    echo "test" > "$temp_file"

    # Mock existing tags but file has none
    mock_function "load_tags" "
        declare -gA file_tags=()
        declare -gA tag_files=()
        file_tags['/tmp/other_file']='some_tag'
        tag_files['some_tag']='/tmp/other_file'
        return 0
    "

    local output
    output=$(set +e; cmd_list "$temp_file" 2>&1)

    assert_contains "$output" "No tags found for" "Should show no tags for file"
    assert_contains "$output" "$temp_file" "Should show file path"

    rm -f "$temp_file"
    restore_function "load_tags"
}

# Test listing tags for a specific file
test_list_file_with_tags() {
    local temp_file=$(mktemp)
    echo "test" > "$temp_file"

    # Mock existing tags with the actual temp file path
    mock_function "load_tags" "
        declare -gA file_tags=()
        declare -gA tag_files=()
        file_tags['$temp_file']='bash|utility|script'
        tag_files['bash']='$temp_file'
        tag_files['utility']='$temp_file'
        tag_files['script']='$temp_file'
        return 0
    "

    local output
    output=$(set +e; cmd_list "$temp_file" 2>&1)

    assert_contains "$output" "Tags for" "Should show header"
    assert_contains "$output" "$temp_file" "Should show file path"
    assert_contains "$output" "bash" "Should contain bash tag"
    assert_contains "$output" "script" "Should contain script tag"
    assert_contains "$output" "utility" "Should contain utility tag"

    rm -f "$temp_file"
    restore_function "load_tags"
}

# Test listing with invalid file - validation is tested elsewhere

# Test list command with too many arguments
test_list_too_many_args() {
    # Mock empty database
    mock_function "load_tags" "
        declare -gA file_tags=()
        declare -gA tag_files=()
        return 0
    "

    local output
    output=$(cmd_list "arg1" "arg2" 2>&1)

    assert_contains "$output" "Usage:" "Should show usage error"

    restore_function "load_tags"
}

# Run integration tests
run_integration_list_tests() {
    run_test_with_isolation "list_no_tags" test_list_no_tags
    run_test_with_isolation "list_all_tags" test_list_all_tags
    run_test_with_isolation "list_file_no_tags" test_list_file_no_tags
    run_test_with_isolation "list_file_with_tags" test_list_file_with_tags
    run_test_with_isolation "list_too_many_args" test_list_too_many_args
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_integration_list_tests
fi

# Export for test runner
export -f run_integration_list_tests