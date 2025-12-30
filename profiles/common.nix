{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./users/john
  ];

  # Set your time zone.
  time.timeZone = "America/New_York";

  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  environment.systemPackages = with pkgs; [
    curl
    git
    dnsutils
    home-manager
    iw
    jq
    pciutils
    python3
    stow # bootstraps homedir.
    vim
    vimPlugins.python-mode
    vimPlugins.vim-addon-nix
    wget
    wirelesstools
  ];

  programs.fish.enable = true;

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  users.groups = {
    builders = { };
    ssh_users = { };
  };

  nix.settings.trusted-users = [
    "root"
    "@builders"
    "@wheel"
  ];
  nix.settings.experimental-features = "nix-command flakes";

  # If SSH is enabled, limit it to members of ssh_users
  services.openssh.settings.AllowGroups = [ "ssh_users" ];

}
