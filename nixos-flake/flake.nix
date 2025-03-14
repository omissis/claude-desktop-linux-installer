{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-desktop.url = "github:k3d3/claude-desktop-linux-flake";
  };

  outputs = { nixpkgs, home-manager, claude-desktop, ... }: {
    homeConfigurations."astrosteveo" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = { 
        inherit claude-desktop;
        username = "astrosteveo";
      };
      modules = [ ./home.nix ];
    };
  };
}
