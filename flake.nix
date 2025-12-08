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

  outputs =
    inputs@{
      disko,
      flake-parts,
      nixpkgs,
      self,
      sops-nix,
      nix-darwin,
      secrets,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {

      imports = [ inputs.treefmt-nix.flakeModule ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {

          devShells = {
            default = pkgs.mkShell {
              nativeBuildInputs = with pkgs; [
                act
                nixd
                pre-commit
              ];
            };
          };

          treefmt.config = {
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = true;
          };
          formatter = config.treefmt.build.wrapper;

        };

      flake =
        let
          x86_64_linux_pkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
          lib = x86_64_linux_pkgs.lib;
          makeTest = import (x86_64_linux_pkgs.path + "/nixos/tests/make-test-python.nix");
          eval-config = import (x86_64_linux_pkgs.path + "/nixos/lib/eval-config.nix");
          qemu-common = import (x86_64_linux_pkgs.path + "/nixos/lib/qemu-common.nix");
          diskoLib = import (disko + "/lib") {inherit lib makeTest eval-config;};
        in
        {

          secrets_path = builtins.toString inputs.secrets;
          checks."x86_64-linux" = let pkgs = x86_64_linux_pkgs; in {
            # https://discourse.nixos.org/t/infinite-recursion-when-modularizing-flake-runnixostest/58579/6
            # Run with: nix run -L .\#checks.x86_64-linux.test.driverInteractive
            hello = x86_64_linux_pkgs.testers.runNixOSTest (import ./tests/hello.nix { inherit inputs; });
            k3s-multi-node = x86_64_linux_pkgs.testers.runNixOSTest ./tests/k3s-multi-node.nix;
            diskoDemo = diskoLib.testLib.makeDiskoTest ((import ./tests/silver.nix) // {inherit pkgs;});
          };

          darwinConfigurations.mbp24 = inputs.nix-darwin.lib.darwinSystem {
            modules = [ ./machines/darwin.nix ];
            specialArgs = {
              inherit inputs;
            };
          };

          darwinConfigurations.mini24 = inputs.nix-darwin.lib.darwinSystem {
            modules = [ ./machines/darwin.nix ];
            specialArgs = {
              inherit inputs;
            };
          };

          # nixosConfigurations.hello = inputs.nixpkgs.lib.nixosSystem {
          #   system = "x86_64-linux";
          #   modules = [ ./machines/hello.nix ];
          # };

        };
    };

}
