{ inputs }:

let
    rakeLeaves = import ./modules/rakeLeaves.nix { inputs = inputs; myLib = {}; };

    myLib = rakeLeaves {
        dir = ./.;
        args = { inherit inputs myLib; };
    };
in
    myLib
