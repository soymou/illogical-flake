inputs:

{ config, lib, pkgs, ... }:

let
  cfg = config.services.illogical-flake;
  pythonEnv = cfg.internal.pythonEnv;
in
{
  config = lib.mkIf cfg.enable {
    # Environment variables for Illogical Impulse
    environment.sessionVariables = {
      QT_QPA_PLATFORMTHEME = "kde";
      QT_STYLE_OVERRIDE = "";
      ILLOGICAL_IMPULSE_DOTFILES_SOURCE = "/home/${cfg.user}/.config";
      ILLOGICAL_IMPULSE_VIRTUAL_ENV = "${pythonEnv}";
      qsConfig = "/home/${cfg.user}/.config/quickshell/ii";
    } // lib.optionalAttrs cfg.hyprland.ozoneWayland.enable {
      NIXOS_OZONE_WL = "1";
    };
  };
}
