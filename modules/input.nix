# USB touchscreen. HID multitouch panels work through libinput without
# drivers; this module only handles panels that are rotated/mis-calibrated.
{ config, lib, ... }:
let
  cfg = config.nixauto.touchscreen;
in
{
  options.nixauto.touchscreen = {
    calibrationMatrix = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "0 -1 1 1 0 0"; # 90° clockwise
      description = ''
        libinput calibration matrix (6 numbers) applied to every touchscreen.
        Use when touch coordinates don't line up with the HDMI picture.
        See https://wayland.freedesktop.org/libinput/doc/latest/absolute-axes.html
      '';
    };
  };

  config = lib.mkIf (cfg.calibrationMatrix != null) {
    services.udev.extraRules = ''
      ENV{ID_INPUT_TOUCHSCREEN}=="1", ENV{LIBINPUT_CALIBRATION_MATRIX}="${cfg.calibrationMatrix}"
    '';
  };
}
