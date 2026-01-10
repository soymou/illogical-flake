inputs:

{ config, lib, pkgs, ... }:

let
  cfg = config.programs.illogical-impulse;
  pythonEnv = cfg.internal.pythonEnv;
in
{
  config = lib.mkIf cfg.enable {
    # Environment variables for Illogical Impulse
    home.sessionVariables = {
      # QT_QPA_PLATFORMTHEME = "qt6ct";  # Use qt6ct for Qt6 theming
      QT_STYLE_OVERRIDE = "";
      ILLOGICAL_IMPULSE_DOTFILES_SOURCE = "${config.home.homeDirectory}/.config";
      qsConfig = "${config.home.homeDirectory}/.config/quickshell/ii";
    };
    
    # Ensure variables are available to systemd services (and Hyprland)
    systemd.user.sessionVariables = config.home.sessionVariables;

    # Install qt6ct for Qt theming
    home.packages = [ pkgs.qt6Packages.qt6ct ];
  };
}
