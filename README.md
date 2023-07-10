# dotfiles-darwin

My minimal setup on MacOS

## 1. Install Nix
```
sh <(curl -L https://nixos.org/nix/install)
```

## 2. Clone Dotfiles
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

## 4. Install Nix Packages
```
nix-env --install --file default.nix
```


## 5. Fix Shortcuts to GUIs
```sh
for f in ~/.nix-profile/Applications/*; do
    ln -svf "$f" ~/Applications/
done
```

## 6. Change Default Shell
```
sudo echo "$HOME/.nix-profile/bin/bash" >> /etc/shells
chsh -s "$HOME/.nix-profile/bin/bash"
```

## 7. Bind Capslock to Command

Navigate to `System Settings` > `Keyboard` > `Keyboard Shortcuts` > `Modifier Keys`
