#!/usr/bin/env bash
#
# unit/yaml_parsing_tests.sh - Unit tests for YAML parsing functions
#

source "$(dirname "${BASH_SOURCE[0]}")/../test_framework.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../tagg"

# Test YAML parsing for simple key-value pairs
test_parse_yaml_simple() {
    # Create a temporary YAML file
    local temp_yaml=$(mktemp)
    cat > "$temp_yaml" << 'EOF'
key1: value1
key2: value2
key3: value with spaces
EOF

    # Parse YAML and capture output
    local output
    output=$(parse_yaml "$temp_yaml")

    # Check that key1=value1 is present
    assert_contains "$output" "key1=value1" "key1 should be parsed correctly"

    # Check that key2=value2 is present
    assert_contains "$output" "key2=value2" "key2 should be parsed correctly"

    # Check that key3=value with spaces is present
    assert_contains "$output" "key3=value with spaces" "key3 with spaces should be parsed correctly"

    # Clean up
    rm -f "$temp_yaml"
}

# Test YAML parsing for nested configuration sections
test_parse_yaml_nested() {
    # Create a temporary YAML file with nested structure
    local temp_yaml=$(mktemp)
    cat > "$temp_yaml" << 'EOF'
key1: value1
nested:
  key2: value2
  key3: value3
another:
  level:
    key4: value4
EOF

    # Parse YAML and capture output
    local output
    output=$(parse_yaml "$temp_yaml")

    # Check flat keys
    assert_contains "$output" "key1=value1" "key1 should be parsed correctly"

    # Check nested keys (flattened with dots)
    assert_contains "$output" "nested.key2=value2" "nested.key2 should be parsed correctly"
    assert_contains "$output" "nested.key3=value3" "nested.key3 should be parsed correctly"
    assert_contains "$output" "another.level.key4=value4" "another.level.key4 should be parsed correctly"

    # Clean up
    rm -f "$temp_yaml"
}

# Run YAML parsing tests
run_unit_yaml_tests() {
    run_test_with_isolation "parse_yaml_simple" test_parse_yaml_simple
    run_test_with_isolation "parse_yaml_nested" test_parse_yaml_nested
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_unit_yaml_tests
fi

# Export for test runner
export -f run_unit_yaml_tests