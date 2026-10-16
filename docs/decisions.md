# Decisions (ADR log)

Short architecture decision records. Add a new entry for each decision; don't edit
old entries. To change a decision, add a new entry that supersedes the old one.

---

## ADR-001: Use nixos-raspberrypi for Pi 5 support (2026-10-17)

**Context:** mainline nixpkgs and nixos-hardware don't fully support booting the Pi 5.
**Decision:** use `github:nvmd/nixos-raspberrypi`, specifically its `lib.nixosSystem`,
the `raspberry-pi-5.base` and `raspberry-pi-5.display-vc4` modules, its `sd-image`
module, and the `kernel` (generational) bootloader.
**Consequences:** we depend on one external flake for the kernel and firmware. It has a
binary cache, so we don't compile kernels.

## ADR-002: nixpkgs follows nixos-raspberrypi (2026-10-17)

**Decision:** `inputs.nixpkgs.follows = "nixos-raspberrypi/nixpkgs"`.
**Why:** the kernel and firmware in its Cachix cache only match if our nixpkgs is the
same. Without the cache, CI would rebuild the RPi kernel from source.
**Consequences:** the nixpkgs version moves when nixos-raspberrypi bumps its pin.
App flakes should `follows` our `nixpkgs` to avoid duplicate closures.

## ADR-003: cage + Qt/QML shell (2026-10-17)

**Decision:** boot into `cage`, a single-application Wayland compositor. It runs the
`nixauto-shell` Qt 6 / QML app as the unprivileged `kiosk` user.
**Why:** cage is minimal, its NixOS module provides autologin, and it handles touch
through libinput. Qt/QML is the de-facto standard for embedded and automotive touch
UIs. It has GPU-accelerated rendering on the Pi's V3D, and its C++ backend lets us
talk to the DSP and other hardware later.
**Open question:** how other apps display. Options: (a) apps are QML modules loaded
into the shell process; (b) the shell becomes a small Wayland compositor (QtWayland
Compositor) that embeds app windows. Decide this when the first real app is built.
cage shows only one fullscreen app at a time, so option (b) would replace cage.

## ADR-004: CI-gated pull updates instead of on-device rebuilds (2026-10-17)

**Requirement:** apps must auto-fetch and rebuild when their repos update (R3).
**Decision:** don't have the Pi poll app repos and compile on the device. Instead:
1. Each app repo notifies this repo when it changes, with a `repository_dispatch`.
2. CI runs `nix flake update <app>`, builds the whole aarch64 system, pushes it to
   the binary cache, and only then commits `flake.lock` to `main`.
3. The Pi runs `system.autoUpgrade` against `main`. It downloads prebuilt paths and
   installs them as the **next boot** generation.

**Why:**
- The Pi never compiles, which saves SD-card wear, heat, time and battery.
- A broken app commit never reaches the car, because it fails the CI gate.
- `flake.lock` records exactly which app versions each car generation contains, and
  rolling back is one bootloader entry away.
- LTE data is used only for real, verified changes.

Full details are in [updates.md](updates.md).

## ADR-005: Apply updates at the next boot (2026-10-17)

**Decision:** `system.autoUpgrade.operation = "boot"` and `allowReboot = false`.
**Why:** switching services or restarting the UI while someone is driving is
unacceptable. The new generation becomes active at the next ignition cycle.

## ADR-006: GitHub Actions on native ARM runners (2026-10-17)

**Decision:** build aarch64 closures on `ubuntu-24.04-arm`, not with QEMU emulation
on x86. x86 `ubuntu-latest` handles evaluation and the x86 shell build.
**Caveat:** free ARM runners are available for public repos. For a private repo,
check GitHub pricing or use a self-hosted aarch64 runner. A spare Pi 5 works for that.

## ADR-007: Boot and run from the NVMe SSD; microSD for install and rescue (2026-10-17)

**Context:** the Pi 5 has a 128 GB M.2 NVMe SSD and a 16 GB microSD card (R8).
**Decision:** the same image built by `.#sdImage` is written to the **NVMe SSD**,
and the Pi boots from it. The microSD card is used to flash the SSD from the Pi,
and as a rescue boot medium.
**Why:**
- An SSD survives the car's sudden power cuts and constant small writes (journal,
  Nix store) much better than an SD card.
- It's also several times faster for boots and updates.
- A single image for both media means no separate installer to maintain. The
  sd-image root partition grows to fill the 128 GB on first boot.

**Caveats:**
- The SD card and the SSD carry identical filesystem labels (`FIRMWARE`,
  `NIXOS_SD`). **Never boot with both inserted**, because the root mount by label
  becomes ambiguous. Remove the SD card after flashing the SSD.
- The Pi 5 EEPROM must allow NVMe boot. Recent bootloaders default to
  `BOOT_ORDER=0xf461` (SD → NVMe → USB). Third-party (non-HAT+) M.2 adapters
  also need `PCIE_PROBE=1`. See the README for the steps.
- The `NIXOS_SD` label on an SSD is cosmetic. Relabelling would mean overriding the
  sd-image module's `fileSystems`, which isn't worth it.

**Future:** if media or map storage needs its own partition, or root should be
read-only, move to a declarative partition layout (for example disko). Write a new
ADR when that happens.
