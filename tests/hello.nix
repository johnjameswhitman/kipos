{ pkgs, secrets, ... }:
{
  name = "hello";
  nodes = {
    machine1 =
      { pkgs, ... }:
      {
        imports = [ ../machines/hello.nix ];
        environment.systemPackages = [ pkgs.hello ];
        environment.etc."dummy".text = secrets.dummy_secret;
      };
  };
  testScript = ''
    start_all()
    machine1.wait_for_unit("sshd.service")
    machine1.succeed("hello")
    machine1.succeed("cat /etc/dummy")
  '';
}
