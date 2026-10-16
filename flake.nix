{
  description = "NixAuto - NixOS-based car infotainment system for the Raspberry Pi 5";

  nixConfig = {
    # Prebuilt Raspberry Pi kernels/firmware. Without this the RPi kernel is
    # compiled from source (hours on CI). See docs/decisions.md (ADR-002).
    extra-substituters = [ "https://nixos-raspberrypi.cachix.org" ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  inputs = {
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    # Follow the RPi flake's nixpkgs so its binary cache actually hits.
    nixpkgs.follows = "nixos-raspberrypi/nixpkgs";

    # App flakes are added here as inputs, see docs/apps.md. Example:
    # nixauto-media.url = "github:MCCVargues/nixauto-media";
    # nixauto-media.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-raspberrypi,
      ...
    }@inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system nixpkgs.legacyPackages.${system});
      nixauto = self.nixosConfigurations.nixauto.config.system.build;
    in
    {
      overlays.default = final: _prev: {
        nixauto-shell = final.callPackage ./shell/package.nix { };
      };

      nixosModules.default = ./modules;

      nixosConfigurations.nixauto = nixos-raspberrypi.lib.nixosSystem {
        specialArgs = inputs;
        modules = [
          { nixpkgs.overlays = [ self.overlays.default ]; }
          nixos-raspberrypi.nixosModules.raspberry-pi-5.base
          # The Pi 5 HDMI ports are driven by the VideoCore (vc4), not RP1.
          nixos-raspberrypi.nixosModules.raspberry-pi-5.display-vc4
          # Defines the SD-card filesystems and makes system.build.sdImage available.
          nixos-raspberrypi.nixosModules.sd-image
          self.nixosModules.default
          ./hosts/nixauto
        ];
      };

      packages = forAllSystems (
        system: pkgs:
        {
          shell = pkgs.callPackage ./shell/package.nix { };
          default = self.packages.${system}.shell;
        }
        // nixpkgs.lib.optionalAttrs (system == "aarch64-linux") {
          toplevel = nixauto.toplevel;
          sdImage = nixauto.sdImage;
        }
      );

      checks = forAllSystems (
        system: _pkgs:
        {
          shell = self.packages.${system}.shell;
        }
        // nixpkgs.lib.optionalAttrs (system == "aarch64-linux") {
          toplevel = nixauto.toplevel;
        }
      );

      devShells = forAllSystems (
        system: pkgs: {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.shell ];
            packages = [ pkgs.nixfmt-tree ];
          };
        }
      );

      formatter = forAllSystems (_system: pkgs: pkgs.nixfmt-tree);
    };
}
