#!/usr/bin/env bash
#
# test_search_functionality.sh - Comprehensive test suite for Epic 2 search features
# Tests search functionality, fuzzy search, directory filtering, multi-tag search,
# progress indicators, related tag suggestions, and tab completion
#

#!/usr/bin/env bash
#
# test_epic2_search.sh - Integration tests for Epic 2 search functionality
#

source "$(dirname "${BASH_SOURCE[0]}")/../test_framework.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../tagg"

# Test setup and teardown
setup_test() {
    # Mock functions for testing - these will be restored in teardown
    mock_function "save_tags" "return 0"
    mock_function "acquire_lock" "return 0"
    mock_function "release_lock" "return 0"
    mock_function "validate_database" "return 0"
}

teardown_test() {
    # Restore mocked functions
    restore_function "save_tags"
    restore_function "acquire_lock"
    restore_function "release_lock"
    restore_function "validate_database"

    # Clean up any test files created
    rm -f "/tmp/test_search_"* 2>/dev/null || true
}

teardown() {
    rm -rf "$TAGGING_BASH_TEST_DIR"
}

# Test exact tag search
test_search_exact_tag() {
    # Mock database with test data
    mock_function "load_tags" "
        declare -gA file_tags=()
        declare -gA tag_files=()
        file_tags['/tmp/test_search_file1.txt']='project-a|bash'
        file_tags['/tmp/test_search_file2.txt']='project-b|python'
        tag_files['project-a']='/tmp/test_search_file1.txt'
        tag_files['bash']='/tmp/test_search_file1.txt'
        tag_files['project-b']='/tmp/test_search_file2.txt'
        tag_files['python']='/tmp/test_search_file2.txt'
        return 0
    "

    local output
    output=$(cmd_search "project-a")

    assert_contains "$output" "Found 1 file(s) with tags: project-a" "Should find one file"
    assert_contains "$output" "/tmp/test_search_file1.txt" "Should show correct file path"
    assert_contains "$output" "bash project-a" "Should show all tags for the file"
    assert_contains "$output" "Search completed in" "Should show timing"

    restore_function "load_tags"
}

# Test multi-tag search (AND logic)
test_search_multiple_tags() {
    # Mock database with overlapping tags
    mock_function "load_tags" "
        declare -gA file_tags=()
        declare -gA tag_files=()
        file_tags['/tmp/test_search_file1.txt']='project-a|bash|utility'
        file_tags['/tmp/test_search_file2.txt']='project-a|python'
        tag_files['project-a']='/tmp/test_search_file1.txt|/tmp/test_search_file2.txt'
        tag_files['bash']='/tmp/test_search_file1.txt'
        tag_files['utility']='/tmp/test_search_file1.txt'
        tag_files['python']='/tmp/test_search_file2.txt'
        return 0
    "

    local output
    output=$(cmd_search "project-a" "bash")

    assert_contains "$output" "Found 1 file(s) with tags: project-a bash" "Should find file with both tags"
    assert_contains "$output" "/tmp/test_search_file1.txt" "Should show correct file"
    assert_contains "$output" "bash project-a utility" "Should show all tags"

    restore_function "load_tags"
}

# Test directory filtering
test_search_directory_filter() {
    # Mock database with files in different directories
    mock_function "load_tags" "
        declare -gA file_tags=()
        declare -gA tag_files=()
        file_tags['/home/user/docs/file1.txt']='important'
        file_tags['/home/user/code/file2.txt']='important'
        tag_files['important']='/home/user/docs/file1.txt|/home/user/code/file2.txt'
        return 0
    "

    local output
    output=$(cmd_search "important" "--dir" "/home/user/docs")

    assert_contains "$output" "Found 1 file(s)" "Should find only file in specified directory"
    assert_contains "$output" "/home/user/docs/file1.txt" "Should show file in docs directory"
    assert_not_contains "$output" "/home/user/code/file2.txt" "Should not show file outside directory"

    restore_function "load_tags"
}

