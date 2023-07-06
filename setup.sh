#!/usr/bin/env sh

for f in *; do
    if [[ ! -d "$f" ]]; then
	continue
    fi
    set -- "$@" "$f"
done

stow "$@"
