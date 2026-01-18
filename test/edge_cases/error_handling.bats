#!/usr/bin/env bats

setup() {
    source /workspace/test/helpers/test_setup.bash
    setup_test_dir
}

teardown() {
    teardown_test_dir
}

@test "Add with invalid tag characters" {
    run ./tagger.sh add file1.txt "tag@#$%"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Tags added" ]]
    
    run ./tagger.sh list file1.txt
    [[ "$output" =~ "tag" ]]
    [[ ! "$output" =~ "@" ]]
}

@test "Add with directory traversal attempt" {
    run ./tagger.sh add file1.txt "../../../etc"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Warning: Invalid tag" ]]
}

@test "Corrupted .tags.md file repair" {
    # Create corrupted file
    echo "# Tags for Directory: /tmp/test" > .tags.md
    echo "## File: file1.txt" >> .tags.md
    echo "- urgent" >> .tags.md
    echo "## Incomplete section" >> .tags.md
    
    run ./tagger.sh validate
    [[ "$output" =~ "Tag database is valid" ]]
}

@test "Empty .tags.md file handling" {
    echo "" > .tags.md
    run ./tagger.sh list --all
    [ "$status" -eq 0 ]
}

@test "Concurrent access with file locking" {
    # This is hard to test directly, but we can check that operations complete
    ./tagger.sh add file1.txt tag1 >/dev/null 2>&1 &
    pid=$!
    ./tagger.sh add file1.txt tag2 >/dev/null 2>&1
    wait $pid
    
    run ./tagger.sh list file1.txt
    [[ "$output" =~ "tag1" ]]
    [[ "$output" =~ "tag2" ]]
}

@test "File with very long tag list" {
    # Create many tags
    tags=""
    for i in {1..50}; do
        tags="$tags tag$i"
    done
    ./tagger.sh add file1.txt $tags >/dev/null 2>&1
    
    run ./tagger.sh list file1.txt
    count=$(echo "$output" | wc -l)
    [ "$count" -gt 40 ]
}

@test "Tags with special characters in names" {
    ./tagger.sh add file1.txt "tag-with-dashes" "tag_with_underscores" >/dev/null 2>&1
    run ./tagger.sh list file1.txt
    [[ "$output" =~ "tag-with-dashes" ]]
    [[ "$output" =~ "tag_with_underscores" ]]
}

@test "Update path for renamed file" {
    ./tagger.sh add file1.txt original >/dev/null 2>&1
    mv file1.txt file1_renamed.txt
    
    run ./tagger.sh update-path file1.txt file1_renamed.txt
    [[ "$output" =~ "Path updated" ]]
    
    run ./tagger.sh list file1_renamed.txt
    [[ "$output" =~ "original" ]]
}

@test "Export produces valid markdown" {
    ./tagger.sh add file1.txt tag1 tag2 >/dev/null 2>&1
    run ./tagger.sh export
    [[ "$output" =~ "# Tags for Directory:" ]]
    [[ "$output" =~ "## File: file1.txt" ]]
    [[ "$output" =~ "- tag1" ]]
    [[ "$output" =~ "- tag2" ]]
}