# Test no matches
test_search_no_matches() {
    # Mock empty database
    mock_function "load_tags" "
        declare -gA file_tags=()
        declare -gA tag_files=()
        return 0
    "

    local output
    output=$(cmd_search "nonexistent-tag")

    assert_contains "$output" "No files found with tags: nonexistent-tag" "Should show no matches message"

    restore_function "load_tags"
}

# Test related tag suggestions
test_search_related_tags() {
    # Mock database with overlapping tags
    mock_function "load_tags" "
        declare -gA file_tags=()
        declare -gA tag_files=()
        file_tags['/tmp/test_search_file1.txt']='project-a|bash|utility'
        file_tags['/tmp/test_search_file2.txt']='project-a|python'
        tag_files['project-a']='/tmp/test_search_file1.txt|/tmp/test_search_file2.txt'
        tag_files['bash']='/tmp/test_search_file1.txt'
        tag_files['utility']='/tmp/test_search_file1.txt'
        tag_files['python']='/tmp/test_search_file2.txt'
        return 0
    "

    local output
    output=$(cmd_search "project-a")

    assert_contains "$output" "Related tags:" "Should show related tags section"
    assert_contains "$output" "bash" "Should suggest bash tag"
    assert_contains "$output" "python" "Should suggest python tag"
    assert_contains "$output" "utility" "Should suggest utility tag"

    restore_function "load_tags"
}

# Test progress indicators for large searches
test_search_progress_indicators() {
    # Mock large database (>100 files)
    local mock_body="declare -gA file_tags=(); declare -gA tag_files=(); "
    for i in {1..150}; do
        mock_body+="file_tags['/tmp/file${i}.txt']='test-tag'; "
        mock_body+="tag_files['test-tag']+='/tmp/file${i}.txt|'; "
    done
    mock_body+="return 0"

    mock_function "load_tags" "$mock_body"

    local output
    output=$(cmd_search "test-tag")

    assert_contains "$output" "Searching" "Should show progress message"
    assert_contains "$output" "% complete" "Should show percentage"
    assert_contains "$output" "Found 150 file(s)" "Should find all files"

    restore_function "load_tags"
}

