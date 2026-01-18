#!/usr/bin/env bats

setup() {
    source /workspace/test/helpers/test_setup.bash
    setup_test_dir
    setup_sample_tags
}

teardown() {
    teardown_test_dir
}

@test "Search finds files with exact tag match" {
    run ./tagger.sh search urgent
    [[ "$output" =~ "file1.txt" ]]
}

@test "Search finds files with partial tag match" {
    run ./tagger.sh search proj
    [[ "$output" =~ "file1.txt" ]]
}

@test "Search finds multiple files" {
    run ./tagger.sh search important
    [[ "$output" =~ "file2.md" ]]
}

@test "Search with no matches" {
    run ./tagger.sh search nonexistent
    [[ "$output" =~ "No matches found" ]]
}

@test "Search with query too short" {
    run ./tagger.sh search a
    [[ "$output" =~ "too short" ]]
}

@test "Search case insensitive" {
    run ./tagger.sh search URGENT
    [[ "$output" =~ "file1.txt" ]]
}

@test "Search with hierarchical tags" {
    run ./tagger.sh search fix
    [[ "$output" =~ "file3.py" ]]
}

@test "Search with separator in query" {
    run ./tagger.sh search project/alpha
    [[ "$output" =~ "file1.txt" ]]
}
