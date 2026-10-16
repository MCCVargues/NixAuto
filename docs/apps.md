# App flakes

Every infotainment feature (media, navigation, audio/DSP control, ...) lives in its
**own repo as a Nix flake** (requirement R3). This repo pins each one as a flake input
and composes them into the system.

## Contract an app flake must meet

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05"; # overridden by NixAuto
  outputs = { self, nixpkgs }: {
    # Required: the app package, buildable for aarch64-linux (and ideally x86_64-linux
    # so it can be developed on a desktop).
    packages.aarch64-linux.default = /* ... */;

    # Optional: a NixOS module for services, udev rules, users, etc.
    # Options must live under `nixauto.apps.<name>.*`.
    nixosModules.default = { config, lib, pkgs, ... }: { /* ... */ };
  };
}
```

> How an app *appears* in the shell's drawer isn't decided yet: it could be a QML
> module loaded in-process or a separate Wayland client. See ADR-003 in
> [decisions.md](decisions.md). Settle that before writing the first real app,
> and update this contract when you do.

## Adding an app to the system

1. Add it as an input in `flake.nix`, following our nixpkgs:
   ```nix
   nixauto-media.url = "github:MCCVargues/nixauto-media";
   nixauto-media.inputs.nixpkgs.follows = "nixpkgs";
   ```
2. Import its module in `nixosConfigurations.nixauto.modules`, or reference its
   package from a module.
3. Run `nix flake lock` and push. CI builds it.

## Auto-update hook (in the app repo)

Add this workflow to the **app** repo. It needs a secret `NIXAUTO_DISPATCH_TOKEN`: a
fine-grained PAT with *Contents: read & write* on the NixAuto repo.

```yaml
# .github/workflows/notify-nixauto.yml
name: Notify NixAuto
on:
  push:
    branches: [main]
jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - uses: peter-evans/repository-dispatch@v3
        with:
          token: ${{ secrets.NIXAUTO_DISPATCH_TOKEN }}
          repository: MCCVargues/NixAuto
          event-type: app-updated
          client-payload: '{"input": "nixauto-media"}'  # this app's input name in NixAuto's flake.nix
```

NixAuto's `update.yml` then updates only that input, builds the full system, and
commits the lock if the build passes. See [updates.md](updates.md).
