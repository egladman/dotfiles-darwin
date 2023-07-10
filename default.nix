{ pkgs ? import <nixpkgs> {} }:

{
  inherit (pkgs)
      bashInteractive
      coreutils-full
      emacs
      gcc
      git
      go
      gnupg
      jq
      kitty
      meld
      nodejs
      rectangle
      shellcheck
      starship
      tree
      vscode;
}