# Simplified Tagging System Requirements Document

## 1. Introduction

### 1.1 Purpose
This document outlines the requirements for a simplified tagging system implemented entirely in Bash. The system provides a command-line interface (CLI) for tagging files within a specified directory, storing tag metadata in a Markdown (.md) file, and performing fuzzy searches on tags. The system emphasizes simplicity, portability, and minimal dependencies while offering features like dynamic suggestions and tab completion.

### 1.2 Scope
The tagging system will allow users to:
- Associate tags (keywords) with files in a directory.
- Store tag data persistently in a single Markdown file per directory.
- Perform fuzzy searches on tags to find associated files.
- Receive dynamic suggestions for tags during input.
- Use tab completion for CLI commands and options.
- Handle first-run setup, including dependency checks and initial configuration.

Out of scope:
- Database integration (explicitly prohibited).
- Graphical user interfaces.
- Multi-user or network-based functionality.
- Support for non-file entities (e.g., URLs, notes without files).

### 1.3 Definitions
- **Tag**: A user-defined keyword (string) associated with one or more files. Tags are case-insensitive and can contain alphanumeric characters, hyphens, and underscores. Tags support hierarchy through a configurable separator character (e.g., "/" for "project/subproject" or "." for "urgent.high"), allowing nested categorization. The separator is managed by the user via a configuration file (e.g., `.tagconfig` or global config), enabling flexible organization without enforcing a specific format. Implications include storage as plain strings (with potential indexing for hierarchies) and search supporting both exact matches and hierarchical queries (e.g., searching "project" matches "project/subproject").
- **Fuzzy Search**: Approximate string matching that tolerates typos or partial matches.
- **Dynamic Suggestions**: Autocomplete-like prompts for tags based on existing tags or partial input.
- **Tab Completion**: Bash completion for command-line arguments and options.
- **First-Run Setup**: Automated installation and configuration on initial use.

## 2. Functional Requirements

### 2.1 Core Functionality
1. **Tag Assignment**
   - Users can add one or more tags to a specific file using a command like `tagger add <file> <tag1> [<tag2> ...]`.
   - If the file does not exist, the operation fails with an error message.
   - Tags are stored in a hidden `.tags.md` file in the current directory.
   - The `.tags.md` file uses Markdown format with sections like:
     ```
     # Tags for Directory: /path/to/dir

     ## File: example.txt
     - tag1
     - tag2

     ## File: another.txt
     - tag1
     - tag3
     ```

2. **Tag Removal**
   - Users can remove one or more tags from a file using `tagger remove <file> <tag1> [<tag2> ...]`.
   - If a tag does not exist on the file, the operation skips it without error.
   - If all tags are removed from a file, the file's section is deleted from `.tags.md`.

3. **Tag Listing**
   - Users can list all tags for a specific file: `tagger list <file>`.
   - Users can list all files associated with a tag: `tagger list --tag <tag>`.
   - Users can list all tags in the directory: `tagger list --all-tags`.
   - Users can list all files with their tags: `tagger list --all`.

4. **Fuzzy Search**
   - Users can search for files by tag using fuzzy matching: `tagger search <query>`.
   - Uses ripgrep for fuzzy search on the `.tags.md` file.
   - Falls back to awk if ripgrep is unavailable.
   - Returns a list of files matching the fuzzy query, sorted by relevance (e.g., exact matches first).

5. **Dynamic Suggestions**
   - During tag input (e.g., in add/remove commands), provide suggestions based on existing tags.
   - Suggestions appear after partial input, showing up to 10 matching tags.
   - Users can cycle through suggestions using arrow keys or tab.

6. **Tab Completion**
   - Enable Bash tab completion for:
     - Commands (add, remove, list, search).
     - Options (--tag, --all, --all-tags).
     - File names in the current directory.
     - Existing tags for relevant commands.

7. **First-Run Setup**
   - On first execution, check for required dependencies (ripgrep, awk).
   - If missing, prompt user to install them (e.g., via package manager).
   - Create the `.tags.md` file if it does not exist.
   - Set up tab completion by sourcing a generated completion script.
   - Make the command globally accessible by offering to copy the script to `/usr/local/bin/tagger`.
   - Allow user to specify custom storage location for `.tags.md` and config files during setup (supports ~ for home directory).

### 2.2 Input/Output
- All commands output to stdout, errors to stderr.
- Output formats: Plain text for lists/searches, Markdown for exports (e.g., `tagger export` to dump `.tags.md`).
- Accept input via command-line arguments; no interactive prompts except for suggestions/setup.

