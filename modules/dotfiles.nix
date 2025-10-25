inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkOption types mkIf;
  cfg = config.services.illogical-flake;

  # Use dotfiles from flake input
  dotfilesSource = inputs.dotfiles;
in
{
  # Import home-manager at the top level
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  options.services.illogical-flake.dotfiles = {
    fish.enable = mkEnableOption "Use the Illogical Impulse fish config" // { default = true; };
    kitty.enable = mkEnableOption "Install kitty and use the Illogical Impulse kitty config" // { default = true; };
    starship.enable = mkEnableOption "Install starship and use the Illogical Impulse prompt" // { default = true; };
  };

  config = mkIf cfg.enable {

    # Setup home-manager
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "backup";

    # User shell configuration
    users.users.${cfg.user} = {
      shell = if cfg.dotfiles.fish.enable then pkgs.fish else pkgs.bash;
    };

    # Shell programs
    programs.fish.enable = cfg.dotfiles.fish.enable;
    programs.starship.enable = cfg.dotfiles.starship.enable;

    # Setup dotfiles via environment.etc symlinks for system-wide access
    environment.etc."illogical-impulse/dotfiles".source = dotfilesSource;

    # Copy all dotfiles from /dots/.config to user's .config directory
    home-manager.users.${cfg.user} = { config, pkgs, ... }:
    let
      customPkgs = import ../pkgs { inherit pkgs; };
    in {
      home.stateVersion = "25.05";

      # Disable home-manager's font management to avoid conflicts
      fonts.fontconfig.enable = false;

      # Symlink OneUI icon themes for illogical-impulse
      home.file.".local/share/icons/OneUI-dark".source = "${customPkgs.illogical-impulse-oneui4-icons}/share/icons/OneUI-dark";
      home.file.".local/share/icons/OneUI-light".source = "${customPkgs.illogical-impulse-oneui4-icons}/share/icons/OneUI-light";

      # Configure icon theme for GTK and Qt applications (Papirus for non-KDE setup)
      gtk = {
        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
      };

      # Set icon theme via dconf for GNOME/GTK apps
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          icon-theme = "Papirus-Dark";
        };
      };

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

        # Copy .local/share contents (icons, etc.)
        localSharePath="${dotfilesSource}/dots/.local/share"
        targetLocalShare="$HOME/.local/share"

        if [ -d "$localSharePath" ]; then
          $DRY_RUN_CMD mkdir -p "$targetLocalShare"

          for item in "$localSharePath"/*; do
            if [ -e "$item" ]; then
              itemName=$(basename "$item")
              targetItem="$targetLocalShare/$itemName"

              # Remove existing file/directory if it exists
              if [ -e "$targetItem" ] || [ -L "$targetItem" ]; then
                $DRY_RUN_CMD rm -rf "$targetItem"
              fi

              # Copy the item
              $DRY_RUN_CMD cp -r "$item" "$targetItem"

              # Make files writable
              $DRY_RUN_CMD chmod -R u+w "$targetItem"
            fi
          done

          # Move illogical-impulse icon to the correct hicolor theme directory if it exists
          if [ -f "$targetLocalShare/icons/illogical-impulse.svg" ]; then
            $DRY_RUN_CMD mkdir -p "$targetLocalShare/icons/hicolor/scalable/apps"
            $DRY_RUN_CMD mv "$targetLocalShare/icons/illogical-impulse.svg" "$targetLocalShare/icons/hicolor/scalable/apps/"
            echo "Moved illogical-impulse icon to hicolor theme directory"
          fi

          echo "Copied Illogical Impulse .local/share files to ~/.local/share"
        fi
      '';
    };
  };
}
