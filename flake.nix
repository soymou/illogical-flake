{
  description = "Illogical Impulse - NixOS module for end-4's Hyprland dotfiles with QuickShell";

  inputs = {
    # These will be overridden by the user's flake
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Default dotfiles - can be overridden by users
    dotfiles = {
      url = "github:end-4/dots-hyprland";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, quickshell, hyprland, nur, home-manager, dotfiles, ... }: {
    # The main NixOS module
    nixosModules.default = { config, lib, pkgs, ... }: (import ./module.nix) {
      inherit config lib pkgs;
      inputs = { inherit quickshell hyprland nur home-manager dotfiles; };
    };
    nixosModules.illogical-flake = self.nixosModules.default;
  };
}
