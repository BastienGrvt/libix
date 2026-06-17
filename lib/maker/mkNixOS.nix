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
    lib = nixpkgs.lib; 
in
    { buildContext, buildInventory }:
        let
            inherit (buildInventory) hostsPath hosts commonModules;
            inherit (buildContext) overlays extraArgs;
            commonModulesResolved = myLib.modules.resolvePaths commonModules;

            mkHost = host:
                let
                    # Cook pkgs
                    pkgs = import nixpkgs {
                        system = host.system;
                        config.allowUnfree = true;
                        overlays = overlays;
                    };
                    
                    # Host specific modules
                    nixosModules = [ { nix.pkgs = pkgs; } ];
                    hostModules = [ "${self}/${hostsPath}/${host.confDir}" ];
                    isoModules = lib.optionals (host.iso or false) [ "${self}/iso/installer.nix" ];
                in
                nixpkgs.lib.nixosSystem {
                    specialArgs = extraArgs;
                    modules = commonModulesResolved ++ nixosModules ++ hostModules ++ isoModules;
                };

        in 
            builtins.mapAttrs (name: host: mkHost host) hosts
