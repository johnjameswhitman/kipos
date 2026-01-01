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
        address = "192.168.20.1";
        prefixLength = 24;
      }
    ];
    wlp5s0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.1.21";
          prefixLength = 24;
        }
      ];
    };
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowPing = true;

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
        5353
      ];
    };

    # Allow some traffic from downstairs
    interfaces.wlp5s0 = {
      allowedTCPPorts = [
        22
        53
      ];
      allowedUDPPorts = [
        53
        5353
      ];
    };

    # Allow traffic between floors
    extraCommands = ''
      iptables -A FORWARD -i br0 -o wlp5s0 -j ACCEPT
      iptables -A FORWARD -i wlp5s0 -o br0 -j ACCEPT
    '';

  };

  networking.nat = {
    enable = true;
    externalInterface = "enp1s0";
    internalIPs = [
      "192.168.20.0/24"
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
      host-record = [
        "blue.local,192.168.20.1"
      ];

      # DHCP
      dhcp-range = [ "interface:br0,192.168.20.32,192.168.20.254,24h" ];
      dhcp-option = [
        "3,192.168.20.1" # default gateway
        "6,192.168.20.1" # dns
      ];
      dhcp-authoritative = true;
      dhcp-rapid-commit = true;
    };
  };

  # mDNS
  services.avahi = {
    enable = true;
    nssmdns4 = true; # Allow software to resolve .local domains
    reflector = true; # For continuity with first floor
    allowInterfaces = [
      "br0"
      "wlp5s0"
    ];
  };

}
