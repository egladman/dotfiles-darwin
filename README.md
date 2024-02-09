# dotfiles-darwin

My minimal development setup on MacOS.

**Disclaimer:** The way I'm using Nix (imperatively) is very much an anti-pattern.

## 1. Install Nix
```
sh <(curl -L https://nixos.org/nix/install)
```

## 2. Clone Dotfiles
```
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
nix-env --install --attr nixpkgs.git nixpkgs.stow
~/.nix-profile/bin/git clone https://github.com/egladman/dotfiles-darwin.git ~/.dotfiles
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

## 5. Add Shell
```
sudo su
echo "/Users/${SUDO_USER:?}/.nix-profile/bin/bash" >> /etc/shells
exit
```

## 6. Change Shell
```
chsh -s "/Users/${USER:?}/.nix-profile/bin/bash"
```

## 7. Bind Capslock to Command

Navigate to `System Settings` > `Keyboard` > `Keyboard Shortcuts` > `Modifier Keys`
