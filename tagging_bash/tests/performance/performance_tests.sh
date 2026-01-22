#!/usr/bin/env bash
#
# performance/performance_tests.sh - Performance tests for timing requirements
#

source "$(dirname "${BASH_SOURCE[0]}")/../test_framework.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../tagg"

# Mock functions for performance testing
validate_file_path() { return 0; }
validate_tag_name() { return 0; }
load_tags() {
    declare -gA file_tags=()
    declare -gA tag_files=()
    return 0;
}
save_tags() { return 0; }
acquire_lock() { return 0; }
release_lock() { return 0; }

# Test performance of single file tagging (<100ms)
test_single_file_performance() {
    local temp_file=$(mktemp)
    echo "test" > "$temp_file"

    local duration
    duration=$(measure_time_ms cmd_add "$temp_file" "perf_test")

    assert_performance "$duration" 100 "Single file tagging"

    rm -f "$temp_file"
}

# Test performance of multiple file tagging
test_multiple_files_performance() {
    local temp_files=()
    for i in {1..5}; do
        local temp_file=$(mktemp)
        echo "test$i" > "$temp_file"
        temp_files+=("$temp_file")
    done

    local duration
    duration=$(measure_time_ms cmd_add "${temp_files[@]}" "multi_perf")

    assert_performance "$duration" 200 "Multiple file tagging (5 files)"

    rm -f "${temp_files[@]}"
}

# Test hash map performance with larger dataset
test_hash_map_performance() {
    # Mock larger dataset
    load_tags() {
        declare -gA file_tags=()
        declare -gA tag_files=()
        # Simulate 1000 tagged files
        for i in {1..1000}; do
            file_tags["/tmp/file_$i"]="tag_$i"
            tag_files["tag_$i"]="/tmp/file_$i"
        done
        return 0;
    }

    local temp_file=$(mktemp)
    echo "test" > "$temp_file"

    local duration
    duration=$(measure_time_ms cmd_add "$temp_file" "new_tag")

    assert_performance "$duration" 100 "Hash map operation with 1000 entries"

    rm -f "$temp_file"
}

# Run performance tests
run_performance_tests() {
    run_test "single_file_performance" test_single_file_performance
    run_test "multiple_files_performance" test_multiple_files_performance
    run_test "hash_map_performance" test_hash_map_performance
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_performance_tests
fi

# Export for test runner
export -f run_performance_tests