{ pkgs ? import <nixpkgs> {} }:

{
  inherit (pkgs)
      awscli2
      aws-vault
      azure-cli
      bashInteractive
      coreutils-full
      dagger
      delve
      emacs
      gcc
      gdlv
      git
      google-cloud-sdk
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
