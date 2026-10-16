# Pull-based updates. The device follows the flake.lock on the main branch,
# which CI only commits after the full system built (and was pushed to the
# binary cache). See docs/updates.md.
{ config, lib, ... }:
let
  cfg = config.nixauto.autoUpdate;
in
{
  options.nixauto.autoUpdate = {
    enable = lib.mkEnableOption "automatic system updates from the NixAuto flake";

    flake = lib.mkOption {
      type = lib.types.str;
      example = "github:owner/NixAuto#nixauto";
      description = "Flake URI (including #configuration) the device upgrades to.";
    };

    dates = lib.mkOption {
      type = lib.types.str;
      default = "hourly";
      description = "systemd calendar expression for update checks.";
    };
  };

  config = lib.mkIf cfg.enable {
    system.autoUpgrade = {
      enable = true;
      inherit (cfg) flake dates;
      # Never switch a running system while driving: updates are installed
      # as the next boot generation and take effect at the next ignition.
      operation = "boot";
      allowReboot = false;
      randomizedDelaySec = "10min";
      persistent = true;
    };

    # Only try when there's actually a network (LTE can be absent for hours).
    systemd.services.nixos-upgrade = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };
  };
}
