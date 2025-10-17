{
  description = "Illogical Impulse - NixOS module for end-4's Hyprland dotfiles with QuickShell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Default dotfiles - can be overridden by users
    dotfiles = {
      url = "github:end-4/dots-hyprland";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, quickshell, hyprland, nur, dotfiles, ... }: {
    # The main NixOS module
    nixosModules.default = import ./module.nix;
    nixosModules.illogical-impulse = self.nixosModules.default;
  };
}
