{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./users/john
  ];

  # Set your time zone.
  time.timeZone = "America/New_York";

  networking.useDHCP = false; # Deprecated

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
    builders = {};
  };

  nix.settings.trusted-users = [
    "root"
    "@builders"
    "@wheel"
  ];
}
