{
  description = "Bootable encrypted VPN Pi5 setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    disko.url = "github:nix-community/disko";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, disko, nixos-hardware, sops-nix, ... }@inputs:
    let
      system = "aarch64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      nixosConfigurations.rpi5 = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          secretsFile = ./secrets/secrets.yaml;
        };
        modules = [
          disko.nixosModules.disko
          nixos-hardware.nixosModules.raspberry-pi-5
          inputs.sops-nix.nixosModules.sops
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          ./hardware/rpi5-hardware.nix
          ./disko-config.nix
          ./hosts/rpi5.nix
        ];
      };
    };
}