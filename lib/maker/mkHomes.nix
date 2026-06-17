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
    lib = nixpkgs.lib;
in
    { buildContext, buildInventory }:
        let
            inherit (buildInventory) homesPath homes commonModules;
            inherit (buildContext) overlays extraArgs;
            commonModulesResolved = myLib.modules.resolvePaths commonModules;

            mkHome = home:
                let
                    # Cook pkgs
                    pkgs = import nixpkgs {
                        system = home.system;
                        config.allowUnfree = true;
                        overlays = overlays;
                    };
                    
                    # Home specific modules
                    hmModules = [ { programs.home-manager.enable = true; } ];
                    homeModules = [ "${self}/${homesPath}/${home.confDir}" ];
                in
                home-manager.lib.homeManagerConfiguration {
                    pkgs = pkgs;
                    extraSpecialArgs = extraArgs;
                    modules = commonModulesResolved ++ homeModules ++ hmModules;
                };

        in 
            builtins.mapAttrs (name: home: mkHome home) homes
