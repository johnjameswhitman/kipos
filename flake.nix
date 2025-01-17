{
  description = "Kipos flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    # sops-nix.url = "github:Mic92/sops-nix";
    # sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{
      disko,
      flake-parts,
      nixpkgs,
      self,
      # sops-nix,
      nix-darwin,
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
        in
        {

          checks."x86_64-linux" = {
            hello = x86_64_linux_pkgs.testers.runNixOSTest ./tests/hello.nix;
            k3s-multi-node = x86_64_linux_pkgs.testers.runNixOSTest ./tests/k3s-multi-node.nix;
          };

          darwinConfigurations.mbp24 = inputs.nix-darwin.lib.darwinSystem {
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
