{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
  };

  outputs = inputs@{ nixpkgs, ... }: {
    nixosConfigurations = {
      thinknix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration-thinknix.nix
        ];
      };
      aurnix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration-aurnix.nix
        ];
      };
    };
  };
}
