{ config, lib, pkgs, inputs, ... }:

let
  inherit (lib) mkEnableOption mkOption types;
  cfg = config.services.illogical-flake;
in
{
  # Import all sub-modules with inputs passed explicitly
  imports = map (module: { ... }: {
    imports = [ module ];
    _module.args = { inherit inputs; };
  }) [
    ./modules/fonts.nix
    ./modules/packages.nix
    ./modules/qt.nix
    ./modules/hyprland.nix
    ./modules/environment.nix
    ./modules/dotfiles.nix
  ];

  # Main options for Illogical Impulse
  options.services.illogical-flake = {
    enable = mkEnableOption "Enable the Illogical Impulse Hyprland setup";

    user = mkOption {
      type = types.str;
      description = "User to configure for Illogical Impulse";
    };

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
