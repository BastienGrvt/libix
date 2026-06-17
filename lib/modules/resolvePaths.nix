{ inputs, myLib }:

/*
    Turns relative path to flake absolute one
*/

let
    self = inputs.self;
in
paths: 
    map (path: "${self}/${path}") paths
