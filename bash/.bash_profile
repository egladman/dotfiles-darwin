# Kitty uses a custom terminfo name that breaks everything
export TERM=xterm-256color

if [[ -d "${HOME}/.asdf" ]]; then
    source "${HOME}/.asdf/asdf.sh"
    source "${HOME}/.asdf/completions/asdf.bash"
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

if [[ -d "${KREW_ROOT:-$HOME/.krew}" ]]; then
    PATH="${PATH}:${KREW_ROOT:-$HOME/.krew}/bin"
fi

if [[ -f "${HOME:?}/.bashrc" ]]; then
    source "${HOME}/.bashrc"
fi

eval "$(mise activate bash)"
