# All NixAuto modules. Each one is opt-in via `nixauto.*` options except base.
{
  imports = [
    ./base.nix
    ./kiosk.nix
    ./auto-update.nix
    ./input.nix
  ];
}
