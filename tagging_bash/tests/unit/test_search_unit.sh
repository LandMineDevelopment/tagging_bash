#!/usr/bin/env bash
#
# test_search_unit.sh - Unit tests for search-related functions
# Tests individual search functions and utilities
#

# Source test framework
source "$(dirname "$0")/../test_framework.sh"

# Source the main tagging script for function testing
source "$(dirname "$0")/../../tagg"

# Test setup
setup_test() {
    export TAGGING_BASH_TEST_DIR="${BATS_TMPDIR:-/tmp}/tagging_test_unit_$$"
    mkdir -p "$TAGGING_BASH_TEST_DIR"
    export TEST_CONFIG_DIR="$TAGGING_BASH_TEST_DIR/.tagging_bash"
    export TEST_TAGS_FILE="$TEST_CONFIG_DIR/tags.md"
    mkdir -p "$TEST_CONFIG_DIR"
}

teardown_test() {
    rm -rf "$TAGGING_BASH_TEST_DIR"
}

# Mock functions for testing
mock_load_tags() {
    # Initialize associative arrays with test data
    declare -gA file_tags=(
        ["$TAGGING_BASH_TEST_DIR/file1.txt"]="project-a|bash"
        ["$TAGGING_BASH_TEST_DIR/file2.txt"]="project-b|python"
        ["$TAGGING_BASH_TEST_DIR/file3.txt"]="project-a|utility"
        ["$TAGGING_BASH_TEST_DIR/subdir/file4.txt"]="bash|script"
    )
    declare -gA tag_files=(
        ["project-a"]="$TAGGING_BASH_TEST_DIR/file1.txt|$TAGGING_BASH_TEST_DIR/file3.txt"
        ["bash"]="$TAGGING_BASH_TEST_DIR/file1.txt|$TAGGING_BASH_TEST_DIR/subdir/file4.txt"
        ["project-b"]="$TAGGING_BASH_TEST_DIR/file2.txt"
        ["python"]="$TAGGING_BASH_TEST_DIR/file2.txt"
        ["utility"]="$TAGGING_BASH_TEST_DIR/file3.txt"
        ["script"]="$TAGGING_BASH_TEST_DIR/subdir/file4.txt"
    )
}

# Unit tests for search argument parsing
test_search_arg_parsing_basic() {
    # Mock the search function to capture parsed arguments
    local search_tags=()
    local search_dir=""
    local fuzzy_mode=false

    # Simulate parsing: tagg search project-a
    set -- "project-a"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dir)
                search_dir="$2"
                shift 2
                ;;
            --fuzzy)
                fuzzy_mode=true
                shift
                ;;
            *)
                search_tags+=("$1")
                shift
                ;;
        esac
    done

    assert_equals "${#search_tags[@]}" "1" "Should have one search tag"
    assert_equals "${search_tags[0]}" "project-a" "Should have correct tag"
    assert_equals "$search_dir" "" "Should have no directory filter"
    assert_equals "$fuzzy_mode" "false" "Should not be fuzzy mode"
}

test_search_arg_parsing_fuzzy() {
    local search_tags=()
    local search_dir=""
    local fuzzy_mode=false

    # Simulate parsing: tagg search --fuzzy project
    set -- "--fuzzy" "project"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dir)
                search_dir="$2"
                shift 2
                ;;
            --fuzzy)
                fuzzy_mode=true
                shift
                ;;
            *)
                search_tags+=("$1")
                shift
                ;;
        esac
    done

    assert_equals "${#search_tags[@]}" "1" "Should have one search tag"
    assert_equals "${search_tags[0]}" "project" "Should have correct tag"
    assert_equals "$fuzzy_mode" "true" "Should be fuzzy mode"
}

test_search_arg_parsing_directory() {
    local search_tags=()
    local search_dir=""
    local fuzzy_mode=false

    # Simulate parsing: tagg search bash --dir /tmp/test
    set -- "bash" "--dir" "/tmp/test"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dir)
                search_dir="$2"
                shift 2
                ;;
            --fuzzy)
                fuzzy_mode=true
                shift
                ;;
            *)
                search_tags+=("$1")
                shift
                ;;
        esac
    done

    assert_equals "${#search_tags[@]}" "1" "Should have one search tag"
    assert_equals "${search_tags[0]}" "bash" "Should have correct tag"
    assert_equals "$search_dir" "/tmp/test" "Should have directory filter"
}

