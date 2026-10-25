# Shared monitoring profile: metrics + log shipping for kipos hosts.
# silver runs the stack (kipos-monitoring repo); this ships host data to it.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Host metrics for the vmagent `node` job on silver.
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = [ "systemd" ];
    extraFlags = [
      "--collector.systemd.unit-whitelist=(incus|docker|dnsmasq|wpa_supplicant|systemd-journald).service"
    ];
  };
  # openFirewall only touches top-level allowedTCPPorts — useless when a
  # per-interface firewall is defined (blue). Open 9100 on the LAN side.
  networking.firewall.interfaces.br0.allowedTCPPorts = [ 9100 ];

  # journald → Loki on silver. Config via environment.etc (services.alloy
  # default configPath=/etc/alloy, reloadable on switch).
  services.alloy.enable = true;
  environment.etc."alloy/config.alloy".text = ''
    loki.source.journal "blue" {
      path = "/var/log/journal"
    }

    loki.relabel "blue" {
      forward_to = [loki.write.default.endpoint]

      rule {
        source_labels = ["__journal__hostname"]
        target_label = "host"
      }
      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label = "unit"
      }
    }

    loki.write "default" {
      endpoint {
        url = "http://192.168.20.26:3100/loki/api/v1/push"
      }
    }
  '';
}
