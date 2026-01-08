inputs:

{ config, lib, pkgs, ... }:

let
  cfg = config.programs.illogical-impulse;
  pythonEnv = cfg.internal.pythonEnv;

  # Override quickshell to enable Polkit
  # We must target the unwrapped package to ensure cmakeFlags take effect during build
  baseQuickshell = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  unwrappedQuickshell = if (builtins.hasAttr "unwrapped" baseQuickshell) then baseQuickshell.unwrapped else baseQuickshell;

  quickshellPackage = unwrappedQuickshell.overrideAttrs (old: {
    cmakeFlags = (old.cmakeFlags or []) ++ [ "-DSERVICE_POLKIT=ON" ];
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [
      pkgs.pkg-config
      pkgs.kdePackages.extra-cmake-modules
    ];
    buildInputs = (old.buildInputs or []) ++ [ 
      pkgs.polkit 
      pkgs.kdePackages.polkit-qt-1
      pkgs.glib
    ];
  });
in
{
  config = lib.mkIf cfg.enable {
    # Qt/KDE packages required for QuickShell functionality
    home.packages = with pkgs; [
      # QuickShell with QtPositioning support (wrap both qs and quickshell)
      (pkgs.symlinkJoin {
        name = "quickshell-with-qtpositioning";
        paths = [ quickshellPackage ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          # Create a fake venv structure for compatibility with scripts that source activate
          mkdir -p $out/venv/bin
          cat > $out/venv/bin/activate <<'EOF'
# Fake activate script for Nix Python environment
# The Python environment is already available in PATH
# Provide a deactivate function for compatibility
deactivate() {
    # In a real venv, this would restore the old PATH
    # Since we're using Nix, there's nothing to deactivate
    :
}
EOF

          # Wrap both quickshell and qs commands with Qt module paths and Python
          for binary in quickshell qs; do
            if [ -f "$out/bin/$binary" ]; then
              wrapProgram "$out/bin/$binary" \
                --prefix QML2_IMPORT_PATH : "${quickshellPackage}/lib/qt-6/qml:$out/lib/qt-6/qml:${lib.makeSearchPath "lib/qt-6/qml" [
                  pkgs.kdePackages.qtpositioning
                  pkgs.kdePackages.qtbase
                  pkgs.kdePackages.qtdeclarative
                  pkgs.kdePackages.qtmultimedia
                  pkgs.kdePackages.qtsensors
                  pkgs.kdePackages.qtsvg
                  pkgs.kdePackages.qtwayland
                  pkgs.kdePackages.qt5compat
                  pkgs.kdePackages.qtimageformats
                  pkgs.kdePackages.qtquicktimeline
                  pkgs.kdePackages.qttools
                  pkgs.kdePackages.qttranslations
                  pkgs.kdePackages.qtvirtualkeyboard
                  pkgs.kdePackages.qtwebsockets
                  pkgs.kdePackages.syntax-highlighting
                  pkgs.kdePackages.kirigami.unwrapped
                ]}" \
                --prefix QT_PLUGIN_PATH : "${lib.makeSearchPath "lib/qt-6/plugins" [
                  pkgs.kdePackages.qtbase
                  pkgs.kdePackages.qtsvg
                  pkgs.kdePackages.qtwayland
                  pkgs.kdePackages.qtimageformats
                  pkgs.qt6Packages.qt6ct
                ]}" \
                --set QT_QPA_PLATFORMTHEME "qt6ct" \
                --prefix PATH : "${pythonEnv}/bin" \
                --set ILLOGICAL_IMPULSE_VIRTUAL_ENV "$out/venv" \
                --prefix XDG_DATA_DIRS : "\$HOME/.local/share:\$HOME/.nix-profile/share:/etc/profiles/per-user/$USER/share:/nix/var/nix/profiles/default/share:/run/current-system/sw/share"
            fi
          done
        '';
      })

      # Qt packages for QuickShell functionality
      kdePackages.qt5compat      # Visual effects (blur, etc.)
      kdePackages.qtbase
      kdePackages.qtdeclarative
      kdePackages.qtimageformats # WEBP and other image formats
      kdePackages.qtmultimedia   # Media playback
      kdePackages.qtpositioning
      kdePackages.qtquicktimeline
      kdePackages.qtsensors
      kdePackages.qtsvg          # SVG image support
      kdePackages.qttools
      kdePackages.qttranslations
      kdePackages.qtvirtualkeyboard
      kdePackages.qtwayland
      kdePackages.qtwebsockets
      kdePackages.syntax-highlighting
      kdePackages.kirigami
    ];
  };
}
