{ pkgs, secrets, ... }:
{
  name = "hello";
  nodes = {
    machine1 =
      { pkgs, ... }:
      {
        imports = [ ../machines/hello.nix ];
        environment.systemPackages = [ pkgs.hello ];
        sops = {
          age.keyFile = "/etc/sops/age/keys.txt";
          defaultSopsFile = /etc/sops/secrets.yaml;
          secrets.hello.neededForUsers = false;
        };
      };
  };
  testScript = ''
    start_all()
    machine1.wait_for_unit("sops-nix.service")
    machine1.succeed("hello")
    machine1.succeed("[[ $(cat /run/secrets/hello) == world ]]")
  '';
}
