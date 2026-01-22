#!/usr/bin/env bash
#
# Test file for tag addition parsing
#

# Source the main script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/tagg"

# Mock functions to avoid actual file operations
load_tags() {
    declare -gA file_tags=()
    declare -gA tag_files=()
    return 0
}
save_tags() { return 0; }
acquire_lock() { return 0; }
release_lock() { return 0; }

# Test cmd_add parsing with positional args
test_cmd_add_parsing() {
    local output
    output=$(cmd_add "$@" 2>&1)
    echo "$output"
}

# Test validate_tag_name
test_validate_tag_name() {
    local tag="$1"
    if validate_tag_name "$tag" 2>/dev/null; then
        echo "PASS"
    else
        echo "FAIL"
    fi
}

# Test validate_file_path
test_validate_file_path() {
    local file="$1"
    if validate_file_path "$file"; then
        echo "PASS"
    else
        echo "FAIL"
    fi
}

# Setup
echo "test" > /tmp/test.txt
echo "test" > /tmp/test2.txt

# Run tests
echo "Running parsing tests..."

# Test 1: Valid positional args (should now pass)
result=$(test_cmd_add_parsing /tmp/test.txt important project-a bash)
if [[ "$result" == *"Added tags"* ]]; then
    echo "Test 1 PASSED (positional parsing works)"
else
    echo "Test 1 FAILED: $result"
fi

# Test 2: Old --tags format (should fail now)
result=$(test_cmd_add_parsing /tmp/test.txt --tags important,project-a,bash)
if [[ "$result" == *"Usage"* || "$result" == *"Error"* ]]; then
    echo "Test 2 PASSED (old --tags rejected)"
else
    echo "Test 2 FAILED: $result"
fi

# Test 3: Adding to multiple files
result=$(test_cmd_add_parsing /tmp/test.txt /tmp/test2.txt newtag1 newtag2)
if [[ "$result" == *"Tagged 2 files with: newtag1 newtag2"* ]]; then
    echo "Test 3 PASSED (multiple files tagged)"
else
    echo "Test 3 FAILED: $result"
fi

echo "Running tag validation tests..."

# Test 3: Valid tags
for tag in "important" "project_a" "tag-1" "tag.1" "123"; do
    result=$(test_validate_tag_name "$tag")
    if [[ "$result" == "PASS" ]]; then
        echo "Tag '$tag' PASSED"
    else
        echo "Tag '$tag' FAILED"
    fi
done

# Test 4: Invalid tags
for tag in "tag with spaces" "tag@symbol" "tag,comma" "tag#hash" ""; do
    result=$(test_validate_tag_name "$tag")
    if [[ "$result" == "FAIL" ]]; then
        echo "Tag '$tag' PASSED (correctly rejected)"
    else
        echo "Tag '$tag' FAILED (should be rejected)"
    fi
done

echo "Running file validation tests..."

# Clean up any existing
rm -f /tmp/test_file.txt /tmp/test_nonexistent.txt

# Create a test file
echo "test" > /tmp/test_file.txt

# Test 5: Valid file
result=$(test_validate_file_path "/tmp/test_file.txt")
if [[ "$result" == "PASS" ]]; then
    echo "File '/tmp/test_file.txt' PASSED"
else
    echo "File '/tmp/test_file.txt' FAILED"
fi

# Test 6: Non-existent file
result=$(test_validate_file_path "/tmp/test_nonexistent.txt")
if [[ "$result" == "FAIL" ]]; then
    echo "File '/tmp/test_nonexistent.txt' PASSED (correctly rejected)"
else
    echo "File '/tmp/test_nonexistent.txt' FAILED (should be rejected)"
fi

# Clean up
rm -f /tmp/test_file.txt /tmp/test.txt /tmp/test2.txt