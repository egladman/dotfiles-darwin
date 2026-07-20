# Homebrew package manifest for these dotfiles.
#
# Install / update:   brew bundle install --file=Brewfile
# Remove drift:       brew bundle cleanup --file=Brewfile   # destructive — review first
# Check status:       brew bundle check  --file=Brewfile
#
# Comments mark packages without a clean brew equivalent — install those
# manually if you want them.

# Install casks to ~/Applications instead of /Applications (no sudo needed)
cask_args appdir: "~/Applications"

# Taps
tap "koekeishiya/formulae"   # for yabai + skhd

# AI
cask "claude-code"
# brew "aider"               # lags upstream; prefer `uv tool install aider-chat` for latest

# CLI
brew "coreutils"             # GNU tools install with `g` prefix unless gnubin is on PATH
brew "fzf"
brew "findutils"
brew "gawk"
brew "git"
brew "grep"                  # `ggrep` on PATH unless gnubin is added
brew "make"                  # `gmake` on PATH unless gnubin is added
brew "gnupg"
brew "gnu-sed"               # `gsed` on PATH unless gnubin is added
brew "ijq"
brew "jq"
brew "llvm"                  # provides lld; heavy — review if too much
brew "ripgrep"
brew "starship"
brew "stow"
# brew "terraform"
brew "terragrunt"
brew "tree"
brew "yq"
brew "quicktype"
brew "openssl@3"

# GUIs
cask "emacs-app"
cask "kitty"
cask "meld"
cask "visual-studio-code"
# cask "utm"

# GUIs - MacOS
cask "rectangle"
# brew "koekeishiya/formulae/skhd"
# brew "koekeishiya/formulae/yabai"

# Databases
brew "postgresql@16"         # pin a major to avoid surprise upgrades

# Cloud
brew "awscli"                # brew's awscli is v2
brew "aws-vault"
# brew "azure-cli"

# Kubernetes
brew "eksctl"
brew "kind"
brew "kubeconform"
brew "kubernetes-cli"        # provides `kubectl`
brew "helm"
brew "kube-linter"
brew "k9s"

# Containers
brew "hadolint"
brew "dive"
brew "podman"
brew "podman-compose"
brew "skopeo"

# Productivity
cask "obsidian"

# Entertainment
# cask "spotify"

# Bash
brew "bash"
brew "shellcheck"

# C/C++
brew "gcc"
brew "pkgconf"               # provides pkg-config
brew "libiconv"

# Golang
brew "delve"
# gdlv — no brew formula; install with: go install github.com/aarzilli/gdlv@latest
brew "go"
brew "golangci-lint"

# Nodejs
brew "node"

# Python
brew "uv"
