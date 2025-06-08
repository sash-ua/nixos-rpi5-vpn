{
  description = "Encrypted bootable WireGuard VPN image for Raspberry Pi 5";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    nixos-images.url = "github:nix-community/nixos-images";
  };

  outputs = { self, nixpkgs, flake-utils, nixos-images, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };
        disk-config = import ./disko.nix;
        vpn-config = import ./configuration.nix;
      in {
        packages.default = nixos-images.packages.${system}.raspberrypi-5.override {
          configuration = pkgs.lib.mkMerge [ disk-config vpn-config ];
        };
      });
}