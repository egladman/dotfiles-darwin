# dotfiles-darwin

## 1. Install Nix
```
sh <(curl -L https://nixos.org/nix/install)
```

## 2. Install Dotfiles
```
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
nix-env -iA nixpkgs.git nixpkgs.stow
git clone git@github.com:egladman/dotfiles-darwin.git ~/.dotfiles
```

## 3. Stow Dotfiles
```
cd ~/.dotfiles
./setup.sh
```

## 4. Install All Packages
```
nix-env -if development.nix
```
