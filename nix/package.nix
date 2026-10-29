{ stdenv, fetchurl, lib, autoPatchelfHook, glibc, libxcb, makeWrapper, jit ? false }:

let
  version = "1.0.7";
  platform = if stdenv.hostPlatform.isDarwin then "darwin" else "linux";
  architecture = if stdenv.hostPlatform.isAarch64 then "arm64" else "x64";
  variant = if stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isx86_64 then "x64-baseline" else architecture;
  releaseVariant = if jit && architecture == "x64" then "x64-jit" else variant + lib.optionalString jit "-jit";
  name = "pi-bolt" + lib.optionalString jit "-jit";
  hashes = {
    "linux-x64-baseline" = "sha256-81NF1AXD2t+D+gdh9o9/pSxmDdDvAr1yHj3kE6IiNvM=";
    "linux-arm64" = "sha256-95ToBj8YBtDuxpl9+CXGi5r7E9UJKbAFBDdsej6KjNM=";
    "darwin-arm64" = "sha256-VV3J8mJ3Md+nvtcOu0iE47vDp/+ftxTguS2V9y2FDlo=";
    "linux-x64-jit" = "sha256-sCzir/SlDPWQj/BF9ZcN0i2EXSe8z/iADZugrh9sDyk=";
    "linux-arm64-jit" = "sha256-jPPr9JAoq0q5W6Yy8q5e6HgQi+PLwmgj/sPzx8OuBrI=";
    "darwin-arm64-jit" = "sha256-XVS7YIx+xJcigbVwfO9EyV/4WleTFzUDeTeOdtlrRQQ=";
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
  nativeBuildInputs = [ makeWrapper ] ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ glibc libxcb ];
  dontStrip = true;
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/libexec
    install -m755 pi $out/libexec/${name}-bin
    cp -r theme assets export-html native $out/libexec/
    cp photon_rs_bg.wasm $out/libexec/
    makeWrapper $out/libexec/${name}-bin $out/bin/${name} \
      --set PI_PACKAGE_DIR $out/libexec
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