### 2.3 Data Persistence
- All tag data stored in `.tags.md` in the current working directory.
- File paths are relative to the directory.
- Handle file renames/moves by updating `.tags.md` (manual command: `tagger update-path <old_path> <new_path>`).

## 3. Non-Functional Requirements

### 3.1 Performance
- Fuzzy search on directories with up to 10,000 files and 100,000 tags completes in under 5 seconds.
- Memory usage remains under 100 MB during operations.
- Startup time (including dependency checks) under 1 second.

### 3.2 Usability
- Commands follow standard CLI conventions (e.g., `--help` for usage).
- Error messages are clear and actionable.
- Tab completion and suggestions reduce typing effort by 50% for frequent users.

### 3.3 Reliability
- System handles concurrent access (e.g., multiple instances running) by locking `.tags.md` during writes.
- Graceful degradation: If ripgrep fails, fall back to awk without interrupting the user.
- Data integrity: Validate `.tags.md` on load; repair minor corruptions automatically.

### 3.4 Security
- No execution of user input as code.
- File paths validated to prevent directory traversal (e.g., no `../../../`).
- Permissions: `.tags.md` readable/writable only by the user.

### 3.5 Portability
- Compatible with Bash 4.0+ on Linux, macOS, and Windows (via WSL/Cygwin).
- No external dependencies beyond ripgrep and awk (both widely available).

### 3.6 Maintainability
- Code modularized into functions for easy updates.
- Self-documenting: Help text and comments in code.
- Version checking: Command to display version (`tagger --version`).

## 4. User Stories

### 4.1 Basic Tagging
- As a user, I want to tag a file with keywords so I can categorize it easily.
- As a user, I want to remove tags from a file if they are no longer relevant.
- As a user, I want to list all tags on a specific file to review its categories.

### 4.2 Searching and Discovery
- As a user, I want to search for files by tag using fuzzy matching so I can find items even with typos.
- As a user, I want to see all files associated with a tag to explore related content.
- As a user, I want dynamic suggestions when adding tags to avoid retyping common ones.

### 4.3 Management and Maintenance
- As a user, I want to list all unique tags in the directory to understand my tagging scheme.
- As a user, I want to update file paths in tags when files are moved.
- As a user, I want the system to set itself up on first use without manual configuration.

### 4.4 Efficiency
- As a user, I want tab completion for commands and file names to speed up interaction.
- As a user, I want fast search results even in large directories.

## 5. Edge Cases

### 5.1 File and Tag Handling
- Empty tag input: Command fails with "No tags provided."
- Duplicate tags on a file: Silently ignored (no duplicates stored).
- Non-existent file: Add/remove fails; search ignores.
- Tag with special characters: Allowed, but validated (no control characters).
- Case sensitivity: Tags are stored lowercase; searches case-insensitive.

### 5.2 Storage and Persistence
- Corrupted `.tags.md`: Attempt repair by parsing valid sections; warn user.
- Directory without `.tags.md`: Treat as empty (first add creates it).
- File with no tags: Listed in `--all` but without section.
- Concurrent writes: Use file locking; later operations wait or fail gracefully.

### 5.3 Search and Suggestions
- Fuzzy search with no matches: Return empty list.
- Suggestions for partial input: Show matches sorted alphabetically.
- Ripgrep unavailable: Fall back to awk regex matching (less fuzzy).

### 5.4 Setup and Dependencies
- Missing ripgrep: Prompt to install; proceed with awk fallback.
- Read-only directory: Setup fails; operations fail.
- Multiple directories: Each has independent `.tags.md`.

### 5.5 Error Scenarios
- Invalid command: Show usage and exit non-zero.
- File not found in list: Inform user "File has no tags."
- Search query too short: Require at least 2 characters.

## 6. Dependencies

### 6.1 Required
- Bash (version 4.0+): Core shell for execution.
- ripgrep (rg): For fuzzy search. Install via package manager (e.g., `apt install ripgrep`).
- awk: Fallback for search; included in most Unix systems.

### 6.2 Optional
- None; system degrades gracefully without ripgrep.

### 6.3 Installation Notes
- First-run setup detects and installs ripgrep if possible.
- awk is assumed present; if not, system fails with clear error.

## 7. Implementation Notes

### 7.1 Architecture
- Single Bash script (`tagger.sh`) containing all logic.
- Functions for each command (e.g., `add_tags`, `fuzzy_search`).
- Use `flock` for file locking on `.tags.md`.

### 7.2 Key Algorithms
- Fuzzy Search: Ripgrep with `--fuzzy` flag; awk uses regex with wildcards.
- Suggestions: Parse `.tags.md` for unique tags; match partial input.
- Tab Completion: Generate Bash completion script on setup; source in user's `.bashrc`.

