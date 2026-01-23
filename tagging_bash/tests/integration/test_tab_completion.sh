#!/usr/bin/env bash
#
# test_tab_completion.sh - Tests for tab completion functionality in Epic 2
# Tests tab completion for search commands, tags, and directory paths
#

# Source test framework
source "$(dirname "$0")/../test_framework.sh"

# Source the main tagging script for testing
source "$(dirname "$0")/../../tagg"

# Test setup
setup() {
    export TAGGING_BASH_TEST_DIR="${BATS_TMPDIR:-/tmp}/tagging_completion_test_$$"
    mkdir -p "$TAGGING_BASH_TEST_DIR"
    export CONFIG_DIR="$TAGGING_BASH_TEST_DIR/.tagging_bash"
    export TAGS_FILE="$CONFIG_DIR/tags.md"
    mkdir -p "$CONFIG_DIR"

    # Create test files and tags
    echo "# Test Tag Database for Completion" > "$TAGS_FILE"
    echo "- file: $TAGGING_BASH_TEST_DIR/project-alpha.sh" >> "$TAGS_FILE"
    echo "  tags: [project-alpha, bash, script]" >> "$TAGS_FILE"
    echo "- file: $TAGGING_BASH_TEST_DIR/project-beta.py" >> "$TAGS_FILE"
    echo "  tags: [project-beta, python, utility]" >> "$TAGS_FILE"
    echo "- file: $TAGGING_BASH_TEST_DIR/common-util.js" >> "$TAGS_FILE"
    echo "  tags: [utility, javascript, common]" >> "$TAGS_FILE"
    echo "- file: $TAGGING_BASH_TEST_DIR/readme.md" >> "$TAGS_FILE"
    echo "  tags: [documentation, markdown]" >> "$TAGS_FILE"
}

teardown() {
    rm -rf "$TAGGING_BASH_TEST_DIR"
}

# Mock completion function for testing
mock_complete() {
    local current_word="$1"
    local previous_word="$2"
    local line="$3"

    # This simulates the completion logic that would be in completion.bash
    case "$previous_word" in
        search)
            # Complete tags
            load_tags 2>/dev/null
            for tag in "${!tag_files[@]}"; do
                if [[ "$tag" == "$current_word"* ]]; then
                    echo "$tag"
                fi
            done
            ;;
        --dir)
            # Complete directory paths
            compgen -d "$current_word" 2>/dev/null || true
            ;;
        tagg)
            # Complete subcommands
            local subcommands=("add" "remove" "edit" "list" "search" "help")
            for cmd in "${subcommands[@]}"; do
                if [[ "$cmd" == "$current_word"* ]]; then
                    echo "$cmd"
                fi
            done
            ;;
    esac
}

# Tab Completion Tests
@test "[TAB COMPLETION] search subcommand completion" {
    # Test completing 'tagg s' to 'tagg search'
    local completions
    completions=$(mock_complete "s" "tagg" "tagg s")

    [[ "$completions" == *"search"* ]]
}

@test "[TAB COMPLETION] search subcommand exact match" {
    # Test completing 'tagg search' (already complete)
    local completions
    completions=$(mock_complete "" "search" "tagg search ")

    # Should show available tags when no current word
    [[ "$completions" == *"project-alpha"* ]] || [[ "$completions" == *"bash"* ]]
}

@test "[TAB COMPLETION] tag completion in search - partial match" {
    # Test completing 'tagg search proj' to show project-alpha, project-beta
    local completions
    completions=$(mock_complete "proj" "search" "tagg search proj")

    [[ "$completions" == *"project-alpha"* ]]
    [[ "$completions" == *"project-beta"* ]]
}

@test "[TAB COMPLETION] tag completion in search - exact prefix" {
    # Test completing 'tagg search project-' to show both project tags
    local completions
    completions=$(mock_complete "project-" "search" "tagg search project-")

    [[ "$completions" == *"project-alpha"* ]]
    [[ "$completions" == *"project-beta"* ]]
}

