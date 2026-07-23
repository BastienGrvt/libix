/**
    Build Home Manager configurations from a context and a home inventory.

    # Type
    mkHome :: { buildContext, buildInventory } -> AttrSet HomeManagerConfiguration

    # Args
    - buildContext: { invOverlays, extraArgs }
    - buildInventory: { homesPath, homes, commonModules }
        - homes: AttrSet of { confDir, system, commonModules }
*/

{ inputs, myLib }:

let
    inherit (inputs) self nixpkgs home-manager;
    hasUnstable = inputs ? nixpkgs-unstable;
    lib = nixpkgs.lib;
in
    { buildContext, buildInventory }:
        let
            inherit (buildInventory) homesPath homes commonModules;
            inherit (buildContext) overlays extraArgs;
            commonModulesResolved = myLib.modules.resolvePaths commonModules;

            mkPkgs = pkgsSource: system:
                import pkgsSource {
                    inherit system overlays;
                    config.allowUnfree = true;
                };

            mkHome = home:
                let
                    pkgs = mkPkgs nixpkgs home.system;

                    # Special args with unstable pkgs
                    specialArgs = extraArgs // lib.optionalAttrs hasUnstable {
                        pkgs-unstable = mkPkgs inputs.nixpkgs-unstable home.system;
                    };

                    hmModules = [ { programs.home-manager.enable = true; } ];
                    homeModules = [ "${self}/${homesPath}/${home.confDir}" ];
                in
                home-manager.lib.homeManagerConfiguration {
                    inherit pkgs;
                    extraSpecialArgs = specialArgs;
                    modules = commonModulesResolved ++ homeModules ++ hmModules;
                };

        in
            builtins.mapAttrs (name: home: mkHome home) homes
