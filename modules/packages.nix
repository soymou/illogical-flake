{ config, lib, pkgs, ... }:

let
  cfg = config.services.illogical-flake;

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
  options.services.illogical-flake.internal.pythonEnv = lib.mkOption {
    type = lib.types.package;
    internal = true;
    default = pythonEnv;
  };

  config = lib.mkIf cfg.enable {
    # System packages for Illogical Impulse
    environment.systemPackages = with pkgs; [
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
      opencv

      # Themes and icons
      adw-gtk3
      customPkgs.illogical-impulse-oneui4-icons

      # Python with required packages for wallpaper analysis
      pythonEnv
      eza  # Modern ls replacement

      # GeoClue for location services (QtPositioning)
      geoclue2

      # KDE/Qt packages (required for QuickShell)
      gnome-keyring
      kdePackages.bluedevil
      kdePackages.bluez-qt
      kdePackages.plasma-nm
      kdePackages.polkit-kde-agent-1
      networkmanager
      kdePackages.kcmutils
      kdePackages.plasma-workspace
      kdePackages.systemsettings
      kdePackages.kdialog

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

    # GeoClue for location services (required for QtPositioning)
    services.geoclue2.enable = true;
  };
}
