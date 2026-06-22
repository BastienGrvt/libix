{ inputs, myLib }:

let
    lib = inputs.nixpkgs.lib;

    prefixes = [
        "backup."
        "bckp."
        "standby."
        "stby."
        "stb."
        "ignore."
        "wip."
    ];

    suffixes = [
        ".bak"
    ];

    isIgnored = name:
        lib.any (p: lib.hasPrefix p name) prefixes || lib.any (s: lib.hasSuffix s name) suffixes;
in
    name: type:
        name != "default.nix"
        && !(isIgnored name)
        && ((type == "regular" && lib.hasSuffix ".nix" name) || type == "directory")