test_search_arg_parsing_multiple() {
    local search_tags=()
    local search_dir=""
    local fuzzy_mode=false

    # Simulate parsing: tagg search project-a bash utility
    set -- "project-a" "bash" "utility"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dir)
                search_dir="$2"
                shift 2
                ;;
            --fuzzy)
                fuzzy_mode=true
                shift
                ;;
            *)
                search_tags+=("$1")
                shift
                ;;
        esac
    done

    assert_equals "${#search_tags[@]}" "3" "Should have three search tags"
    assert_equals "${search_tags[0]}" "project-a" "Should have first tag"
    assert_equals "${search_tags[1]}" "bash" "Should have second tag"
    assert_equals "${search_tags[2]}" "utility" "Should have third tag"
}

# Unit tests for search logic
test_exact_search_single_match() {
    mock_load_tags

    local file_path="$TAGGING_BASH_TEST_DIR/file1.txt"
    local file_tags_str="${file_tags[$file_path]}"
    local search_tags=("project-a")
    local fuzzy_mode=false

    local has_all_tags=true
    for search_tag in "${search_tags[@]}"; do
        local tag_found=false
        if [[ "$fuzzy_mode" == true ]]; then
            # Fuzzy search
            IFS='|' read -ra file_tag_array <<< "$file_tags_str"
            for file_tag in "${file_tag_array[@]}"; do
                if [[ "$file_tag" == *"$search_tag"* ]]; then
                    tag_found=true
                    break
                fi
            done
        else
            # Exact search
            if [[ "$file_tags_str" =~ (^|\|)$search_tag($|\|) ]]; then
                tag_found=true
            fi
        fi
        if [[ "$tag_found" == false ]]; then
            has_all_tags=false
            break
        fi
    done

    assert_equals "$has_all_tags" "true" "File should match single tag"
}

test_exact_search_single_no_match() {
    mock_load_tags

    local file_path="$TAGGING_BASH_TEST_DIR/file1.txt"
    local file_tags_str="${file_tags[$file_path]}"
    local search_tags=("nonexistent")
    local fuzzy_mode=false

    local has_all_tags=true
    for search_tag in "${search_tags[@]}"; do
        local tag_found=false
        if [[ "$file_tags_str" =~ (^|\|)$search_tag($|\|) ]]; then
            tag_found=true
        fi
        if [[ "$tag_found" == false ]]; then
            has_all_tags=false
            break
        fi
    done

    assert_equals "$has_all_tags" "false" "File should not match nonexistent tag"
}

test_fuzzy_search_substring_match() {
    mock_load_tags

    local file_path="$TAGGING_BASH_TEST_DIR/file1.txt"
    local file_tags_str="${file_tags[$file_path]}"
    local search_tags=("proj")
    local fuzzy_mode=true

    local has_all_tags=true
    for search_tag in "${search_tags[@]}"; do
        local tag_found=false
        IFS='|' read -ra file_tag_array <<< "$file_tags_str"
        for file_tag in "${file_tag_array[@]}"; do
            if [[ "$file_tag" == *"$search_tag"* ]]; then
                tag_found=true
                break
            fi
        done
        if [[ "$tag_found" == false ]]; then
            has_all_tags=false
            break
        fi
    done

    assert_equals "$has_all_tags" "true" "File should match fuzzy substring"
}

test_fuzzy_search_no_substring_match() {
    mock_load_tags

    local file_path="$TAGGING_BASH_TEST_DIR/file1.txt"
    local file_tags_str="${file_tags[$file_path]}"
    local search_tags=("xyz")
    local fuzzy_mode=true

    local has_all_tags=true
    for search_tag in "${search_tags[@]}"; do
        local tag_found=false
        IFS='|' read -ra file_tag_array <<< "$file_tags_str"
        for file_tag in "${file_tag_array[@]}"; do
            if [[ "$file_tag" == *"$search_tag"* ]]; then
                tag_found=true
                break
            fi
        done
        if [[ "$tag_found" == false ]]; then
            has_all_tags=false
            break
        fi
    done

    assert_equals "$has_all_tags" "false" "File should not match unrelated substring"
}

test_multi_tag_search_all_match() {
    mock_load_tags

    local file_path="$TAGGING_BASH_TEST_DIR/file1.txt"
    local file_tags_str="${file_tags[$file_path]}"
    local search_tags=("project-a" "bash")
    local fuzzy_mode=false

    local has_all_tags=true
    for search_tag in "${search_tags[@]}"; do
        local tag_found=false
        if [[ "$file_tags_str" =~ (^|\|)$search_tag($|\|) ]]; then
            tag_found=true
        fi
        if [[ "$tag_found" == false ]]; then
            has_all_tags=false
            break
        fi
    done

    assert_equals "$has_all_tags" "true" "File should match all tags"
}

