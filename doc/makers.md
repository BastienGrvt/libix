# Makers examples

## `mkNixOS`
 
Injects `pkgs-unstable` into `specialArgs` when the consumer declares a `nixpkgs-unstable` input. Hosts with `iso = true` additionally import `iso/installer.nix`.
 
```nix
# invNixOS.nix
{
  hostsPath = "hosts/";
  commonModules = [ "modules/nixos" ];
  hosts.laptop = { confDir = "laptop/"; system = "x86_64-linux"; iso = false; };
}
 
# flake.nix
nixosConfigurations = myLib.makers.mkNixOS {
  inherit buildContext;
  buildInventory = import ./invNixOS.nix;
};
```
 
Builds `.#laptop` from `hosts/laptop/`.
 
## `mkHomes`
 
Enables `programs.home-manager` automatically.
 
```nix
# invHomes.nix
{
  homesPath = "homes";
  commonModules = [ "modules/hm" ];
  homes.wspace = { confDir = "wspace"; system = "x86_64-linux"; };
}
 
# flake.nix
homeConfigurations = myLib.makers.mkHomes {
  inherit buildContext;
  buildInventory = import ./invHomes.nix;
};
```
 
## `mkDroids`
 
```nix
# invDroids.nix
{
  droidsPath = "hosts";
  commonModules = [ "modules/droid" ];
  droids.termux = { confDir = "termux"; system = "aarch64-linux"; };
}
 
# flake.nix
nixOnDroidConfigurations = myLib.makers.mkDroids {
  inherit buildContext;
  buildInventory = import ./invDroids.nix;
};
```
 
## `mkShells`
 
Resolves an inheritance chain from the path, skipping files that do not exist. Lists and `shellHook` concatenate; other fields are last-wins.
 
```nix
# invShells.nix
{
  shellsPath = "shells";
  shells = {
    python = { confDir = "python/base.nix";  system = "x86_64-linux"; };
    manim  = { confDir = "python/manim.nix"; system = "x86_64-linux"; };
  };
}
 
# shells/base.nix
{ pkgs, ... }: { packages = [ pkgs.git ]; }
 
# shells/python/base.nix
{ pkgs, ... }: { packages = [ pkgs.python3 ]; }
 
# shells/python/manim.nix
{ pkgs, ... }: {
  packages = [ pkgs.manim ];
  shellHook = "echo manim ready";
}
 
# flake.nix
devShells = myLib.makers.mkShells {
  inherit buildContext;
  buildInventory = import ./invShells.nix;
};
```
 
`nix develop .#manim` gets `git`, `python3`, and `manim` — the chain is merged, not overridden.
 
## `mkHive`
 
Hosts without `deploySSH` are skipped, so build-only targets coexist with deployable nodes in one inventory.
 
```nix
# invHive.nix
{
  hostsPath = "hosts/";
  commonModules = [ "modules/nixos" ];
  confSSH = { user = "admin"; port = 22; options = [ "sudo" "-u" ]; };
  hosts = {
    edge = {
      confDir = "edge/";
      system = "x86_64-linux";
      deploySSH = { ip = "10.0.0.2"; tags = [ "prod" ]; };
    };
    installer = { confDir = "iso/"; system = "x86_64-linux"; };  # no deploySSH -> skipped
  };
}
 
# flake.nix
colmenaHive = myLib.makers.mkHive {
  inherit buildContext;
  buildInventory = import ./invHive.nix;
};
```
 
## `mkOverlays`
 
Each overlay is namespaced, landing at `pkgs.<name>.<drv>` instead of the top level of `pkgs`.
 
```nix
# overlays/default.nix
myLib.makers.mkOverlays [
  { name = "scripts"; dir = ./scripts; args = { inherit inputs myLib; }; }
]
 
# overlays/scripts/hello.nix
{ pkgs, ... }: pkgs.writeShellApplication {
  name = "hello";
  text = "echo hi";
}
```
 
Exposes `pkgs.scripts.hello`. Unlike the others, `mkOverlays` takes a plain list and feeds `buildContext.overlays`.

