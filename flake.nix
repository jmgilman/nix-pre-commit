{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  # deadnix: skip
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = pkgs.callPackage ./lib.nix { };
        formatter = pkgs.nixpkgs-fmt;
      in
      {
        inherit lib formatter;
        devShells.default =
          (
            with pkgs;
            lib.mkLocalConfig [
              # lint
              {
                package = deadnix;
                args = [ "--edit" ];
                types = [ "nix" ];
              }
              {
                package = statix;
                args = [ "fix" ];
                types = [ "nix" ];
                pass_filenames = false;
              }
              # format
              {
                package = formatter;
                types = [ "nix" ];
              }
              {
                package = beautysh;
                args = [ "--indent-size" "2" ];
                types = [ "shell" ];
              }
            ]
          ).devShell;
      }
    );
}
