#!/bin/bash
# Simplified Tagging System (tagger.sh)
# A pure bash CLI for managing file tags with fuzzy search and completion

set -euo pipefail  # Strict error handling

# Version
readonly VERSION="1.0.0"

# Global data structures
declare -A config
declare -A file_tags
declare -A tag_files
declare -a all_tags

# Default configuration
config=(
    [tag_separator]="/"
    [max_suggestions]=10
    [min_search_length]=2
)

# First-run setup and dependency checks
setup_environment() {
    # Check if first run (no .tags.md in current dir)
    if [[ ! -f .tags.md ]]; then
        echo "First run detected. Setting up tagging system..."

        # Check dependencies
        local missing_deps=()
        if ! command -v awk &> /dev/null; then
            missing_deps+=("awk")
        fi
        if ! command -v rg &> /dev/null; then
            echo "ripgrep (rg) is recommended for fuzzy search but not found."
            read -p "Install ripgrep? (y/N): " install_rg
            if [[ $install_rg =~ ^[Yy]$ ]]; then
                if command -v apt &> /dev/null; then
                    sudo apt update && sudo apt install -y ripgrep
                elif command -v yum &> /dev/null; then
                    sudo yum install -y ripgrep
                else
                    echo "Please install ripgrep manually for optimal fuzzy search."
                fi
            else
                echo "Proceeding without ripgrep. Fuzzy search will use awk fallback."
            fi
        fi

        if [[ ${#missing_deps[@]} -gt 0 ]]; then
            echo "Error: Missing required dependencies: ${missing_deps[*]}" >&2
            exit 1
        fi

        # Create .tags.md
        local dir_path
        dir_path=$(pwd)
        cat > .tags.md << EOF
# Tags for Directory: $dir_path

EOF
        echo "Setup complete. Created .tags.md in $dir_path"

        # Generate tab completion
        generate_completion
        echo "Tab completion set up. Add 'source ~/.tagger_completion.sh' to your ~/.bashrc for persistence."
    fi
}

generate_completion() {
    cat > ~/.tagger_completion.sh << 'EOF'
_tagger_complete() {
    local cur prev words cword
    _init_completion || return

    case $prev in
        add|remove)
            # Complete files
            COMPREPLY=( $(compgen -f -- "$cur") )
            ;;
        list)
            if [[ $cur == --* ]]; then
                COMPREPLY=( $(compgen -W "--tag --all-tags --all" -- "$cur") )
            else
                # Complete files
                COMPREPLY=( $(compgen -f -- "$cur") )
            fi
            ;;
        --tag)
            # Complete existing tags
            local tags_file
            tags_file=$(find . -name ".tags.md" -type f 2>/dev/null | head -1)
            if [[ -f $tags_file ]]; then
                local tags
                tags=$(grep "^- " "$tags_file" | sed 's/^- //' | sort | uniq)
                COMPREPLY=( $(compgen -W "$tags" -- "$cur") )
            fi
            ;;
        *)
            COMPREPLY=( $(compgen -W "add remove list search update-path export validate --help --version" -- "$cur") )
            ;;
    esac
}

complete -F _tagger_complete tagger
EOF
    source ~/.tagger_completion.sh
}

# Utility functions
normalize_tag() {
    local tag="$1"
    # Convert to lowercase
    tag="${tag,,}"
    # Remove invalid characters (keep alphanumeric, hyphens, underscores, separator)
    local sep="${config[tag_separator]}"
    tag="${tag//[^a-zA-Z0-9${sep}_-]/}"
    # Prevent directory traversal
    [[ "$tag" =~ \.\. ]] && return 1
    echo "$tag"
}

get_file_tags() {
    local file="$1"
    echo "${file_tags[$file]:-}"
}

get_tag_files() {
    local tag="$1"
    echo "${tag_files[$tag]:-}"
}

