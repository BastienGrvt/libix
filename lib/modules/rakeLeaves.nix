/**
  Recursively import Nix files from a directory tree into a nested attribute set.
  A directory containing a `default.nix` is treated as a single leaf.

  # Type
  rakeLeaves :: { dir, args } -> AttrSet

  # Args
  - dir: The root directory path to scan.
  - args: The attribute set of arguments to pass to each imported Nix file.

  # Example
    rakeLeaves {
      dir = ./my-folder;
      args = { inherit inputs myLib; };
    }
*/

{ inputs, myLib }:

let
    lib = inputs.nixpkgs.lib;

    autoImport = {dir, args}:
        let
            # Get `dir` contents as the attrset `{ "file_name" = "file_type" }`
            contents = builtins.readDir dir;
            
            # Keep all folder and filter according to `isValidNode.nix`
            # NB: import isValidNode manually to avoid bootstrab issues
            isValidNode = import ./isValidNode.nix { inherit inputs myLib; };
            validNodes = lib.filterAttrs myLib.modules.isValidNode contents;
    
            processNode = name: type:
                let
                    # Absolute path of the node from the tree root
                    path = dir + "/${name}";
                    
                    # Build the node attrset value
                    attrValue = 
                        # If directory
                        if type == "directory" then
                            # If there is a `default.nix` -> import `default.nix` as a leaf
                            if builtins.pathExists (path + "/default.nix") then
                                import (path + "/default.nix") args
                            # If not `default.nix` -> recursion as a branch
                            else
                                autoImport { dir = path; inherit args; }
                        # If nix file -> import the file as a leaf
                        else
                            import path args;
                    
                    # Cleanup for node attrset name
                    attrName = lib.removeSuffix ".nix" name;
                in
                    # Return the attrset { <attrName> = <attrValue> }
                    lib.nameValuePair attrName attrValue;

        in
            # lib.mapAttrs' permet de modifier à la fois la CLEF et la VALEUR du dictionnaire (??)
            lib.mapAttrs' processNode validNodes;
in
    autoImport
