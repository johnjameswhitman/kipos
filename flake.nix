{
  description = "Kipos flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    secrets.url = "git+ssh://git@github.com/johnjameswhitman/kipos-secrets.git?ref=main&shallow=1";
    secrets.inputs.nixpkgs.follows = "nixpkgs";

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
    diskoLib = import (disko + "/lib") {inherit lib makeTest eval-config;};
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
      # silverAlt = diskoLib.testLib.makeDiskoTest (import ./tests/silver.nix);
      silverAlt = diskoLib.testLib.makeDiskoTest ((import ./tests/silver.nix) // {inherit pkgs;});
      k3s-multi-node = pkgs.testers.runNixOSTest ./tests/k3s-multi-node.nix;
    };

}
