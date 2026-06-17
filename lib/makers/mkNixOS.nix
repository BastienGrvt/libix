/*
    Build NixOS systems from a context and a host inventory.

    # Type
    mkNixOS :: { buildContext, buildInventory } -> AttrSet NixOSSystem

    # Args
    - buildContext: { invOverlays, extraArgs }
    - buildInventory: { hostsPath, hosts, commonModules }
        - hosts: AttrSet of { confDir, system, iso, commonModules }
*/

{ inputs, myLib }:

let
    inherit (inputs) self nixpkgs;
    hasUnstable = inputs ? nixpkgs-unstable;
    lib = nixpkgs.lib;
in
    { buildContext, buildInventory }:
        let
            inherit (buildInventory) hostsPath hosts commonModules;
            inherit (buildContext) overlays extraArgs;
            commonModulesResolved = myLib.modules.resolvePaths commonModules;

            mkPkgs = pkgsSource: system:
                import pkgsSource {
                    inherit system overlays;
                    config.allowUnfree = true;
                };

            mkHost = host:
                let
                    # Pkgs
                    pkgs = mkPkgs nixpkgs host.system;

                    # Special args with unstable pkgs
                    specialArgs = extraArgs // lib.optionalAttrs hasUnstable {
                        pkgs-unstable = mkPkgs inputs.nixpkgs-unstable host.system;
                    };
                    
                    # Default modules
                    nixosModules = [ { nixpkgs.pkgs = pkgs; } ];
                    hostModules = [ "${self}/${hostsPath}/${host.confDir}" ];
                    isoModules = lib.optionals (host.iso or false) [ "${self}/iso/installer.nix" ];
                in
                lib.nixosSystem {
                    specialArgs = specialArgs;
                    modules = commonModulesResolved ++ nixosModules ++ hostModules ++ isoModules;
                };

        in
            builtins.mapAttrs (name: host: mkHost host) hosts
