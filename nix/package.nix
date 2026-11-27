{ stdenv, fetchurl, lib, autoPatchelfHook, glibc, libxcb, coreutils, jit ? false }:

let
  version = "1.3.1";
  platform = if stdenv.hostPlatform.isDarwin then "darwin" else "linux";
  architecture = if stdenv.hostPlatform.isAarch64 then "arm64" else "x64";
  variant = if stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isx86_64 then "x64-baseline" else architecture;
  releaseVariant = if jit && architecture == "x64" then "x64-jit" else variant + lib.optionalString jit "-jit";
  name = "pi-bolt" + lib.optionalString jit "-jit";
  hashes = {
    "linux-x64-baseline" = "sha256-ngGw97lt4GXuFy9eVrjEz26rnt1FA1kAJkl/hZ90JMA=";
    "linux-arm64" = "sha256-bYi28rtLzvzYJFpzMKH2k+0qAVgiSppoDGZ7mIvQ6hk=";
    "darwin-arm64" = "sha256-2dERxMGkhHnnKyUZ/UHTlwVAyNJ2o+Bt7LO3+9hGVe4=";
    "linux-x64-jit" = "sha256-adyD6fWjD91+GVmffEdEECzKJkY9fLZXNqzG/eBES8E=";
    "linux-arm64-jit" = "sha256-dsaHxREQtncdAtwrHcfm3bK9o6LD/Yp5rfinD3Wu8bM=";
    "darwin-arm64-jit" = "sha256-hr5FtY7b5Qdc59cArLGxccE52pzhaGGdJBz5dGBJLLk=";
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
