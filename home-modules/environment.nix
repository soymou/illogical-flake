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
      QT_QPA_PLATFORMTHEME = "qt6ct";  # Use qt6ct for Qt6 theming
      QT_STYLE_OVERRIDE = "";
      ILLOGICAL_IMPULSE_DOTFILES_SOURCE = "${config.home.homeDirectory}/.config";
      ILLOGICAL_IMPULSE_VIRTUAL_ENV = "${pythonEnv}";
      qsConfig = "${config.home.homeDirectory}/.config/quickshell/ii";
    };

    # Install qt6ct for Qt theming
    home.packages = [ pkgs.qt6Packages.qt6ct ];
  };
}
