{ config, pkgs, lib, ... }:

{
  networking.hostName = "rpi5-vpn";
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;

  imports = [ ];

#  boot.loader.generic-extlinux-compatible.enable = lib.mkForce false;
#  boot.loader.systemd-boot.enable = true;
#  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.raspberryPi = {
    enable = true;
    uboot.enable = false;
  };
  boot.loader.generic-extlinux-compatible.enable = lib.mkForce false;

  boot.initrd.network.enable = true;
  boot.initrd.network.ssh.enable = true;
  boot.initrd.network.ssh.authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIAAk0liWgeVtW7RVeg+jnGqJOpGvmVvh/aFOpJGvu3B vpn"
  ];

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIAAk0liWgeVtW7RVeg+jnGqJOpGvmVvh/aFOpJGvu3B vpn"
  ];

  services.wireguard.enable = true;
  services.fail2ban.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 51820 ]; # add WireGuard + SSH
  };
  services.tor.enable = false; # optional, can be turned on
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;

  time.timeZone = "Etc/UTC";

  services.prometheus.exporters.node.enable = true;

  environment.systemPackages = with pkgs; [
    restic
    borgbackup
    wireguard-tools
    fail2ban
    ddclient
    tor
  ];

  services.ddclient = {
    enable = true;
    configFile = "/etc/ddclient/ddclient.conf"; # You provide this
  };

  security.sudo.wheelNeedsPassword = false;
}