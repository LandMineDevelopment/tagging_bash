#!/usr/bin/env bats

setup() {
    # Make script executable if not already
    chmod +x /workspace/tagger.sh
}

@test "Help option displays usage information" {
    run /workspace/tagger.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Simplified Tagging System" ]]
    [[ "$output" =~ "USAGE:" ]]
    [[ "$output" =~ "COMMANDS:" ]]
}

@test "Short help option -h works" {
    run /workspace/tagger.sh -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Simplified Tagging System" ]]
}

@test "Version option displays version" {
    run /workspace/tagger.sh --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Simplified Tagging System v" ]]
}

@test "Short version option -v works" {
    run /workspace/tagger.sh -v
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Simplified Tagging System v" ]]
}

@test "No arguments shows help" {
    run /workspace/tagger.sh
    [ "$status" -eq 0 ]
    [[ "$output" =~ "USAGE:" ]]
}

@test "Unknown command shows appropriate error" {
    run bash -c "echo 'n' | /workspace/tagger.sh nonexistent"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown command 'nonexistent'" ]]
    [[ "$output" =~ "Use 'tagger --help' for usage information" ]]
}

@test "Invalid add command usage" {
    run bash -c "echo 'n' | /workspace/tagger.sh add"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage: tagger add <file>" ]]
}

@test "Invalid remove command usage" {
    run bash -c "echo 'n' | /workspace/tagger.sh remove"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage: tagger remove <file>" ]]
}

@test "Invalid list command usage" {
    run bash -c "echo 'n' | /workspace/tagger.sh list"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage: tagger list" ]]
}

@test "Invalid search command usage" {
    run bash -c "echo 'n' | /workspace/tagger.sh search"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage: tagger search <query>" ]]
}

@test "Invalid update-path command usage" {
    run bash -c "echo 'n' | /workspace/tagger.sh update-path old"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage: tagger update-path <old_path> <new_path>" ]]
}

@test "Help mentions all main commands" {
    run /workspace/tagger.sh --help
    [[ "$output" =~ "add" ]]
    [[ "$output" =~ "remove" ]]
    [[ "$output" =~ "list" ]]
    [[ "$output" =~ "search" ]]
    [[ "$output" =~ "update-path" ]]
    [[ "$output" =~ "export" ]]
    [[ "$output" =~ "validate" ]]
}
