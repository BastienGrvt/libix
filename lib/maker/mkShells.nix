{ inputs, myLib }:

# FROM LLM MUST BE UNDESTAND

let
    inherit (inputs) self nixpkgs;
    lib = nixpkgs.lib;

    # From "python/proj1.nix", build the chain: [ base.nix python/base.nix python/proj1.nix ]
    buildChain = shellsDir: confDir:
        let
            parts = lib.splitString "/" confDir;
            # For "python/proj1.nix" → [ "base.nix" "python/base.nix" "python/proj1.nix" ]
            dirs = lib.sublist 0 (lib.length parts - 1) parts;
            bases = [ (shellsDir + "/base.nix") ]
                ++ lib.imap0 (i: _:
                    shellsDir + "/${lib.concatStringsSep "/" (lib.sublist 0 (i + 1) dirs)}/base.nix"
                ) dirs;
            validBases = builtins.filter (p: builtins.pathExists p) bases;
        in
            validBases ++ [ (shellsDir + "/${confDir}") ];

    # Merge configs: lists concatenate, shellHook concatenates, rest last-wins
    # The pipeline is based on `lib.foldl` for [ attrset_1 attrset_2 ...] -(with-special-rules)-> attrset_1 // attrset_2 // ...
    merge = configs:
        lib.foldl (a: b:
            (builtins.removeAttrs a [ "packages" "nativeBuildInputs" "buildInputs" "shellHook" ])
            // (builtins.removeAttrs b [ "packages" "nativeBuildInputs" "buildInputs" "shellHook" ])
            // {
                packages = (a.packages or []) ++ (b.packages or []);
                nativeBuildInputs = (a.nativeBuildInputs or []) ++ (b.nativeBuildInputs or []);
                buildInputs = (a.buildInputs or []) ++ (b.buildInputs or []);
                shellHook = (a.shellHook or "") + (b.shellHook or "");
            }
        ) {} configs;
in
    { buildContext, buildInventory }:
        let
            inherit (buildInventory) shellsPath shells;
            inherit (buildContext) overlays extraArgs;
            shellsDir = "${self}/${shellsPath}";

            mkShell = name: shell:
                let
                    pkgs = import nixpkgs {
                        system = shell.system;
                        config.allowUnfree = true;
                        inherit overlays;
                    };
                    args = extraArgs // { inherit pkgs lib; };
                    chain = buildChain shellsDir shell.confDir;
                    configs = map (f: import f args) chain;
                in
                    lib.nameValuePair shell.system {
                        ${name} = pkgs.mkShell (merge configs);
                    };

        in
            # Group by system: { x86_64-linux = { py-proj1 = drv; py-proj2 = drv; }; }
            lib.foldlAttrs (acc: name: shell:
                lib.recursiveUpdate acc
                    (builtins.listToAttrs [ (mkShell name shell) ])
            ) {} shells
