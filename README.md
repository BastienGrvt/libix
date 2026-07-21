# libix

Shared Nix library: builders that turn a declarative inventory into `nixosConfigurations`, `homeConfigurations`, `nixOnDroidConfigurations`, `devShells`, or a Colmena hive.

Consumer example: [`nixus`](https://github.com/BastienGrvt/nixus).

## Usage

```nix
inputs.libix.url = "github:BastienGrvt/libix";

# in outputs
myLib = inputs.libix.mkLib inputs;

nixosConfigurations = myLib.makers.mkNixOS {
  buildContext  = { overlays = [ ]; extraArgs = { inherit self inputs myLib; }; };
  buildInventory = import ./invNixOS.nix;
};
```

`mkLib` takes the consumer's inputs, so `inputs.self` resolves against the importing flake.

## API

`lib/` is raked, so paths map to attributes: `lib/makers/mkNixOS.nix` → `myLib.makers.mkNixOS`.

### `makers`

All take `{ buildContext, buildInventory }`, where `buildContext = { overlays, extraArgs }`.

| Builder | Produces | Inventory |
| --- | --- | --- |
| `mkNixOS` | `nixosConfigurations` | `{ hostsPath, hosts, commonModules }`, host = `{ confDir, system, iso }` |
| `mkHomes` | `homeConfigurations` | `{ homesPath, homes, commonModules }`, home = `{ confDir, system }` |
| `mkDroids` | `nixOnDroidConfigurations` | `{ droidsPath, droids, commonModules }` |
| `mkShell` | `devShells` by system | `{ shellsPath, shells }` |
| `mkHive` | Colmena hive | adds `confSSH`; host needs `deploySSH = { ip, tags }` |
| `mkOverlays` | overlay list | `[ { name, dir, args } ]` |

- `mkNixOS` injects `pkgs-unstable` if the consumer declares `nixpkgs-unstable`; `iso = true` also imports `iso/installer.nix`.
- `mkShell` builds an inheritance chain from the path: `python/manim.nix` imports `base.nix`, `python/base.nix`, then itself. Lists and `shellHook` concatenate, the rest is last-wins.
- `mkOverlays` namespaces each overlay at `pkgs.<name>.<drv>`.
- `mkHive` skips hosts without `deploySSH`.

### `modules`

| Helper | Signature | Purpose |
| --- | --- | --- |
| `rakeLeaves` | `{ dir, args } -> AttrSet` | Import a tree into a nested attrset |
| `findModules` | `Path -> [Path]` | Collect module paths for `imports` |
| `resolvePaths` | `[String] -> [String]` | Flake-relative → absolute via `inputs.self` |
| `resolveProfiles` | `[String] -> [String]` | Same, rooted at `<flake>/profiles` |

Traversal: a `.nix` file is a leaf, a directory with `default.nix` is a leaf, anything else is recursed.
Prefixes `backup.`, `bckp.`, `standby.`, `stby.`, `stb.`, `ignore.` are skipped.

## Requirements

Dependencies come from the consumer's inputs: `home-manager` for `mkHomes`, `nix-on-droid` for `mkDroids`, `colmena` for `mkHive`. `nixpkgs-unstable` is optional.

