/**
  Build Nix-on-Droid configurations from a context and a droid inventory.

  # Type
  mkNixOnDroid :: { buildContext, buildInventory } -> AttrSet NixOnDroidConfiguration

  # Args
  - buildContext: { invOverlays, extraArgs }
  - buildInventory: { droidsPath, droids, commonModules }
    - droids: AttrSet of { confDir, system, commonModules }
*/

{ inputs, myLib }:

let
    inherit (inputs) self nixpkgs nix-on-droid;
    lib = nixpkgs.lib;
in
    { buildContext, buildInventory }:
        let
            inherit (buildInventory) droidsPath droids commonModules;
            inherit (buildContext) overlays extraArgs;
            commonModulesResolved = myLib.modules.resolvePaths commonModules;

            mkDroid = droid:
                let
                    # Cook pkgs
                    pkgs = import nixpkgs {
                        system = droid.system;
                        config.allowUnfree = true;
                        overlays = overlays; 
                    };

                    # Droid specific modules
                    droidModules = [ 
                        "${self}/${droidsPath}/${droid.confDir}" 
                    ];
                in
                    nix-on-droid.lib.nixOnDroidConfiguration {
                        pkgs = pkgs;
                        extraSpecialArgs = extraArgs;
                        modules = commonModulesResolved ++ droidModules;
                    };

    in 
        builtins.mapAttrs (name: droid: mkDroid droid) droids
