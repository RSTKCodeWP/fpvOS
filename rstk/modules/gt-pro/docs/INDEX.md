# GT Pro — documentation index

Stock **18.21.7**, board **4861**, sensor **PS5280** (I2C `0x48`, IDs `52` / `80`).

| Document | Description |
|----------|-------------|
| [../MODULE.md](../MODULE.md) | Module specification (hardware, layout, upstream path) |
| [boot-flow-4861.md](boot-flow-4861.md) | Boot chain, GPIO, fpvOS hook in `fpv_run_cx4861.sh` |
| [sensor-probe-live.txt](sensor-probe-live.txt) | Live VTX probe (COM12): NAND, versions, camera log |
| [live-factory/](live-factory/) | `/factory` JSON from connected hardware |

## Binary artifacts

| Tree | Role |
|------|------|
| [../reverse/firmware/](../reverse/firmware/) | Raw NAND `.bin` images |
| [../reverse/unpacked/](../reverse/unpacked/) | UBIFS: rootfs, factory, stock `usrdata/fpv` |
| [../reverse/analysis/](../reverse/analysis/) | `strings` extracts |
| [../source/ps5280/](../source/ps5280/) | fpvOS PS5280 glue source |

Regenerate `reverse/firmware` + `reverse/unpacked`:  
`python3 rstk/tools/build_gt_reverse.py` (from repo root).
