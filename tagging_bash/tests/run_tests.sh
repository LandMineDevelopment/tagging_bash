#!/usr/bin/env bash
#
# run_tests.sh - Main test runner for tagging_bash
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_framework.sh"
source "$SCRIPT_DIR/helpers/test_helpers.sh"

# Import test suites
source "$SCRIPT_DIR/unit/tag_validation_tests.sh"
source "$SCRIPT_DIR/integration/add_command_tests.sh"
source "$SCRIPT_DIR/integration/remove_command_tests.sh"
source "$SCRIPT_DIR/integration/edit_command_tests.sh"
source "$SCRIPT_DIR/integration/list_command_tests.sh"
source "$SCRIPT_DIR/integration/search_command_tests.sh"
source "$SCRIPT_DIR/performance/performance_tests.sh"

# Run test suite with isolation
run_isolated_test_suite() {
    local suite_name="$1"
    local suite_script="$2"

    echo -e "${BLUE}=== Test Suite: $suite_name ===${NC}"

    # The test suites are already sourced, so just call the appropriate function
    local suite_func
    case "$suite_name" in
        "Unit Tests - Tag Validation")
            suite_func="run_unit_tag_tests"
            ;;
        "Integration Tests - Add Command")
            suite_func="run_integration_add_tests"
            ;;
        "Integration Tests - Remove Command")
            suite_func="run_integration_remove_tests"
            ;;
        "Integration Tests - Edit Command")
            suite_func="run_integration_edit_tests"
            ;;
        "Integration Tests - List Command")
            suite_func="run_integration_list_tests"
            ;;
        "Integration Tests - Search Command")
            suite_func="run_integration_search_tests"
            ;;
        "Performance Tests")
            suite_func="run_performance_tests"
            ;;
        *)
            echo -e "${RED}Unknown test suite: $suite_name${NC}"
            return 1
            ;;
    esac

    if eval "$suite_func"; then
        echo -e "${GREEN}Suite PASSED${NC}"
    else
        echo -e "${RED}Suite FAILED${NC}"
        return 1
    fi

    echo ""
}

# Main test runner
main() {
    echo "🧪 Running Tagging Bash Test Suite"
    echo "=================================="

    # Run test suites in isolated processes
    run_isolated_test_suite "Unit Tests - Tag Validation" "$SCRIPT_DIR/unit/tag_validation_tests.sh"
    run_isolated_test_suite "Integration Tests - Add Command" "$SCRIPT_DIR/integration/add_command_tests.sh"
    run_isolated_test_suite "Integration Tests - Remove Command" "$SCRIPT_DIR/integration/remove_command_tests.sh"
    run_isolated_test_suite "Integration Tests - Edit Command" "$SCRIPT_DIR/integration/edit_command_tests.sh"
    run_isolated_test_suite "Integration Tests - List Command" "$SCRIPT_DIR/integration/list_command_tests.sh"
    run_isolated_test_suite "Integration Tests - Search Command" "$SCRIPT_DIR/integration/search_command_tests.sh"
    run_isolated_test_suite "Performance Tests" "$SCRIPT_DIR/performance/performance_tests.sh"

    # Print final summary
    echo ""
    print_test_summary

    # Exit with appropriate code
    if [[ $TEST_FAILED -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi