/*
    Build Colmena hive from a context and a host inventory.

    # Type
    mkHive :: { buildContext, buildInvetory } -> AttrSet ColmenaHive

    # Args
    - buildContext: { overlays, extraArgs }
    - buildInventory: { hostsPath, hosts, commonModules, confSSH }
        - hosts: AttrSet of { confDir, system, deploySSH }
        - hosts without `deploySSH` are skipped (e.g. build-only iso images)
*/

{ inputs, myLib }:

let
    inherit (inputs) self nixpkgs colmena;
    hasUnstable = inputs ? nixpkgs-unstable;
    lib = nixpkgs.lib;
in
    { buildContext, buildInventory }:
        let
            # Get build inputs
            inherit (buildInventory) hostsPath hosts commonModules confSSH;
            inherit (buildContext) overlays extraArgs;
            commonModulesResolved = myLib.modules.resolvePaths commonModules;

            # Only hosts with a deploy target join the hive
            deployHosts = lib.filterAttrs (_: host: host ? deploySSH) hosts;

            # Helper: make pkgs
            mkPkgs = pkgsSource: system:
                import pkgsSource {
                    inherit system overlays;
                    config.allowUnfree = true;
                };

            # Helper: make host node pkgs
            mkNodePkgs = name: host: mkPkgs nixpkgs host.system;

            # Helper: make host node special args
            mkNodeSpecialArgs = name: host:
                # Untable host
                lib.optionalAttrs hasUnstable {
                    pkgs-unstable = mkPkgs inputs.nixpkgs-unstable host.system;
                };

            hiveMeta = {
                meta = {

                    # Default
                    specialArgs = extraArgs;
                    nixpkgs = mkPkgs nixpkgs "x86_64-linux";

                    # Node
                    nodeNixpkgs = builtins.mapAttrs mkNodePkgs deployHosts;
                    nodeSpecialArgs = builtins.mapAttrs mkNodeSpecialArgs deployHosts;
                };

                defaults = { ... }: {
                    imports = commonModulesResolved;
                    deployment = {
                        targetUser = confSSH.user;
                        targetPort = confSSH.port;
                        privilegeEscalationCommand = confSSH.options;
                    };
                };
            };

            hiveHosts = builtins.mapAttrs (name: host: {
                imports = [ "${self}/${hostsPath}/${host.confDir}" ];
                deployment = {
                    targetHost = host.deploySSH.ip;
                    tags = host.deploySSH.tags;
                };
            }) deployHosts;

        in
            colmena.lib.makeHive (hiveMeta // hiveHosts)
