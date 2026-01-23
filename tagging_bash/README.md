# tagging_bash

A powerful, bash-native file tagging system for universal file organization across all directories. Provides instant file discovery, programmatic integration, and frictionless tagging with markdown-based storage for version control compatibility.

## Features

- **Universal File Tagging**: Tag any file in any directory
- **Instant File Discovery**: Find files by tags in milliseconds
- **Advanced Search**: Exact matching, multiple tags, directory filtering
- **Bash-Native**: Single script with no external dependencies
- **Version Control Friendly**: Markdown storage format
- **Intelligent Tab Completion**: Context-aware completion for commands, files, and tags
- **Bulk Operations**: Tag multiple files with patterns and wildcards
- **Atomic Operations**: Data integrity with file locking
- **Cross-Platform**: Works on Linux, macOS, and WSL
- **Self-Contained Installation**: Everything in user directory, clean uninstall

## Installation

### Quick Install
```bash
git clone <repository>
cd tagging_bash
./tagg install
```

This installs the tool to `~/.tagging_bash/bin/tagg`, sets up tab completion, and optionally adds the tool to your PATH permanently.

### What Install Does
- Creates `~/.tagging_bash/` directory structure
- Copies executable to `~/.tagging_bash/bin/tagg`
- Sets up tab completion in `~/.tagging_bash/completion.bash`
- Optionally modifies `~/.bashrc` for PATH and completion
- Initializes tag database in `~/.tagging_bash/tags.md`

### Manual PATH Setup
If you declined PATH setup during install:
```bash
export PATH="$PATH:~/.tagging_bash/bin"
# Or add to ~/.bashrc permanently
echo 'export PATH="$PATH:~/.tagging_bash/bin"' >> ~/.bashrc
```

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

#### Search Files by Tags
```bash
# Find files with specific tag
tagg search important

# Search for files with multiple tags (AND logic)
tagg search python utility

# Search within specific directory
tagg search project-a --dir /home/user/docs
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
- Commands (add, remove, edit, list, search)
- File paths
- Existing tags (context-aware)

Completion is automatically set up during installation. If needed manually:
```bash
source ~/.tagging_bash/completion.bash
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
# Tag validation settings
# TAG_SEPARATOR="."  # Reserved for future hierarchical tags

# Database settings
# Database validation and integrity checks are automatic
```

## Requirements

- Bash 4.0+ (for associative arrays)
- Standard Unix tools (sed, grep, find)
- File locking support (flock)

## Architecture

- **Storage**: Markdown files in `~/.tagging_bash/tags.md`
- **Format**: `# /path/to/file` followed by `- tag` entries per line
- **Performance**: In-memory hash maps for instant lookups and searches
- **Concurrency**: File locking (flock) prevents data corruption
- **Atomicity**: Temporary files ensure crash-safe operations
- **Self-Contained**: All files in user directory, no system modifications

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

# Search for files with specific tags
tagg search python  # Shows files tagged with 'python'
tagg search utility important  # Shows files with both tags

# List tags for specific file
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

# Advanced search
tagg search python --dir src/  # Search in specific directory
tagg search important urgent   # Files with multiple tags

# Error handling
tagg add nonexistent.txt tag   # Error: File does not exist
tagg add file.txt invalid@tag  # Error: Invalid tag name
tagg search nonexistent-tag    # Shows no matches found
```

## Testing

Run the comprehensive test suite:
```bash
cd tagging_bash
./tests/run_tests.sh
```

Tests include:
- **Unit Tests**: Tag validation, utility functions (4 tests)
- **Integration Tests**: All commands (add, remove, edit, list, search) (18 tests)
- **Performance Tests**: Timing and load validation (3 tests)
- **Total**: 27 automated tests with proper isolation and cleanup

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
- Completion is set up automatically during install
- If issues: `source ~/.tagging_bash/completion.bash`
- Restart your shell session

### Performance Tips

- Keep tag names short and descriptive
- Use consistent tagging conventions
- For large codebases, consider hierarchical tags (e.g., `component.subcomponent`)

## Changelog

### v0.1.0
- **Epic 1 Complete:** Core file tagging functionality
  - Add, remove, edit, and list commands
  - Tag validation and duplicate prevention
  - Bulk operations with file patterns
  - Comprehensive error handling
  - Atomic operations with file locking
  - Markdown storage format

- **Epic 2 Complete:** File discovery and search
  - Search files by exact tag matching
  - Multiple tag search with AND logic
  - Directory-scoped search filtering
  - Fast search performance (<500ms)
  - Rich search result formatting
  - Related tag suggestions during search

- **Infrastructure:**
  - Self-contained installation in user directory
  - Intelligent tab completion for all commands
  - Comprehensive test suite (27 tests)
  - Automatic install/uninstall with user consent
  - Cross-platform bash compatibility