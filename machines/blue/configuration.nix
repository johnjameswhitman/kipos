# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./router.nix
    ../../profiles/common.nix
    ../../profiles/users/deployer
    inputs.sops-nix.nixosModules.sops
  ];

  # WiFi things
  # networking.wireless.athUserRegulatoryDomain = true;
  hardware.enableRedistributableFirmware = true;
  hardware.firmware = [
    pkgs.wireless-regdb
  ];
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="US"
  '';

  boot.kernelParams = [
    "amd_iommu=off"
    "console=ttyS0,115200n8"
  ];
  boot.loader.grub.extraConfig = "
    serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1
    terminal_input serial
    terminal_output serial
  ";

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only
  networking.hostName = "blue"; # Define your hostname.
  networking.hostId = "ad79e2ce";

  # https://nixos.wiki/wiki/Distributed_build#NixOS
  nix.buildMachines = [
    {
      hostName = "builder";
      system = "x86_64-linux";
      maxJobs = 1;
      speedFactor = 2;
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
      mandatoryFeatures = [ ];
    }
  ];
  nix.distributedBuilds = true;
  nix.extraOptions = ''
    builders-use-substitutes = true
  '';
  nix.settings.trusted-users = [
    "root"
    "@wheel"
  ];

  sops = {
    defaultSopsFile = inputs.secrets + "/machines/blue/secrets.yaml";
    secrets.wifi = { };
  };

  # systemd.services."wpa_supplicant-wlp5s0.service".Unit.After
  networking.wireless = {
    enable = true;
    interfaces = [ "wlp5s0" ];
    secretsFile = config.sops.secrets.wifi.path;
    networks.downstairs = {
      ssid = inputs.secrets.blue.wifi_downstairs_ssid;
      pskRaw = "ext:downstairs_psk";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}
