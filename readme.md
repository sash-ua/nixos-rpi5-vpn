# nixos-rpi5-vpn: Bootable Encrypted NVMe SSD Image for Raspberry Pi 5

## Overview
A secure, reproducible NixOS configuration targeting Raspberry Pi 5, enabling:
- Bootable NVMe SSD with FAT32 `/boot` and LUKS-encrypted root
- WireGuard VPN server
- SSH key access
- Dropbear in initrd for remote LUKS unlock
- UFW, Fail2Ban, unattended-upgrades
- Tor and Dynamic DNS integration

---

Flake Layout
```bash
nixos-rpi5-vpn/
├── flake.nix
├── flake.lock
├── hosts/
│   └── rpi5.nix
├── hardware/
│   └── rpi5-hardware.nix
├── overlays/
│   └── default.nix
└── disk-config.nix
```

---

Build & Flash
```bash
# Build system image:
nix build .#nixosConfigurations.rpi5.config.system.build.sdImage

# Write to SSD using Raspberry Pi Imager or dd
sudo dd if=result/sd-image/*.img of=/dev/sdX bs=4M status=progress
```
Next steps:
1.	Generate WireGuard keys and /etc/wireguard/private.key.
2.	Configure /etc/ddclient/ddclient.conf with your DDNS provider.
3.	Flash the image to the SSD and boot.
