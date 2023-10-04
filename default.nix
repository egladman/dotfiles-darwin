{ pkgs ? import <nixpkgs> {} }:

{
  inherit (pkgs)
      awscli2
      aws-vault
      bashInteractive
      coreutils-full
      delve
      emacs
      gcc
      gdlv
      git
      go
      golangci-lint
      gnupg
      direnv
      jq
      k9s
      kitty
      llvm
      meld
      nix-direnv
      nodejs
      obsidian
      postgresql
      python311
      rectangle
      shellcheck
      starship
      tree
      vscode
      yabai;
}
