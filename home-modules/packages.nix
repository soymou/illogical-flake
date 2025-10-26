inputs:

{ config, lib, pkgs, ... }:

let
  cfg = config.programs.illogical-impulse;

  # Custom packages
  customPkgs = import ../pkgs { inherit pkgs; };

  # Python environment for quickshell wallpaper analysis
  pythonEnv = pkgs.python3.withPackages (ps: [
    ps.build
    ps.cffi
    ps.click
    ps."dbus-python"
    ps."kde-material-you-colors"
    ps.libsass
    ps.loguru
    ps."material-color-utilities"
    ps.materialyoucolor
    ps.numpy
    ps.pillow
    ps.psutil
    ps.pycairo
    ps.pygobject3
    ps.pywayland
    ps.setproctitle
    ps."setuptools-scm"
    ps.tqdm
    ps.wheel
    ps."pyproject-hooks"
    ps.opencv4
  ]);
in
{
  # Export pythonEnv for use in other modules
  options.programs.illogical-impulse.internal.pythonEnv = lib.mkOption {
    type = lib.types.package;
    internal = true;
    default = pythonEnv;
  };

  config = lib.mkIf cfg.enable {
    # User packages for Illogical Impulse
    home.packages = with pkgs; [
      # Core utilities
      cava
      lxqt.pavucontrol-qt
      wireplumber
      libdbusmenu-gtk3
      playerctl
      brightnessctl
      ddcutil
      axel
      bc
      cliphist
      curl
      rsync
      wget
      libqalculate
      ripgrep
      jq

      # GUI applications
      foot
      fuzzel
      matugen
      mpv
      mpvpaper
      swappy
      wf-recorder
      hyprshot
      wlogout

      # System utilities
      xdg-user-dirs
      tesseract
      slurp
      upower
      wtype
      ydotool
      glib
      swww
      translate-shell
      hyprpicker
      imagemagick
      ffmpeg
      gnome-settings-daemon  # Provides gsettings
      libnotify  # Provides notify-send
      easyeffects
      grim

      # Wayland/Hyprland specific
      hyprlock
      hypridle
      hyprsunset
      wayland-protocols
      wl-clipboard

      # Development libraries
      libsoup_3
      libportal-gtk4
      gobject-introspection
      sassc
      # opencv is included in pythonEnv, no need to include it separately

      # Themes and icons
      adw-gtk3
      customPkgs.illogical-impulse-oneui4-icons
      papirus-icon-theme  # Primary icon theme
      adwaita-icon-theme  # GNOME fallback icons
      hicolor-icon-theme  # Base icon theme (required by most themes)
      # Note: breeze-icons not included to avoid Qt5/Qt6 conflicts with system config

      # Python with required packages for wallpaper analysis
      pythonEnv
      eza  # Modern ls replacement

      # Minimal Qt/KDE packages (only what's needed for functionality)
      gnome-keyring  # Keyring support
      kdePackages.bluedevil  # Bluetooth management (for kcm_bluetooth)
      kdePackages.plasma-nm  # Network management (for kcm_networkmanagement)
      kdePackages.polkit-kde-agent-1  # Polkit authentication agent
      kdePackages.kdialog  # Dialog prompts

      # Additional Qt support
      libsForQt5.qtgraphicaleffects
      libsForQt5.qtsvg
    ] ++ lib.optionals cfg.dotfiles.fish.enable [
      fish
    ] ++ lib.optionals cfg.dotfiles.kitty.enable [
      kitty
    ] ++ lib.optionals cfg.dotfiles.starship.enable [
      starship
    ];
  };
}
