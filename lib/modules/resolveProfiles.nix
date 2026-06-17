{ inputs, myLib }:

# Turns relative path profiles to flake absolute one
# Basic usage: imports = myLib.fromProfiles [ "core" "graphical/sway" "gaming" ];

let
  profilesRoot = "${inputs.self}/profiles";
in
names: 
    map (name: "${profilesRoot}/${name}") names
