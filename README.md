# Illogical Impulse Flake

Home-manager module for [end-4's Illogical Impulse Hyprland dotfiles](https://github.com/end-4/dots-hyprland) with QuickShell integration.

**Based on**: [xBLACKICEx/end-4-dots-hyprland-nixos](https://github.com/xBLACKICEx/end-4-dots-hyprland-nixos)

## Prerequisites

You need to configure these at the system level (in `configuration.nix`):

```nix
# Enable Hyprland
programs.hyprland.enable = true;

# Required services
services.geoclue2.enable = true;  # For QtPositioning
services.networkmanager.enable = true;  # For network management
services.upower.enable = true; # For battery status

# System fonts (optional but recommended)
fonts.packages = with pkgs; [
  rubik
  nerd-fonts.ubuntu
  nerd-fonts.jetbrains-mono
];
```

## Installation

### Minimal Setup

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    illogical-flake = {
      url = "github:soymou/illogical-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, illogical-flake, ... }: {
    homeConfigurations.yourusername = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        illogical-flake.homeManagerModules.default
        {
          programs.illogical-impulse.enable = true;
        }
      ];
    };
  };
}
```

### Full Configuration

```nix
{
  programs.illogical-impulse = {
    enable = true;

    # Customize shell tools (all enabled by default)
    dotfiles = {
      fish.enable = true;     # Fish shell with custom config
      kitty.enable = true;    # Kitty terminal emulator
      starship.enable = true; # Starship prompt
    };
    
    # Hyprland Plugins (Declarative installation & loading)
    hyprland.plugins = [
      pkgs.hyprlandPlugins.hyprbars
      pkgs.hyprlandPlugins.hyprexpo
      # Add any other plugins available in nixpkgs
    ];
  };
}
```

### Using Your Own Dotfiles Fork

Override the `dotfiles` input to use your own fork:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Your custom dotfiles
    dotfiles = {
      url = "git+https://github.com/yourusername/dots-hyprland?submodules=1";
      flake = false;
    };

    illogical-flake = {
      url = "github:soymou/illogical-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.dotfiles.follows = "dotfiles";  # Override to use your dotfiles
    };
  };

  outputs = { nixpkgs, home-manager, illogical-flake, ... }: {
    homeConfigurations.yourusername = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        illogical-flake.homeManagerModules.default
        {
          programs.illogical-impulse.enable = true;
        }
      ];
    };
  };
}
```

**Important**: The dotfiles repository uses git submodules for some components (like Material shapes). You **must** include `?submodules=1` in the URL to fetch them properly.

You can use any source supported by Nix flakes:
- **GitHub with submodules**: `url = "git+https://github.com/owner/repo?submodules=1";`
- **Git**: `url = "git+https://example.com/repo.git?submodules=1";`
- **Local path**: `url = "path:/home/user/dotfiles";` (useful for development)
  - For local paths, ensure submodules are initialized: `git submodule update --init --recursive`

## What's Included

- **QuickShell**: Qt6-based desktop shell with Material Design 3
- **Dynamic Theming**: Automatic color palette generation from wallpapers
- **Complete UI**: Bar, sidebars, lock screen, logout menu
- **Power Management**: hypridle, hyprlock, hyprsunset
- **Tools**: fuzzel launcher, wlogout, hyprshot, hyprpicker, and more
- **Python Environment**: Pre-configured for wallpaper analysis scripts
- **Qt/QML Modules**: Complete Qt6 setup including QtPositioning
- **Fonts**: Material Symbols, Nerd Fonts, and UI fonts

## Updating

```bash
# Update the flake
nix flake update illogical-flake
home-manager switch --flake .#yourusername

# Update your dotfiles
nix flake update dotfiles
home-manager switch --flake .#yourusername
```

## Credits

- **[end-4](https://github.com/end-4)** - Creator of the Illogical Impulse dotfiles
- **[xBLACKICEx](https://github.com/xBLACKICEx)** - Original NixOS flake
- **[outfoxxed](https://git.outfoxxed.me/outfoxxed/quickshell)** - QuickShell developer
