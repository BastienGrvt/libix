# libix

Personal Nix libry with helpers used accross my flakes.

The tree directory under `lib/` is raked at import time: directory layout is the API, e.g. `lib/makers/mkNixOS.nix` becomes `myLib.makers.mkNixOS`. 
Adding a helper by dropping a file in the right category, nothing is registered by hand.

Current categories: 
 - `modules` (tree traversal and path resolution) 
 - `makers` (configuration builders). 

Consumer example: [`nixus-public`](https://github.com/BastienGrvt/nixus-public).

## Usage

```nix
inputs.libix.url = "github:BastienGrvt/libix";

# in outputs
myLib = inputs.libix.mkLib inputs;
```

`mkLib` takes the consumer's inputs: `inputs.self` resolves against the importing flake and every helper is available under one `myLib` attrset.

## `modules`

Tree walking and path resolution, the primitives the rest of the library is built on.

| Helper | Signature | Purpose |
| --- | --- | --- |
| `rakeLeaves` | `{ dir, args } -> AttrSet` | Import a tree into a nested attrset mirroring the directory structure |
| `findModules` | `Path -> [Path]` | Collect module paths for `imports` |
| `resolvePaths` | `[String] -> [String]` | Flake-relative → absolute via `inputs.self` |
| `resolveProfiles` | `[String] -> [String]` | Same, rooted at `<flake>/profiles` |

Shared traversal rules: a `.nix` file is a leaf, a directory containing `default.nix` is a leaf, anything else is recursed.
Prefixes `backup.`, `bckp.`, `standby.`, `stby.`, `stb.`, `ignore.` are skipped, so a module is disabled by renaming it rather than editing imports.

`rakeLeaves` bootstraps the library itself.

## `makers`

Builders turning a declarative inventory (attrset describing machines) into flake outputs, so a consuming flake holds no per-machine logic.

All take `{ buildContext, buildInventory }`, where `buildContext = { overlays, extraArgs }`.

| Builder | Produces | Inventory |
| --- | --- | --- |
| `mkNixOS` | `nixosConfigurations` | `{ hostsPath, hosts, commonModules }`, host = `{ confDir, system, iso }` |
| `mkHomes` | `homeConfigurations` | `{ homesPath, homes, commonModules }`, home = `{ confDir, system }` |
| `mkDroids` | `nixOnDroidConfigurations` | `{ droidsPath, droids, commonModules }` |
| `mkShells` | `devShells` by system | `{ shellsPath, shells }` |
| `mkHive` | Colmena hive | adds `confSSH`; host needs `deploySSH = { ip, tags }` |
| `mkOverlays` | overlay list | `[ { name, dir, args } ]` |

- `mkNixOS` injects `pkgs-unstable` if the consumer declares `nixpkgs-unstable`; `iso = true` also imports `iso/installer.nix`.
- `mkShells` builds an inheritance chain from the path: `python/manim.nix` imports `base.nix`, `python/base.nix`, then itself. Lists and `shellHook` concatenate, the rest is last-wins.
- `mkOverlays` namespaces each overlay at `pkgs.<name>.<drv>`.
- `mkHive` skips hosts without `deploySSH`, so build-only targets coexist with deployable nodes.



## Dependencies

Dependencies come from the consumer's inputs, and only what is used is loaded: `home-manager` for `mkHomes`, `nix-on-droid` for `mkDroids`, `colmena` for `mkHive`. `nixpkgs-unstable` is optional.


