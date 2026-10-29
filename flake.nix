{
  description = "Nix package for pi-bolt";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      packages = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.callPackage ./nix/package.nix { };
      });
    };
}
