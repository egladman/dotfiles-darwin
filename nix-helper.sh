#!/usr/bin/env sh

set -o errexit

__NIX_PACKAGE_LIST="${__NIX_PACKAGE_LIST:-packages}"
__NIX_PROFILE_DIR="${XDG_STATE_HOME:-${HOME}/.local/state}/nix/profiles"
__NIX_PROFILE_NAME="${__NIX_PROFILE_NAME:-development}"
__NIX_PROFILE_PATH="${__NIX_PROFILE_DIR}/${__NIX_PROFILE_NAME}"
__NIX_FORCE_INSTALL=${__NIX_FORCE_INSTALL:-0}

__die() {
    printf '%s\n' "$@" >&2
    printf '%s\n' "Dying..."
    return 1
}

__log() {
    printf '>> %s\n' "$@"
}

__nix_update_channels() {
    nix-channel --update
}

__nix_add_channels() {
    # Ensures the prerequisite nix channels are present

    for chan in nixpkgs nixpkgs-unstable; do
	chan_dir="${__NIX_PROFILE_DIR}/channels/${chan}"

	chan_exists=1    
	[ ! -d "$chan_dir" ] && chan_exists=0	
	
        case "$chan" in
            "nixpkgs")
                [ $chan_exists -eq 1 ] || __die "Could not find channel '$chan'"
                ;;
             "nixpkgs-unstable")
                 [ $chan_exists -eq 1 ] || nix-channel --add https://nixos.org/channels/nixpkgs-unstable "$chan"
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
    nix-env --install --profile $__NIX_PROFILE_PATH --attr "${1:?}"
}

__nix_upgrade() {
    nix-env --upgrade --profile $__NIX_PROFILE_PATH --attr "${1:?}"
}

__nix_switch_profile() {
    __log "switching to profile ${__NIX_PROFILE_NAME} that has path $__NIX_PROFILE_PATH"
    nix-env --switch-profile $__NIX_PROFILE_PATH
}

__nix_add_shortcuts() {
    for f in ~/.nix-profile/Applications/*; do
        [ ! -e "$f" ] && continue
        ln -svf "$f" ~/Applications/
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
                __die "Unrecognized command: $1"
                ;;
        esac
        shift
    done 

    __nix_switch_profile
    __nix_add_shortcuts
}

main "$@"
