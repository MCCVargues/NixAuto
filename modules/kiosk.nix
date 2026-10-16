# Boots straight into the infotainment shell: cage (single-app Wayland
# compositor) on tty1, auto-logged-in as the unprivileged `kiosk` user.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixauto.kiosk;
in
{
  options.nixauto.kiosk = {
    enable = lib.mkEnableOption "the NixAuto kiosk session";

    program = lib.mkOption {
      type = lib.types.path;
      default = lib.getExe pkgs.nixauto-shell;
      defaultText = lib.literalExpression "lib.getExe pkgs.nixauto-shell";
      description = "Fullscreen program cage runs.";
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics.enable = true;

    users.users.kiosk = {
      isNormalUser = true;
      extraGroups = [
        "video"
        "input"
        "audio"
      ];
    };

    services.cage = {
      enable = true;
      user = "kiosk";
      program = cfg.program;
      environment = {
        QT_QPA_PLATFORM = "wayland";
        XKB_DEFAULT_LAYOUT = "us";
      };
    };

    # If the shell crashes, bring it straight back.
    systemd.services."cage-tty1".serviceConfig = {
      Restart = lib.mkForce "always";
      RestartSec = 1;
    };
  };
}
