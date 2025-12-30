{ inputs, ... }:
{
  name = "sanity";
  nodes = {
    machine1 =
      { pkgs, ... }:
      let
        secrets_path = builtins.toString inputs.secrets;
      in
      {
        imports = [
          ./sanity_vm.nix
          inputs.sops-nix.nixosModules.sops
        ];

        environment.systemPackages = [ pkgs.hello ];

        environment.etc = {
          "hello".text = inputs.secrets.dummy.hello;
          "sops/age/keys.txt".text = inputs.secrets.dummy.age_key;
          "sops/secrets.yaml".text = inputs.secrets.dummy.sops_yaml;
        };

        sops = {
          age.keyFile = "/etc/sops/age/keys.txt";
          defaultSopsFile = "/etc/sops/secrets.yaml";
          # sops-nix complained about the secrets not living in the store, but
          # I had trouble finding an approach that exposed secrets.yaml from
          # the host store (CI kept complanining that the path did not exist).
          validateSopsFiles = false;
          # While iterating you can do:
          # nix build .#checks.x86_64-linux.hello --override-input secrets ../kipos-secrets
          secrets.hello = { };
        };
      };
  };
  testScript = ''
    start_all()
    # machine1.wait_for_unit("sops-nix.service")
    machine1.wait_for_unit("sshd.service")
    machine1.succeed("hello")
    machine1.succeed("[[ $(cat /etc/hello) == world ]]")
    machine1.succeed("[[ $(cat /run/secrets/hello) == world ]]")
  '';
}
