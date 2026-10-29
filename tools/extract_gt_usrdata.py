#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "boot"))
import mkascentimg as mk  # noqa: E402

src = Path(sys.argv[1])
out = Path(sys.argv[2])
mk.extract_ubi(src.read_bytes(), out)
print(out)
