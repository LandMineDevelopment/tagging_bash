#!/usr/bin/env bash
#
# integration/search_command_tests.sh - Integration tests for search command
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
}

# Test basic search with no matches
test_search_no_matches() {
    # Mock empty tags
    mock_function "load_tags" "
        declare -gA file_tags=()
        declare -gA tag_files=()
        return 0
    "

    local output
    output=$(cmd_search "nonexistent" 2>&1)

    assert_contains "$output" "No files found with tags: nonexistent" "Should show no matches message"

    restore_function "load_tags"
}

# Test basic search with matches
test_search_with_matches() {
    # Set mock data directly
    declare -gA file_tags=()
    declare -gA tag_files=()
    for i in {1..150}; do
        file_tags["/tmp/file${i}.txt"]='test-tag'
        tag_files['test-tag']+="/tmp/file${i}.txt|"
    done

    # Mock load_tags to do nothing since we set the arrays directly
    mock_function "load_tags" "return 0"

    local output
    output=$(cmd_search "test-tag")

    # Note: Progress is only shown for searches taking >1 second
    # For mocked data, search is instant so no progress shown
    assert_contains "$output" "Found 150 file(s)" "Should find all mocked files"

    restore_function "load_tags"
}

# Test directory scoped search
test_search_directory_scope() {
    # Mock existing tags
    mock_function "load_tags" "
        declare -gA file_tags=()
        declare -gA tag_files=()
        file_tags['/tmp/dir1/file1']='bash'
        file_tags['/tmp/dir2/file2']='bash'
        tag_files['bash']='/tmp/dir1/file1|/tmp/dir2/file2'
        return 0
    "

    local output
    output=$(cmd_search "bash" --dir "/tmp/dir1" 2>&1)

    assert_contains "$output" "Found 1 file(s) with tags: bash" "Should show found in directory"
    assert_contains "$output" "/tmp/dir1/file1" "Should contain file1"
    assert_not_contains "$output" "/tmp/dir2/file2" "Should not contain file2"

    restore_function "load_tags"
}

# Test related tag suggestions
test_search_related_tags() {
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
    output=$(cmd_search "bash" 2>&1)

    assert_contains "$output" "Found 2 file(s) with tags: bash" "Should show found message"
    assert_contains "$output" "Related tags: script utility" "Should show related tags"

    restore_function "load_tags"
}

# Run integration tests
run_integration_search_tests() {
    run_test_with_isolation "search_no_matches" test_search_no_matches
    run_test_with_isolation "search_with_matches" test_search_with_matches
    run_test_with_isolation "search_directory_scope" test_search_directory_scope
    run_test_with_isolation "search_related_tags" test_search_related_tags
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_integration_search_tests
fi

# Export for test runner
export -f run_integration_search_tests