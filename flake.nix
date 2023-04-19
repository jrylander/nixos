{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11-small";
    gotosocial.url = "path:./pkgs/gotosocial";
  };

  outputs = inputs@{ nixpkgs, gotosocial, ... }: {
    nixosConfigurations = {
      gotosocial =
      let
        system = "x86_64-linux";
      in
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            {
              nixpkgs.overlays = [
                (_: _: { gotosocial = inputs.gotosocial.packages.${system}.default; })
              ];
            }
	    ./modules/gotosocial.nix
            ./configuration.nix
          ];
        };
    };
  };

}

