{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
          allowUnfreePredicate = _: true;
        };
      };
    in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          nixd
          nil
          alejandra
          nixpkgs-fmt
        ];
      };
    };
}
