inputs:

{ config, lib, pkgs, ... }:

let
  cfg = config.programs.illogical-impulse;
  nurPkgs = inputs.nur.legacyPackages.${pkgs.system};
in
{
  config = lib.mkIf cfg.enable {
    # Install fonts as home packages
    home.packages = with pkgs; [
      material-symbols
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
