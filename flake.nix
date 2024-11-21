{
  description = "Kipos flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    alejandra.url = "github:kamadorueda/alejandra/d7552fef2ccf1bbf0d36b27f6fddb19073f205b7";
    alejandra.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    alejandra,
    disko,
    nixpkgs,
    self,
    sops-nix,
    ...
  }: let
    system = "x86_64-linux"; # Later can add support for darwin as-needed.
    pkgs = import nixpkgs {
      system = "${system}";
      config.allowUnfree = true;
    };
    makeTest = import (pkgs.path + "/nixos/tests/make-test-python.nix");
    eval-config = import (pkgs.path + "/nixos/lib/eval-config.nix");
    lib = pkgs.lib;
    diskoLib = import disko.lib {inherit lib makeTest eval-config;};
  in {
    formatter.${system} = alejandra.defaultPackage.${system};
    devShell."${system}" = import ./shell.nix {inherit pkgs;};

    # test is a hostname for our machine
    # nixosConfigurations.hello = nixpkgs.lib.nixosSystem {
    #   inherit system;
    #   modules = [
    #     ./configuration.nix
    #   ];
    # };

    checks.${system} = {
      hello = pkgs.testers.runNixOSTest ./tests/hello.nix;
      # silver = disko.lib.testLib.makeDiskoTest (import ./tests/silver.nix);
      silverAlt = diskoLib.testLib.makeDiskoTest (import ./tests/silver.nix);
      k3s-multi-node = pkgs.testers.runNixOSTest ./tests/k3s-multi-node.nix;
    };
  };
}
