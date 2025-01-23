{ config, pkgs, ... }:
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  # Homebrew packages (need to manually install homebrew first)
  homebrew.enable = true;
  homebrew.casks = [
    "gnucash"
    "joplin"
    "middleclick"
    "obsidian"
    "sensiblesidebuttons"
    "steam"
  ];

  services.nix-daemon.enable = true;

  security.pam.enableSudoTouchIdAuth = true;

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
