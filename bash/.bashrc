
source /dev/stdin <<<"$(kitty + complete setup bash)"

# starship
eval "$(starship init bash)"

#############
# traversal #
#############

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

cl() {
    command cd "$@" && ls
}

la() {
    ls -a "$@"
}

mkcd() {
    # Create multiple directories and cd into the first one
    mkdir -p "$@" && command cd "!$"
}

#########
# emacs #
#########

emacs() {
    TERM=xterm-emacs command emacs "$@"
}

emacsclient() {
    TERM=xterm-emacs command emacslient "$@"
}

em() {
    emacs -nw "$@"
}

ec() {
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

    emacsclient "${emacs_opts[@]}" "$@"
}

ce() {
    em --create-frame "$@"
}

##############
# kubernetes #
##############

k() {
    kubectl "$@"
}

kk() {
    kubectl kustomize "$@"
}

#######
# git #
#######

g() {
    git "$@"
}

git() {
    case "$1" in
        'yeet')
            set -- push --force origin HEAD
            ;;
	'unfuck')
	    set -- reset --hard origin/HEAD
	    ;;
    esac

    command git "$@"
}

gitc() {
    command git commit -m "$*"
}

gitp() {
   command git push origin HEAD 
}

gitch() {
    # Usage: gitch ebe6942..905e279 dcek8bg

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

    command git cherry-pick "${argv[@]}"
}

########
# misc #
########

extract() {
    # Usage: extract <path/to/archive1> <path/to/archive2>
    #        extract foobar.tar.gz

    for archive in "$@"; do
        if [[ ! -e "$archive" ]]; then
            printf '%s\n' "${FUNCNAME[0]}: File '$archive' does not exist."
            return 1
        fi

        case "${archive,,}" in
	    *.tar)
		tar xf "$archive"
		;;
            *.tar.gz|*.tgz)
                tar xzf "$archive"
                ;;
            *.tar.bz2|*.tbz2)
                tar xjf "$archive"
                ;;
            *.rar)
                unrar x "$archive"
                ;;
            *.zip)
                unzip "$archive"
                ;;
            *.z)
                uncompress "$archive"
                ;;
            *.7z)
                7z x "$archive"
                ;;
            *)
                printf '%s\n' "${FUNCNAME[0]}: Unable to extract contents of '${archive}'. File has unsupported extension."
                return 1
        esac
    done
}
