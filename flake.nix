{
  description = "Raspberry Pi 5 VPN Server with Encrypted NVMe";

  nixConfig = {
    bash-prompt = "\[nixos-rpi5-vpn\] \u279c ";
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "rpi5-vpn.cachix.org-1:dxEppnOrxg/EQdFRn6J8iAMNsKeWTvc06xlD1fwQ8uo="
    ];
    connect-timeout = 5;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi/main";
    };
    disko = {
      url = "github:nvmd/disko/gpt-attrs";
      inputs.nixpkgs.follows = "nixos-raspberrypi/nixpkgs";
    };
    nixos-anywhere.url = "github:nix-community/nixos-anywhere";
  };

  outputs = { self, nixpkgs, nixos-raspberrypi, disko, nixos-anywhere, ... }@inputs:
    let
      system = "aarch64-linux";
      inherit (self) outPath;
    in {
      nixosConfigurations.rpi5 = nixos-raspberrypi.lib.nixosSystemFull {
        specialArgs = inputs;
        modules = [
          ({ config, pkgs, lib, nixos-raspberrypi, disko, ... }: {
            imports = with nixos-raspberrypi.nixosModules; [
              raspberry-pi-5.base
              raspberry-pi-5.display-vc4
              "${outPath}/pi5-config.nix"
            ] ++ [
              nixos-raspberrypi.nixosModules.sd-image
#              "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            ];
          })
          ({ lib, ... }: {
              boot.loader.generic-extlinux-compatible.enable = lib.mkForce false;
          })
          disko.nixosModules.disko
          ./disko-config.nix
          ({ config, pkgs, lib, ... }:
          let
          in {
            fileSystems."/".device = lib.mkForce "/dev/mapper/crypted";
            fileSystems."/boot/firmware".device = lib.mkForce "/dev/disk/by-partlabel/FIRMWARE";

            boot.initrd.luks.devices."crypted".device = "/dev/disk/by-partlabel/CRYPT";
            boot.initrd.network.enable = true;
            boot.initrd.network.ssh = {
              enable = true;
              authorizedKeys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGxpO3D2rhdfxomK1gaDfpHHEw0ReNXR8tT7rXkcfXeZ internet@Alexs-MBP.local"
              ];
              hostKeys = [ ./secrets/initrd-ssh/ssh_host_ed25519_key ];
            };
          })
          ({ config, pkgs, lib, ... }: {
            networking.hostId = "8821e309";
            networking.hostName = "rpi5-vpn";
            boot.tmp.useTmpfs = true;
            services.openssh.enable = true;
            users.users.root.openssh.authorizedKeys.keys = [
              # Main SSH key
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIAAk0liWgeVtW7RVeg+jnGqJOpGvmVvh/aFOpJGvu3B vpn"
            ];

            networking.wireguard.interfaces = {
              wg0 = {
                ips = [ "10.0.0.1/24" ]; # Adjust as needed

                privateKeyFile = "/etc/wireguard/privatekey"; # You must provide this securely

                peers = [
                  {
                    publicKey = "peerPublicKeyHere";
                    allowedIPs = [ "10.0.0.2/32" ]; # adjust per peer
                  }
                ];
              };
            };
            services.fail2ban.enable = true;
            networking.firewall.enable = true;
            services.tor.enable = false;

            services.prometheus.exporters.node.enable = true;

            system.autoUpgrade = {
              enable = true;
              allowReboot = true;
            };

            time.timeZone = "Etc/UTC";

            security.sudo.wheelNeedsPassword = false;
          })
          # Advanced: Use non-default kernel from kernel-firmware bundle
          ({ config, pkgs, lib, ... }:
          let
            kernelBundle = pkgs.linuxAndFirmware.v6_6_31;
          in {
            nixpkgs.overlays = lib.mkAfter [
              (self: super: {
                # This is used in (modulesPath + "/hardware/all-firmware.nix") when at least
                # enableRedistributableFirmware is enabled
                # I know no easier way to override this package
                inherit (kernelBundle) raspberrypiWirelessFirmware;
                # Some derivations want to use it as an input,
                # e.g. raspberrypi-dtbs, omxplayer, sd-image-* modules
                inherit (kernelBundle) raspberrypifw;
              })
            ];
            boot = {
              loader.raspberryPi.firmwarePackage = kernelBundle.raspberrypifw;
              kernelPackages = kernelBundle.linuxPackages_rpi5;
            };
          })
        ];
      };
    };
}