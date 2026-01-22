# tagging_bash

A powerful, bash-native file tagging system for universal file organization across all directories. Provides instant file discovery, programmatic integration, and frictionless tagging with markdown-based storage for version control compatibility.

## Features

- **Universal File Tagging**: Tag any file in any directory
- **Instant Search**: Find files by tags in milliseconds
- **Bash-Native**: Single script with no external dependencies
- **Version Control Friendly**: Markdown storage format
- **Tab Completion**: Intelligent completion for commands, files, and tags
- **Bulk Operations**: Tag multiple files with patterns
- **Atomic Operations**: Data integrity with file locking
- **Cross-Platform**: Works on Linux, macOS, and WSL

## Installation

### Quick Install
```bash
git clone <repository>
cd tagging_bash
./tagg install
```

This creates the configuration directory `~/.tagging_bash` and initializes the tag database.

### Manual Install
1. Copy `tagg` script to your PATH (e.g., `/usr/local/bin/`)
2. Run `tagg install` to set up configuration
3. Optional: Set up tab completion by sourcing `completion.bash`

## Usage

### Basic Commands

#### Add Tags to Files
```bash
# Tag a single file
tagg add script.sh bash utility

# Tag multiple files
tagg add *.txt documentation

# Tag with file patterns
tagg add *.py python
```

#### Remove Tags from Files
```bash
# Remove specific tag from file
tagg remove script.sh utility

# Remove tags from multiple files
tagg remove *.txt old-tag
```

#### Edit Tags on Files
```bash
# Replace old tag with new tag
tagg edit script.sh old-tag new-tag

# Edit tags on multiple files
tagg edit *.py deprecated current
```

#### List Tags and Files
```bash
# Show all tags globally
tagg list

# Show tags for specific file
tagg list script.sh
```

### Advanced Usage

#### Bulk Operations
```bash
# Add tags to all Python files
tagg add *.py python

# Remove tags from files in subdirectory
tagg remove subdir/* temp

# Edit tags with file type patterns
tagg edit *.md draft published
```

#### Tab Completion
The tool supports intelligent tab completion for:
- Commands (add, remove, edit, list)
- File paths
- Existing tags (context-aware)

To enable completion:
```bash
source ~/.local/share/bash-completion/completions/tagg
```

#### Error Handling
All commands provide clear error messages:
- Invalid tag names
- Non-existent files
- Permission issues
- Database corruption

### Configuration

Configuration is stored in `~/.tagging_bash/config.sh`:
```bash
# Tag separator (default: ".")
TAG_SEPARATOR="."

# Fuzzy search threshold (default: 0.8)
FUZZY_THRESHOLD=0.8
```

## Requirements

- Bash 4.0+ (for associative arrays)
- Standard Unix tools (sed, grep, find)
- File locking support (flock)

## Architecture

- **Storage**: Markdown files in `~/.tagging_bash/tags.md`
- **Format**: `# /path/to/file` followed by `- tag` entries
- **Performance**: In-memory hash maps for instant lookups
- **Concurrency**: File locking prevents data corruption
- **Atomicity**: Temporary files ensure crash-safe operations

## Examples

### Basic Workflow
```bash
# Install and set up
tagg install

# Tag some files
tagg add important.txt priority high
tagg add script.sh bash utility
tagg add data.csv python analysis

# Find files by tag
tagg list  # Shows all tags: priority, high, bash, utility, python, analysis

# Search for Python files
tagg list script.sh  # Shows: bash, utility
```

### Advanced Scenarios
```bash
# Bulk tagging
tagg add *.py python
tagg add tests/*.sh bash test

# Tag management
tagg edit old_script.sh deprecated archived
tagg remove *.tmp temp

# Error handling
tagg add nonexistent.txt tag  # Error: File does not exist
tagg add file.txt invalid@tag  # Error: Invalid tag name
```

## Testing

Run the comprehensive test suite:
```bash
cd tagging_bash
./tests/run_tests.sh
```

Tests include:
- Unit tests for validation functions
- Integration tests for all commands
- Performance tests for timing requirements

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is open source. See LICENSE file for details.

## Troubleshooting

### Common Issues

**"Command not found"**
- Ensure `tagg` is in your PATH
- Run `tagg install` to set up configuration

**"Permission denied"**
- Check file permissions on target files
- Ensure write access to `~/.tagging_bash`

**"Database integrity error"**
- The tag database may be corrupted
- Run `tagg install` to recreate configuration

**Tab completion not working**
- Source the completion script: `source ~/.local/share/bash-completion/completions/tagg`
- Restart your shell session

### Performance Tips

- Keep tag names short and descriptive
- Use consistent tagging conventions
- For large codebases, consider hierarchical tags (e.g., `component.subcomponent`)

## Changelog

### v0.1.0
- Initial release with core tagging functionality
- Add, remove, edit, and list commands
- Tab completion support
- Bulk operations with patterns
- Comprehensive test suite
- Markdown storage format
- Atomic operations with file locking