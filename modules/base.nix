# Baseline system: nix settings, users, networking (incl. LTE), logging.
{ pkgs, ... }:
{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
      auto-optimise-store = true;
      # Add the project cache here once it exists (see README "Binary cache"):
      extra-substituters = [ "https://mccv.cachix.org" ];
      extra-trusted-public-keys = [ "mccv.cachix.org-1:ye019q3sF5R8uWm6KZniEyLO+Bu4wWohVGN8p4fmgSI=" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # NetworkManager drives both Wi-Fi (workshop/home) and the LTE modem
  # (through ModemManager). Add the APN with nmcli, see README.
  networking.networkmanager.enable = true;
  networking.modemmanager.enable = true;

  services.timesyncd.enable = true;

  # Reachable as nixauto.local on Wi-Fi/Ethernet for maintenance.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  users.mutableUsers = false;
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  # Limit SD-card wear; the car may lose power at any moment.
  services.journald.extraConfig = ''
    SystemMaxUse=64M
  '';

  environment.systemPackages = with pkgs; [
    git
    htop
    usbutils
    libinput # `libinput list-devices` / `debug-events` for the touchscreen
    alsa-utils # `aplay -l` for the I2S DSP link
    nvme-cli # SSD health: `sudo nvme smart-log /dev/nvme0`
    raspberrypi-eeprom # `rpi-eeprom-config` to check/set BOOT_ORDER for NVMe boot
  ];

  fonts.packages = [ pkgs.inter ];
}
