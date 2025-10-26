inputs:

{ config, lib, pkgs, ... }:

let
  cfg      = config.services.illogical-flake;
  nurPkgs  = inputs.nur.legacyPackages.${pkgs.system};
  customPkgs = import ../pkgs { inherit pkgs; };
in
{
  config = lib.mkIf cfg.enable {
    fonts.packages = with pkgs; [
      customPkgs.material-symbols
      rubik
      nurPkgs.repos.skiletro.gabarito
      nerd-fonts.ubuntu
      nerd-fonts.ubuntu-mono
      nerd-fonts.jetbrains-mono
      nerd-fonts.caskaydia-cove
      nerd-fonts.fantasque-sans-mono
      nerd-fonts.mononoki
      nerd-fonts.space-mono
    ];
  };
}
