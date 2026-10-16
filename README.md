# NixAuto

A car infotainment system built on NixOS for the **Raspberry Pi 5**. It has an HDMI
display, a USB touchscreen, I2S audio to a custom DSP board and LTE connectivity.
Every feature runs on the device (no CarPlay or Android Auto), and each app is its
own Nix flake. Apps are updated automatically through a CI-verified pipeline.

Right now it boots into a home screen with a big clock and date on the left and an
app drawer on the right.

- What it must do: [docs/requirements.md](docs/requirements.md)
- How it's built: [docs/architecture.md](docs/architecture.md)
- Why it's built that way: [docs/decisions.md](docs/decisions.md)
- How updates reach the car: [docs/updates.md](docs/updates.md)
- Writing an app: [docs/apps.md](docs/apps.md)

---

## Setup

### 0. Prerequisites

- [Nix](https://nixos.org/download) with flakes enabled
  (`experimental-features = nix-command flakes`).
- A GitHub repo for this project. CI builds the aarch64 system on GitHub's native
  ARM runners.
- Pi 5 hardware (8 GB): an M.2 NVMe SSD (the system disk, 128 GB here), a microSD
  card for flashing (16 GB is enough), an HDMI display, a USB touch controller, and
  later the LTE modem and DSP board.

You don't need an ARM machine. CI can build everything. To build locally on an x86
machine running NixOS, enable emulation with `boot.binfmt.emulatedSystems = [ "aarch64-linux" ];`.

### 1. Personalise the config

Edit [hosts/nixauto/default.nix](hosts/nixauto/default.nix):

1. **Add your SSH public key** to `users.users.admin.openssh.authorizedKeys.keys`.
   Password login is disabled, so you need this to get in.
2. Set `nixauto.autoUpdate.flake` to **your** repo (`github:<owner>/<repo>#nixauto`).
3. Optionally adjust `time.timeZone`.

### 2. Lock file

`flake.lock` is committed and pins exact versions of nixpkgs, the Pi kernel and every
app. Don't move it forward by hand on `main`. The **Update inputs** workflow does it
after a successful build (see [docs/updates.md](docs/updates.md)). Run that workflow
manually from the Actions tab whenever you want the latest versions.

### 3. Binary cache (strongly recommended)

Without a cache, the Pi has to compile every update itself.

1. Create a cache at [cachix.org](https://www.cachix.org).
2. In the GitHub repo settings, add:
   - the variable `CACHIX_CACHE_NAME`, set to your cache name
   - the secret `CACHIX_AUTH_TOKEN`, set to a Cachix auth token
3. Add the cache URL and its public key to `nix.settings` in
   [modules/base.nix](modules/base.nix). There are commented lines ready for this.

### 4. Build the SD image

**Using CI (easiest):** go to Actions → **SD image** → *Run workflow*, then download the
`nixauto-sd-image` artifact. Pushing a `v*` tag also attaches the image to a GitHub
release.

**Locally (aarch64 or binfmt):**

```sh
nix build .#sdImage --accept-flake-config
ls result/sd-image/
```

### 5. Flash and boot

The system runs from the **M.2 NVMe SSD**. The microSD card is only used to get the
image onto the SSD, and later as a rescue disk. The same image works on both.

```sh
# On your PC. Check the device name first with lsblk; dd overwrites the target.
# If the artifact came from GitHub as a .zip, unzip it first.
zstdcat nixos-image-rpi5-*.img.zst | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
```

You can also use Raspberry Pi Imager → *Use custom*.

**Option A: you have a USB M.2 enclosure.** Flash the image straight onto the SSD
from your PC, fit the SSD in the Pi, and skip to *Check the bootloader*.

**Option B: flash the SSD from the Pi using the microSD card.**

1. Flash the image to the **microSD** card as shown above.
2. Boot the Pi from the card with the SSD connected. Connect Ethernet and SSH in with
   `ssh admin@nixauto.local`.
3. Copy the image to the Pi (`scp nixos-image-rpi5-*.img.zst admin@nixauto.local:`),
   then write it to the SSD:
   ```sh
   lsblk   # the SSD shows up as /dev/nvme0n1
   zstdcat nixos-image-rpi5-*.img.zst | sudo dd of=/dev/nvme0n1 bs=4M status=progress conv=fsync
   sudo poweroff
   ```
4. **Remove the microSD card.** The card and the SSD have identical partition labels,
   so never boot with both inserted.

**Check the bootloader (once per Pi).** Pi 5s from 2024 onwards try SD, then NVMe,
then USB by default. With the SSD-only system booted (or from the SD system), run:

```sh
sudo rpi-eeprom-config          # look for BOOT_ORDER; it should include 6 (NVMe), e.g. 0xf461
sudo -E rpi-eeprom-config --edit   # if needed: BOOT_ORDER=0xf461; add PCIE_PROBE=1 for non-HAT+ M.2 adapters
```

If the Pi can't find the SSD at all, the easiest fix is Raspberry Pi Imager → *Misc
utility images* → *Bootloader* → *NVMe/USB boot*. Write that to the SD card, boot it
once and wait for the green LED to flash steadily, then flash the SD card with the
NixAuto image again and continue with option B.

Connect HDMI and the USB touchscreen, and power on. The root partition grows to fill
the SSD on first boot, and then the home screen appears. Keep the microSD card
somewhere safe. With the NixAuto image on it, you can boot it to fix or reflash the
SSD; take the SSD out or wipe it first because of the label clash.

### 6. Networking

You can only SSH in once the Pi is on a network. On first boot, use Ethernet: plug in
a cable, then run `ssh admin@nixauto.local`.

```sh
# Wi-Fi (garage / home)
sudo nmcli device wifi connect "<SSID>" password "<password>"

# LTE modem (check it's detected: mmcli -L)
sudo nmcli connection add type gsm ifname '*' con-name lte apn <your-apn>
sudo nmcli connection up lte
```

### 7. Updates

After setup, the car keeps itself up to date:

- When you push to an app repo, or every Monday, CI updates `flake.lock`, builds the
  full system and commits the lock only if the build succeeds.
- The Pi checks every hour while it's online. It installs the new system as the
  **next boot** entry, which becomes active the next time the ignition is turned on.
  The running UI is never switched mid-drive.

To push a change by hand, from a machine that can build aarch64 (or use
`--build-host admin@nixauto.local` to build on the Pi):

```sh
nixos-rebuild boot --flake .#nixauto --target-host admin@nixauto.local --sudo
```

Rollback: choose an older generation at boot, or run `sudo nixos-rebuild boot --rollback`.

---

## Development

```sh
nix run .#shell          # run the home screen in a window on your desktop
nix develop              # shell with Qt/CMake for working on shell/
nix flake check          # what CI runs (eval + shell build)
nix build .#toplevel     # full Pi system (aarch64)
nix fmt                  # format Nix files
```

## Troubleshooting

| Symptom | Check |
|---------|-------|
| Black screen / no UI | `journalctl -b -u cage-tty1` |
| Touch rotated or offset | `libinput list-devices`, then set `nixauto.touchscreen.calibrationMatrix` |
| Wrong resolution | uncomment the `video=HDMI-A-1:...` kernel parameter in `hosts/nixauto/default.nix` |
| Update didn't arrive | `systemctl status nixos-upgrade`, `journalctl -u nixos-upgrade` |
| LTE down | `mmcli -m 0`, `nmcli connection show lte` |
| SSD not detected | `lsblk`, `dmesg \| grep -i -e pcie -e nvme`; check the ribbon cable; for a third-party adapter, check `PCIE_PROBE=1` in the EEPROM |
| Boots the wrong disk / random mount failures | Make sure the microSD card is **removed**; it has the same labels as the SSD |
| SSD health | `sudo nvme smart-log /dev/nvme0` |
