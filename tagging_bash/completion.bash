# Bash completion for tagg
# This file should be sourced or placed in bash-completion directory

_tagg() {
    local cur prev words cword
    _init_completion || return

    case $cword in
        1)
            COMPREPLY=($(compgen -W "install uninstall add remove edit list help" -- "$cur"))
            ;;
        2)
            case $prev in
                add|remove|edit|list)
                    _filedir
                    ;;
            esac
            ;;
        3)
            case ${words[1]} in
                add)
                    # Complete files and existing tags
                    _filedir
                    local tags
                    tags=$(tagg list 2>/dev/null | sed 's/^  //' | tr '\n' ' ')
                    COMPREPLY+=($(compgen -W "$tags" -- "$cur"))
                    ;;
                remove)
                    # Complete tags for the specified file
                    local file="${words[2]}"
                    if [[ -f "$file" ]]; then
                        local tags
                        tags=$(tagg list "$file" 2>/dev/null | sed 's/^  //' | tr '\n' ' ')
                        COMPREPLY=($(compgen -W "$tags" -- "$cur"))
                    fi
                    ;;
                edit)
                    # Complete tags for the specified file
                    local file="${words[2]}"
                    if [[ -f "$file" ]]; then
                        local tags
                        tags=$(tagg list "$file" 2>/dev/null | sed 's/^  //' | tr '\n' ' ')
                        COMPREPLY=($(compgen -W "$tags" -- "$cur"))
                    fi
                    ;;
            esac
            ;;
        4)
            case ${words[1]} in
                edit)
                    # Complete all existing tags for new-tag
                    local tags
                    tags=$(tagg list 2>/dev/null | sed 's/^  //' | tr '\n' ' ')
                    COMPREPLY=($(compgen -W "$tags" -- "$cur"))
                    ;;
                add)
                    # Continue completing files and tags
                    _filedir
                    local tags
                    tags=$(tagg list 2>/dev/null | sed 's/^  //' | tr '\n' ' ')
                    COMPREPLY+=($(compgen -W "$tags" -- "$cur"))
                    ;;
            esac
            ;;
        *)
            # For add, continue with files and tags
            case ${words[1]} in
                add)
                    _filedir
                    local tags
                    tags=$(tagg list 2>/dev/null | sed 's/^  //' | tr '\n' ' ')
                    COMPREPLY+=($(compgen -W "$tags" -- "$cur"))
                    ;;
            esac
            ;;
    esac
}

complete -F _tagg tagg