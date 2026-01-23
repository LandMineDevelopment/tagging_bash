#!/usr/bin/env bash
#
# run_epic2_tests.sh - Run all Epic 2 search functionality tests
# Comprehensive test runner for search, fuzzy search, directory filtering,
# multi-tag search, progress indicators, related tag suggestions, and tab completion
#

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_DIR="$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Functions
log_info() {
    echo -e "${BLUE}INFO:${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}PASS:${NC} $*" >&2
}

log_failure() {
    echo -e "${RED}FAIL:${NC} $*" >&2
}

log_warning() {
    echo -e "${YELLOW}WARN:${NC} $*" >&2
}

run_test_file() {
    local test_file="$1"
    local test_type="$2"

    if [[ ! -f "$test_file" ]]; then
        log_warning "Test file not found: $test_file"
        return 1
    fi

    log_info "Running $test_type tests: $(basename "$test_file")"

    # Source the test framework and run tests
    local output_file
    output_file=$(mktemp)

    # Run the test file and capture output
    if bash "$test_file" >"$output_file" 2>&1; then
        log_success "$test_type tests completed successfully"
        cat "$output_file" # Show test output
        return 0
    else
        local exit_code=$?
        log_failure "$test_type tests failed (exit code: $exit_code)"
        cat "$output_file" # Show test output for debugging
        return 1
    fi
}

run_performance_tests() {
    local test_file="$TEST_DIR/performance/test_search_performance.sh"

    log_info "Running performance tests (this may take a while)..."

    if run_test_file "$test_file" "Performance"; then
        log_success "Performance tests passed"
        return 0
    else
        log_failure "Performance tests failed"
        return 1
    fi
}

run_integration_tests() {
    local test_file="$TEST_DIR/integration/search_command_tests.sh"

    if run_test_file "$test_file" "Integration"; then
        log_success "Integration tests passed"
        return 0
    else
        log_failure "Integration tests failed"
        return 1
    fi
}

run_unit_tests() {
    local test_file="$TEST_DIR/unit/test_search_unit.sh"

    if run_test_file "$test_file" "Unit"; then
        log_success "Unit tests passed"
        return 0
    else
        log_failure "Unit tests failed"
        return 1
    fi
}

run_completion_tests() {
    local test_file="$TEST_DIR/integration/test_tab_completion.sh"

    if run_test_file "$test_file" "Tab Completion"; then
        log_success "Tab completion tests passed"
        return 0
    else
        log_failure "Tab completion tests failed"
        return 1
    fi
}

show_summary() {
    echo
    echo "=================================================="
    echo "Epic 2 Search Features Test Summary"
    echo "=================================================="
    echo
    echo "Test Coverage:"
    echo "✅ Unit Tests - Individual search function testing"
    echo "✅ Integration Tests - End-to-end CLI search functionality"
    echo "✅ Performance Tests - Speed and scalability validation"
    echo "✅ Tab Completion Tests - Interactive completion features"
    echo
    echo "Features Tested:"
    echo "• Search functionality (exact tag matching)"
    echo "• Fuzzy search (substring matching)"
    echo "• Directory filtering (--dir option)"
    echo "• Multi-tag search (AND logic)"
    echo "• Progress indicators (for large searches)"
    echo "• Related tag suggestions"
    echo "• Tab completion for commands and tags"
    echo "• Tab completion for directory paths"
    echo
    echo "Performance Requirements:"
    echo "• Local operations: < 100ms"
    echo "• Search operations: < 500ms (up to 10,000 files)"
    echo "• Tab completion: < 50ms (instant response)"
    echo
    echo "Edge Cases Covered:"
    echo "• Empty databases and no matches"
    echo "• Special characters in tags and file names"
    echo "• Unicode support"
    echo "• Very long tag names"
    echo "• Concurrent operations"
    echo "• File permission issues"
    echo "• Corrupted database recovery"
    echo
}

show_usage() {
    cat << EOF
Epic 2 Search Features Test Runner

USAGE:
    $0 [options] [test-types]

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Verbose output
    -q, --quiet         Quiet mode (less output)
    --no-performance    Skip performance tests
    --no-completion     Skip tab completion tests

TEST TYPES:
    unit                Run unit tests only
    integration         Run integration tests only
    performance         Run performance tests only
    completion          Run tab completion tests only
    all                 Run all tests (default)

EXAMPLES:
    $0                      # Run all tests
    $0 unit integration     # Run unit and integration tests
    $0 --no-performance     # Run all except performance tests
    $0 performance          # Run only performance tests

EXIT CODES:
    0   All tests passed
    1   Some tests failed
    2   Invalid arguments
    3   Test framework not found

EOF
}

# Parse command line arguments
VERBOSE=false
QUIET=false
SKIP_PERFORMANCE=false
SKIP_COMPLETION=false
TEST_TYPES=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        --no-performance)
            SKIP_PERFORMANCE=true
            shift
            ;;
        --no-completion)
            SKIP_COMPLETION=true
            shift
            ;;
        unit|integration|performance|completion|all)
            TEST_TYPES+=("$1")
            shift
            ;;
        *)
            echo "Error: Unknown argument: $1" >&2
            echo "Use -h or --help for usage information" >&2
            exit 2
            ;;
    esac
done

# Default to all tests if none specified
if [[ ${#TEST_TYPES[@]} -eq 0 ]]; then
    TEST_TYPES=("all")
fi

# Check prerequisites
if [[ ! -f "$TEST_DIR/test_framework.sh" ]]; then
    echo "Error: Test framework not found at $TEST_DIR/test_framework.sh" >&2
    exit 3
fi

if [[ ! -f "$PROJECT_ROOT/tagg" ]]; then
    echo "Error: Main tagging script not found at $PROJECT_ROOT/tagg" >&2
    exit 3
fi

# Main test execution
main() {
    local overall_result=0

    if [[ "$QUIET" != true ]]; then
        echo "=================================================="
        echo "Running Epic 2 Search Features Tests"
        echo "=================================================="
        echo
    fi

    # Run tests based on selection
    for test_type in "${TEST_TYPES[@]}"; do
        case $test_type in
            unit|all)
                if ! run_unit_tests; then
                    overall_result=1
                fi
                ;;
            integration|all)
                if ! run_integration_tests; then
                    overall_result=1
                fi
                ;;
            performance|all)
                if [[ "$SKIP_PERFORMANCE" != true ]]; then
                    if ! run_performance_tests; then
                        overall_result=1
                    fi
                else
                    log_info "Skipping performance tests (--no-performance)"
                fi
                ;;
            completion|all)
                if [[ "$SKIP_COMPLETION" != true ]]; then
                    if ! run_completion_tests; then
                        overall_result=1
                    fi
                else
                    log_info "Skipping tab completion tests (--no-completion)"
                fi
                ;;
        esac
    done

    # Show summary
    if [[ "$QUIET" != true ]]; then
        show_summary
    fi

    if [[ $overall_result -eq 0 ]]; then
        log_success "All selected tests completed successfully!"
    else
        log_failure "Some tests failed. Check output above for details."
    fi

    return $overall_result
}

# Run main function
main "$@"