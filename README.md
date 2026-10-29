# nixpkg-pi-bolt

Nix flake packaging for [Pi-Bolt](https://github.com/opensec-git/Pi-Bolt), the native-compiled Pi coding agent.

Build or run with:

```sh
nix build github:RogerNavelsaker/nixpkg-pi-bolt
nix run github:RogerNavelsaker/nixpkg-pi-bolt -- --version
nix run github:RogerNavelsaker/nixpkg-pi-bolt#jit -- --version
```

Pinned to upstream release 1.0.7. Platforms: x86_64 Linux, ARM64 Linux, and Apple Silicon macOS. Linux x86-64 uses upstream’s `x64-baseline` build for CPU compatibility. The derivation preserves the upstream binary unstripped because stripping breaks its embedded Pi-Bolt CLI.

The `default` output disables JIT for plugin execution. The `jit` output enables it and installs as `pi-bolt-jit`.
