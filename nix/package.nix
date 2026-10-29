{ stdenv, fetchurl, lib, autoPatchelfHook, glibc }:

let
  version = "1.0.7";
  platform = if stdenv.hostPlatform.isDarwin then "darwin" else "linux";
  architecture = if stdenv.hostPlatform.isAarch64 then "arm64" else "x64";
  variant = if stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isx86_64 then "x64-baseline" else architecture;
  archive = "pi-bolt-${platform}-${variant}.tar.gz";
  hashes = {
    "linux-x64-baseline" = "sha256-81NF1AXD2t+D+gdh9o9/pSxmDdDvAr1yHj3kE6IiNvM=";
    "linux-arm64" = "sha256-95ToBj8YBtDuxpl9+CXGi5r7E9UJKbAFBDdsej6KjNM=";
    "darwin-arm64" = "sha256-VV3J8mJ3Md+nvtcOu0iE47vDp/+ftxTguS2V9y2FDlo=";
  };
in
stdenv.mkDerivation {
  pname = "pi-bolt";
  inherit version;
  src = fetchurl {
    url = "https://github.com/opensec-git/Pi-Bolt/releases/download/bolt-v${version}/${archive}";
    hash = hashes."${platform}-${variant}";
  };
  sourceRoot = "pi-bolt-${platform}-${variant}";
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ glibc ];
  dontStrip = true;
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 pi $out/bin/pi-bolt
    runHook postInstall
  '';
  meta = {
    description = "Pi coding agent compiled ahead of time to native code";
    homepage = "https://github.com/opensec-git/Pi-Bolt";
    license = lib.licenses.mit;
    mainProgram = "pi-bolt";
    platforms = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
  };
}
