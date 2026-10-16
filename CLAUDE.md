# NixAuto: guide for agents

NixOS-based car infotainment system for a Raspberry Pi 5. Start here, then read:

1. **[docs/requirements.md](docs/requirements.md)**: what the owner asked for. It's
   the source of truth. **When the owner states a new requirement, record it there
   (with a date) in the same change.**
2. [docs/decisions.md](docs/decisions.md): ADR log. Add an ADR for any
   non-obvious technical choice. Don't rewrite old ADRs; supersede them.
3. [docs/architecture.md](docs/architecture.md), [docs/updates.md](docs/updates.md),
   [docs/apps.md](docs/apps.md): keep these accurate when you change the matching code.

## Hard constraints

- Target: **aarch64-linux, Raspberry Pi 5**, through `nvmd/nixos-raspberrypi`.
  nixpkgs **follows** that flake's nixpkgs (ADR-002). Don't add a separate nixpkgs pin.
- Pi 5 with 8 GB RAM. The system runs from a **128 GB M.2 NVMe SSD**. The 16 GB
  microSD card is for flashing and rescue only (ADR-007). Don't design for SD-only
  storage.
- Display is HDMI and touch is USB HID. Audio goes over I2S to a custom DSP board.
  Network is LTE (ModemManager).
- **No CarPlay or Android Auto.** All features run on the device.
- Every app is its **own flake repo**, pinned as an input here (docs/apps.md).
- Updates are applied with `operation = "boot"`. Never switch a live system in the
  car (ADR-005).
- Only `.github/workflows/update.yml` should move `flake.lock` forward on `main`,
  because devices trust it.

## Conventions

- NixOS options live under `nixauto.*` (`kiosk`, `autoUpdate`, `touchscreen`, and
  later `apps.<name>`). Each module in `modules/` is enabled by an option. The car's
  values are set in `hosts/nixauto/default.nix`.
- Format Nix with `nix fmt` (nixfmt-tree).
- Shell UI: Qt 6/QML in `shell/`. Shared colours and sizes are in `qml/Theme.qml`.
  Touch targets must be at least `Theme.touchTarget`. Register new QML files in
  `shell/CMakeLists.txt`.

## Verifying changes

```sh
nix flake check          # evaluates the aarch64 config + builds the shell
nix build .#toplevel     # full system (needs aarch64 or binfmt; CI does this)
nix run .#shell          # look at the UI on a desktop
```

The owner's workstation (Fedora Atomic) **doesn't have Nix installed**, but it has
podman. Run Nix in a container. The repo must be `git add`-ed, because flakes only see
tracked files:

```sh
podman run --rm -v "$PWD":/src:Z -w /src docker.io/nixos/nix:latest sh -c '
  git config --global --add safe.directory /src
  export NIX_CONFIG="experimental-features = nix-command flakes
accept-flake-config = true"
  git add -A && nix flake check --all-systems --no-build && nix build .#shell'
git reset -q   # undo the container's `git add`
```

To look at the UI headlessly, run the shell under `xvfb-run` (from nixpkgs) with
`QT_QPA_PLATFORM=xcb QT_QUICK_BACKEND=software QT_FORCE_STDERR_LOGGING=1`, then
capture it with ImageMagick `import -window root`. Without `QT_FORCE_STDERR_LOGGING`,
Qt sends its warnings to journald and they're lost in a container.

## Gotchas learned

- QML files live in `shell/qml/` but are aliased to the module root
  (`QT_RESOURCE_ALIAS`). Without the alias, the implicit directory import shadows the
  `Theme` singleton and every `Theme.*` is `undefined`.
