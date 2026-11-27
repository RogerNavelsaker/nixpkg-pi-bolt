#!/usr/bin/env bash
# Sync nix/package.nix version + per-variant hashes from the latest opensec-git/Pi-Bolt release (tags bolt-v*).
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
file=nix/package.nix
tag=$(gh api repos/opensec-git/Pi-Bolt/releases/latest --jq .tag_name)
version=${tag#bolt-v}
current=$(grep -oE '^\s*version = "[^"]+"' "$file" | head -n1 | sed -E 's/.*"([^"]+)"/\1/')
[ "$current" != "$version" ] || { echo "already at $version"; exit 0; }
for key in $(grep -oE '^\s*"[a-z0-9-]+" = "sha256-[^"]+";' "$file" | sed -E 's/^\s*"([^"]+)".*/\1/'); do
  hash=$(nix store prefetch-file --json "https://github.com/opensec-git/Pi-Bolt/releases/download/$tag/pi-bolt-$key.tar.gz" | jq -r .hash)
  sed -i -E "s|^(\s*\"$key\" = \")sha256-[^\"]+(\";)|\1$hash\2|" "$file"
done
sed -i -E "0,/^(\s*version = \")[^\"]+(\";)/s||\1$version\2|" "$file"
echo "synced pi-bolt $version"
