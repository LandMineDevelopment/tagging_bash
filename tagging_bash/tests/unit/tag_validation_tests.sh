#!/usr/bin/env bash
#
# unit/tag_validation_tests.sh - Unit tests for tag validation functions
#

source "$(dirname "${BASH_SOURCE[0]}")/../test_framework.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../tagg"

# Test tag validation
test_validate_tag_name_valid() {
    # Valid tags
    assert_equals "$(run_command_get_exit validate_tag_name "valid_tag")" 0 "valid_tag should pass"
    assert_equals "$(run_command_get_exit validate_tag_name "tag-name")" 0 "tag-name should pass"
    assert_equals "$(run_command_get_exit validate_tag_name "tag.name")" 0 "tag.name should pass"
    assert_equals "$(run_command_get_exit validate_tag_name "tag123")" 0 "tag123 should pass"
}

test_validate_tag_name_invalid() {
    # Invalid tags
    assert_equals "$(run_command_get_exit validate_tag_name "tag with spaces")" 1 "spaces should fail"
    assert_equals "$(run_command_get_exit validate_tag_name "tag@symbol")" 1 "@ should fail"
    assert_equals "$(run_command_get_exit validate_tag_name "tag,comma")" 1 "comma should fail"
    assert_equals "$(run_command_get_exit validate_tag_name "")" 1 "empty should fail"
    assert_equals "$(run_command_get_exit validate_tag_name "$(printf 'a%.0s' {1..51})")" 1 "too long should fail"
}

test_validate_file_path_valid() {
    # Create temp file for testing
    local temp_file=$(mktemp)
    echo "test" > "$temp_file"

    assert_equals "$(run_command_get_exit validate_file_path "$temp_file")" 0 "existing file should pass"

    rm -f "$temp_file"
}

test_validate_file_path_invalid() {
    assert_equals "$(run_command_get_exit validate_file_path "/nonexistent/file")" 1 "nonexistent file should fail"
}

# Run unit tests
run_unit_tag_tests() {
    run_test "validate_tag_name_valid" test_validate_tag_name_valid
    run_test "validate_tag_name_invalid" test_validate_tag_name_invalid
    run_test "validate_file_path_valid" test_validate_file_path_valid
    run_test "validate_file_path_invalid" test_validate_file_path_invalid
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_unit_tag_tests
fi

# Export for test runner
export -f run_unit_tag_tests