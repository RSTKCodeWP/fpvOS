#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../../.." && pwd)"
export PATH="${ROOT}/output-air/host/bin:/usr/sbin:/usr/bin:/sbin:/bin"
CC=arm-buildroot-linux-musleabi-gcc
SRC="${ROOT}/rstk/modules/gt-pro/source/ps5280/libsns_ps5280.c"
OUT="${ROOT}/rstk/modules/gt-pro/source/ps5280/libsns_ps5280.so"
DST="${ROOT}/output-air/target/usrdata/fpv/air/lib/libsns_ps5280.so"
$CC -shared -fPIC -O2 -Wall -Wextra \
    -Wl,-soname,libsns_ps5280.so \
    -o "$OUT" "$SRC"
mkdir -p "$(dirname "$DST")"
$CC -shared -fPIC -O2 -Wall -Wextra \
    -Wl,-soname,libsns_ps5280.so \
    -o "$DST" "$SRC"
chmod 755 "$OUT" "$DST"
echo "built $(ls -l "$OUT")"
arm-buildroot-linux-musleabi-nm -D "$OUT" | grep g_sns || true
file "$OUT"
