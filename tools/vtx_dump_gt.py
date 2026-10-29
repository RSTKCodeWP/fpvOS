#!/usr/bin/env python3
"""Pull GT stock blobs from VTX shell (COM12) into vendor/gt-4w/reverse/unpacked/."""
from __future__ import annotations

import base64
import re
import sys
import time
from pathlib import Path

import serial

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "vendor" / "gt-4w" / "reverse" / "unpacked" / "usrdata-stock"
PORT = sys.argv[1] if len(sys.argv) > 1 else "COM12"
PROMPT = re.compile(r"#\s*$")

REMOTE_PATHS = [
    "/usrdata/fpv/ar_ldyhs_sky",
    "/usrdata/fpv/ko_cv610_20s",
    "/usrdata/fpv/tunning",
    "/usrdata/fpv/air/lib",
]


def drain(ser: serial.Serial, timeout: float) -> bytes:
    t0 = time.monotonic()
    buf = bytearray()
    idle = 0.0
    while time.monotonic() - t0 < timeout:
        n = ser.in_waiting
        if n:
            buf += ser.read(n)
            idle = 0.0
        else:
            time.sleep(0.02)
            idle += 0.02
            if buf and idle > 0.35:
                break
    return bytes(buf)


def run_shell(ser: serial.Serial, cmd: str, wait: float = 8.0) -> str:
    ser.reset_input_buffer()
    ser.write((cmd + "\n").encode())
    ser.flush()
    raw = drain(ser, wait).decode("utf-8", errors="replace")
    # Drop echoed command line(s).
    lines = raw.splitlines()
    out = []
    for line in lines:
        if line.strip() == cmd.strip():
            continue
        if PROMPT.search(line):
            continue
        out.append(line)
    return "\n".join(out)


def list_remote_files(ser: serial.Serial) -> list[str]:
    parts = []
    for p in REMOTE_PATHS:
        if p.endswith("ar_ldyhs_sky"):
            parts.append(f"test -f {p} && echo {p}")
        else:
            parts.append(f"find {p} -type f 2>/dev/null")
    cmd = "; ".join(parts)
    text = run_shell(ser, cmd, wait=15.0)
    files: list[str] = []
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("/"):
            files.append(line)
    return sorted(set(files))


def remote_size(ser: serial.Serial, remote: str) -> int:
    text = run_shell(ser, f"wc -c < '{remote}'", wait=4.0).strip()
    m = re.search(r"(\d+)", text)
    return int(m.group(1)) if m else 0


def pull_b64(ser: serial.Serial, remote: str) -> bytes:
    size = remote_size(ser, remote)
    wait = max(30.0, min(900.0, size / 5000.0 + 15.0))
    cmd = (
        f"echo B64BEGIN; "
        f"(base64 -w 0 '{remote}' 2>/dev/null || busybox base64 '{remote}'); "
        f"echo; echo B64END"
    )
    ser.reset_input_buffer()
    ser.write((cmd + "\n").encode())
    ser.flush()
    t0 = time.monotonic()
    raw = bytearray()
    while time.monotonic() - t0 < wait:
        n = ser.in_waiting
        if n:
            raw += ser.read(n)
            if b"B64END" in raw:
                break
        else:
            time.sleep(0.05)
    text = raw.decode("utf-8", errors="replace")
    if "B64BEGIN" not in text or "B64END" not in text:
        raise RuntimeError(f"bad frame for {remote}: {text[:200]!r}")
    payload = text.split("B64BEGIN", 1)[1].split("B64END", 1)[0]
    payload = "".join(payload.split())
    if not payload:
        raise RuntimeError(f"empty b64 for {remote}")
    return base64.b64decode(payload, validate=False)


def local_path(remote: str) -> Path:
    if remote.startswith("/usrdata/fpv/"):
        rel = remote[len("/usrdata/") :]
        return OUT / rel
    return OUT / remote.lstrip("/")


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    ser = serial.Serial(PORT, 115200, timeout=0.2, write_timeout=30)
    ser.write(b"\n")
    time.sleep(0.4)
    ser.reset_input_buffer()
    run_shell(ser, "cd /", 1.0)

    files = list_remote_files(ser)
    manifest = OUT / "MANIFEST.txt"
    ok = 0
    with manifest.open("w", encoding="utf-8") as mf:
        mf.write(f"port={PORT}\nfiles={len(files)}\n\n")
        for i, remote in enumerate(files, 1):
            dest = local_path(remote)
            dest.parent.mkdir(parents=True, exist_ok=True)
            print(f"[{i}/{len(files)}] {remote}")
            try:
                data = pull_b64(ser, remote)
            except Exception as e:
                print(f"  FAIL: {e}")
                mf.write(f"FAIL {remote} {e}\n")
                continue
            dest.write_bytes(data)
            mf.write(f"{len(data)}\t{remote}\n")
            ok += 1
    ser.close()
    print(f"done {ok}/{len(files)} -> {OUT}")
    return 0 if ok == len(files) else 1


if __name__ == "__main__":
    raise SystemExit(main())
