# dotfiles-darwin

My minimal development setup on MacOS.

**Disclaimer:** The way in which I use Nix is very much an anti-pattern ¯\_(ツ)_/¯

## 1. Install Nix
```
sh <(curl -L https://nixos.org/nix/install)
```

## 2. Clone Dotfiles
```
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
nix-env --install --attr nixpkgs.git nixpkgs.stow
git clone git@github.com:egladman/dotfiles-darwin.git ~/.dotfiles
```

## 3. Stow Dotfiles
```
cd ~/.dotfiles
./stow-helper.sh
```

## 4. Install Nix Packages
```
./nix-helper.sh install
```

## 5. Change Default Shell
```
sudo echo "$HOME/.nix-profile/bin/bash" >> /etc/shells
chsh -s "$HOME/.nix-profile/bin/bash"
```

## 7. Bind Capslock to Command

Navigate to `System Settings` > `Keyboard` > `Keyboard Shortcuts` > `Modifier Keys`
