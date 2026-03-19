{
  description = "A Nix-flake-based Node.js development environment";
  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0";
  outputs =
    { self, ... }@inputs:
    let
      supportedSystems = [
        "aarch64-linux"
      ];
      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import inputs.nixpkgs { inherit system; };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default =
            pkgs.mkShell
              {
                packages =
                  with pkgs;
                  [
                    nodejs
                    nodePackages.npm
                    bun
                  ];
              };
          }
      );
    };
}
