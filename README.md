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
- [ ] Auto-update flake via GHA
- [ ] See if disko works with tests
- [ ] Clean up `hello.nix`

[nix_vm_gist]: https://gist.github.com/FlakM/0535b8aa7efec56906c5ab5e32580adf
[secrets]: https://unmovedcentre.com/posts/secrets-management/#overview-and-video

## Refs

Other people's configs...

- https://github.com/dustinlyons/nixos-config/blob/main/modules/darwin/casks.nix
- https://github.com/cameronraysmith/nix-config/blob/main/flake.nix
- https://0xda.de/blog/2024/07/framework-and-nixos-sops-nix-secrets-management/#separating-our-secrets-from-our-config
