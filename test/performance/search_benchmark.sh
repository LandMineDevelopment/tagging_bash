#!/bin/bash
# Performance test for search functionality

source /workspace/test/helpers/test_setup.bash

echo "Setting up performance test environment..."
setup_test_dir

# Create many files and tags for performance testing
echo "Creating test data..."
for i in {1..100}; do
    touch "file$i.txt"
    ./tagger.sh add "file$i.txt" "tag$i" "common" >/dev/null 2>&1
done

echo "Running search performance tests..."

# Test 1: Search for common tag
start_time=$(date +%s.%3N)
./tagger.sh search common >/dev/null 2>&1
end_time=$(date +%s.%3N)
duration=$(echo "$end_time - $start_time" | bc)
echo "Search 'common' (should find all files): ${duration}s"

# Test 2: Search for unique tag
start_time=$(date +%s.%3N)
./tagger.sh search tag50 >/dev/null 2>&1
end_time=$(date +%s.%3N)
duration=$(echo "$end_time - $start_time" | bc)
echo "Search 'tag50' (should find 1 file): ${duration}s"

# Test 3: Search for non-existent tag
start_time=$(date +%s.%3N)
./tagger.sh search nonexistent >/dev/null 2>&1
end_time=$(date +%s.%3N)
duration=$(echo "$end_time - $start_time" | bc)
echo "Search 'nonexistent' (should find 0 files): ${duration}s"

# Test 4: Add operation performance
start_time=$(date +%s.%3N)
./tagger.sh add newfile.txt perf_test >/dev/null 2>&1
end_time=$(date +%s.%3N)
duration=$(echo "$end_time - $start_time" | bc)
echo "Add operation: ${duration}s"

# Test 5: List all operation
start_time=$(date +%s.%3N)
./tagger.sh list --all >/dev/null 2>&1
end_time=$(date +%s.%3N)
duration=$(echo "$end_time - $start_time" | bc)
echo "List all operation: ${duration}s"

echo "Performance tests completed."
teardown_test_dir
