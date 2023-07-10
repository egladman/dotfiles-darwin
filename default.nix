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
      direnv
      jq
      kitty
      llvm
      meld
      nix-direnv
      nodejs
      python311
      rectangle
      shellcheck
      starship
      tree
      vscode;
}