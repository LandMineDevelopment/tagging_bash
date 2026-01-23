# Epic 2 Search Features Test Suite

This directory contains comprehensive test automation for all Epic 2 features of the tagging_bash project. Epic 2 focuses on file discovery and search capabilities.

## Overview

Epic 2 implements powerful search functionality including:
- **Search functionality**: Exact tag matching to find files
- **Fuzzy search**: Substring matching for flexible discovery
- **Directory filtering**: Limit searches to specific directories
- **Multi-tag search**: Find files with multiple tags (AND logic)
- **Progress indicators**: Show progress for long-running searches
- **Related tag suggestions**: Suggest related tags during search
- **Tab completion**: Intelligent completion for commands, tags, and paths

## Test Structure

```
tests/
├── run_epic2_tests.sh          # Main test runner script
├── test_framework.sh           # Core test framework utilities
├── unit/
│   └── test_search_unit.sh     # Unit tests for search functions
├── integration/
│   ├── test_epic2_search.sh    # Integration tests for search CLI
│   └── test_tab_completion.sh  # Tab completion tests
├── performance/
│   └── test_search_performance.sh # Performance and load tests
└── helpers/                    # Test helper utilities
```

## Test Levels

### Unit Tests (`test_search_unit.sh`)
- Test individual search functions and algorithms
- Validate argument parsing logic
- Test search matching algorithms (exact vs fuzzy)
- Edge cases for tag validation and result formatting
- Directory filtering logic

### Integration Tests (`test_epic2_search.sh`)
- End-to-end CLI command testing
- File system interactions
- Database operations
- Error condition handling
- Real-world usage scenarios

### Performance Tests (`test_search_performance.sh`)
- Response time validation (< 500ms for searches)
- Scalability testing with large datasets
- Memory usage monitoring
- Concurrent operation handling
- Load testing under memory pressure

### Tab Completion Tests (`test_tab_completion.sh`)
- Command completion validation
- Tag completion from existing database
- Directory path completion
- Fuzzy search completion
- Performance of completion operations

## Running Tests

### Run All Tests
```bash
cd tagging_bash/tests
./run_epic2_tests.sh
```

### Run Specific Test Types
```bash
# Unit tests only
./run_epic2_tests.sh unit

# Integration tests only
./run_epic2_tests.sh integration

# Performance tests only
./run_epic2_tests.sh performance

# Multiple test types
./run_epic2_tests.sh unit integration
```

### Skip Slow Tests
```bash
# Skip performance tests (which can be slow)
./run_epic2_tests.sh --no-performance

# Skip tab completion tests
./run_epic2_tests.sh --no-completion
```

### Verbose Output
```bash
./run_epic2_tests.sh -v
```

## Test Framework

The test suite uses a custom bash-based test framework (`test_framework.sh`) that provides:

- **Assertions**: `assert_equals`, `assert_true`, `assert_false`
- **Test organization**: `describe` blocks and test functions
- **Setup/teardown**: `setup()` and `teardown()` functions
- **Colored output**: Pass/fail indicators with colors
- **Timing**: Performance measurement utilities

### Writing New Tests

```bash
@test "[UNIT] my new test" {
    # Setup
    setup_test_data

    # Exercise
    result=$(some_function "input")

    # Verify
    assert_equals "$result" "expected_output"

    # Cleanup
    teardown_test_data
}
```

## Performance Requirements

The tests validate that Epic 2 meets these performance targets:

- **Local operations**: < 100ms response time
- **Search operations**: < 500ms for datasets up to 10,000 files
- **Tab completion**: < 50ms (instant response)
- **Large searches**: Progress indicators for operations > 1 second
- **Memory usage**: No significant leaks or excessive consumption

## Coverage Areas

### Functional Coverage
- ✅ Exact tag search (`tagg search tag1`)
- ✅ Fuzzy search (`tagg search --fuzzy tag`)
- ✅ Directory filtering (`tagg search tag --dir /path`)
- ✅ Multi-tag AND logic (`tagg search tag1 tag2`)
- ✅ Progress indicators for large searches
- ✅ Related tag suggestions in results
- ✅ Tab completion for all commands and arguments

### Edge Cases
- Empty tag databases
- Files with no tags
- Special characters in tags (underscores, hyphens, dots)
- Unicode characters in file names and tags
- Very long tag names
- Concurrent file system operations
- File permission issues
- Corrupted database files

### Error Conditions
- Invalid tag names
- Non-existent directories
- Database read/write errors
- Insufficient permissions
- Malformed input

## Test Data

Tests use temporary directories and files created during test execution:
- Test files with various tag combinations
- Hierarchical directory structures
- Files with special characters and unicode
- Large datasets for performance testing

## Integration with CI/CD

The test suite is designed to work in CI/CD pipelines:

```yaml
# Example GitHub Actions step
- name: Run Epic 2 Tests
  run: |
    cd tagging_bash/tests
    ./run_epic2_tests.sh --no-performance  # Skip slow perf tests in CI
```

## Troubleshooting

### Common Issues

**Tests fail with "command not found"**
- Ensure the main `tagg` script is executable: `chmod +x tagg`
- Check that the script is in the correct location

**Performance tests are slow**
- Performance tests create large test datasets
- Use `--no-performance` flag for faster runs
- Ensure sufficient disk space for test files

**Tab completion tests fail**
- Ensure `completion.bash` is present and sourced
- Check that bash completion is available in the environment

**Permission denied errors**
- Tests create temporary files in `/tmp`
- Ensure write permissions to `/tmp`
- Check for restrictive umask settings

### Debug Mode

Enable debug output:
```bash
DEBUG=1 ./run_epic2_tests.sh
```

### Manual Test Execution

Run individual test files directly:
```bash
bash tests/unit/test_search_unit.sh
bash tests/integration/test_epic2_search.sh
```

## Contributing

When adding new tests:

1. Follow the existing naming conventions
2. Add appropriate test categorization ([UNIT], [INTEGRATION], etc.)
3. Include edge cases and error conditions
4. Update this README if adding new test types
5. Ensure tests clean up after themselves

## Related Documentation

- `../../README.md` - Main project documentation
- `../../epics.md` - Epic definitions and acceptance criteria
- `test_framework.sh` - Test framework documentation
- `../../completion.bash` - Tab completion implementation