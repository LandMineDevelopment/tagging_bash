#!/usr/bin/env bats

setup() {
    source /workspace/test/helpers/test_setup.bash
    setup_test_dir
    setup_sample_tags
}

teardown() {
    teardown_test_dir
}

@test "List tags for specific file" {
    run ./tagger.sh list file1.txt
    [[ "$output" =~ "urgent" ]]
    [[ "$output" =~ "project/alpha" ]]
}

@test "List files for specific tag" {
    run ./tagger.sh list --tag urgent
    [[ "$output" =~ "file1.txt" ]]
}

@test "List all tags" {
    run ./tagger.sh list --all-tags
    [[ "$output" =~ "urgent" ]]
    [[ "$output" =~ "project/alpha" ]]
    [[ "$output" =~ "important" ]]
    [[ "$output" =~ "docs" ]]
    [[ "$output" =~ "bug" ]]
    [[ "$output" =~ "fix/urgent" ]]
}

@test "List all files with tags" {
    run ./tagger.sh list --all
    [[ "$output" =~ "file1.txt:" ]]
    [[ "$output" =~ "file2.md:" ]]
    [[ "$output" =~ "file3.py:" ]]
    [[ "$output" =~ "urgent" ]]
    [[ "$output" =~ "important" ]]
}

@test "List non-existent file" {
    run ./tagger.sh list nonexistent.txt
    [[ "$output" =~ "No tags found" ]]
}

@test "List files for non-existent tag" {
    run ./tagger.sh list --tag nonexistent
    [[ "$output" =~ "No files found" ]]
}