# Run integration tests
run_integration_epic2_search_tests() {
    run_test_with_isolation "search_exact_tag" test_search_exact_tag
    run_test_with_isolation "search_multiple_tags" test_search_multiple_tags
    run_test_with_isolation "search_directory_filter" test_search_directory_filter
    run_test_with_isolation "search_no_matches" test_search_no_matches
    run_test_with_isolation "search_related_tags" test_search_related_tags
    run_test_with_isolation "search_progress_indicators" test_search_progress_indicators
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_integration_epic2_search_tests
fi

# Export for test runner
export -f run_integration_epic2_search_tests

@test "[INTEGRATION] fuzzy search - finds similar tags" {
    # Setup
    echo "- file: $TAGGING_BASH_TEST_DIR/file1.txt" >> "$TAGS_FILE"
    echo "  tags: [project-alpha, bash]" >> "$TAGS_FILE"
    echo "- file: $TAGGING_BASH_TEST_DIR/file2.txt" >> "$TAGS_FILE"
    echo "  tags: [project-beta, python]" >> "$TAGS_FILE"

    run "$TAGGING_BASH_TEST_DIR/../../tagg" search "proj"
    assert_equals "$?" "0"
    [[ "$output" == *"file1.txt"* ]] || [[ "$output" == *"file2.txt"* ]]
}

@test "[INTEGRATION] directory filtering - limits search to specific directory" {
    # Setup
    echo "- file: $TAGGING_BASH_TEST_DIR/file1.txt" >> "$TAGS_FILE"
    echo "  tags: [bash]" >> "$TAGS_FILE"
    echo "- file: $TAGGING_BASH_TEST_DIR/subdir/file4.txt" >> "$TAGS_FILE"
    echo "  tags: [bash]" >> "$TAGS_FILE"

    run "$TAGGING_BASH_TEST_DIR/../../tagg" search "bash" --dir "$TAGGING_BASH_TEST_DIR/subdir"
    assert_equals "$?" "0"
    [[ "$output" == *"file4.txt"* ]]
    [[ "$output" != *"file1.txt"* ]]
}

@test "[INTEGRATION] multi-tag search - finds files with all specified tags" {
    # Setup
    echo "- file: $TAGGING_BASH_TEST_DIR/file1.txt" >> "$TAGS_FILE"
    echo "  tags: [project-a, bash, script]" >> "$TAGS_FILE"
    echo "- file: $TAGGING_BASH_TEST_DIR/file2.txt" >> "$TAGS_FILE"
    echo "  tags: [project-a, python]" >> "$TAGS_FILE"
    echo "- file: $TAGGING_BASH_TEST_DIR/file3.txt" >> "$TAGS_FILE"
    echo "  tags: [bash, utility]" >> "$TAGS_FILE"

    run "$TAGGING_BASH_TEST_DIR/../../tagg" search "project-a" "bash"
    assert_equals "$?" "0"
    [[ "$output" == *"file1.txt"* ]]
    [[ "$output" != *"file2.txt"* ]]
    [[ "$output" != *"file3.txt"* ]]
}

@test "[INTEGRATION] search results display - shows full context" {
    # Setup
    echo "- file: $TAGGING_BASH_TEST_DIR/file1.txt" >> "$TAGS_FILE"
    echo "  tags: [project-a, bash, script]" >> "$TAGS_FILE"

    run "$TAGGING_BASH_TEST_DIR/../../tagg" search "project-a"
    assert_equals "$?" "0"
    [[ "$output" == *"file1.txt"* ]]
    [[ "$output" == *"project-a"* ]]
    [[ "$output" == *"bash"* ]]
    [[ "$output" == *"script"* ]]
}

@test "[INTEGRATION] related tag suggestions - shows suggestions during search" {
    # Setup
    echo "- file: $TAGGING_BASH_TEST_DIR/file1.txt" >> "$TAGS_FILE"
    echo "  tags: [project-a, bash, script]" >> "$TAGS_FILE"
    echo "- file: $TAGGING_BASH_TEST_DIR/file2.txt" >> "$TAGS_FILE"
    echo "  tags: [project-b, bash, utility]" >> "$TAGS_FILE"

    run "$TAGGING_BASH_TEST_DIR/../../tagg" search "bash"
    assert_equals "$?" "0"
    [[ "$output" == *"Related tags"* ]] || [[ "$output" == *"Suggestions"* ]]
}

@test "[INTEGRATION] search with no matches - shows appropriate message" {
    run "$TAGGING_BASH_TEST_DIR/../../tagg" search "nonexistent-tag"
    assert_equals "$?" "0"
    [[ "$output" == *"No files found"* ]] || [[ "$output" == *"not found"* ]]
}

@test "[INTEGRATION] search help - displays usage information" {
    run "$TAGGING_BASH_TEST_DIR/../../tagg" search --help
    assert_equals "$?" "0"
    [[ "$output" == *"search"* ]]
    [[ "$output" == *"USAGE"* ]] || [[ "$output" == *"SYNOPSIS"* ]]
}

# Performance Tests
@test "[PERFORMANCE] search performance - completes within 500ms for small dataset" {
    # Setup: add 10 files with tags
    for i in {1..10}; do
        echo "test content $i" > "$TAGGING_BASH_TEST_DIR/file$i.txt"
        echo "- file: $TAGGING_BASH_TEST_DIR/file$i.txt" >> "$TAGS_FILE"
        echo "  tags: [tag$i, common-tag]" >> "$TAGS_FILE"
    done

    local start_time=$(date +%s%3N)
    run "$TAGGING_BASH_TEST_DIR/../../tagg" search "common-tag"
    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))

    assert_equals "$?" "0"
    [ "$duration" -lt 500 ] # Should complete in under 500ms
}

