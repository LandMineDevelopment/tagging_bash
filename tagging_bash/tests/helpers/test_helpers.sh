#!/usr/bin/env bash
#
# helpers/test_helpers.sh - Test helper functions and data factories
#

# Data factories for consistent test data
create_test_file() {
    local content="${1:-test content}"
    local temp_file=$(mktemp)
    echo "$content" > "$temp_file"
    echo "$temp_file"
}

create_test_files() {
    local count="${1:-3}"
    local files=()
    for i in $(seq 1 "$count"); do
        files+=("$(create_test_file "content$i")")
    done
    echo "${files[@]}"
}

# Cleanup helpers
cleanup_test_files() {
    local files=("$@")
    rm -f "${files[@]}"
}

# Database helpers
create_temp_db() {
    local temp_dir=$(mktemp -d)
    export TAGS_FILE="$temp_dir/tags.md"
    export CONFIG_DIR="$temp_dir"
    mkdir -p "$temp_dir"
    touch "$TAGS_FILE"
    echo "$temp_dir"
}

cleanup_temp_db() {
    local temp_dir="$1"
    rm -rf "$temp_dir"
    unset TAGS_FILE
    unset CONFIG_DIR
}

# Tag database inspection
get_file_tags() {
    local file="$1"
    # This would need to load and parse the database
    echo "tag1 tag2"  # Mock for testing
}

get_tag_files() {
    local tag="$1"
    # This would need to load and parse the database
    echo "/tmp/file1 /tmp/file2"  # Mock for testing
}

# Performance measurement helpers
measure_time_ms() {
    local start_time
    local end_time
    local duration_ms

    start_time=$(date +%s%N 2>/dev/null || echo "0")
    "$@"
    end_time=$(date +%s%N 2>/dev/null || echo "0")

    duration_ms=$(( (end_time - start_time) / 1000000 ))
    echo "$duration_ms"
}

# Concurrent testing helpers
run_concurrent_commands() {
    local command="$1"
    local count="${2:-3}"

    local pids=()
    for i in $(seq 1 "$count"); do
        eval "$command" &
        pids+=($!)
    done

    # Wait for all to complete
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
}

# Export functions
export -f create_test_file
export -f create_test_files
export -f cleanup_test_files
export -f create_temp_db
export -f cleanup_temp_db
export -f get_file_tags
export -f get_tag_files
export -f run_concurrent_commands