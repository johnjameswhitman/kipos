{ config, pkgs, ... }:
let
  lokiUrl = "http://192.168.20.26:3100/loki/api/v1/push";
in
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  # --- monitoring (kipos-monitoring stack on silver) ---
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
        replacement = "mini24"
      }
    }

    loki.write "default" {
      endpoint { url = "${lokiUrl}" }
    }
  '';

  launchd.daemons.node-exporter = {
    command = "${pkgs.prometheus-node-exporter}/bin/node_exporter";
    serviceConfig.RunAtLoad = true;
    serviceConfig.KeepAlive = true;
    serviceConfig.ProcessType = "Background";
  };
  launchd.daemons.alloy = {
    command = "${pkgs.grafana-alloy}/bin/alloy run /etc/alloy/config.alloy";
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
