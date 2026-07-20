# dotfiles-darwin

My minimal development setup on MacOS.

## Setup

1. Install [Homebrew](https://brew.sh)

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

1. Clone dotfiles

```
git clone https://github.com/egladman/dotfiles-darwin.git ~/.dotfiles
```

1. Stow dotfiles

```
cd ~/.dotfiles
./stow-helper.sh
```

### Packages

1. Install packages via Homebrew

```
cd ~/.dotfiles
brew bundle install --file=Brewfile
```

### Shell

1. Add Homebrew bash to `/etc/shells`

```
sudo su
echo "/opt/homebrew/bin/bash" >> /etc/shells
exit
```

1. Update default shell to Homebrew bash

```
chsh -s /opt/homebrew/bin/bash
```

## Miscellaneous

1. Bind Capslock to Command. Navigate to `System Settings` > `Keyboard` > `Keyboard Shortcuts` > `Modifier Keys`
