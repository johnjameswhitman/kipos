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
    machine1.wait_for_unit("sshd.service")
    machine1.succeed("hello")
  '';
}
