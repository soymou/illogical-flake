inputs:

{ config, lib, pkgs, ... }:

let
  cfg = config.programs.illogical-impulse;
  pythonEnv = cfg.internal.pythonEnv;
  
  # The raw QuickShell package
  qsPackage = inputs.quickshell.packages.${pkgs.system}.default;
  
  # Runtime dependencies
  qtImports = [
    pkgs.kdePackages.qtbase
    pkgs.kdePackages.qtdeclarative
    pkgs.kdePackages.qtsvg
    pkgs.kdePackages.qtwayland
    pkgs.kdePackages.qt5compat
    pkgs.kdePackages.qtimageformats
    pkgs.kdePackages.qtmultimedia
    pkgs.kdePackages.qtpositioning
    pkgs.kdePackages.qtsensors
    pkgs.kdePackages.qtquicktimeline
    pkgs.kdePackages.qttools
    pkgs.kdePackages.qttranslations
    pkgs.kdePackages.qtvirtualkeyboard
    pkgs.kdePackages.qtwebsockets
    pkgs.kdePackages.syntax-highlighting
    pkgs.kdePackages.kirigami.unwrapped
  ];
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ 
      # WRAPPED QuickShell (named "qs" to match config expectation)
      # This replaces the raw package to avoid collisions and force environment
      (pkgs.writeShellScriptBin "qs" ''
        # Force environment variables for reliability
        export QT_PLUGIN_PATH="${lib.makeSearchPath "lib/qt-6/plugins" qtImports}:${lib.makeSearchPath "lib/qt6/plugins" qtImports}:${lib.makeSearchPath "lib/plugins" qtImports}"
        export QML2_IMPORT_PATH="${lib.makeSearchPath "lib/qt-6/qml" qtImports}"
        export XDG_DATA_DIRS="${lib.makeSearchPath "share" [ pkgs.adwaita-icon-theme pkgs.hicolor-icon-theme ]}:$HOME/.nix-profile/share:$HOME/.local/share:/run/current-system/sw/share:$XDG_DATA_DIRS"
        export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
        export QT_QPA_PLATFORMTHEME=gtk3
        
        # Launch the real binary
        exec ${qsPackage}/bin/qs "$@"
      '')
    ] ++ qtImports ++ [
      pkgs.qt6Packages.qt6ct
      pythonEnv
    ];
  };
}