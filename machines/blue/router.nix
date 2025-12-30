# Pretty much ripped from: https://github.com/jgillich/nixos/blob/master/roles/router.nix
{
  config,
  lib,
  pkgs,
  ...
}:
{

  environment.systemPackages = with pkgs; [
    dnsmasq
    hostapd
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  networking.domain = "local";
  networking.nameservers = [
    "127.0.0.1"
    "8.8.8.8"
    "8.8.4.4"
  ];

  # Native interfaces
  networking.interfaces.enp1s0.useDHCP = true; # WAN, next to serial
  networking.interfaces.enp2s0.useDHCP = false; # LAN, bridged
  networking.interfaces.enp3s0.useDHCP = false; # LAN, bridged
  networking.interfaces.enp4s0.useDHCP = false; # LAN, bridged

  # Wireless interface - original mac: 04:f0:21:88:49:a3
  # Change this so that hostapd can manage sub-interfaces:
  # https://wallabag.s2sq.com/view/465
  # networking.interfaces.wlp5s0.macAddress = "06:f0:21:88:49:a0";
  networking.wlanInterfaces = {
    wlp5s0 = {
      device = "wlp5s0";
    };
  };

  networking.bridges = {
    br0.interfaces = [
      "enp2s0"
      "enp3s0"
      "enp4s0"
    ];
  };

  networking.interfaces = {
    br0.ipv4.addresses = [
      {
        address = "192.168.2.1";
        prefixLength = 24;
      }
    ];
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowPing = true;
    # TODO: disable SSH on WAN
    interfaces.enp1s0.allowedTCPPorts = [ 22 ];
    # Enable basic services on the LAN-side of router
    interfaces.br0 = {
      allowedTCPPorts = [
        22
        53
        80
        443
      ];
      allowedUDPPorts = [
        53
        67
      ];
    };
  };

  networking.nat = {
    enable = true;
    externalInterface = "enp1s0";
    internalIPs = [
      "192.168.2.0/24"
    ];
  };

  services.dnsmasq = {
    enable = true;
    settings = {
      # General
      domain-needed = true;
      bogus-priv = true;
      no-resolv = true;

      # Local domain settings
      domain = "local";
      local = "/local/";
      expand-hosts = true;

      # Listening settings
      interface = [ "br0" ];
      bind-interfaces = true;

      # DNS
      server = [
        "8.8.8.8"
        "8.8.4.4"
      ];
      cache-size = 1024;

      # DHCP
      dhcp-range = [ "interface:br0,192.168.2.32,192.168.2.254,24h" ];
      dhcp-option = [
        "3,192.168.2.1" # default gateway
        "6,192.168.2.1" # dns
      ];
      dhcp-authoritative = true;
      dhcp-rapid-commit = true;
    };
  };

}