### 7.3 Data Format
- Markdown for human readability and easy editing.
- File sections with bullet lists for tags.
- Header with directory path for context.

### 7.4 Testing Considerations
- Unit tests via Bats (Bash Automated Testing System).
- Integration tests: Simulate directory with files, add tags, search.
- Edge case tests: Corrupted files, missing dependencies.

### 7.5 Deployment
- Distribute as single script; user makes executable (`chmod +x tagger.sh`).
- Add to PATH for global use.
- Documentation: Inline `--help` and separate README.md.

### 7.6 Testing Requirements and Instructions
This section outlines the comprehensive testing strategy for the tagging system. All tests must pass before deployment. Developers should follow these instructions to set up and run tests.

#### Testing Strategy
- **Unit Testing**: Test individual functions (e.g., `normalize_tag`, `fuzzy_search`) in isolation using Bats. Cover normal cases, edge cases, and error conditions.
- **Integration Testing**: Test full workflows (e.g., add → list → search → remove) in a simulated environment. Use temporary directories and files.
- **Performance Testing**: Benchmark operations (e.g., search on 10k files under 5s) using time commands or scripts.
- **Edge Case Testing**: Test corrupted `.tags.md`, missing dependencies, concurrent access, special characters, and boundary conditions.
- **Security Testing**: Verify input sanitization, file permissions, and no injection vulnerabilities.
- **Usability Testing**: Manual testing of CLI, tab completion, and suggestions in interactive shell.

#### Tools and Setup
- **Bats**: Install via `sudo apt install bats` (Ubuntu/Debian) or `brew install bats` (macOS). Run tests with `bats test/`.
- **Test Directory Structure**:
  ```
  project/
  ├── tagger.sh
  ├── test/
  │   ├── unit/
  │   │   ├── normalize_tag.bats
  │   │   └── fuzzy_search.bats
  │   ├── integration/
  │   │   ├── add_remove.bats
  │   │   └── search_workflow.bats
  │   ├── performance/
  │   │   └── benchmark.sh
  │   └── helpers/
  │       └── test_setup.sh
  └── README.md
  ```
- **Test Helpers**: Create `test/helpers/test_setup.sh` with functions to create temp directories, add sample tags, and clean up.

#### Running Tests
1. **Prerequisites**: Ensure Bats is installed. Run in a Linux/macOS environment with bash 4.0+.
2. **Unit Tests**: `cd project && bats test/unit/`
3. **Integration Tests**: `bats test/integration/`
4. **Performance Tests**: `bash test/performance/benchmark.sh`
5. **All Tests**: `bats test/` (runs all .bats files)
6. **Continuous Integration**: Use GitHub Actions or similar to run tests on push/PR. Example workflow:
   ```yaml
   name: Test
   on: [push, pull_request]
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
       - uses: actions/checkout@v2
       - run: sudo apt update && sudo apt install -y bats ripgrep awk
       - run: bats test/
   ```
7. **Manual Testing**: For interactive features (suggestions, completion), run the script manually in a shell and verify behavior.
8. **Coverage**: Aim for 80%+ code coverage. Use `kcov` or manual checks for untested paths.

#### Test Examples
- **Unit Test Example** (in test/unit/normalize_tag.bats):
  ```bash
  @test "normalize_tag converts to lowercase" {
      run normalize_tag "TAG"
      [ "$output" = "tag" ]
  }
  ```
- **Integration Test Example** (in test/integration/add_remove.bats):
  ```bash
  setup() {
      mkdir -p /tmp/test_dir
      cd /tmp/test_dir
      # Create sample files and run setup
  }
  @test "add and remove tags workflow" {
      run tagger add file1.txt tag1 tag2
      run tagger list file1.txt
      [[ "$output" == *"tag1"* ]] && [[ "$output" == *"tag2"* ]]
      run tagger remove file1.txt tag1
      run tagger list file1.txt
      [[ "$output" != *"tag1"* ]] && [[ "$output" == *"tag2"* ]]
  }
  teardown() {
      rm -rf /tmp/test_dir
  }
  ```

#### Reporting and Fixing Failures
- Tests output pass/fail status. Fix failures immediately.
- Log errors with context (e.g., "Failed to add tag due to file lock").
- For performance failures, optimize algorithms or adjust benchmarks.

This ensures the system is reliable, secure, and performant. Developers must run tests locally before committing. If tests fail in CI, block merges.

### 7.5 Deployment
- Distribute as single script; user makes executable (`chmod +x tagger.sh`).
- Add to PATH for global use.
- Documentation: Inline `--help` and separate README.md.

This requirements document provides a comprehensive blueprint for the tagging system, ensuring all aspects are covered for successful implementation.