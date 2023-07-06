{ pkgs ? import <nixpkgs> {} }:

{
  inherit (pkgs)
      bash
      coreutils
      emacs
      gcc
      git
      go
      gnupg
      kitty
      meld
      nodejs
}