parse_tags_md() {
    file_tags=()
    tag_files=()
    all_tags=()

    local current_file=""
    while IFS= read -r line; do
        if [[ $line =~ ^\#\#\ File:\ (.+)$ ]]; then
            current_file="${BASH_REMATCH[1]}"
            file_tags[$current_file]=""
        elif [[ $line =~ ^-\ (.+)$ ]]; then
            local tag="${BASH_REMATCH[1]}"
            if [[ -n $current_file ]]; then
                file_tags[$current_file]="${file_tags[$current_file]} $tag"
                local current_files
                current_files=$(get_tag_files "$tag")
                tag_files[$tag]="$current_files $current_file"
            fi
            # Add to all_tags if not present
            if [[ ! " ${all_tags[*]} " =~ " $tag " ]]; then
                all_tags+=("$tag")
            fi
        fi
    done < .tags.md
}

write_tags_md() {
    local dir_path
    dir_path=$(pwd)
    cat > .tags.md.tmp << EOF
# Tags for Directory: $dir_path

EOF

    for file in "${!file_tags[@]}"; do
        local tags_str
        tags_str=$(get_file_tags "$file")
        if [[ -n $tags_str ]]; then
            echo "## File: $file" >> .tags.md.tmp
            for tag in $tags_str; do
                echo "- $tag" >> .tags.md.tmp
            done
            echo "" >> .tags.md.tmp
        fi
    done

    mv .tags.md.tmp .tags.md
}

lock_file() {
    # Simple file locking using mkdir (not perfect but works for basic concurrency)
    local lock_dir=".tags.lock"
    if ! mkdir "$lock_dir" 2>/dev/null; then
        echo "Tag database is locked by another process. Please try again." >&2
        exit 1
    fi
    trap "rmdir '$lock_dir'" EXIT
}

# Command implementations
cmd_add() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: tagger add <file> [<tag1> <tag2> ...]" >&2
        exit 1
    fi

    local file="$1"
    shift

    if [[ ! -f $file ]]; then
        echo "Error: File '$file' does not exist" >&2
        exit 1
    fi

    # If no tags provided, prompt interactively with suggestions
    local tags=("$@")
    if [[ ${#tags[@]} -eq 0 ]]; then
        echo "Enter tags for $file (press Enter for suggestions, Ctrl+C to cancel):"
        read -e -p "Tags: " -a tags
        # If still empty, show suggestions
        if [[ ${#tags[@]} -eq 0 ]]; then
            parse_tags_md
            if [[ ${#all_tags[@]} -gt 0 ]]; then
                echo "Available tags:"
                printf '%s\n' "${all_tags[@]}" | head -10
            fi
            read -e -p "Tags: " -a tags
        fi
    fi

    if [[ ${#tags[@]} -eq 0 ]]; then
        echo "No tags provided" >&2
        exit 1
    fi

    parse_tags_md
    lock_file

    for tag in "${tags[@]}"; do
        normalized=$(normalize_tag "$tag")
        if [[ $? -eq 0 ]]; then
            # Check if tag already exists
            local current_tags
            current_tags=$(get_file_tags "$file")
            if [[ ! " $current_tags " =~ " $normalized " ]]; then
                file_tags[$file]="$current_tags $normalized"
                local tag_files_str
                tag_files_str=$(get_tag_files "$normalized")
                tag_files[$normalized]="$tag_files_str $file"
                if [[ ! " ${all_tags[*]} " =~ " $normalized " ]]; then
                    all_tags+=("$normalized")
                fi
            fi
        else
            echo "Warning: Invalid tag '$tag' skipped" >&2
        fi
    done

    write_tags_md
    echo "Tags added to $file"
}

cmd_remove() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: tagger remove <file> [<tag1> <tag2> ...]" >&2
        exit 1
    fi

    local file="$1"
    shift

    # If no tags provided, prompt interactively
    local tags=("$@")
    if [[ ${#tags[@]} -eq 0 ]]; then
        parse_tags_md
        local current_tags
        current_tags=$(get_file_tags "$file")
        if [[ -n $current_tags ]]; then
            echo "Current tags for $file: $current_tags"
            read -e -p "Tags to remove: " -a tags
        else
            echo "No tags found for $file" >&2
            exit 1
        fi
    fi

    if [[ ${#tags[@]} -eq 0 ]]; then
        echo "No tags provided" >&2
        exit 1
    fi

    parse_tags_md
    lock_file

    for tag in "${tags[@]}"; do
        normalized=$(normalize_tag "$tag")
        # Remove from file_tags
        local current_tags
        current_tags=$(get_file_tags "$file")
        file_tags[$file]="${current_tags// $normalized / }"
        file_tags[$file]="${file_tags[$file]// $normalized/}"
        file_tags[$file]="${file_tags[$file]// $normalized /}"
        # Remove from tag_files
        local current_files
        current_files=$(get_tag_files "$normalized")
        tag_files[$normalized]="${current_files// $file / }"
        tag_files[$normalized]="${tag_files[$normalized]// $file/}"
        tag_files[$normalized]="${tag_files[$normalized]// $file /}"
    done

    # Remove file entry if no tags left
    local final_tags
    final_tags=$(get_file_tags "$file")
    if [[ -z $final_tags ]]; then
        unset file_tags[$file]
    fi

    write_tags_md
    echo "Tags removed from $file"
}

cmd_list() {
    parse_tags_md

    if [[ $# -eq 0 ]]; then
        echo "Usage: tagger list <file> | --tag <tag> | --all-tags | --all" >&2
        exit 1
    fi

    case "$1" in
        --tag)
            if [[ $# -lt 2 ]]; then
                echo "Usage: tagger list --tag <tag>" >&2
                exit 1
            fi
            local tag="$2"
            normalized=$(normalize_tag "$tag")
            if [[ -n ${tag_files[$normalized]} ]]; then
                for file in ${tag_files[$normalized]}; do
                    echo "$file"
                done
            else
                echo "No files found with tag '$tag'"
            fi
            ;;
        --all-tags)
            for tag in "${all_tags[@]}"; do
                echo "$tag"
            done
            ;;
        --all)
            for file in "${!file_tags[@]}"; do
                local tags_str
                tags_str=$(get_file_tags "$file")
                echo "$file: $tags_str"
            done
            ;;
        *)
            local file="$1"
            local file_tags_str
            file_tags_str=$(get_file_tags "$file")
            if [[ -n $file_tags_str ]]; then
                for tag in $file_tags_str; do
                    echo "$tag"
                done
            else
                echo "No tags found for file '$file'"
            fi
            ;;
    esac
}

cmd_search() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: tagger search <query>" >&2
        exit 1
    fi

    local query="$1"
    if [[ ${#query} -lt ${config[min_search_length]} ]]; then
        echo "Query too short. Minimum length: ${config[min_search_length]}" >&2
        exit 1
    fi

    parse_tags_md

    local results=()
    if command -v rg &> /dev/null; then
        # Use ripgrep for fuzzy search
        while IFS= read -r line; do
            if [[ $line =~ ^\#\#\ File:\ (.+)$ ]]; then
                local file="${BASH_REMATCH[1]}"
                # Check if file has matching tags
                local file_tags_str
                file_tags_str=$(get_file_tags "$file")
                if rg -q "$query" <<< "$file_tags_str"; then
                    results+=("$file")
                fi
            fi
        done < .tags.md
    else
        # Awk fallback
        for file in "${!file_tags[@]}"; do
            local file_tags_str
            file_tags_str=$(get_file_tags "$file")
            if awk -v q="$query" '{exit !(index($0, q))}' <<< "$file_tags_str"; then
                results+=("$file")
            fi
        done
    fi

    if [[ ${#results[@]} -gt 0 ]]; then
        printf '%s\n' "${results[@]}"
    else
        echo "No matches found for '$query'"
    fi
}

cmd_update_path() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: tagger update-path <old_path> <new_path>" >&2
        exit 1
    fi

    local old_path="$1"
    local new_path="$2"

    parse_tags_md
    lock_file

    local old_tags
    old_tags=$(get_file_tags "$old_path")
    if [[ -n $old_tags ]]; then
        file_tags[$new_path]="$old_tags"
        unset file_tags[$old_path]

        # Update tag_files
        for tag in "${all_tags[@]}"; do
            local tag_files_str
            tag_files_str=$(get_tag_files "$tag")
            tag_files[$tag]="${tag_files_str// $old_path / $new_path }"
            tag_files[$tag]="${tag_files[$tag]// $old_path/ $new_path}"
            tag_files[$tag]="${tag_files[$tag]// $old_path / $new_path }"
        done
    fi

    write_tags_md
    echo "Path updated: $old_path -> $new_path"
}

cmd_export() {
    cat .tags.md
}

cmd_validate() {
    if [[ ! -f .tags.md ]]; then
        echo "Error: .tags.md not found" >&2
        exit 1
    fi

    # Basic validation: check structure
    local errors=0
    local line_num=1
    while IFS= read -r line; do
        if [[ $line_num -eq 1 && ! $line =~ ^#\ Tags\ for\ Directory: ]]; then
            echo "Error: Invalid header on line $line_num" >&2
            errors=$((errors + 1))
        fi
        ((line_num++))
    done < .tags.md

    if [[ $errors -eq 0 ]]; then
        echo "Tag database is valid"
    else
        echo "Found $errors validation errors" >&2
        exit 1
    fi
}

# Show help
show_help() {
    cat << EOH
Simplified Tagging System v${VERSION}
A command-line tool for tagging files with fuzzy search support.

USAGE:
    tagger [COMMAND] [OPTIONS]

COMMANDS:
    add <file> <tag1> [<tag2> ...]    Add tags to a file
    remove <file> <tag1> [<tag2> ...] Remove tags from a file
    list <file>                     List tags for a specific file
    list --tag <tag>                List files with a specific tag
    list --all-tags                 List all unique tags
    list --all                      List all files with their tags
    search <query>                  Fuzzy search for files by tag
    update-path <old> <new>         Update file path in tags
    export                          Export tags to stdout
    validate                        Validate tag database integrity

OPTIONS:
    --help, -h                      Show this help message
    --version, -v                   Show version information

EXAMPLES:
    tagger add document.txt important project/alpha
    tagger list document.txt
    tagger search proj
    tagger remove document.txt important

For more information, see the documentation.
EOH
}

# Show version
show_version() {
    echo "Simplified Tagging System v${VERSION}"
}

# Parse arguments and dispatch
parse_args() {
    case "${1:-}" in
        --help|-h|"")
            show_help
            exit 0
            ;;
        --version|-v)
            show_version
            exit 0
            ;;
        add)
            shift
            cmd_add "$@"
            ;;
        remove)
            shift
            cmd_remove "$@"
            ;;
        list)
            shift
            cmd_list "$@"
            ;;
        search)
            shift
            cmd_search "$@"
            ;;
        update-path)
            shift
            cmd_update_path "$@"
            ;;
        export)
            shift
            cmd_export "$@"
            ;;
        validate)
            shift
            cmd_validate "$@"
            ;;
        *)
            echo "Error: Unknown command '$1'" >&2
            echo "Use 'tagger --help' for usage information." >&2
            exit 1
            ;;
    esac
}

# Main function
main() {
    # Only setup for commands that need it
    case "${1:-}" in
        --help|-h|"")
            parse_args "$@"
            ;;
        --version|-v)
            parse_args "$@"
            ;;
        *)
            setup_environment
            parse_args "$@"
            ;;
    esac
}

# Run main only if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
