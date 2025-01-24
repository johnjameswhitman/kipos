{ pkgs, ... }:
{
  name = "hello";
  nodes = {
    machine1 =
      { pkgs, ... }:
      {
        imports = [ ../machines/hello.nix ];
        environment.systemPackages = [ pkgs.hello ];
      };
  };
  testScript = ''
    start_all()
    machine1.wait_for_unit("sops-nix.service")
    machine1.succeed("hello")
    # machine1.succeed("[[ $(cat /run/secrets/hello) == world ]]")
    machine1.succeed("[[ $(cat /etc/hello) == world ]]")
  '';
}
