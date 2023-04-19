{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-21.11-small;
    nixpkgs-unstable.url = github:NixOS/nixpkgs/nixos-unstable;
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
      in
      {
        packages = (import ./default.nix) {
            buildGo120Module = pkgs-unstable.buildGo120Module;
            fetchFromGitHub = pkgs.fetchFromGitHub;
          };
      }
    );
}
