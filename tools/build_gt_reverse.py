#!/usr/bin/env python3
"""Rebuild vendor/gt-4w/reverse/ (firmware + unpacked trees + analysis)."""
from __future__ import annotations

import hashlib
import pathlib
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
GT = ROOT / "vendor" / "gt-4w"
sys.path.insert(0, str(ROOT / "boot"))
import mkascentimg as mk  # noqa: E402

DESKTOP_FW = pathlib.Path(
    "/mnt/c/Users/Admin/Desktop/Ascent_GT_Pro_18_21_7_root-ascent/"
    "Ascent_GT_Pro_18_21_7_root-ascent/Firmware"
)
DESKTOP_BASE = DESKTOP_FW.parent
OUT = GT / "reverse"
DOCS = GT / "docs"
LOCAL_USRDATA_FPVOS = ROOT / "output-gt" / "usrdata.bin"


def sha256_file(p: pathlib.Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def copy_firmware() -> None:
    fw = OUT / "firmware"
    fw.mkdir(parents=True, exist_ok=True)
    mapping = {
        "boot.bin": "boot.bin",
        "env.bin": "env.bin",
        "sel.bin": "sel.bin",
        "kernel.bin": "kernel.bin",
        "rootfs.bin": "rootfs.bin",
        "factory.bin": "factory.bin",
        "usrdata.bin.stock.bak": "usrdata.stock.bin",
    }
    if not DESKTOP_FW.is_dir():
        sys.exit(f"missing desktop firmware dir: {DESKTOP_FW}")
    for src_name, dst_name in mapping.items():
        src = DESKTOP_FW / src_name
        if not src.is_file():
            sys.exit(f"missing {src}")
        shutil.copy2(src, fw / dst_name)
    if LOCAL_USRDATA_FPVOS.is_file():
        shutil.copy2(LOCAL_USRDATA_FPVOS, fw / "usrdata.fpvos.bin")
    kestrel = DESKTOP_FW / "usrdata.kestrel.bin"
    if kestrel.is_file():
        shutil.copy2(kestrel, fw / "usrdata.kestrel.bin")
    shutil.copy2(DESKTOP_FW / "burn_table_VTX_Ascent.xml", OUT / "burn_table_VTX_Ascent.xml")


def extract_ubi_blob(blob: pathlib.Path, dest: pathlib.Path) -> None:
    if dest.exists():
        shutil.rmtree(dest)
    mk.extract_ubi(blob.read_bytes(), dest)


def extract_trees() -> None:
    unpacked = OUT / "unpacked"
    unpacked.mkdir(parents=True, exist_ok=True)
    fw = OUT / "firmware"
    extract_ubi_blob(fw / "rootfs.bin", unpacked / "rootfs")
    extract_ubi_blob(fw / "factory.bin", unpacked / "factory")
    extract_ubi_blob(fw / "usrdata.stock.bin", unpacked / "usrdata-stock")


def copy_pc_tool_extras() -> None:
    for name in ("driver", "hooks"):
        src = DESKTOP_BASE / name
        if src.is_dir():
            dst = OUT / "pc-tool" / name
            if dst.exists():
                shutil.rmtree(dst)
            shutil.copytree(src, dst)


def strings_dump(binary: pathlib.Path, out: pathlib.Path, limit: int = 4000) -> None:
    if not binary.is_file():
        return
    proc = subprocess.run(
        ["strings", "-n", "6", str(binary)],
        capture_output=True,
        text=True,
        check=False,
    )
    lines = proc.stdout.splitlines()[:limit]
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_inventory() -> None:
    lines = [
        "Ascent GT Pro (board 4861) reverse kit",
        f"built from {DESKTOP_FW}",
        "",
        "=== firmware images (SHA256) ===",
    ]
    sums: list[str] = []
    for p in sorted(OUT.rglob("*")):
        if not p.is_file():
            continue
        if p.name in ("SHA256SUMS", "INVENTORY.txt"):
            continue
        rel = p.relative_to(OUT)
        digest = sha256_file(p)
        sums.append(f"{digest}  {rel.as_posix()}")
        if rel.parts[0] == "firmware":
            lines.append(f"{rel}\t{p.stat().st_size}\t{digest[:16]}...")
    (OUT / "INVENTORY.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
    (OUT / "SHA256SUMS").write_text("\n".join(sums) + "\n", encoding="utf-8")


def main() -> None:
    preserved_docs = None
    live_factory = DOCS / "live-factory"
    if live_factory.is_dir():
        preserved_docs = pathlib.Path("/tmp/gt-docs-live-factory")
        if preserved_docs.exists():
            shutil.rmtree(preserved_docs)
        shutil.copytree(live_factory, preserved_docs)
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)
    copy_firmware()
    extract_trees()
    copy_pc_tool_extras()
    sky = OUT / "unpacked" / "usrdata-stock" / "fpv" / "ar_ldyhs_sky"
    strings_dump(sky, OUT / "analysis" / "ar_ldyhs_sky.strings.txt")
    strings_dump(
        OUT / "unpacked" / "rootfs" / "sbin" / "init",
        OUT / "analysis" / "rootfs-init.strings.txt",
        limit=500,
    )
    if preserved_docs and preserved_docs.is_dir():
        shutil.copytree(preserved_docs, live_factory, dirs_exist_ok=True)
        shutil.rmtree(preserved_docs)
    write_inventory()
    print(OUT)


if __name__ == "__main__":
    main()
