{
  # files in current directory
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    helix-steel-system = {
      url = "github:mattwparas/helix/steel-event-system";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      supportedSystems = [ "aarch64-linux" ];
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./flake/devshells.nix
        ./flake/packages.nix
      ];
      systems = supportedSystems;
    };

}
