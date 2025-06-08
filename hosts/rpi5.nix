{ config, pkgs, lib, ... }:
  # Replace boot.initrd.secrets
  let
    initrdHostKey = pkgs.runCommand "ssh-initrd-key" { } ''
      mkdir -p $out
      cp ${config.sops.secrets.sshHostKey.path} $out/ssh_host_ed25519_key
    '';
  in
{
  imports = [ ];

  fileSystems."/".device = lib.mkForce "/dev/mapper/crypted";

  networking.hostName = "rpi5-vpn";
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIAAk0liWgeVtW7RVeg+jnGqJOpGvmVvh/aFOpJGvu3B vpn"
  ];

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  security.pam.sshAgentAuth.enable = true;

  environment.systemPackages = with pkgs; [ wireguard-tools tor ddclient ];

  services.fail2ban.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 51820 ];
    allowedUDPPorts = [ 51820 ];
  };

  systemd.timers.nixos-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  systemd.services.nixos-update = {
    script = ''
      nix-channel --update
      nixos-rebuild switch --flake /etc/nixos
    '';
    serviceConfig.Type = "oneshot";
  };

  boot.initrd.network.enable = true;

  boot.initrd.luks.devices."crypted".keyFile = lib.mkForce "/mnt/keyfile.bin";

  boot.initrd.preDeviceCommands = ''
    mkdir -p /mnt
    mount -t vfat -o ro /dev/disk/by-label/KEYUSB /mnt || \
    mount -t ext4 -o ro /dev/disk/by-label/KEYUSB /mnt
  '';

  boot.initrd.network.ssh = {
    enable = true;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIAAk0liWgeVtW7RVeg+jnGqJOpGvmVvh/aFOpJGvu3B vpn"
    ];
    port = 2222;
    hostKeys = [ "/etc/ssh-initrd/ssh_host_ed25519_key" ];
  };

  boot.initrd.secrets = {
  "/etc/ssh-initrd/ssh_host_ed25519_key" = lib.mkForce "${initrdHostKey}/ssh_host_ed25519_key";
  };

  systemd.services.prepare-initrd-secrets = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p /var/lib/ssh-initrd
      cp ${config.sops.secrets.sshHostKey.path} /var/lib/ssh-initrd/ssh_host_ed25519_key
      chmod 0400 /var/lib/ssh-initrd/ssh_host_ed25519_key
    '';
  };

  sops.age.keyFile = "/etc/sops/age/key.txt";

  sops.secrets = {
    sshHostKey = {
      sopsFile = ./../secrets/initrd.yaml;
      path = "/etc/ssh-initrd/ssh_host_ed25519_key";
    };

    wireguardPrivateKey = {
      sopsFile = ./../secrets/secrets.yaml;
      restartUnits = [ "wg-quick-wg0.service" ];
    };

    ddclientConf = {
      sopsFile = ./../secrets/ddclient.yaml;
      path = "/etc/ddclient/ddclient.conf";
    };
  };

  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.100.0.1/24" ];
    listenPort = 51820;
    privateKeyFile = config.sops.secrets.wireguardPrivateKey.path;
    peers = [
      {
        publicKey = "6PFdVDrs+2JWqtBWHPAKToQcLPJZHMQdEMJazGv8Z30=";
        allowedIPs = [ "10.100.0.2/32" ];
        persistentKeepalive = 25;
      }
    ];
  };

  services.ddclient = {
    enable = true;
    configFile = "/etc/ddclient/ddclient.conf";
  };

  services.tor = {
    enable = true;
    client.enable = true;
    settings = {
      SocksPort = "9050";
    };
  };

  system.stateVersion = "24.05";
}