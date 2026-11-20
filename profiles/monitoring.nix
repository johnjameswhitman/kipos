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

  # journald → OpenObserve on silver (Loki-compatible push). The Loki
  # container on :3100 is retired. Config via environment.etc (services.alloy
  # default configPath=/etc/alloy, reloadable on switch).
  #
  # Prerequisite on blue, not stored in this repo: /etc/alloy/o2pass owned by
  # root, mode 600. nixpkgs runs alloy as DynamicUser, which cannot read that
  # file, so PID 1 loads it with LoadCredential and the config reads
  # $CREDENTIALS_DIRECTORY/o2pass. ConditionPathExists skips the unit instead
  # of failing the switch when the file is absent; `systemctl start alloy`
  # (or a reboot) picks it up afterwards. A trailing newline in the file is
  # fine; the client trims surrounding whitespace.
  services.alloy.enable = true;
  systemd.services.alloy.unitConfig.ConditionPathExists = "/etc/alloy/o2pass";
  systemd.services.alloy.serviceConfig.LoadCredential = [ "o2pass:/etc/alloy/o2pass" ];
  system.activationScripts.alloy-o2pass.text = ''
    if [ ! -f /etc/alloy/o2pass ]; then
      printf '%s\n' "monitoring: /etc/alloy/o2pass is absent; alloy.service is skipped until that root-owned mode-600 file is installed, then run: systemctl start alloy" >&2
    else
      mode=$(${pkgs.coreutils}/bin/stat -c %a /etc/alloy/o2pass 2>/dev/null || printf '%s' unknown)
      if [ "$mode" != "600" ]; then
        printf '%s\n' "monitoring: /etc/alloy/o2pass mode is $mode; expected 600 so only root can read the OpenObserve password. Activation continues." >&2
      fi
    fi
  '';
  environment.etc."alloy/config.alloy".text = ''
    // __journal_* labels are dropped before forward_to, so host/unit have to
    // be copied with relabel_rules on the journal source. forward_to is
    // required on loki.relabel and ignored when only its rules export is used.
    // loki.write exports receiver; .endpoint is not an export (see darwin.nix).
    loki.relabel "blue" {
      forward_to = []

      rule {
        source_labels = ["__journal__hostname"]
        target_label = "host"
      }
      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label = "unit"
      }
    }

    loki.source.journal "blue" {
      path = "/var/log/journal"
      forward_to = [loki.write.default.receiver]
      relabel_rules = loki.relabel.blue.rules
    }

    loki.write "default" {
      endpoint {
        url = "http://192.168.20.26:5080/api/default/loki/api/v1/push"
        basic_auth {
          username = "root@openobserve.local"
          password_file = sys.env("CREDENTIALS_DIRECTORY") + "/o2pass"
        }
      }
    }
  '';
}
