# Illogical Impulse NixOS Flake

A NixOS flake for [end-4's Illogical Impulse Hyprland dotfiles](https://github.com/end-4/dots-hyprland) with QuickShell integration.

**Based on**: [xBLACKICEx/end-4-dots-hyprland-nixos](https://github.com/xBLACKICEx/end-4-dots-hyprland-nixos)

## About

This flake provides a NixOS module that installs and configures end-4's beautiful Material Design 3 Hyprland desktop environment. It includes:

- **Hyprland**: Modern tiling Wayland compositor
- **QuickShell**: Qt-based shell for the desktop interface  
- **Material Design 3**: Dynamic theming based on wallpaper colors
- **Complete desktop environment**: All required applications and utilities

## Features

- Material Design 3 interface with dynamic wallpaper-based theming
- Power management (hypridle, hyprlock) and blue light filtering (hyprsunset)
- System controls, audio management, and screenshot tools
- Flexible dotfiles sourcing from any Git repository
- Fish shell, Kitty terminal, and Starship prompt integration
- All required fonts and dependencies included

## Installation

1. Add this flake to your `flake.nix` inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    illogical-impulse.url = "github:soymou/illogical-flake";
  };

  outputs = { nixpkgs, illogical-impulse, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { 
        inherit (illogical-impulse.inputs) quickshell hyprland nur dotfiles;
      };
      modules = [
        ./configuration.nix
        illogical-impulse.nixosModules.default
      ];
    };
  };
}
```

2. Configure in your `configuration.nix`:

```nix
services.illogical-impulse = {
  enable = true;
  user = "yourusername";
};
```

## Configuration Options

### Basic Usage (uses end-4's original dotfiles)

```nix
services.illogical-impulse = {
  enable = true;
  user = "mou";
  hyprland = {
    enable = true;
    ozoneWayland.enable = true;  # For Chrome/Chromium Wayland support
  };
};
```

### Using Your Own Fork

```nix
services.illogical-impulse = {
  enable = true;
  user = "mou";
  dotfiles = {
    source = {
      url = "github:yourusername/dots-hyprland";
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
  };
};
```

### Advanced Dotfiles Configuration

#### GitHub Repository (URL format)
```nix
dotfiles = {
  source = {
    url = "github:end-4/dots-hyprland";
    sha256 = "sha256-...";
    rev = "main";  # optional: specific branch/tag/commit
  };
};
```

#### GitHub Repository (attribute format)
```nix
dotfiles = {
  source = {
    type = "github";
    owner = "end-4";
    repo = "dots-hyprland";
    sha256 = "sha256-...";
    rev = "main";
  };
};
```

#### Git Repository
```nix
dotfiles = {
  source = {
    type = "git";
    url = "https://git.sr.ht/~user/dotfiles";
    rev = "main";
    sha256 = "sha256-...";
  };
};
```

#### GitLab
```nix
dotfiles = {
  source = {
    type = "gitlab";
    owner = "user";
    repo = "dotfiles";
    sha256 = "sha256-...";
  };
};
```

### Application Configuration

```nix
dotfiles = {
  fish.enable = true;     # Fish shell config (default: true)
  kitty.enable = true;    # Kitty terminal (default: true)  
  starship.enable = true; # Starship prompt (default: true)
};
```

### Hyprland Configuration

```nix
hyprland = {
  enable = true;          # Enable Hyprland (default: true)
  
  # Monitor setup
  monitor = [
    ",preferred,auto,1"                 # Default monitor
    "DP-1,1920x1080@60,0x0,1"         # Specific monitor config
  ];
  
  # Custom Hyprland package (optional)
  package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  xdgPortalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  
  ozoneWayland.enable = true;  # Chrome/Chromium Wayland support
};
```

## Getting SHA256 Hash

To get the SHA256 hash for any repository:

```bash
nix-prefetch-url --unpack https://github.com/owner/repo/archive/main.tar.gz
```

Or use `lib.fakeSha256` initially, then replace with the correct hash from the error message.

## What's Included

### Desktop Environment
- **Hyprland**: Tiling Wayland compositor with smooth animations
- **QuickShell**: Modern Qt-based desktop shell with Material Design 3
- **Dynamic theming**: Colors automatically generated from wallpaper
- **Wallpaper management**: hyprpaper and swww for wallpaper handling

### System Integration
- **Power management**: hypridle for idle detection, hyprlock for screen locking
- **Blue light filtering**: hyprsunset for automatic color temperature adjustment
- **Audio controls**: PipeWire integration with pavucontrol-qt
- **Media controls**: playerctl for media key handling
- **Screenshot tools**: hyprshot and swappy for screenshots and annotation
- **System monitoring**: Built-in system resource monitoring

### Applications & Tools
- **Terminal**: Kitty terminal with custom configuration
- **Shell**: Fish shell with custom functions and aliases
- **Prompt**: Starship prompt with custom styling
- **File manager**: Integrated file management
- **Application launcher**: Fuzzel launcher with custom styling

### Fonts & Theming
- **Material Symbols**: Google's Material Design icon font
- **Nerd Fonts**: Programming fonts with icon support
- **Custom fonts**: Rubik, Gabarito, and other UI fonts
- **Complete theme**: Consistent Material Design 3 theming across all applications

## System Requirements

- **NixOS**: 23.11 or later (24.11+ recommended)
- **Graphics**: Hardware-accelerated graphics (recommended)
- **Memory**: 4GB+ RAM recommended
- **Storage**: Additional ~2GB for all packages and dependencies

## Troubleshooting

### SHA256 Mismatch
Update the `dotfiles.source.sha256` value when the repository changes.

### QuickShell Not Starting
- Ensure your user is set correctly in the configuration
- Check that all required inputs are properly passed in `specialArgs`

### Missing Fonts or Icons
- The module includes all required fonts automatically
- If icons appear as text, rebuild your system: `sudo nixos-rebuild switch`

### Performance Issues
- Ensure hardware graphics acceleration is enabled
- Consider disabling animations if running on older hardware

## Credits

- **[end-4](https://github.com/end-4)** - Original Illogical Impulse dotfiles and design
- **[xBLACKICEx](https://github.com/xBLACKICEx)** - Original NixOS flake implementation this is based on
- **[outfoxxed](https://git.outfoxxed.me/outfoxxed/quickshell)** - QuickShell development
- **[hyprwm](https://github.com/hyprwm)** - Hyprland compositor

## License

This flake packaging follows the same license as the original dotfiles. See the [original repository](https://github.com/end-4/dots-hyprland) for license details.

## Contributing

This flake aims to provide a clean, maintainable way to use end-4's dotfiles on NixOS. Feel free to open issues or submit pull requests for improvements.
