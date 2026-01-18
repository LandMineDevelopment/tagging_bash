#!/usr/bin/env bats

setup() {
    # Source the tagger script to access functions
    source /workspace/tagger.sh
}

@test "normalize_tag converts to lowercase" {
    run normalize_tag "TAG"
    [ "$status" -eq 0 ]
    [ "$output" = "tag" ]
}

@test "normalize_tag handles mixed case" {
    run normalize_tag "ProJect/AlPhA"
    [ "$status" -eq 0 ]
    [ "$output" = "project/alpha" ]
}

@test "normalize_tag removes invalid characters" {
    run normalize_tag "tag@#$%^&*()"
    [ "$status" -eq 0 ]
    [ "$output" = "tag" ]
}

@test "normalize_tag preserves valid separator" {
    run normalize_tag "project/urgent"
    [ "$status" -eq 0 ]
    [ "$output" = "project/urgent" ]
}

@test "normalize_tag handles empty string" {
    run normalize_tag ""
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "normalize_tag rejects directory traversal" {
    run normalize_tag "../../../etc/passwd"
    [ "$status" -eq 1 ]
}

@test "normalize_tag handles dots in valid context" {
    run normalize_tag "urgent.high"
    [ "$status" -eq 0 ]
    [ "$output" = "urgent.high" ]
}

@test "normalize_tag removes spaces" {
    run normalize_tag "tag with spaces"
    [ "$status" -eq 0 ]
    [ "$output" = "tagwithspaces" ]
}

@test "normalize_tag handles underscores" {
    run normalize_tag "my_tag"
    [ "$status" -eq 0 ]
    [ "$output" = "my_tag" ]
}

@test "normalize_tag handles numbers" {
    run normalize_tag "tag123"
    [ "$status" -eq 0 ]
    [ "$output" = "tag123" ]
}
