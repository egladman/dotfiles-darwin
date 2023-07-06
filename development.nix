{ pkgs ? import <nixpkgs> {} }:

{
  inherit (pkgs)
      bash
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
      shellcheck
      starship
      tree;
}