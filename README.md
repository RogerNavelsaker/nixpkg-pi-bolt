# nixpkg-pi-bolt

Nix flake packaging for [Pi-Bolt](https://github.com/opensec-git/Pi-Bolt), the native-compiled Pi coding agent.

Build or run with:

```sh
nix build github:RogerNavelsaker/nixpkg-pi-bolt
nix run github:RogerNavelsaker/nixpkg-pi-bolt -- --version
```

Pinned to upstream release 1.0.7. Platforms: x86_64 Linux, ARM64 Linux, and Apple Silicon macOS. Linux x86-64 uses the generic upstream `x64` build; select `x64-baseline` on older CPUs without AVX2 by extending the package variant.
