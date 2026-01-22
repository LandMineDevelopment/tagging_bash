#!/usr/bin/env bash
#
# test_framework.sh - Core test framework utilities
# Provides assertions, test runner, and reporting for bash-based testing
#

# Prevent multiple sourcing
if [[ -n "${_TEST_FRAMEWORK_LOADED:-}" ]]; then
    return 0
fi
readonly _TEST_FRAMEWORK_LOADED=true

# Test framework constants
readonly TEST_PASS=0
readonly TEST_FAIL=1
readonly TEST_SKIP=2

# Global test counters
TEST_TOTAL=0
TEST_PASSED=0
TEST_FAILED=0
TEST_SKIPPED=0

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Assertion functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-"Expected '$expected', got '$actual'"}"

    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        return $TEST_PASS
    else
        echo -e "${RED}✗ FAIL${NC}: $message"
        return $TEST_FAIL
    fi
}

assert_true() {
    local condition="$1"
    local message="${2:-"Expected true, got false"}"

    if [[ "$condition" == "true" ]] || [[ "$condition" -eq 0 ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        return $TEST_PASS
    else
        echo -e "${RED}✗ FAIL${NC}: $message"
        return $TEST_FAIL
    fi
}

assert_false() {
    local condition="$1"
    local message="${2:-"Expected false, got true"}"

    if [[ "$condition" == "false" ]] || [[ "$condition" -ne 0 ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        return $TEST_PASS
    else
        echo -e "${RED}✗ FAIL${NC}: $message"
        return $TEST_FAIL
    fi
}

assert_exists() {
    local file="$1"
    local message="${2:-"File should exist: $file"}"

    if [[ -e "$file" ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        return $TEST_PASS
    else
        echo -e "${RED}✗ FAIL${NC}: $message"
        return $TEST_FAIL
    fi
}

assert_not_exists() {
    local file="$1"
    local message="${2:-"File should not exist: $file"}"

    if [[ ! -e "$file" ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        return $TEST_PASS
    else
        echo -e "${RED}✗ FAIL${NC}: $message"
        return $TEST_FAIL
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-"String should contain '$needle'"}"

    if [[ "$haystack" == *"$needle"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        return $TEST_PASS
    else
        echo -e "${RED}✗ FAIL${NC}: $message"
        return $TEST_FAIL
    fi
}

assert_performance() {
    local duration_ms="$1"
    local max_ms="$2"
    local operation="${3:-"operation"}"

    if [[ $duration_ms -le $max_ms ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $operation completed in ${duration_ms}ms (max: ${max_ms}ms)"
        return $TEST_PASS
    else
        echo -e "${RED}✗ FAIL${NC}: $operation took ${duration_ms}ms (exceeded ${max_ms}ms limit)"
        return $TEST_FAIL
    fi
}

# Test runner functions
run_test() {
    local test_name="$1"
    local test_function="$2"

    echo -e "${BLUE}Running test:${NC} $test_name"

    TEST_TOTAL=$((TEST_TOTAL + 1))

    if $test_function; then
        TEST_PASSED=$((TEST_PASSED + 1))
    else
        TEST_FAILED=$((TEST_FAILED + 1))
    fi

    echo ""
}

# Setup/teardown functions for test isolation
setup_test() {
    # Override this function in test files to set up test state
    return 0
}

teardown_test() {
    # Override this function in test files to clean up test state
    # Clean up any temp files created during tests
    if [[ -n "${TEST_TEMP_FILES:-}" ]]; then
        for temp_file in $TEST_TEMP_FILES; do
            rm -f "$temp_file" 2>/dev/null || true
        done
        unset TEST_TEMP_FILES
    fi
    # Clean up test files created in project directory
    local project_dir
    project_dir="$(dirname "${BASH_SOURCE[0]}")/../.."
    rm -f "$project_dir/test"*.txt 2>/dev/null || true
    rm -f "$project_dir/testfile"* 2>/dev/null || true
    rm -f "$project_dir/empty_file.txt" 2>/dev/null || true
    rm -f "$project_dir/another_file.txt" 2>/dev/null || true
    # Clean up any other test artifacts
    find "$project_dir" -name "*test*" -type f -size 0 -delete 2>/dev/null || true
    return 0
}

# Mock management functions
mock_function() {
    local func_name="$1"
    local mock_body="$2"

    # Store original function if not already stored
    if ! declare -f "_original_$func_name" >/dev/null 2>&1; then
        eval "_original_$func_name() $(declare -f "$func_name" | tail -n +2)"
    fi

    # Install mock
    eval "$func_name() { $mock_body }"
}

restore_function() {
    local func_name="$1"

    # Restore original function if it was mocked
    if declare -f "_original_$func_name" >/dev/null 2>&1; then
        eval "$func_name() $(declare -f "_original_$func_name" | tail -n +2)"
        unset -f "_original_$func_name"
    fi
}

# Run test with setup/teardown
run_test_with_isolation() {
    local test_name="$1"
    local test_function="$2"

    echo -e "${BLUE}Running test:${NC} $test_name"

    TEST_TOTAL=$((TEST_TOTAL + 1))

    # Setup
    if setup_test; then
        # Run test
        if $test_function; then
            TEST_PASSED=$((TEST_PASSED + 1))
        else
            TEST_FAILED=$((TEST_FAILED + 1))
        fi
    else
        echo -e "${RED}SETUP FAILED${NC}: $test_name"
        TEST_FAILED=$((TEST_FAILED + 1))
    fi

    # Teardown
    teardown_test

    echo ""
}

run_test_suite() {
    local suite_name="$1"
    local suite_function="$2"

    echo -e "${BLUE}=== Test Suite: $suite_name ===${NC}"

    # Reset counters for suite
    local suite_total=0
    local suite_passed=0
    local suite_failed=0

    # Run suite function by name
    if eval "$suite_function"; then
        echo -e "${GREEN}Suite PASSED${NC}"
    else
        echo -e "${RED}Suite FAILED${NC}"
    fi

    echo ""
}

print_test_summary() {
    echo -e "${BLUE}=== Test Summary ===${NC}"
    echo "Total tests: $TEST_TOTAL"
    echo -e "Passed: ${GREEN}$TEST_PASSED${NC}"
    echo -e "Failed: ${RED}$TEST_FAILED${NC}"
    echo -e "Skipped: ${YELLOW}$TEST_SKIPPED${NC}"

    if [[ $TEST_FAILED -gt 0 ]]; then
        echo -e "${RED}❌ Some tests failed${NC}"
        return 1
    else
        echo -e "${GREEN}✅ All tests passed${NC}"
        return 0
    fi
}

# Utility functions
run_command_get_exit() {
    local exit_code=0
    "$@" || exit_code=$?
    echo $exit_code
}

measure_time_ms() {
    local start_time=$(date +%s%3N)
    "$@" >/dev/null 2>&1  # Suppress output for timing
    local end_time=$(date +%s%3N)
    echo $((end_time - start_time))
}

create_temp_dir() {
    mktemp -d
}

cleanup_temp_dir() {
    local temp_dir="$1"
    rm -rf "$temp_dir"
}

# Export functions for sourcing
export -f assert_equals
export -f assert_true
export -f assert_false
export -f assert_exists
export -f assert_not_exists
export -f assert_contains
export -f assert_performance
export -f run_test
export -f run_test_suite
export -f print_test_summary
export -f run_command_get_exit
export -f measure_time_ms
export -f create_temp_dir
export -f cleanup_temp_dir
export -f setup_test
export -f teardown_test
export -f mock_function
export -f restore_function
export -f run_test_with_isolation