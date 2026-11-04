{ stdenv, fetchurl, lib, autoPatchelfHook, glibc, libxcb, coreutils, jit ? false }:

let
  version = "1.0.9";
  platform = if stdenv.hostPlatform.isDarwin then "darwin" else "linux";
  architecture = if stdenv.hostPlatform.isAarch64 then "arm64" else "x64";
  variant = if stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isx86_64 then "x64-baseline" else architecture;
  releaseVariant = if jit && architecture == "x64" then "x64-jit" else variant + lib.optionalString jit "-jit";
  name = "pi-bolt" + lib.optionalString jit "-jit";
  hashes = {
    "linux-x64-baseline" = "sha256-5nz7ATILQVrkZXjiEauqhUhBXGQNAesnOd0MmNiIPwc=";
    "linux-arm64" = "sha256-qpX61ryquwL4xmSMY34H48fJwg20g9NmxpQPdceY80Q=";
    "darwin-arm64" = "sha256-F3j+kIns5Rl5VAfoNKm8xd14NhChp45x4iKuS/gBwQg=";
    "linux-x64-jit" = "sha256-OnBJaGtFdG3+55weqWmvT8YJh5JVeQ7jivmk0IiuAMM=";
    "linux-arm64-jit" = "sha256-zrSlSB8hfe/htRY7O6CITzQAmkH9TBSYhhlkV5cuRHY=";
    "darwin-arm64-jit" = "sha256-8ztL+KxSIcWldNkWNVybGyKwfsx8D0zdLgX12k054UI=";
  };
in
stdenv.mkDerivation {
  pname = name;
  inherit version;
  src = fetchurl {
    url = "https://github.com/opensec-git/Pi-Bolt/releases/download/bolt-v${version}/pi-bolt-${platform}-${releaseVariant}.tar.gz";
    hash = hashes."${platform}-${releaseVariant}";
  };
  sourceRoot = "pi-bolt-${platform}-${releaseVariant}";
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ glibc libxcb ];
  dontStrip = true;
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/libexec
    install -m755 pi $out/libexec/${name}-bin
    cp -r theme assets export-html native $out/libexec/
    cp photon_rs_bg.wasm $out/libexec/
    cat > $out/bin/${name} <<'EOF'
#!/bin/sh
binary="@binary@"
if [ "$1" = compile ]; then
  out=
  want_out=
  for arg do
    if [ "$want_out" = 1 ]; then out=$arg; want_out=; continue; fi
    case "$arg" in
      --out) want_out=1 ;;
    esac
  done
  if [ -n "$out" ]; then
    parent=$(@coreutils@/bin/dirname -- "$out") || exit 1
    mkdir -p "$parent" || exit 1
    parent=$(cd "$parent" && pwd) || exit 1
    "$binary" "$@" &
    child=$!
    (
      while kill -0 "$child" 2>/dev/null; do
        for work in "$parent"/.compile-*; do
          [ -f "$work/pid" ] && [ "$(@coreutils@/bin/cat "$work/pid")" = "$child" ] && @coreutils@/bin/chmod -R u+rwX "$work" 2>/dev/null || :
        done
        @coreutils@/bin/sleep 0.05
      done
    ) &
    watcher=$!
    wait "$child"
    status=$?
    kill "$watcher" 2>/dev/null || :
    wait "$watcher" 2>/dev/null || :
    exit "$status"
  fi
fi
export PI_PACKAGE_DIR="@libexec@"
exec "$binary" "$@"
EOF
    substituteInPlace $out/bin/${name} \
      --replace-fail @binary@ $out/libexec/${name}-bin \
      --replace-fail @coreutils@ ${coreutils} \
      --replace-fail @libexec@ $out/libexec
    chmod +x $out/bin/${name}
    runHook postInstall
  '';
  meta = {
    description = "Pi coding agent compiled ahead of time to native code${lib.optionalString jit " with JIT enabled for extensions"}";
    homepage = "https://github.com/opensec-git/Pi-Bolt";
    license = lib.licenses.mit;
    mainProgram = name;
    platforms = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
  };
}