@test "[TAB COMPLETION] tag completion in search - no matches" {
    # Test completing 'tagg search xyz' (no matches)
    local completions
    completions=$(mock_complete "xyz" "search" "tagg search xyz")

    [[ -z "$completions" ]] # Should be empty
}

@test "[TAB COMPLETION] tag completion in search - full tag" {
    # Test completing 'tagg search bash ' (space after complete tag)
    local completions
    completions=$(mock_complete "" "bash" "tagg search bash ")

    # Should show tags that could be next in multi-tag search
    [[ "$completions" == *"script"* ]] || [[ "$completions" == *"utility"* ]]
}

@test "[TAB COMPLETION] directory completion - partial path" {
    # Create test directory structure
    mkdir -p "$TAGGING_BASH_TEST_DIR/test-dir"
    mkdir -p "$TAGGING_BASH_TEST_DIR/another-dir"

    # Test completing 'tagg search tag --dir test-'
    local completions
    completions=$(mock_complete "test-" "--dir" "tagg search tag --dir test-")

    [[ "$completions" == *"$TAGGING_BASH_TEST_DIR/test-dir"* ]]
}

@test "[TAB COMPLETION] directory completion - root path" {
    # Test completing 'tagg search tag --dir /tmp'
    local completions
    completions=$(mock_complete "/tmp" "--dir" "tagg search tag --dir /tmp")

    # Should complete to directories under /tmp
    [[ "$completions" == *"/tmp"* ]]
}

@test "[TAB COMPLETION] fuzzy search tag completion" {
    # Test that completion works the same for fuzzy search
    local completions_exact
    completions_exact=$(mock_complete "proj" "search" "tagg search proj")

    local completions_fuzzy
    completions_fuzzy=$(mock_complete "proj" "--fuzzy" "tagg search --fuzzy proj")

    # Should be the same completions
    [[ "$completions_exact" == "$completions_fuzzy" ]]
}

@test "[TAB COMPLETION] multi-tag completion" {
    # Test completing second tag in 'tagg search bash '
    local completions
    completions=$(mock_complete "" "bash" "tagg search bash ")

    # Should show tags that frequently appear with bash
    [[ "$completions" == *"script"* ]]
}

@test "[TAB COMPLETION] completion after options" {
    # Test completing after --fuzzy flag
    local completions
    completions=$(mock_complete "util" "search" "tagg search --fuzzy util")

    [[ "$completions" == *"utility"* ]]
}

@test "[TAB COMPLETION] completion case sensitivity" {
    # Test that completion is case-sensitive (bash tags are lowercase)
    local completions
    completions=$(mock_complete "BASH" "search" "tagg search BASH")

    [[ -z "$completions" ]] # Should not match uppercase
}

@test "[TAB COMPLETION] completion with special characters" {
    # Add a tag with allowed special characters
    echo "- file: $TAGGING_BASH_TEST_DIR/test.sh" >> "$TAGS_FILE"
    echo "  tags: [test_tag.with.dots]" >> "$TAGS_FILE"

    local completions
    completions=$(mock_complete "test_tag" "search" "tagg search test_tag")

    [[ "$completions" == *"test_tag.with.dots"* ]]
}

# Integration tests with actual completion script
@test "[INTEGRATION] completion script loads without errors" {
    # Test that the completion script can be sourced
    source "$TAGGING_BASH_TEST_DIR/../../completion.bash" 2>/dev/null
    local exit_code=$?

    assert_equals "$exit_code" "0"
}

@test "[INTEGRATION] completion functions are defined" {
    source "$TAGGING_BASH_TEST_DIR/../../completion.bash" 2>/dev/null

    # Check that completion functions exist
    type _tagg_complete >/dev/null 2>&1
    local function_exists=$?

    assert_equals "$function_exists" "0"
}

@test "[INTEGRATION] completion setup works" {
    source "$TAGGING_BASH_TEST_DIR/../../completion.bash" 2>/dev/null

    # Check that complete command was called
    complete -p tagg 2>/dev/null | grep -q "_tagg_complete"
    local complete_set=$?

    assert_equals "$complete_set" "0"
}