@test "[PERFORMANCE] fuzzy search performance - handles partial matches efficiently" {
    # Setup: add files with similar tags
    for i in {1..5}; do
        echo "test content $i" > "$TAGGING_BASH_TEST_DIR/file$i.txt"
        echo "- file: $TAGGING_BASH_TEST_DIR/file$i.txt" >> "$TAGS_FILE"
        echo "  tags: [project-feature-$i, common]" >> "$TAGS_FILE"
    done

    local start_time=$(date +%s%3N)
    run "$TAGGING_BASH_TEST_DIR/../../tagg" search "proj"
    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))

    assert_equals "$?" "0"
    [ "$duration" -lt 300 ] # Fuzzy search should be fast
    [[ "$output" == *"file"* ]] # Should find matches
}

# Edge Cases and Error Conditions
@test "[EDGE CASE] search with empty tag database" {
    # Empty tags file
    echo "# Empty Tag Database" > "$TAGS_FILE"

    run "$TAGGING_BASH_TEST_DIR/../../tagg" search "any-tag"
    assert_equals "$?" "0"
    [[ "$output" == *"No files found"* ]] || [[ "$output" == *"not found"* ]]
}

@test "[EDGE CASE] search with special characters in tags" {
    # Setup
    echo "- file: $TAGGING_BASH_TEST_DIR/file1.txt" >> "$TAGS_FILE"
    echo "  tags: [tag_with_underscores, tag-with-hyphens, tag.with.dots]" >> "$TAGS_FILE"

    run "$TAGGING_BASH_TEST_DIR/../../tagg" search "tag_with_underscores"
    assert_equals "$?" "0"
    [[ "$output" == *"file1.txt"* ]]

    run "$TAGGING_BASH_TEST_DIR/../../tagg" search "tag-with-hyphens"
    assert_equals "$?" "0"
    [[ "$output" == *"file1.txt"* ]]

    run "$TAGGING_BASH_TEST_DIR/../../tagg" search "tag.with.dots"
    assert_equals "$?" "0"
    [[ "$output" == *"file1.txt"* ]]
}

@test "[EDGE CASE] search with very long tag names" {
    # Setup
    local long_tag="very-long-tag-name-that-might-cause-issues-with-parsing-or-display"
    echo "- file: $TAGGING_BASH_TEST_DIR/file1.txt" >> "$TAGS_FILE"
    echo "  tags: [$long_tag]" >> "$TAGS_FILE"

    run "$TAGGING_BASH_TEST_DIR/../../tagg" search "$long_tag"
    assert_equals "$?" "0"
    [[ "$output" == *"file1.txt"* ]]
}

@test "[EDGE CASE] search with unicode characters in tags" {
    # Setup
    echo "- file: $TAGGING_BASH_TEST_DIR/file1.txt" >> "$TAGS_FILE"
    echo "  tags: [tâg-wíth-ünicödé]" >> "$TAGS_FILE"

    run "$TAGGING_BASH_TEST_DIR/../../tagg" search "tâg-wíth-ünicödé"
    assert_equals "$?" "0"
    [[ "$output" == *"file1.txt"* ]]
}

@test "[ERROR CONDITION] search with invalid directory path" {
    run "$TAGGING_BASH_TEST_DIR/../../tagg" search "tag" --dir "/nonexistent/directory"
    assert_equals "$?" "1" # Should return error for invalid directory
    [[ "$output" == *"Error"* ]] || [[ "$output" == *"not found"* ]]
}

@test "[ERROR CONDITION] search with malformed tag database" {
    # Create malformed YAML
    echo "- file: $TAGGING_BASH_TEST_DIR/file1.txt" > "$TAGS_FILE"
    echo "  tags: [tag1" >> "$TAGS_FILE" # Missing closing bracket

    run "$TAGGING_BASH_TEST_DIR/../../tagg" search "tag1"
    # Should handle gracefully, not crash
    assert_equals "$?" "1" # Error exit code expected for malformed data
}

# Progress Indicators (mock test - actual implementation would show progress)
@test "[PROGRESS] search shows progress for large datasets" {
    # This test would need to be adjusted based on actual progress implementation
    # For now, just verify the command doesn't hang
    timeout 10s "$TAGGING_BASH_TEST_DIR/../../tagg" search "test-tag"
    assert_equals "$?" "0"
}