# The in-car Raspberry Pi 5. Everything machine-specific lives here;
# reusable behaviour lives in ../../modules.
{ lib, ... }:
{
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  networking.hostName = "nixauto";
  time.timeZone = "Europe/Amsterdam";

  # Generational bootloader recommended by nixos-raspberrypi for new installs:
  # each NixOS generation gets its own kernel/initrd, so rollbacks work.
  boot.loader.raspberry-pi.bootloader = "kernel";

  # Root filesystem lives on the M.2 NVMe SSD (see docs/decisions.md ADR-007).
  # Enable the external PCIe x1 connector. HAT+-compliant M.2 boards are
  # auto-detected, but third-party adapters need this; harmless otherwise.
  hardware.raspberry-pi.config.all.base-dt-params = {
    pciex1 = {
      enable = true;
      value = "on";
    };
    # Gen 3 is ~2x faster but not officially certified; try if the SSD is stable.
    # pciex1_gen = { enable = true; value = "3"; };
  };

  # Pulled in by the sd-image base profile; not needed, and it's a large
  # out-of-tree kernel module.
  boot.supportedFilesystems.zfs = lib.mkForce false;

  # Force a specific HDMI mode if the screen's EDID is wrong/missing:
  # boot.kernelParams = [ "video=HDMI-A-1:1280x720@60" ];

  nixauto = {
    kiosk.enable = true;

    autoUpdate = {
      enable = true;
      # Must point at the repo CI pushes the verified flake.lock to.
      flake = "github:MCCVargues/NixAuto#nixauto";
    };
  };

  # SSH public keys for the `admin` user. Password login is disabled, so
  # without a key there is no remote access (and evaluation fails on purpose).
  users.users.admin.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHeyZ5MbwZ8KuC3hYuT2Tp05HpHkrkau3KM+53OfPEyh"
  ];

  system.stateVersion = "26.05";
}
