{ inputs, nixpkgs, ... }:
{
  perSystem =
    { system, ... }:
    let
      projectOverlays = [
        inputs.helix-steel-system.overlays.default
        (final: prev: {
          helix-steel-system = final.helix.overrideAttrs (old: {
            cargoBuildFeatures = (
              (old.cargoBuildFeatures or [ ])
              ++ [
                "git"
                "steel"
              ]
            );
          });
        })
      ];
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
          allowUnfreePredicate = _: true;
        };
        overlays = projectOverlays;
      };
      hxx = pkgs.writeShellApplication {
        name = "hxx";
        runtimeInputs = [ pkgs.helix-steel-system ];
        text = ''
          exec ${pkgs.helix-steel-system}/bin/hx "$@"
        '';
      };
    in
    {
      packages = {
        default = hxx;
      };
    };
}
