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
source "$SCRIPT_DIR/integration/list_command_tests.sh"
source "$SCRIPT_DIR/performance/performance_tests.sh"

# Main test runner
main() {
    echo "🧪 Running Tagging Bash Test Suite"
    echo "=================================="

    # Run test suites
    run_test_suite "Unit Tests - Tag Validation" run_unit_tag_tests
    run_test_suite "Integration Tests - Add Command" run_integration_add_tests
    run_test_suite "Integration Tests - Remove Command" run_integration_remove_tests
    run_test_suite "Integration Tests - List Command" run_integration_list_tests
    run_test_suite "Performance Tests" run_performance_tests

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