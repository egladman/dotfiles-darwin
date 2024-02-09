#!/usr/bin/env sh

# A POSIX script to install/upgrade a predefined list of Nix packages on MacOS

set -o errexit

__NIX_PACKAGE_LIST="${__NIX_PACKAGE_LIST:-packages}"
__NIX_PROFILE_DIR="${XDG_STATE_HOME:-${HOME:?}/.local/state}/nix/profiles"
__NIX_APPLICATION_DIR="${__NIX_APPLICATION_DIR:-${HOME:?}/Applications}"
__NIX_PROFILE_NAME="${__NIX_PROFILE_NAME:-development}"
__NIX_PROFILE_PATH="${__NIX_PROFILE_DIR}/${__NIX_PROFILE_NAME}"
__NIX_FORCE_INSTALL=${__NIX_FORCE_INSTALL:-0}

__die() {
    printf '%s\n' "$@" >&2
    printf '%s\n' "dying..."
    exit 1
}

__log() {
    printf '>> %s\n' "$@"
}

__nix_update_channels() {
    nix-channel --update "$1"
}

__nix_add_channels() {
    # Ensures the prerequisite nix channels are present

    for chan in nixpkgs-unstable; do
	chan_dir="${__NIX_PROFILE_DIR}/channels/${chan}"
	
        chan_exists=1
        if [ ! -d "$chan_dir" ]; then
            __log "channel $chan does not exist"
            chan_exists=0
        fi

        case "$chan" in
             "nixpkgs-unstable")
                if [ $chan_exists -eq 0 ]; then
                    __log "adding channel $chan"
                    nix-channel --add https://nixos.org/channels/nixpkgs-unstable "$chan"
                    __nix_update_channels "$chan"
                fi
                ;;
        esac
    done
}

__nix_foreach_package() {
    func_callback="${1:?}"

    while IFS= read -r line; do
        case "$line" in
            "#"*|"")
                continue
                ;;        
        esac

	# Split on whitespace
	set -- $(printf "$line" | tr '.' ' ')
	channel="$1"
	name="$2"
 
        if [ $# -eq 1 ]; then
             name="$1"
             channel="nixpkgs"
        fi
        package="${channel}.${name}"

	"$func_callback" "$package"
    done < "$__NIX_PACKAGE_LIST"
}

__nix_install() {
    package="${1:?}"

    is_installed=1
    derivative="$(nix-env --query --available --attr "${1:?}")"

    nix-env --query "$derivative" --installed || is_installed=0

    if [ $is_installed -eq 1 -a $__NIX_FORCE_INSTALL -eq 0 ]; then
        __log "package $1 already installed, to forcibly re-install set environment variable __NIX_FORCE_INSTALL=1"
        return 0
    fi

    nix-env --install --profile $__NIX_PROFILE_PATH --attr "$1"
}

__nix_upgrade() {
    nix-env --upgrade --profile $__NIX_PROFILE_PATH --attr "${1:?}"
}

__nix_switch_profile() {
    __log "switching to profile ${__NIX_PROFILE_NAME} that has path $__NIX_PROFILE_PATH"
    nix-env --switch-profile $__NIX_PROFILE_PATH
}

__nix_add_shortcuts() {
    if [ ! -d "$__NIX_APPLICATION_DIR" ]; then
        mkdir -p "$__NIX_APPLICATION_DIR"
    fi

    for f in "${HOME}/.nix-profile/Applications"/*; do
        [ ! -e "$f" ] && continue
        ln -svf "$f" "${__NIX_APPLICATION_DIR}"
    done
}

main() {
    # Default to upgrading packages if no operation is specified
    [ -z "$1" ] && set -- upgrade 

    while [ $# -gt 0 ]; do
        case "$1" in
            "install")
                __nix_add_channels
                __nix_foreach_package __nix_install
                ;;
            "upgrade")
                __nix_update_channels
                __nix_foreach_package __nix_upgrade
                ;;
            *)
                __die "unrecognized command: $1"
                ;;
        esac
        shift
    done 

    __nix_switch_profile
    __nix_add_shortcuts
}

main "$@"
