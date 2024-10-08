{pkgs, ...}: {
  name = "hello";
  nodes = {
    machine = {pkgs, ...}: {
      imports = [../machines/hello.nix];
      environment.systemPackages = [pkgs.hello];
    };
  };
  testScript = ''
    start_all()
    machine.wait_for_unit("sshd.service")
    machine.succeed("hello")
    machine.succeed("ssh-keygen -t rsa -N ''' -f ~/.ssh/id_rsa")
  '';
}
