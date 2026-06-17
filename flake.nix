{
    description = "libix - shared Nix library across flakes.";

    inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    outputs = { self, nixpkgs, ... }: {

        mkLib = inputs: import ./lib { inherit inputs; };
       
        # NB: mkLib is applied with the consumer's inputs, so both inputs.self (path resolution) and nixpkgs.lib (helpers) come from the importing host.
        # For stronger reproducibility, split the sources libix's own inputs (for nixpkgs.lib) and the consumer's inputs (for inputs.self).
    };
}
