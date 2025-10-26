{ config, lib, pkgs, inputs, ... }:

let
  inherit (lib) mkEnableOption mkOption types;
  cfg = config.programs.illogical-impulse;
in
{
  # Import all sub-modules
  imports = [
    (import ./home-modules/fonts.nix inputs)
    (import ./home-modules/packages.nix inputs)
    (import ./home-modules/qt.nix inputs)
    (import ./home-modules/environment.nix inputs)
    (import ./home-modules/dotfiles.nix inputs)
  ];

  # Main options for Illogical Impulse
  options.programs.illogical-impulse = {
    enable = mkEnableOption "Enable the Illogical Impulse Hyprland configuration";

    # Internal options (not meant to be set by users)
    internal = {
      pythonEnv = mkOption {
        type = types.package;
        internal = true;
        description = "Python environment for QuickShell (internal use only)";
      };
    };
  };

  # Main configuration is now handled by sub-modules
  # Each sub-module checks cfg.enable and provides its own configuration
}
