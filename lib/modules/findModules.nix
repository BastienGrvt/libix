{ inputs, myLib }:

/**
  Recursively discover Nix modules in a directory tree and flatten them into a list of paths.
  A directory is considered a "leaf" (module) if it contains a `default.nix`.

  # Tree structure:
  Directory -> branch
  Nix file -> leaf
  Directory with `default.nix` -> leaf

  # Type
  findModules :: Path -> [Path]

  # Args
  - dir: The root directory to scan.

  # Example
    imports = findModules ./profiles/nixos
    => [ /path/to/core.nix /path/to/network/default.nix ]
*/

let
    lib = inputs.nixpkgs.lib;

    autoImport = dir:
        let
            # Get `dir` contents as the attrset `{ <dir_name> = <dir_type> }`
            contents = builtins.readDir dir;
            
            # Keep all folder and files except standby, ignore, and `default.nix`
            filterDir = name: type:
                name != "default.nix" &&
                !(lib.hasPrefix "standby." name) &&
                !(lib.hasPrefix "stby." name) &&
                !(lib.hasPrefix "ignore." name) &&
                !(lib.hasPrefix "wip." name) &&
                ((type == "regular" && lib.hasSuffix ".nix" name) || type == "directory");
            validNodes = lib.filterAttrs (name: type: filterDir name type) contents;

            # Function that check if the studied directory is a branch or a leaf
            processNode = name: type:
                let
                    # Absolute path of the node from the tree root
                    path = dir + "/${name}";
                in
                    # If directory -> leaf or branch
                    if type == "directory" then
                        # If `default.nix` in directory -> leaf
                        if builtins.pathExists (path + "/default.nix") then
                            [ path ]
                        # If not `default.nix` -> branch
                        else
                            autoImport path
                    # If nix file -> leaf
                    else
                        [ path ];

            # Map `processNode` to the attrset `{ <dir_name> = <dir_type> }`
            # Example: { "name1" = "regular"; "name2" = "directory"; } -> [ [ name1.nix ] [ /name2/name1.nix /name2/name2.nix] ]
            listOfLists = lib.mapAttrsToList processNode validNodes;
        in
            # Flat the recusrive list in a single list
            builtins.concatLists listOfLists;
in
    autoImport
