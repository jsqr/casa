{ config, pkgs, lib, inputs, ... }:

let
  unfreePkgs = import inputs.nixpkgs-unstable { inherit (pkgs) system; config.allowUnfree = true; };
in
{
  imports = [ ./common.nix ];

  home.username = "jj";
  home.homeDirectory = "/home/jj";

  targets.genericLinux.enable = true;

  services.ollama.enable = true;
  
  home.packages = [ pkgs.code-server unfreePkgs.claude-code ];

  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
      hosts = [ "https://github.com" ];
    };
  };
}
