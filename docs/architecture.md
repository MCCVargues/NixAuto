# Architecture

## Hardware

```
             HDMI                      I2S (+ control TBD)
 Display <────────── Raspberry Pi 5 ─────────────────────> DSP board ──> amps/speakers
 Touch   ──────────>   (NixOS)
         USB HID         │ USB
                         └──> LTE modem (ModemManager) ──> Internet
```

- **Board:** a Raspberry Pi 5 with 8 GB RAM.
- **Storage:** a 128 GB M.2 NVMe SSD on the PCIe x1 connector holds the whole system
  (`/boot/firmware` and `/`). The 16 GB microSD card is only for installing and
  recovery, and stays out of the car in normal use (ADR-007).
  `dtparam=pciex1=on` is set in [hosts/nixauto/default.nix](../hosts/nixauto/default.nix).
  NVMe support is built into the Pi kernel (`CONFIG_BLK_DEV_NVME=y`).
- **Display:** HDMI, driven by the VideoCore through the `vc4` KMS driver
  (`nixos-raspberrypi.nixosModules.raspberry-pi-5.display-vc4`).
- **Touch:** a USB HID multitouch device that libinput handles directly. If touch is
  rotated or misaligned, set `nixauto.touchscreen.calibrationMatrix`
  ([modules/input.nix](../modules/input.nix)).
- **Audio:** I2S to the custom DSP board. *Not implemented yet.* It will need a device
  tree overlay (set through `hardware.raspberry-pi.config`, see nixos-raspberrypi's
  `modules/configtxt.nix`) and an ALSA card definition.
- **Network:** an LTE modem managed by NetworkManager and ModemManager. Wi-Fi also
  works, which is useful in the garage.

## Software stack

| Layer | Choice | Where |
|-------|--------|-------|
| Pi 5 kernel, firmware, bootloader | [nvmd/nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi), `kernel` bootloader | `flake.nix` |
| OS | NixOS (nixpkgs follows nixos-raspberrypi's pin, currently 26.05) | `modules/`, `hosts/nixauto/` |
| Compositor | [cage](https://github.com/cage-kiosk/cage), a single-app Wayland kiosk on tty1, user `kiosk` | `modules/kiosk.nix` |
| Shell / home screen | Qt 6 + QML (C++ host), package `nixauto-shell` | `shell/` |
| Updates | `system.autoUpgrade` pulling the CI-verified flake, `operation = "boot"` | `modules/auto-update.nix`, `.github/workflows/update.yml` |

## Repository layout

```
flake.nix                 inputs, nixosConfigurations.nixauto, packages, checks
hosts/nixauto/default.nix the car's machine config (hostname, SSH keys, update URL)
modules/                  reusable NixOS modules, options under `nixauto.*`
  base.nix                nix settings, users, SSH, NetworkManager/ModemManager
  kiosk.nix               cage + shell autostart  (nixauto.kiosk.*)
  auto-update.nix         pull-based updates      (nixauto.autoUpdate.*)
  input.nix               touchscreen calibration (nixauto.touchscreen.*)
shell/                    Qt/QML home screen (clock + app drawer)
.github/workflows/        ci.yml, update.yml, image.yml
docs/                     requirements, architecture, decisions, updates, apps
```

## Flake outputs

- `nixosConfigurations.nixauto`: the car.
- `packages.aarch64-linux.{toplevel,sdImage}`: the system closure and a flashable image.
- `packages.<system>.shell`: the home screen. It also builds on x86_64, so you can run
  it on a desktop with `nix run .#shell`.
- `checks.<system>`: built by `nix flake check` and CI.
- `nixosModules.default`, `overlays.default`: for reuse, for example by a future
  dev-VM config.

## Users

- `admin`: SSH key only, passwordless sudo. Use it for maintenance.
- `kiosk`: unprivileged. Runs cage and the UI. It has no password and no SSH access.
- `users.mutableUsers = false`, so all accounts are declared in Nix.
