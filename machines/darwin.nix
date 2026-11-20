{ config, pkgs, ... }:
let
  # OpenObserve on silver (Loki-compatible push). The Loki container on :3100
  # is retired. The password is not in this repo: install /etc/alloy/o2pass
  # on mini24 and mbp24 (owner root, mode 600) before Alloy can authenticate.
  # launchd runs the daemon as root, so it can read that file. A trailing
  # newline is fine; the client trims surrounding whitespace. Activation does
  # not create the file and does not fail when it is missing.
  lokiUrl = "http://192.168.20.26:5080/api/default/loki/api/v1/push";
in
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  # --- monitoring (node_exporter to silver; logs to OpenObserve) ---
  # Re-allow node_exporter in the app firewall on each activation: nix store
  # paths change per generation and socketfilterfw matches by exact path.
  system.activationScripts.monitoring.text = ''
    NE="${pkgs.prometheus-node-exporter}/bin/node_exporter"
    /usr/libexec/ApplicationFirewall/socketfilterfw --add "$NE" >/dev/null 2>&1 || true
    /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp "$NE" >/dev/null 2>&1 || true
    /bin/mkdir -p /var/lib/alloy
    # Warn only. darwin-rebuild runs activation with `set -e`; a missing or
    # loose password file must not abort the switch. /etc/alloy/o2pass is a
    # normal file beside the nix-managed config.alloy symlink — do not replace
    # that symlink.
    if [ ! -f /etc/alloy/o2pass ]; then
      printf '%s\n' "monitoring: /etc/alloy/o2pass is absent; activation continues, but Alloy cannot authenticate to OpenObserve until that root-owned mode-600 file is installed." >&2
    else
      mode=$(/usr/bin/stat -f '%Lp' /etc/alloy/o2pass 2>/dev/null || printf '%s' unknown)
      if [ "$mode" != "600" ]; then
        printf '%s\n' "monitoring: /etc/alloy/o2pass mode is $mode; expected 600 so only root can read the OpenObserve password. Activation continues." >&2
      fi
    fi
  '';
  system.activationScripts.monitoring.order = 700;
  environment.etc."alloy/config.alloy".text = ''
    local.file_match "mini24" {
      // sync the file tailers with new files appearing in the log dir
      sync_period = "5m"
      path_targets = [
        {"__path__" = "/var/log/install.log"},
        {"__path__" = "/var/log/system.log"},
      ]
    }

    loki.source.file "mini24" {
      targets = local.file_match.mini24.targets
      forward_to = [loki.relabel.mini24.receiver]
    }

    loki.relabel "mini24" {
      forward_to = [loki.write.default.receiver]
      rule {
        source_labels = ["__path__"]
        target_label = "host"
        // mini24 and mbp24 share this module, so mbp24 logs are labeled
        // host=mini24 as well.
        replacement = "mini24"
      }
    }

    loki.write "default" {
      endpoint {
        url = "${lokiUrl}"
        basic_auth {
          username = "root@openobserve.local"
          password_file = "/etc/alloy/o2pass"
        }
      }
    }
  '';

  launchd.daemons.node-exporter = {
    command = "${pkgs.prometheus-node-exporter}/bin/node_exporter";
    serviceConfig.RunAtLoad = true;
    serviceConfig.KeepAlive = true;
    serviceConfig.ProcessType = "Background";
  };
  launchd.daemons.alloy = {
    # --storage.path is required: launchd cwd is / (read-only SES root),
    # alloy default data-alloy/ dir would fail with EROFS.
    command = "${pkgs.grafana-alloy}/bin/alloy run --server.http.listen-addr=127.0.0.1:12345 --storage.path=/var/lib/alloy /etc/alloy/config.alloy";
    serviceConfig.RunAtLoad = true;
    serviceConfig.KeepAlive = true;
    serviceConfig.ProcessType = "Background";
  };

  # Homebrew packages (need to manually install homebrew first)
  homebrew.enable = true;
  homebrew.casks = [
    "gnucash"
    "joplin"
    "middleclick"
    "obsidian"
    "sensiblesidebuttons"
    "sanesidebuttons"
    "steam"
  ];

  # nix-darwin >= 5.7: activation runs as root; homebrew needs the primary user.
  system.primaryUser = "johnwhitman";

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Auto-clean nix packages
  nix.gc.automatic = true;

  # Set Git commit hash for darwin-version.
  # system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Allow unfree packages.
  nixpkgs.config.allowUnfree = true;

  # Try to use same version of nix as nixpkgs.
  nix.package = pkgs.nixVersions.latest;

}
