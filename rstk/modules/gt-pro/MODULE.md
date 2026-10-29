# Module: Ascent GT Pro (4861)

## Identification

| Field | Value |
|-------|--------|
| Product | Caddx Ascent **GT Pro** VTX |
| Board type | **4861** (`fpv_board_type`) |
| Stock firmware | **18.21.7** (BurnTool pack) |
| SoC | HiSilicon **Hi3516CV610** (CV610 20S) |
| Camera sensor | **PrimeSensor PS5280** — I2C **0x48**, ID bytes **0x52 / 0x80** |
| Radio | Artosyn **8030** family (see `fpv_run_cx4861.sh` RF GPIO map) |

## Purpose

Enable **fpvOS** on GT Pro where the stock sky binary links the CMOS driver internally, and document a **full reverse kit** for factory-aligned engineering (NAND images, unpacked UBIFS, analysis).

## Directory map

```text
rstk/modules/gt-pro/
├── MODULE.md          ← this file
├── README.md          ← short entry
├── docs/              ← human-readable analysis & live captures
├── source/ps5280/     ← RSTK fpvOS glue (MIT-style contribution candidate)
└── reverse/           ← vendor binaries + manifests (proprietary)
    ├── firmware/      ← raw .bin partitions
    ├── unpacked/      ← rootfs, factory, usrdata-stock trees
    ├── analysis/      ← strings, generated notes
    └── pc-tool/       ← Windows recovery driver
```

## RSTK vs fpvOS

| Item | Layer |
|------|--------|
| `libsns_ps5280.c` | **RSTK** — loads stock `ar_ldyhs_sky` CMOS vtable at `0x267be4` |
| `br-external/`, `build.sh` | **fpvOS** — integrate via PR when upstream accepts |
| `reverse/firmware/*` | **RSTK only** — Caddx/HiSilicon, not for upstream |

## Rebuild

From repository root (fpvOS checkout):

```bash
python3 rstk/tools/build_gt_reverse.py
```

Requires desktop BurnTool tree at  
`~/Desktop/Ascent_GT_Pro_18_21_7_root-ascent/.../Firmware`  
and optional `output-gt/usrdata.bin` for fpvOS usrdata variant.

Build PS5280 glue `.so` (needs fpvOS air cross toolchain):

```bash
./rstk/modules/gt-pro/source/ps5280/build.sh
```

Pull live usrdata files from VTX (COM12):

```bash
python3 rstk/tools/vtx_dump_gt.py COM12
```

## Integrity

- `reverse/SHA256SUMS` — all files under `reverse/`
- `reverse/INVENTORY.txt` — firmware image sizes and hashes
- `docs/live-factory/` — per-session `/factory` JSON from hardware

## Upstream contribution path

1. Propose `libsns_ps5280.c` + build integration on a branch from **`main`** (fpvOS only).
2. Do **not** attach `reverse/firmware` to public PRs.
3. Reference live probe data in `docs/sensor-probe-live.txt` for review context.
