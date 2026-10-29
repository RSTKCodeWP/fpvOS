# GT-Rev — Ascent GT Pro (4861) shelf map

Stock **18.21.7**, sensor **PS5280** (I2C `0x48`, chip IDs `52` / `80`).

## `docs/`

| File | Contents |
|------|----------|
| `boot-flow-4861.md` | Boot script flow, GPIO, fpvOS hook in `fpv_run_cx4861.sh` |
| `sensor-probe-live.txt` | Live COM12 probe: NAND map, versions, camera log |
| `live-factory/` | `/factory` JSON copied from the connected VTX |

## `source/ps5280/`

fpvOS glue driver (`libsns_ps5280.c`) that maps stock `ar_ldyhs_sky` CMOS at `0x267be4`.

## `reverse/firmware/`

Raw BurnTool NAND images: boot, env, sel, kernel, rootfs, factory, stock usrdata,
plus `usrdata.fpvos.bin` / `usrdata.kestrel.bin` variants.

## `reverse/unpacked/`

UBIFS trees extracted from firmware: `rootfs/`, `factory/`, `usrdata-stock/fpv/` (full
stock app tree including `ar_ldyhs_sky`, `ko_cv610_20s/`, `tunning/`, `boot_ar8030/`).

## `reverse/analysis/`

`strings` from `ar_ldyhs_sky` and rootfs `init`.

## `reverse/pc-tool/`

Windows USB serial driver INF and recovery hook scripts.

Rebuild firmware/unpacked/analysis: `python3 tools/build_gt_reverse.py` from repo root.
