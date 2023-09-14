{ pkgs ? import <nixpkgs> {} }:

{
  inherit (pkgs)
      awscli2
      aws-vault
      bashInteractive
      coreutils-full
      emacs
      gcc
      git
      go
      gnupg
      direnv
      jq
      kitty
      llvm
      meld
      nix-direnv
      nodejs
      obsidian
      python311
      rectangle
      shellcheck
      starship
      tree
      vscode
      yabai;
}