{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.john = {
    uid = 1000;
    isNormalUser = true;
    shell = pkgs.fish;

    extraGroups = [
      "builders"
      "docker"
      "libvirtd"
      "lxd"
      "networking"
      "podman"
      "ssh_users"
      "wheel"
    ];

    # For rootless podman.
    # https://gist.github.com/adisbladis/187204cb772800489ee3dac4acdd9947
    # https://wiki.archlinux.org/title/Podman#Set_subuid_and_subgid
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];

    openssh.authorizedKeys.keyFiles = [
      ./id_ed25519_hp_nas.pub
      ./id_ed25519_iphone_14_pro.pub
      ./id_ed25519_mbp24.pub
      ./id_ed25519_mini24.pub
      ./id_rsa_hp_nas.pub
      ./id_rsa_x1c6.pub
      ./id_rsa_z420.pub
    ];
  };
}
