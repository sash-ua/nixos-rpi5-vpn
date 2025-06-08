{ pkgs, ... }:

{
  imports = [
    ./disko.nix
  ];

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "vpnpi";
  networking.useDHCP = true;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "yes";
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIAAk0liWgeVtW7RVeg+jnGqJOpGvmVvh/aFOpJGvu3B vpn" # <-- your SSH public key
  ];

  services.wireguard.enable = true;

  services.fail2ban.enable = true;
  networking.firewall.enable = true;

  environment.systemPackages = with pkgs; [
    wireguard-tools
    curl htop vim
  ];

  services.autoUpgrade = {
    enable = true;
    dates = "03:00";
    randomizedDelaySec = "45min";
  };

  boot.initrd.luks.devices = {
    cryptroot.device = "/dev/nvme0n1p2";
  };

  system.stateVersion = "24.05";
}