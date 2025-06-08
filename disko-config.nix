{ config, lib, ... }:

let
  firmwarePartition = {
    label = "FIRMWARE";
    priority = 1;
    type = "0700";  # Microsoft basic data (for Pi firmware)
    attributes = [ 0 ];
    size = "1024M";
    content = {
      type = "filesystem";
      format = "vfat";
      mountpoint = "/boot/firmware";
      mountOptions = [
        "noatime"
        "noauto"
        "x-systemd.automount"
        "x-systemd.idle-timeout=1min"
      ];
    };
  };
in {
  disko.devices = {
    disk.nvme0 = {
      type = "disk";
      device = "/dev/nvme0";
      content = {
        type = "gpt";
        partitions = {
          FIRMWARE = firmwarePartition;

          root = {
            label = "CRYPT";
            size = "100%";
            content = {
              type = "luks";
              name = "crypted";
              settings.allowDiscards = true;
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [ "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}