#!/bin/bash

# Test helper functions for tagger.sh tests

# Set up a temporary test directory
setup_test_dir() {
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR"
    
    # Create sample files
    touch file1.txt file2.md file3.py
    
    # Make tagger.sh available
    cp /workspace/tagger.sh ./tagger.sh
    chmod +x ./tagger.sh
    
    # Initialize (simulate first run without prompts)
    mkdir -p ~/.tagger 2>/dev/null || true
    # Answers: storage dir (empty for current), install rg (n), make global (n)
    printf '\n\nn\nn\n' | ./tagger.sh --version >/dev/null 2>&1 || true
    # Clean up any generated files
    rm -f ~/.tagger_completion.sh tagger
}

# Clean up test directory
teardown_test_dir() {
    cd /
    rm -rf "$TEST_DIR"
    # Clean up PATH changes if any
    sed -i '/export PATH.*tagger/d' ~/.bashrc 2>/dev/null || true
}

# Add sample tags for testing
setup_sample_tags() {
    ./tagger.sh add file1.txt urgent project/alpha >/dev/null 2>&1
    ./tagger.sh add file2.md important docs >/dev/null 2>&1
    ./tagger.sh add file3.py bug fix/urgent >/dev/null 2>&1
}

# Get current tagger.sh path
tagger_cmd() {
    echo "./tagger.sh"
}
