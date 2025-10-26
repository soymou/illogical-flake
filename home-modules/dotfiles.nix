inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkOption types mkIf mkDefault;
  cfg = config.programs.illogical-impulse;

  # Use dotfiles from flake input
  dotfilesSource = inputs.dotfiles;

  # Custom packages
  customPkgs = import ../pkgs { inherit pkgs; };
  oneUIIconsPath = "${customPkgs.illogical-impulse-oneui4-icons}/share/icons";
in
{
  options.programs.illogical-impulse.dotfiles = {
    fish.enable = mkEnableOption "Use the Illogical Impulse fish config" // { default = true; };
    kitty.enable = mkEnableOption "Install kitty and use the Illogical Impulse kitty config" // { default = true; };
    starship.enable = mkEnableOption "Install starship and use the Illogical Impulse prompt" // { default = true; };
  };

  config = mkIf cfg.enable {
    # Shell programs
    programs.fish.enable = cfg.dotfiles.fish.enable;
    programs.starship.enable = cfg.dotfiles.starship.enable;

    # OneUI icons are copied and modified by the activation script below
    # (cannot use home.file symlinks because we need to modify index.theme)

    # Symlink standard icon themes
    home.file.".local/share/icons/Papirus-Dark".source = "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark";
    home.file.".local/share/icons/Papirus".source = "${pkgs.papirus-icon-theme}/share/icons/Papirus";
    home.file.".local/share/icons/Papirus-Light".source = "${pkgs.papirus-icon-theme}/share/icons/Papirus-Light";
    home.file.".local/share/icons/Adwaita".source = "${pkgs.adwaita-icon-theme}/share/icons/Adwaita";
    # hicolor is managed by the activation script below, not as a symlink

    # Configure icon theme for GTK and Qt applications
    # Use OneUI-dark which will fall back to Papirus-Dark via inheritance
    gtk = {
      enable = mkDefault true;
      iconTheme = {
        name = mkDefault "OneUI-dark";
        package = mkDefault (let
          customPkgs = import ../pkgs { inherit pkgs; };
        in customPkgs.illogical-impulse-oneui4-icons);
      };
    };

    # Set icon theme via dconf for GNOME/GTK apps
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        icon-theme = mkDefault "OneUI-dark";
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

      # Fix Qt icon theme configuration to use OneUI-dark/OneUI-light with Papirus fallback
      for qt_conf in "$targetPath/qt5ct/qt5ct.conf" "$targetPath/qt6ct/qt6ct.conf"; do
        if [ -f "$qt_conf" ]; then
          # Replace OneUI with OneUI-dark, OneUI-light stays as-is
          $DRY_RUN_CMD sed -i 's/^icon_theme=OneUI$/icon_theme=OneUI-dark/' "$qt_conf"
          $DRY_RUN_CMD sed -i 's/^icon_theme=OneUI-light$/icon_theme=OneUI-light/' "$qt_conf"
          echo "Updated Qt icon theme in $(basename $(dirname $qt_conf))"
        fi
      done

      # Fix fontconfig conf.d if it's a file instead of directory
      if [ -f "$targetPath/fontconfig/conf.d" ]; then
        $DRY_RUN_CMD rm "$targetPath/fontconfig/conf.d"
        $DRY_RUN_CMD mkdir -p "$targetPath/fontconfig/conf.d"
        echo "Fixed fontconfig/conf.d to be a directory"
      fi

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

      # Copy OneUI icon themes and modify index.theme to inherit from Papirus
      for theme in OneUI-dark OneUI-light; do
        fallback_theme="Papirus-Dark"
        if [ "$theme" = "OneUI-light" ]; then
          fallback_theme="Papirus-Light"
        fi

        # Remove existing OneUI theme directory
        if [ -e "$targetLocalShare/icons/$theme" ] || [ -L "$targetLocalShare/icons/$theme" ]; then
          $DRY_RUN_CMD rm -rf "$targetLocalShare/icons/$theme"
        fi

        # Copy OneUI theme from nix store
        oneui_source="${oneUIIconsPath}/$theme"
        if [ -d "$oneui_source" ]; then
          $DRY_RUN_CMD cp -r "$oneui_source" "$targetLocalShare/icons/$theme"
          $DRY_RUN_CMD chmod -R u+w "$targetLocalShare/icons/$theme"

          # Update the Inherits line to include Papirus
          if [ -f "$targetLocalShare/icons/$theme/index.theme" ]; then
            $DRY_RUN_CMD sed -i "s/^Inherits=.*/Inherits=$fallback_theme,hicolor/" "$targetLocalShare/icons/$theme/index.theme"
            echo "Copied and updated $theme to inherit from $fallback_theme"
          fi
        fi
      done

      # Update icon cache for all installed icon themes
      echo "Updating icon cache..."
      for theme_dir in "$targetLocalShare/icons"/*; do
        if [ -d "$theme_dir" ]; then
          theme_name=$(basename "$theme_dir")
          if [ -f "$theme_dir/index.theme" ] || [ -f "$theme_dir/icon-theme.cache" ]; then
            $DRY_RUN_CMD ${pkgs.gtk3}/bin/gtk-update-icon-cache -f -t "$theme_dir" 2>/dev/null || true
            echo "Updated icon cache for $theme_name"
          fi
        fi
      done
    '';
  };
}
