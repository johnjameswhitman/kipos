{ pkgs, ... }:
{
  name = "router-nat-verification";

  nodes = {
    # 1. The Internet (Simulated ISP)
    # Represents the outside world.
    upstream =
      { ... }:
      {
        virtualisation.vlans = [ 1 ]; # Connects to Router WAN
        networking.interfaces.eth1.ipv4.addresses = [
          {
            address = "198.51.100.1";
            prefixLength = 24;
          }
        ];
        networking.firewall.enable = false; # Allow all traffic for the test "internet"
      };

    # 2. The Router (DUT - Device Under Test)
    # This mocks your APU2 configuration.
    router =
      { config, pkgs, ... }:
      {
        virtualisation.vlans = [
          1
          2
        ]; # 1=WAN, 2=LAN

        # Enable Packet Forwarding (Critical for routers)
        boot.kernel.sysctl = {
          "net.ipv4.conf.all.forwarding" = true;
          "net.ipv6.conf.all.forwarding" = true;
        };

        # WAN Configuration (eth1)
        networking.interfaces.eth1.ipv4.addresses = [
          {
            address = "198.51.100.2";
            prefixLength = 24;
          }
        ];
        networking.defaultGateway = "198.51.100.1";

        # LAN Configuration (eth2)
        networking.interfaces.eth2.ipv4.addresses = [
          {
            address = "192.168.1.1";
            prefixLength = 24;
          }
        ];

        # Firewall & NAT
        networking.nat = {
          enable = true;
          externalInterface = "eth1";
          internalInterfaces = [ "eth2" ];
        };

        # Ensure firewall is actually on
        networking.firewall.enable = true;
      };

    # 3. The Client (LAN Device)
    # Represents a laptop or server behind the router.
    client =
      { ... }:
      {
        virtualisation.vlans = [ 2 ]; # Connects to Router LAN
        networking.interfaces.eth1.ipv4.addresses = [
          {
            address = "192.168.1.2";
            prefixLength = 24;
          }
        ];
        networking.defaultGateway = "192.168.1.1";
      };
  };

  # The Python Test Script
  testScript = ''
    start_all()

    # 1. Wait for networks to come up
    upstream.wait_for_unit("network.target")
    router.wait_for_unit("network.target")
    client.wait_for_unit("network.target")

    with subtest("Verify Local LAN Connectivity"):
        # Can the client ping the router's LAN IP?
        client.succeed("ping -c 1 192.168.1.1")

    with subtest("Verify NAT / Internet Connectivity"):
        # Can the client reach the 'Internet' (Upstream) via the Router?
        # This confirms Masquerading/NAT is working.
        client.succeed("ping -c 1 198.51.100.1")

    with subtest("Verify Firewall Blocks Inbound"):
        # The Upstream should NOT be able to reach the Client directly
        upstream.fail("ping -c 1 192.168.1.2")
  '';

}
