# Importing this implies that a remote user can deploy to the importer.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.deployer = {
    description = "system deploy user";
    uid = 1003;
    isNormalUser = true;
    extraGroups = [
      "builders"
      "wheel"
      "networking"
      "sudo"
    ]; # Enable ‘sudo’ for the user.

    openssh.authorizedKeys.keyFiles = [
      ./id_ed25519_hp_nas.pub
      ./id_rsa_hp_nas.pub
      ./id_rsa_x1c6.pub
      ./id_rsa_z420.pub
    ];
  };

  services.openssh.settings.AllowUsers = [ "deployer" ];

  security.sudo.extraRules = [
    {
      users = [ "deployer" ];
      commands = [
        {
          command = "/nix/store/*-activatable-nixos-system-*/activate-rs";
          options = [
            "NOPASSWD"
          ];
        }
        {
          command = "/run/current-system/sw/bin/rm /tmp/deploy-rs-canary-*";
          options = [
            "NOPASSWD"
          ];
        }
      ];
    }
  ];

  nix.settings.trusted-users = [ "deployer" ];

}
