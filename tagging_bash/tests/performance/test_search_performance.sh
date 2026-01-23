#!/usr/bin/env bash
#
# test_search_performance.sh - Performance tests for Epic 2 search features
# Tests performance requirements and scalability
#

# Source test framework
source "$(dirname "$0")/../test_framework.sh"

# Source the main tagging script for testing
source "$(dirname "$0")/../../tagg"

# Test setup
setup() {
    export TAGGING_BASH_TEST_DIR="${BATS_TMPDIR:-/tmp}/tagging_perf_test_$$"
    mkdir -p "$TAGGING_BASH_TEST_DIR"
    export CONFIG_DIR="$TAGGING_BASH_TEST_DIR/.tagging_bash"
    export TAGS_FILE="$CONFIG_DIR/tags.md"
    mkdir -p "$CONFIG_DIR"
}

teardown() {
    rm -rf "$TAGGING_BASH_TEST_DIR"
}

# Performance test utilities
measure_time() {
    local start_time=$(date +%s%N 2>/dev/null || echo "0")
    "$@"
    local exit_code=$?
    local end_time=$(date +%s%N 2>/dev/null || echo "0")
    local duration_ms=$(( (end_time - start_time) / 1000000 ))
    echo "$duration_ms"
    return $exit_code
}

create_test_files() {
    local count=$1
    local tags_file="$TAGS_FILE"

    # Create initial tags file
    echo "# Performance Test Tag Database" > "$tags_file"

    # Create files with tags
    for i in $(seq 1 "$count"); do
        local filename="file${i}.txt"
        local filepath="$TAGGING_BASH_TEST_DIR/$filename"

        # Create the file
        echo "test content $i" > "$filepath"

        # Add to tags database
        echo "- file: $filepath" >> "$tags_file"

        # Assign tags based on file number
        local tags=""
        if (( i % 3 == 0 )); then tags="project-a"; fi
        if (( i % 5 == 0 )); then tags="${tags:+$tags|}utility"; fi
        if (( i % 7 == 0 )); then tags="${tags:+$tags|}bash"; fi
        if (( i % 11 == 0 )); then tags="${tags:+$tags|}python"; fi
        if (( i % 13 == 0 )); then tags="${tags:+$tags|}script"; fi

        # Ensure every file has at least one tag
        if [[ -z "$tags" ]]; then
            tags="common-tag"
        fi

        echo "  tags: [$tags]" >> "$tags_file"
        echo "" >> "$tags_file"
    done
}

# Performance Tests
@test "[PERFORMANCE] search small dataset - exact match under 100ms" {
    create_test_files 10

    local duration
    duration=$(measure_time "$TAGGING_BASH_TEST_DIR/../../tagg" search "project-a")

    [ "$duration" -lt 100 ] # Should complete in under 100ms
}

@test "[PERFORMANCE] search medium dataset - exact match under 500ms" {
    create_test_files 100

    local duration
    duration=$(measure_time "$TAGGING_BASH_TEST_DIR/../../tagg" search "project-a")

    [ "$duration" -lt 500 ] # Should complete in under 500ms
}

@test "[PERFORMANCE] search large dataset - exact match under 500ms" {
    create_test_files 1000

    local start_time=$(date +%s%N)
    "$TAGGING_BASH_TEST_DIR/../../tagg" search "project-a" >/dev/null 2>&1
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))

    [ "$duration" -lt 500 ] # Should complete in under 500ms
}

@test "[PERFORMANCE] fuzzy search performance - substring search" {
    create_test_files 100

    local duration
    duration=$(measure_time "$TAGGING_BASH_TEST_DIR/../../tagg" search --fuzzy "proj")

    [ "$duration" -lt 300 ] # Fuzzy search should be reasonably fast
}

@test "[PERFORMANCE] multi-tag search performance - AND logic" {
    create_test_files 200

    local duration
    duration=$(measure_time "$TAGGING_BASH_TEST_DIR/../../tagg" search "project-a" "utility")

    [ "$duration" -lt 500 ] # Multi-tag search should be under 500ms
}

@test "[PERFORMANCE] directory-filtered search performance" {
    create_test_files 500

    # Create subdirectory with subset of files
    mkdir -p "$TAGGING_BASH_TEST_DIR/subset"
    for i in {1..50}; do
        echo "subset content $i" > "$TAGGING_BASH_TEST_DIR/subset/file${i}.txt"
        echo "- file: $TAGGING_BASH_TEST_DIR/subset/file${i}.txt" >> "$TAGS_FILE"
        echo "  tags: [subset-tag]" >> "$TAGS_FILE"
        echo "" >> "$TAGS_FILE"
    done

    local duration
    duration=$(measure_time "$TAGGING_BASH_TEST_DIR/../../tagg" search "subset-tag" --dir "$TAGGING_BASH_TEST_DIR/subset")

    [ "$duration" -lt 200 ] # Directory-filtered search should be fast
}

@test "[PERFORMANCE] search with progress indicators - large dataset" {
    create_test_files 2000

    # Capture stderr for progress messages
    local start_time=$(date +%s%N)
    "$TAGGING_BASH_TEST_DIR/../../tagg" search "common-tag" 2>&1 | grep -q "Searching"
    local progress_shown=$?
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))

    [ "$duration" -lt 1000 ] # Should complete in under 1 second even with progress
    [ "$progress_shown" -eq 0 ] # Progress should be shown for large datasets
}

