source /dev/stdin <<<"$(kitty + complete setup bash)"

# starship
eval "$(starship init bash)"

cd() {
    case "$*" in
        '...') # git repository root
            local path
            path="$(git rev-parse --show-toplevel)"
            if [[ $? -ne 0 ]]; then
                printf '%s\n' "${FUNCNAME[0]}: Not inside a git repository"
                return 1
            fi
            set -- "$path"
            ;;
    esac

    command cd "$@"
}

dc() {
    command cd "${OLDPWD:?}"
}

em() {
    local base_dir="${XDG_RUNTIME_DIR:-${TMPDIR:?}}/emacs"
    if [[ ! -d "$base_dir" ]]; then
	mkdir -p "$base_dir"
    fi

    # Passing an empty string will automatically start
    # the daemon if its not already running
    declare -a emacs_opts=(
	--socket-name="${base_dir}/server"
	--alternate-editor=''
    )

    TERM=xterm-emacs emacsclient "${emacs_opts[@]}" "$@"
}

la() {
    ls -a "$@"
}

mkcd() {
    # Create multiple directories and cd into the first one
    mkdir -p "$@" && cd "!$"
}

k() {
    kubectl "$@"
}

git-cherrypick() {
    # Usage: git-cherrypick ebe6942..905e279 dcek8bg

    # Rewrites commit ranges to be inclusive of both range endpoints. By default
    # range <commit1>..<commit2> does not include the starting commit in the
    # range. That's wack

    declare -a argv=("$@")
    for i in "${!argv[@]}"; do
        if [[ "${argv[$i]}" =~ ^([A-Za-z0-9]+)(\^)?\.\.([A-Za-z0-9]+)$ ]]; then
            if [[ "${BASH_REMATCH[2]}" == "^" ]]; then
                printf "${FUNCNAME[0]}: Unexpected character ^"
                return 1
            fi

            argv[$i]="${BASH_REMATCH[1]}^..${BASH_REMATCH[3]}"
        fi
    done

    git cherry-pick "${argv[@]}"
}

unpack() {
    # Usage: unpack <file1> <file2>
    #        unpack foobar.tar.gz

    for target in "$@"; do
        if [[ ! -f "$target" ]]; then
            printf '%s\n' "${FUNCNAME[0]}: File '$target' does not exist"
            return 1
        fi
    done

    for target in "$@"; do
        case "$target" in
            *.tar.gz|*.tgz)
                tar xzf "$target"
                ;;
            *.tar.bz2|*.tbz2)
                tar xjf "$target"
                ;;
            *.rar)
                unrar x "$target"
                ;;
            *.zip)
                unzip "$target"
                ;;
            *.Z)
                uncompress "$target"
                ;;
            *.7z)
                7z x "$target"
                ;;
            *)
                printf '%s\n' "${FUNCNAME[0]}: File '$target' has unsupported extension"
                return 1
        esac
    done
}
