{
  description = "Advent of Code 2022 in Zig!";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    zig-overlay.url = "github:mitchellh/zig-overlay";
    zig-overlay.inputs.nixpkgs.follows = "nixpkgs";
    nur-packages-dfrankland.url = "github:dfrankland/nur-packages";
    nur-packages-dfrankland.inputs.nixpkgs.follows = "nixpkgs";
    known-folders.url = "github:ziglibs/known-folders";
    known-folders.flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, zig-overlay, nur-packages-dfrankland, known-folders, ... }:
    with flake-utils.lib;
    eachSystem allSystems (system:
      let
        overlays = [
          zig-overlay.overlays.default
          (final: prev: {
            inherit known-folders;
          })
        ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        nur-packages-dfrankland-pkgs = import nur-packages-dfrankland { inherit pkgs; };
      in
      with pkgs;
      {
        devShell = mkShell {
          buildInputs = [
            zigpkgs."0.10.0"
            nur-packages-dfrankland-pkgs.zigmod
            nur-packages-dfrankland-pkgs.zls
          ];

          shellHook = ''
            # none
          '';
        };
      }
    );
}
