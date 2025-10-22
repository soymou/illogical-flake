{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.services.illogical-flake;
  nurPkgs = inputs.nur.legacyPackages.${pkgs.system};
in
{
  config = lib.mkIf cfg.enable {
    # Required fonts for the Illogical Impulse setup
    fonts.packages = with pkgs; [
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
