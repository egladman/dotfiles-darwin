# Kitty uses a custom terminfo name that breaks everything
export TERM=xterm-256color

if [[ -f '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]]; then
  source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
  export NIX_PATH="$HOME/.nix-defexpr"
fi

if [[ -d "${HOME}/.local/bin" ]]; then
    PATH="${PATH}:${HOME}/.local/bin"
fi

export GOPATH="${HOME:?}/.go"
if [[ -d "$GOPATH" ]]; then
    PATH="${PATH}:${GOPATH}/bin"
fi

if [[ -d "${HOME:?}/.cargo" ]]; then
    PATH="${PATH}:${HOME}/.cargo/bin"
fi

if [[ -d "${HOME:?}/.npmpackages" ]]; then
    PATH="${PATH}:${HOME}/.npmpackages/bin"
fi

if [[ -d "${KREW_ROOT:-$HOME/.krew}" ]]; then
    PATH="${PATH}:${KREW_ROOT:-$HOME/.krew}/bin"
fi

eval "$(direnv hook bash)"

if [[ -f "${HOME:?}/.bashrc" ]]; then
    source "${HOME}/.bashrc"
fi

