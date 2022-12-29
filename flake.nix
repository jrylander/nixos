{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11-small";
  };

  outputs = inputs@{ nixpkgs, ... }: {
    nixosConfigurations = {
      syncnix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
        ];
      };
    };
  };

}