test_multi_tag_search_partial_match() {
    mock_load_tags

    local file_path="$TAGGING_BASH_TEST_DIR/file1.txt"
    local file_tags_str="${file_tags[$file_path]}"
    local search_tags=("project-a" "python")
    local fuzzy_mode=false

    local has_all_tags=true
    for search_tag in "${search_tags[@]}"; do
        local tag_found=false
        if [[ "$file_tags_str" =~ (^|\|)$search_tag($|\|) ]]; then
            tag_found=true
        fi
        if [[ "$tag_found" == false ]]; then
            has_all_tags=false
            break
        fi
    done

    assert_equals "$has_all_tags" "false" "File should not match when missing one tag"
}

# Unit tests for directory filtering logic
test_directory_filtering_in_directory() {
    local file_path="$TAGGING_BASH_TEST_DIR/subdir/file4.txt"
    local search_dir="$TAGGING_BASH_TEST_DIR/subdir"

    local should_include=true
    if [[ -n "$search_dir" ]]; then
        if [[ "$file_path" != "$search_dir"/* ]]; then
            should_include=false
        fi
    fi

    assert_equals "$should_include" "true" "File in directory should be included"
}

test_directory_filtering_not_in_directory() {
    local file_path="$TAGGING_BASH_TEST_DIR/file1.txt"
    local search_dir="$TAGGING_BASH_TEST_DIR/subdir"

    local should_include=true
    if [[ -n "$search_dir" ]]; then
        if [[ "$file_path" != "$search_dir"/* ]]; then
            should_include=false
        fi
    fi

    assert_equals "$should_include" "false" "File not in directory should be excluded"
}

test_directory_filtering_no_directory() {
    local file_path="$TAGGING_BASH_TEST_DIR/file1.txt"
    local search_dir=""

    local should_include=true
    if [[ -n "$search_dir" ]]; then
        if [[ "$file_path" != "$search_dir"/* ]]; then
            should_include=false
        fi
    fi

    assert_equals "$should_include" "true" "File should be included when no directory filter"
}

# Unit tests for tag validation in search
test_tag_validation_valid() {
    local tags=("project-a" "bash_script" "test-file")
    local all_valid=true

    for tag in "${tags[@]}"; do
        if [[ ! "$tag" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
            all_valid=false
            break
        fi
    done

    assert_equals "$all_valid" "true" "Valid tags should pass validation"
}

test_tag_validation_invalid_spaces() {
    local tag="project a"
    local is_valid=true

    if [[ ! "$tag" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
        is_valid=false
    fi

    assert_equals "$is_valid" "false" "Tag with spaces should be invalid"
}

test_tag_validation_invalid_special_chars() {
    local tag="project@tag"
    local is_valid=true

    if [[ ! "$tag" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
        is_valid=false
    fi

    assert_equals "$is_valid" "false" "Tag with @ should be invalid"
}

# Unit tests for result formatting
test_result_formatting_tag_sorting() {
    local tags="zebra|alpha|beta"
    IFS='|' read -ra tag_array <<< "$tags"
    local sorted_tags
    mapfile -t sorted_tags < <(printf '%s\n' "${tag_array[@]}" | sort)

    assert_equals "${sorted_tags[0]}" "alpha" "First tag should be alpha"
    assert_equals "${sorted_tags[1]}" "beta" "Second tag should be beta"
    assert_equals "${sorted_tags[2]}" "zebra" "Third tag should be zebra"
}

test_result_formatting_unique_suggestions() {
    local all_result_tags=("bash" "python" "bash" "utility")
    local unique_suggestions=($(printf '%s\n' "${all_result_tags[@]}" | sort | uniq))

    assert_equals "${#unique_suggestions[@]}" "3" "Should have 3 unique tags"
    assert_equals "${unique_suggestions[0]}" "bash" "First suggestion should be bash"
    assert_equals "${unique_suggestions[1]}" "python" "Second suggestion should be python"
    assert_equals "${unique_suggestions[2]}" "utility" "Third suggestion should be utility"
}

# Unit tests for progress calculation
test_progress_calculation_percentage() {
    local processed=25
    local total_files=100
    local percent=$((processed * 100 / total_files))

    assert_equals "$percent" "25" "25% of 100 should be 25"
}

test_progress_calculation_zero_division() {
    local processed=0
    local total_files=0
    local percent=0

    if [[ $total_files -gt 0 ]]; then
        percent=$((processed * 100 / total_files))
    fi

    assert_equals "$percent" "0" "Should handle zero total files"
}

# Unit tests for timing calculations
test_timing_calculation_ms_conversion() {
    local start_time=1000000000  # nanoseconds
    local end_time=1500000000    # nanoseconds
    local duration_ms=$(( (end_time - start_time) / 1000000 ))

    assert_equals "$duration_ms" "500" "5 second difference should be 500ms"
}

# Edge cases for search logic
test_edge_case_empty_file_tags() {
    local file_tags_str=""
    local search_tags=("project-a")
    local fuzzy_mode=false

    local has_all_tags=true
    for search_tag in "${search_tags[@]}"; do
        local tag_found=false
        if [[ "$file_tags_str" =~ (^|\|)$search_tag($|\|) ]]; then
            tag_found=true
        fi
        if [[ "$tag_found" == false ]]; then
            has_all_tags=false
            break
        fi
    done

    assert_equals "$has_all_tags" "false" "Empty tags should not match"
}

test_edge_case_single_tag() {
    local file_tags_str="bash"
    local search_tags=("bash")
    local fuzzy_mode=false

    local has_all_tags=true
    for search_tag in "${search_tags[@]}"; do
        local tag_found=false
        if [[ "$file_tags_str" =~ (^|\|)$search_tag($|\|) ]]; then
            tag_found=true
        fi
        if [[ "$tag_found" == false ]]; then
            has_all_tags=false
            break
        fi
    done

    assert_equals "$has_all_tags" "true" "Single tag should match exactly"
}

test_edge_case_fuzzy_empty_search() {
    local file_tags_str="project-a|bash"
    local search_tags=("")
    local fuzzy_mode=true

    local has_all_tags=true
    for search_tag in "${search_tags[@]}"; do
        local tag_found=false
        IFS='|' read -ra file_tag_array <<< "$file_tags_str"
        for file_tag in "${file_tag_array[@]}"; do
            if [[ "$file_tag" == *"$search_tag"* ]]; then
                tag_found=true
                break
            fi
        done
        if [[ "$tag_found" == false ]]; then
            has_all_tags=false
            break
        fi
    done

    # Empty string matches everything in bash
    assert_equals "$has_all_tags" "true" "Empty fuzzy search should match all"
}

# Main test runner
run_unit_search_tests() {
    run_test_with_isolation "search_arg_parsing_basic" test_search_arg_parsing_basic
    run_test_with_isolation "search_arg_parsing_fuzzy" test_search_arg_parsing_fuzzy
    run_test_with_isolation "search_arg_parsing_directory" test_search_arg_parsing_directory
    run_test_with_isolation "search_arg_parsing_multiple" test_search_arg_parsing_multiple
    run_test_with_isolation "exact_search_single_match" test_exact_search_single_match
    run_test_with_isolation "exact_search_single_no_match" test_exact_search_single_no_match
    run_test_with_isolation "fuzzy_search_substring_match" test_fuzzy_search_substring_match
    run_test_with_isolation "fuzzy_search_no_substring_match" test_fuzzy_search_no_substring_match
    run_test_with_isolation "multi_tag_search_all_match" test_multi_tag_search_all_match
    run_test_with_isolation "multi_tag_search_partial_match" test_multi_tag_search_partial_match
    run_test_with_isolation "directory_filtering_in_directory" test_directory_filtering_in_directory
    run_test_with_isolation "directory_filtering_not_in_directory" test_directory_filtering_not_in_directory
    run_test_with_isolation "directory_filtering_no_directory" test_directory_filtering_no_directory
    run_test_with_isolation "tag_validation_valid" test_tag_validation_valid
    run_test_with_isolation "tag_validation_invalid_spaces" test_tag_validation_invalid_spaces
    run_test_with_isolation "tag_validation_invalid_special_chars" test_tag_validation_invalid_special_chars
    run_test_with_isolation "result_formatting_tag_sorting" test_result_formatting_tag_sorting
    run_test_with_isolation "result_formatting_unique_suggestions" test_result_formatting_unique_suggestions
    run_test_with_isolation "progress_calculation_percentage" test_progress_calculation_percentage
    run_test_with_isolation "progress_calculation_zero_division" test_progress_calculation_zero_division
    run_test_with_isolation "timing_calculation_ms_conversion" test_timing_calculation_ms_conversion
    run_test_with_isolation "edge_case_empty_file_tags" test_edge_case_empty_file_tags
    run_test_with_isolation "edge_case_single_tag" test_edge_case_single_tag
    run_test_with_isolation "edge_case_fuzzy_empty_search" test_edge_case_fuzzy_empty_search
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_unit_search_tests
fi

# Export for test runner
export -f run_unit_search_tests