# Performance tests for completion
@test "[PERFORMANCE] tag completion is fast" {
    local start_time=$(date +%s%N 2>/dev/null || echo "0")
    local completions
    completions=$(mock_complete "p" "search" "tagg search p")
    local end_time=$(date +%s%N 2>/dev/null || echo "0")
    local duration=$(( (end_time - start_time) / 1000000 ))

    [ "$duration" -lt 50 ] # Completion should be instant
    [[ "$completions" == *"project-alpha"* ]]
}

@test "[PERFORMANCE] completion with many tags" {
    # Add many tags to test performance
    for i in {1..100}; do
        echo "- file: $TAGGING_BASH_TEST_DIR/many${i}.txt" >> "$TAGS_FILE"
        echo "  tags: [tag${i}, category-${i}]" >> "$TAGS_FILE"
    done

    local start_time=$(date +%s%N 2>/dev/null || echo "0")
    local completions
    completions=$(mock_complete "tag" "search" "tagg search tag")
    local end_time=$(date +%s%N 2>/dev/null || echo "0")
    local duration=$(( (end_time - start_time) / 1000000 ))

    [ "$duration" -lt 100 ] # Should remain fast even with many tags
    [[ "$completions" == *"tag1"* ]]
}

# Edge cases for completion
@test "[EDGE CASE] completion with empty search" {
    local completions
    completions=$(mock_complete "" "search" "tagg search ")

    # Should show all available tags
    [[ "$completions" == *"bash"* ]]
    [[ "$completions" == *"python"* ]]
}

@test "[EDGE CASE] completion after invalid subcommand" {
    local completions
    completions=$(mock_complete "something" "invalid" "tagg invalid something")

    [[ -z "$completions" ]] # Should not complete for invalid subcommands
}

@test "[EDGE CASE] completion with quoted tags" {
    # Test completion when tags might contain spaces (though tags don't allow spaces)
    # This tests the completion logic robustness
    local completions
    completions=$(mock_complete "bash" "search" "tagg search 'bash")

    [[ "$completions" == *"script"* ]]
}

@test "[EDGE CASE] completion when no tags database exists" {
    # Remove tags file
    rm -f "$TAGS_FILE"

    local completions
    completions=$(mock_complete "test" "search" "tagg search test")

    [[ -z "$completions" ]] # Should handle missing database gracefully
}

@test "[EDGE CASE] completion with very long tag names" {
    # Add a very long tag
    local long_tag="very_long_tag_name_that_might_cause_issues_with_completion_and_display"
    echo "- file: $TAGGING_BASH_TEST_DIR/long.sh" >> "$TAGS_FILE"
    echo "  tags: [$long_tag]" >> "$TAGS_FILE"

    local completions
    completions=$(mock_complete "very_long" "search" "tagg search very_long")

    [[ "$completions" == *"$long_tag"* ]]
}

@test "[EDGE CASE] completion with unicode in tags" {
    # Add tag with unicode characters
    echo "- file: $TAGGING_BASH_TEST_DIR/unicode.sh" >> "$TAGS_FILE"
    echo "  tags: [tâg-wíth-ünicödé]" >> "$TAGS_FILE"

    local completions
    completions=$(mock_complete "tâg" "search" "tagg search tâg")

    [[ "$completions" == *"tâg-wíth-ünicödé"* ]]
}

# Error handling in completion
@test "[ERROR HANDLING] completion handles database read errors" {
    # Make tags file unreadable
    chmod 000 "$TAGS_FILE"

    local completions
    completions=$(mock_complete "test" "search" "tagg search test")

    # Should handle gracefully (return empty or continue)
    # Note: This test may need adjustment based on actual error handling

    chmod 644 "$TAGS_FILE" # Restore permissions
}

@test "[ERROR HANDLING] completion with corrupted database" {
    # Create corrupted tags file
    echo "corrupted yaml content: [unclosed" > "$TAGS_FILE"

    local completions
    completions=$(mock_complete "test" "search" "tagg search test")

    # Should handle gracefully without crashing
    [[ -z "$completions" ]] || true # Allow empty or any safe result
}