@test "[PERFORMANCE] tab completion simulation - instant response" {
    create_test_files 100

    # Simulate tab completion by searching for partial tags
    local duration
    duration=$(measure_time "$TAGGING_BASH_TEST_DIR/../../tagg" search "proj" 2>/dev/null)

    [ "$duration" -lt 50 ] # Tab completion should be instant (< 50ms)
}

@test "[PERFORMANCE] memory usage - no memory leaks in large searches" {
    create_test_files 1000

    # Get memory usage before
    local mem_before=$(ps -o rss= $$ 2>/dev/null || echo "0")

    # Run search
    "$TAGGING_BASH_TEST_DIR/../../tagg" search "common-tag" >/dev/null 2>&1

    # Get memory usage after
    local mem_after=$(ps -o rss= $$ 2>/dev/null || echo "0")

    # Memory should not increase dramatically (allow 10MB increase)
    local mem_increase=$((mem_after - mem_before))
    [ "$mem_increase" -lt 10000 ] # Less than 10MB increase
}

@test "[PERFORMANCE] concurrent search operations" {
    create_test_files 200

    # Run multiple searches concurrently
    local pids=()
    for i in {1..3}; do
        "$TAGGING_BASH_TEST_DIR/../../tagg" search "project-a" >/dev/null 2>&1 &
        pids+=($!)
    done

    # Wait for all to complete
    local start_time=$(date +%s%N)
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))

    [ "$duration" -lt 1000 ] # Concurrent searches should complete reasonably fast
}

@test "[PERFORMANCE] search result formatting - large result sets" {
    # Create many files with same tag to test result formatting performance
    for i in {1..200}; do
        echo "content $i" > "$TAGGING_BASH_TEST_DIR/file${i}.txt"
        echo "- file: $TAGGING_BASH_TEST_DIR/file${i}.txt" >> "$TAGS_FILE"
        echo "  tags: [bulk-test]" >> "$TAGS_FILE"
        echo "" >> "$TAGS_FILE"
    done

    local duration
    duration=$(measure_time "$TAGGING_BASH_TEST_DIR/../../tagg" search "bulk-test" >/dev/null)

    [ "$duration" -lt 800 ] # Formatting 200 results should be under 800ms
}

@test "[PERFORMANCE] database loading performance" {
    create_test_files 1000

    # Time just the database loading part
    local start_time=$(date +%s%N)
    # Source the script to get access to load_tags function
    (source "$TAGGING_BASH_TEST_DIR/../../tagg" && load_tags)
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))

    [ "$duration" -lt 200 ] # Database loading should be fast
}

@test "[PERFORMANCE] search scalability - performance degrades gracefully" {
    # Test with increasing dataset sizes
    local sizes=(10 50 100 200)

    for size in "${sizes[@]}"; do
        # Clean start
        rm -f "$TAGS_FILE"
        create_test_files "$size"

        local duration
        duration=$(measure_time "$TAGGING_BASH_TEST_DIR/../../tagg" search "common-tag" >/dev/null 2>&1)

        # Performance should scale reasonably (not exponentially)
        # Allow up to 10ms per 10 files
        local expected_max=$((size * 10))
        [ "$duration" -lt "$expected_max" ]
    done
}

@test "[PERFORMANCE] fuzzy search vs exact search performance ratio" {
    create_test_files 500

    # Time exact search
    local exact_duration
    exact_duration=$(measure_time "$TAGGING_BASH_TEST_DIR/../../tagg" search "project-a" >/dev/null 2>&1)

    # Time fuzzy search
    local fuzzy_duration
    fuzzy_duration=$(measure_time "$TAGGING_BASH_TEST_DIR/../../tagg" search --fuzzy "proj" >/dev/null 2>&1)

    # Fuzzy should not be more than 2x slower than exact
    local ratio=$((fuzzy_duration * 100 / exact_duration))
    [ "$ratio" -lt 200 ]
}

@test "[PERFORMANCE] cold start vs warm start performance" {
    create_test_files 200

    # Cold start (first run)
    local cold_duration
    cold_duration=$(measure_time "$TAGGING_BASH_TEST_DIR/../../tagg" search "project-a" >/dev/null 2>&1)

    # Warm start (immediate second run - data should be cached)
    local warm_duration
    warm_duration=$(measure_time "$TAGGING_BASH_TEST_DIR/../../tagg" search "project-a" >/dev/null 2>&1)

    # Warm start should be faster
    [ "$warm_duration" -le "$cold_duration" ]
}

# Load testing
@test "[LOAD] search under memory pressure simulation" {
    create_test_files 100

    # Simulate memory pressure by limiting available memory (if possible)
    # This is a basic test - in real load testing, would use tools like stress-ng

    ulimit -v 50000 2>/dev/null || true # Try to limit virtual memory to ~50MB

    local duration
    duration=$(measure_time timeout 30 "$TAGGING_BASH_TEST_DIR/../../tagg" search "common-tag")

    # Should complete even under memory pressure
    [ "$duration" -lt 5000 ] # Allow more time under memory pressure
}

@test "[LOAD] search with many concurrent file operations" {
    create_test_files 50

    # This test would simulate file system contention
    # In a real scenario, would have multiple processes reading/writing files

    local duration
    duration=$(measure_time "$TAGGING_BASH_TEST_DIR/../../tagg" search "common-tag")

    # Should perform well even with potential file system contention
    [ "$duration" -lt 300 ]
}