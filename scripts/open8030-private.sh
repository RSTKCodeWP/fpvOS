#!/bin/sh
# open8030-private.sh <Open8030 checkout>
#
# Copies an Open8030 checkout's board profiles (register defaults, pins and
# keys, reverse engineered from the stock radio firmware) and the goggle's
# radio config from its .local/ into vendor/open8030 (git-ignored), for a build
# with OPEN8030_PRIVATE_DIR=vendor/open8030: new or changed profiles. The
# released ones come from the open8030-profiles package.
set -e
src=${1:?usage: $0 <Open8030 checkout>}
dst=$(cd "$(dirname "$0")/.." && pwd)/vendor/open8030
files=".local/profiles/ascent-vrx-pro.c .local/profiles/ascent-lite-plus.c
       .local/profiles/bb_defaults.inc .local/bb_config_gnd_open8030.json"
for f in $files; do
	[ -f "$src/$f" ] || { echo "open8030-private: no $src/$f" >&2; exit 1; }
done
mkdir -p "$dst"
for f in $files; do cp "$src/$f" "$dst/"; done
cd "$dst" && sha256sum ascent-vrx-pro.c ascent-lite-plus.c bb_defaults.inc bb_config_gnd_open8030.json > SHA256SUMS
echo "open8030-private: $dst"
cat SHA256SUMS
