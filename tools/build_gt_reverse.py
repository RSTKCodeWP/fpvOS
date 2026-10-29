#!/usr/bin/env python3
"""Shim → rstk/tools/build_gt_reverse.py (RSTK module tooling)."""
from __future__ import annotations

import runpy
from pathlib import Path

runpy.run_path(str(Path(__file__).resolve().parents[1] / "rstk/tools/build_gt_reverse.py"))
