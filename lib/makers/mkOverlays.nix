/*
  Build a list of overlays from an input inventory.
  Each overlay is structured to provide an isolated namespace in pkgs.

  # Type
  mkOverlay :: [AttrSet] -> [Overlay]

  # Args
  - overlayInventory: A list of attribute sets containing:
    - name: The namespace name (e.g., "nixus")
    - dir: Path to the directory to scan
    - args: Extra arguments to pass to rakeLeaves

  # Example
    mkOverlay [
      {
        name = "nixus";
        dir = ./pkgs;
        args = { inherit inputs; };
      }
    ]
*/

{ inputs, myLib }:

overlayInventory:
    let
        # Build one overlay `final: prev: { <...> }`
        mkOne = { name, dir, args }: final: prev: {
            "${name}" = myLib.modules.rakeLeaves {
                dir = dir;
                args = args // { pkgs = final; }; 
            };
        };
    in
        # Build the list of overlays `[ (final: prev: { <name> = <overlayAttrset> }) ]` 
        builtins.map mkOne overlayInventory
