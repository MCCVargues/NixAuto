{
  lib,
  stdenv,
  cmake,
  ninja,
  qt6,
}:
stdenv.mkDerivation {
  pname = "nixauto-shell";
  version = "0.1.0";

  src = lib.cleanSource ./.;

  nativeBuildInputs = [
    cmake
    ninja
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtwayland
  ];

  meta = {
    description = "NixAuto home screen: clock/date pane and app drawer";
    mainProgram = "nixauto-shell";
    platforms = lib.platforms.linux;
  };
}
