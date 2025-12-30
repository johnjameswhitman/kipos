# Kipos

Collection of system configs for my machines.

## TODO

- [x] Configure a basic `test` VM with flake
- [x] Build `test` VM locally (ref: [_Setting up qemu VM using nix flakes_][nix_vm_gist])
    ```shell
    nixos-rebuild build-vm --flake .#test
    QEMU_NET_OPTS="hostfwd=tcp::2221-:22" result/bin/run-nixos-vm
    # VM will run in the terminal where you started it, but you can also SSH in:
    ssh -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no admin@localhost -p 2221
    # Once done, hit CTRL+a,x to shut down VM
    ```
- [x] Build `test` VM locally
- [x] Build `test` VM in GHA
- [x] Wire secrets into the repo (ref [blog post][secrets_blog_post])
    - [x] Set up `kipos-secrets` non-public repo to hold SOPS yaml (ref [sops-nix][sops_nix]
        for basic getting-started info)
    - [x] Generate `kipos-secrets` [Deploy Key][gh_deploy_keys] pair (public key
        goes into `kipos-secrets` settings, private key goes into `kipos`
        secret)
    - [x] Update `kipos` GHA to load private Deploy Key from secret into
        ssh-agent
    - [x] Reference `kipos-secrets` as an input to flake
    - [x] Wire dummy secrets into `hello.nix` test
- [ ] Auto-update flake via GHA
- [ ] See if disko works with tests
- [ ] Clean up `hello.nix`

### Router

- [x] Pull in old config
- [x] Simplify config:
  - [x] No VLANs to start
  - [x] Single subnet
  - [x] DNS / DHCP
  - [x] NAT for basics
- [x] Set up secrets
- [x] Re-image machine, add deploy key to CI
- [ ] SSH config for remote builds
- [ ] Simple WiFi network
- [ ] Wireguard
- [ ] Observability
  - [ ] Logging
  - [ ] Metrics
  - [ ] pmacct or ntopng

[nix_vm_gist]: https://gist.github.com/FlakM/0535b8aa7efec56906c5ab5e32580adf
[gh_deploy_keys]: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys#deploy-keys
[sops_nix]: https://github.com/Mic92/sops-nix
[secrets_blog_post]: https://unmovedcentre.com/posts/secrets-management/#overview-and-video

## Refs

Other people's configs...

- https://github.com/dustinlyons/nixos-config/blob/main/modules/darwin/casks.nix
- https://github.com/cameronraysmith/nix-config/blob/main/flake.nix
- https://0xda.de/blog/2024/07/framework-and-nixos-sops-nix-secrets-management/#separating-our-secrets-from-our-config
