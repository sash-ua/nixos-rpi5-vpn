{ pkgs, ... }:
{
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Raspberry Pi 5 uses same kernel as RPi4
  boot.kernelPackages = pkgs.linuxPackages_rpi4;

  # Required modules
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usbhid" ];
  boot.kernelModules = [ "kvm-arm64" ];
}
