{
  description = "Kipos flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
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
  in {
    formatter.${system} = pkgs.alejandra;

    # test is a hostname for our machine
    #    nixosConfigurations.hello = nixpkgs.lib.nixosSystem {
    #      inherit system;
    #      modules = [
    #        ./configuration.nix
    #      ];
    #    };

    checks.${system}.hello = pkgs.testers.runNixOSTest ./tests/hello.nix;
  };
}
