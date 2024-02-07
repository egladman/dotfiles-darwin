#!/usr/bin/env bash

set -o errexit

main() {
    declare -a stow_args
    while [[ $# -gt 0 ]]; do
	case "$1" in
	    --)
		shift
		stow_args=("$@")
		break
		;;
	esac
	shift
    done

    # Find all top-level directories
    declare -a target_dirs
    for f in *; do
	if [[ ! -d "$f" ]]; then
	    continue
	fi
	target_dirs+=("$f")
    done

    stow "${stow_args[@]}" "${target_dirs[@]}"
    printf '%s\n' "Success"
}

main "$@"
