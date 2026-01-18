#!/usr/bin/env bats

setup() {
    source /workspace/test/helpers/test_setup.bash
    setup_test_dir
}

teardown() {
    teardown_test_dir
}

@test "Add tags to file" {
    run ./tagger.sh add file1.txt urgent project/alpha
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Tags added to file1.txt" ]]
    
    run ./tagger.sh list file1.txt
    [[ "$output" =~ "urgent" ]]
    [[ "$output" =~ "project/alpha" ]]
}

@test "Add duplicate tags are ignored" {
    ./tagger.sh add file1.txt urgent >/dev/null 2>&1
    run ./tagger.sh add file1.txt urgent
    [ "$status" -eq 0 ]
    
    run ./tagger.sh list file1.txt
    count=$(echo "$output" | grep -c "urgent")
    [ "$count" -eq 1 ]
}

@test "Add tags to non-existent file fails" {
    run ./tagger.sh add nonexistent.txt tag
    [ "$status" -eq 1 ]
    [[ "$output" =~ "does not exist" ]]
}

@test "Remove tags from file" {
    ./tagger.sh add file1.txt urgent important >/dev/null 2>&1
    run ./tagger.sh remove file1.txt urgent
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Tags removed from file1.txt" ]]
    
    run ./tagger.sh list file1.txt
    [[ ! "$output" =~ "urgent" ]]
    [[ "$output" =~ "important" ]]
}

@test "Remove non-existent tag does nothing" {
    ./tagger.sh add file1.txt urgent >/dev/null 2>&1
    run ./tagger.sh remove file1.txt nonexistent
    [ "$status" -eq 0 ]
    
    run ./tagger.sh list file1.txt
    [[ "$output" =~ "urgent" ]]
}

@test "Remove all tags from file" {
    ./tagger.sh add file1.txt urgent >/dev/null 2>&1
    run ./tagger.sh remove file1.txt urgent
    [ "$status" -eq 0 ]
    
    run ./tagger.sh list file1.txt
    [[ "$output" =~ "No tags found" ]]
}

@test "Remove from non-existent file fails" {
    run ./tagger.sh remove nonexistent.txt tag
    [ "$status" -eq 1 ]
    [[ "$output" =~ "does not exist" ]]
}

@test "Add and remove workflow preserves other files" {
    ./tagger.sh add file1.txt tag1 >/dev/null 2>&1
    ./tagger.sh add file2.md tag2 >/dev/null 2>&1
    
    run ./tagger.sh list file1.txt
    [[ "$output" =~ "tag1" ]]
    
    run ./tagger.sh list file2.md
    [[ "$output" =~ "tag2" ]]
    
    ./tagger.sh remove file1.txt tag1 >/dev/null 2>&1
    
    run ./tagger.sh list file2.md
    [[ "$output" =~ "tag2" ]]
}
