{ config, lib, pkgs, inputs, ... }:

let
  inherit (lib) mkEnableOption mkOption types mkIf;
  cfg = config.services.illogical-flake;
in
{
  options.services.illogical-flake.hyprland = {
    enable = mkEnableOption "Enable Hyprland window manager" // { default = true; };

    monitor = mkOption {
      type = types.listOf types.str;
      default = [ ",preferred,auto,1" ];
      description = "Monitor preferences passed to Hyprland.";
    };

    package = mkOption {
      type = types.package;
      default = inputs.hyprland.packages.${pkgs.system}.hyprland;
      description = "Hyprland package to use.";
    };

    xdgPortalPackage = mkOption {
      type = types.package;
      default = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
      description = "xdg-desktop-portal implementation for Hyprland.";
    };

    ozoneWayland.enable = mkEnableOption "Set NIXOS_OZONE_WL=1 for Chromium based apps";
  };

  config = mkIf (cfg.enable && cfg.hyprland.enable) {
    # Enable Hyprland with xwayland and portal support
    programs.hyprland = {
      enable = true;
      package = cfg.hyprland.package;
      xwayland.enable = true;
      portalPackage = cfg.hyprland.xdgPortalPackage;
    };
  };
}
