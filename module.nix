{ config, lib, pkgs, inputs, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    mkDefault;

  cfg = config.services.illogical-flake;
  
  # External packages
  nurPkgs = inputs.nur.legacyPackages.${pkgs.system};
  
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

  # Determine dotfiles source
  dotfilesSource = 
    let
      src = cfg.dotfiles.source;
      # Check if source is empty (default state)
      isEmpty = src == {} || (src.url or null) == null && (src.type or null) == null;
    in
    if isEmpty then
      # Use default dotfiles from flake input
      inputs.dotfiles
    else
      let
        # Remove null values and flake=false from the attribute set
        cleanSrc = lib.filterAttrs (name: value: 
          value != null && !(name == "flake" && value == false)
        ) src;
        
        # Handle different source formats
        hasUrl = cleanSrc.url or null != null;
        hasType = cleanSrc.type or null != null;
      in
      if hasUrl && lib.hasPrefix "github:" cleanSrc.url then
        # Handle github: URLs specially
        let
          urlParts = lib.splitString "/" (lib.removePrefix "github:" cleanSrc.url);
          owner = builtins.elemAt urlParts 0;
          repo = builtins.elemAt urlParts 1;
        in
        pkgs.fetchFromGitHub {
          inherit owner repo;
          rev = cleanSrc.rev or cleanSrc.ref or "main";
          sha256 = cleanSrc.sha256 or cleanSrc.hash;
        }
      else if hasType && cleanSrc.type == "github" then
        pkgs.fetchFromGitHub {
          owner = cleanSrc.owner;
          repo = cleanSrc.repo;
          rev = cleanSrc.rev or cleanSrc.ref or "main";
          sha256 = cleanSrc.sha256 or cleanSrc.hash;
        }
      else if hasType && cleanSrc.type == "git" then
        pkgs.fetchgit {
          url = cleanSrc.url;
          rev = cleanSrc.rev;
          sha256 = cleanSrc.sha256 or cleanSrc.hash;
        }
      else
        builtins.fetchTree cleanSrc;
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];
  
  options.services.illogical-flake = {
    enable = mkEnableOption "Enable the Illogical Impulse Hyprland setup";

    user = mkOption {
      type = types.str;
      description = "User to configure for Illogical Impulse";
    };

    dotfiles = {
      source = mkOption {
        type = types.submodule {
          options = {
            # URL-based sources
            url = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "URL of the repository (github:owner/repo, git+https://..., etc.)";
            };
            
            # GitHub-specific options
            type = mkOption {
              type = types.nullOr (types.enum [ "github" "gitlab" "sourcehut" "git" "mercurial" "tarball" ]);
              default = null;
              description = "Type of source";
            };
            owner = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Repository owner (for GitHub/GitLab/SourceHut)";
            };
            repo = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Repository name (for GitHub/GitLab/SourceHut)";
            };
            
            # Git options
            rev = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Git revision/commit hash";
            };
            ref = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Git reference (branch/tag name)";
            };
            
            # Hash options
            sha256 = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "SHA256 hash of the fetched content";
            };
            hash = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "SRI hash of the fetched content (newer format)";
            };
            
            # Additional options
            flake = mkOption {
              type = types.bool;
              default = false;
              description = "Whether this is a flake";
            };
            dir = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Subdirectory within the source";
            };
            submodules = mkOption {
              type = types.nullOr types.bool;
              default = null;
              description = "Whether to fetch git submodules";
            };
            fetchSubmodules = mkOption {
              type = types.nullOr types.bool;
              default = null;
              description = "Whether to fetch git submodules (alias for submodules)";
            };
            allRefs = mkOption {
              type = types.nullOr types.bool;
              default = null;
              description = "Whether to fetch all refs";
            };
            
            # Tarball/file options
            name = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Name for the derivation";
            };
            
            # Mercurial options
            branch = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Mercurial branch";
            };
          };
        };
        default = {};
        description = ''
          Source of dotfiles as an attribute set like flake inputs with all standard Nix fetcher options.
          
          Examples:
          # GitHub
          { type = "github"; owner = "end-4"; repo = "dots-hyprland"; sha256 = "..."; }
          { url = "github:end-4/dots-hyprland"; sha256 = "..."; }
          
          # Git
          { type = "git"; url = "https://git.sr.ht/~user/dotfiles"; ref = "main"; sha256 = "..."; }
          
          # GitLab
          { type = "gitlab"; owner = "user"; repo = "dotfiles"; sha256 = "..."; }
        '';
      };

      fish.enable = mkEnableOption "Use the Illogical Impulse fish config" // { default = true; };
      kitty.enable = mkEnableOption "Install kitty and use the Illogical Impulse kitty config" // { default = true; };
      starship.enable = mkEnableOption "Install starship and use the Illogical Impulse prompt" // { default = true; };
    };

    hyprland = {
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

  };

  config = mkIf cfg.enable {
    
    # Enable home-manager
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "backup";
    
    # Hyprland configuration with portal
    programs.hyprland = mkIf cfg.hyprland.enable {
      enable = true;
      package = cfg.hyprland.package;
      xwayland.enable = true;
      portalPackage = cfg.hyprland.xdgPortalPackage;
    };

    # GeoClue for location services (required for QtPositioning)
    services.geoclue2.enable = true;



    # Required fonts
    fonts.packages = with pkgs; [
      material-symbols
      rubik
      nurPkgs.repos.skiletro.gabarito
      nerd-fonts.ubuntu
      nerd-fonts.ubuntu-mono
      nerd-fonts.jetbrains-mono
      nerd-fonts.caskaydia-cove
      nerd-fonts.fantasque-sans-mono
      nerd-fonts.mononoki
      nerd-fonts.space-mono
    ];

    # System packages
    environment.systemPackages = [
      # QuickShell with QtPositioning support (wrap both qs and quickshell)
      (pkgs.symlinkJoin {
        name = "quickshell-with-qtpositioning";
        paths = [ inputs.quickshell.packages.${pkgs.system}.default ];
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
                --prefix QML2_IMPORT_PATH : "${lib.makeSearchPath "lib/qt-6/qml" [
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
                ]}" \
                --prefix PATH : "${pythonEnv}/bin" \
                --set ILLOGICAL_IMPULSE_VIRTUAL_ENV "$out/venv"
            fi
          done
        '';
      })
      
      # Core utilities
      pkgs.cava
      pkgs.lxqt.pavucontrol-qt
      pkgs.wireplumber
      pkgs.libdbusmenu-gtk3
      pkgs.playerctl
      pkgs.brightnessctl
      pkgs.ddcutil
      pkgs.axel
      pkgs.bc
      pkgs.cliphist
      pkgs.curl
      pkgs.rsync
      pkgs.wget
      pkgs.libqalculate
      pkgs.ripgrep
      pkgs.jq
      
      # GUI applications
      pkgs.foot
      pkgs.fuzzel
      pkgs.matugen
      pkgs.mpv
      pkgs.mpvpaper
      pkgs.swappy
      pkgs.wf-recorder
      pkgs.hyprshot
      pkgs.wlogout
      
      # System utilities
      pkgs.xdg-user-dirs
      pkgs.tesseract
      pkgs.slurp
      pkgs.upower
      pkgs.wtype
      pkgs.ydotool
      pkgs.glib
      pkgs.swww
      pkgs.translate-shell
      pkgs.hyprpicker
      pkgs.imagemagick
      pkgs.ffmpeg
      pkgs.gnome-settings-daemon  # Provides gsettings
      pkgs.libnotify  # Provides notify-send
      
      # Wayland/Hyprland specific
      pkgs.hyprlock
      pkgs.hypridle
      pkgs.hyprsunset
      pkgs.wayland-protocols
      pkgs.wl-clipboard
      
      # Development libraries
      pkgs.libsoup_3
      pkgs.libportal-gtk4
      pkgs.gobject-introspection
      pkgs.sassc
      pkgs.opencv
      
      # Themes and icons
      pkgs.adw-gtk3
      pkgs.illogical-impulse-oneui4-icons
      
      # Python with required packages for wallpaper analysis
      pythonEnv
      pkgs.eza  # Modern ls replacement
      
      # GeoClue for location services (QtPositioning)
      pkgs.geoclue2
      
      # KDE/Qt packages (required for QuickShell)
      pkgs.gnome-keyring
      pkgs.kdePackages.bluedevil
      pkgs.kdePackages.bluez-qt
      pkgs.kdePackages.plasma-nm
      pkgs.kdePackages.polkit-kde-agent-1
      pkgs.networkmanager
      pkgs.kdePackages.kcmutils
      pkgs.kdePackages.plasma-workspace
      pkgs.kdePackages.systemsettings
      pkgs.kdePackages.kdialog
      
      # Qt packages for QuickShell functionality
      pkgs.kdePackages.qt5compat      # Visual effects (blur, etc.)
      pkgs.kdePackages.qtbase
      pkgs.kdePackages.qtdeclarative
      pkgs.kdePackages.qtimageformats # WEBP and other image formats
      pkgs.kdePackages.qtmultimedia   # Media playback
      pkgs.kdePackages.qtpositioning
      pkgs.kdePackages.qtquicktimeline
      pkgs.kdePackages.qtsensors
      pkgs.kdePackages.qtsvg          # SVG image support
      pkgs.kdePackages.qttools
      pkgs.kdePackages.qttranslations
      pkgs.kdePackages.qtvirtualkeyboard
      pkgs.kdePackages.qtwayland
      pkgs.kdePackages.qtwebsockets
      pkgs.kdePackages.syntax-highlighting
      
      # Additional Qt support
      pkgs.libsForQt5.qtgraphicaleffects
      pkgs.libsForQt5.qtsvg
    ] ++ lib.optionals cfg.dotfiles.fish.enable [
      pkgs.fish
    ] ++ lib.optionals cfg.dotfiles.kitty.enable [
      pkgs.kitty
    ] ++ lib.optionals cfg.dotfiles.starship.enable [
      pkgs.starship
    ];

    # Environment variables
    environment.sessionVariables = {
      QT_QPA_PLATFORMTHEME = "kde";
      QT_STYLE_OVERRIDE = "";
      ILLOGICAL_IMPULSE_DOTFILES_SOURCE = "/home/${cfg.user}/.config";
      ILLOGICAL_IMPULSE_VIRTUAL_ENV = "${pythonEnv}";
      qsConfig = "/home/${cfg.user}/.config/quickshell/ii";
    } // lib.optionalAttrs cfg.hyprland.ozoneWayland.enable {
      NIXOS_OZONE_WL = "1";
    };

    # User configuration
    users.users.${cfg.user} = {
      shell = if cfg.dotfiles.fish.enable then pkgs.fish else pkgs.bash;
    };

    # Fish shell configuration
    programs.fish.enable = cfg.dotfiles.fish.enable;

    # Starship configuration
    programs.starship.enable = cfg.dotfiles.starship.enable;

    # Setup dotfiles via environment.etc symlinks for system-wide access
    environment.etc = mkIf (cfg.dotfiles.source != "local") {
      "illogical-impulse/dotfiles".source = dotfilesSource;
    };

    # Copy all dotfiles from /dots/.config to user's .config directory
    home-manager.users.${cfg.user} = { config, ... }: {
      home.stateVersion = "25.05";

      # Disable home-manager's font management to avoid conflicts
      fonts.fontconfig.enable = false;

      # Use activation script to copy files instead of symlinking
      home.activation.copyIllogicalImpulseConfigs = config.lib.dag.entryAfter ["writeBoundary"] ''
        # Path to the config directory in the dotfiles source
        configPath="${dotfilesSource}/dots/.config"
        targetPath="$HOME/.config"

        # Directories to exclude from copying (QuickShell manages these dynamically)
        excludedDirs=("illogical-impulse")

        # Copy all items from dotfiles .config to user .config
        $DRY_RUN_CMD mkdir -p "$targetPath"

        # Create illogical-impulse directory structure if it doesn't exist
        $DRY_RUN_CMD mkdir -p "$targetPath/illogical-impulse"

        # Copy the default config.json only if it doesn't already exist
        if [ ! -f "$targetPath/illogical-impulse/config.json" ]; then
          if [ -f "$configPath/illogical-impulse/config.json" ]; then
            $DRY_RUN_CMD cp "$configPath/illogical-impulse/config.json" "$targetPath/illogical-impulse/config.json"
            $DRY_RUN_CMD chmod u+w "$targetPath/illogical-impulse/config.json"
          fi
        fi

        for item in "$configPath"/*; do
          itemName=$(basename "$item")

          # Skip excluded directories
          skip=false
          for excluded in "''${excludedDirs[@]}"; do
            if [ "$itemName" = "$excluded" ]; then
              skip=true
              break
            fi
          done

          if [ "$skip" = true ]; then
            continue
          fi

          targetItem="$targetPath/$itemName"

          # Remove existing file/directory if it exists
          if [ -e "$targetItem" ] || [ -L "$targetItem" ]; then
            $DRY_RUN_CMD rm -rf "$targetItem"
          fi

          # Copy the item (works for both files and directories)
          $DRY_RUN_CMD cp -r "$item" "$targetItem"

          # Make files writable
          $DRY_RUN_CMD chmod -R u+w "$targetItem"
        done

        echo "Copied Illogical Impulse configuration files to ~/.config"
      '';
    };
  };
}
