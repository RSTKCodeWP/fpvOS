# RSTK workspace

This fork separates **upstream fpvOS** (Caddx Ascent open firmware by [gehee/fpvOS](https://github.com/gehee/fpvOS)) from **RSTK product engineering** (hardware bring-up, vendor reverse kits, and contributions back upstream).

## Repository layout

| Zone | Location | Maintained by | Git branch |
|------|----------|---------------|------------|
| **fpvOS** | Repository root (`build.sh`, `br-external/`, `docs/`, …) | Upstream + sync | `main` tracks `gehee/fpvOS` |
| **RSTK** | `rstk/` only | RSTKCodeWP | `GT-Rev`, tags `GT-Rev` |

Nothing under `rstk/` is part of upstream fpvOS. Do not merge RSTK blobs into upstream pull requests unless explicitly agreed (license, size, proprietary vendor binaries).

## Modules

| Module | Path | Status |
|--------|------|--------|
| Ascent **GT Pro** (board 4861, PS5280) | [`modules/gt-pro/`](modules/gt-pro/) | Reverse kit + PS5280 glue driver |

See [`modules/gt-pro/MODULE.md`](modules/gt-pro/MODULE.md) for hardware scope, artifacts, and rebuild commands.

## Workflow

1. **`main`** — auto-synced from `gehee/fpvOS` every few minutes ([`fpvOS-sync`](https://github.com/RSTKCodeWP/fpvOS-sync)). Use for building stock fpvOS and rebasing product work.
2. **`GT-Rev`** — single product commit **`GT-Rev`**: fpvOS baseline at branch point + entire `rstk/` tree. Proposals to upstream live on topic branches forked from `main`.
3. **Contributing upstream** — fork `main`, branch `feature/…`, PR to `gehee/fpvOS`. Keep RSTK-only assets out of those PRs.

## Tools

RSTK-specific scripts live in [`rstk/tools/`](tools/). fpvOS upstream tools remain in repository-root `tools/`.

## Legal

RSTK modules may contain **Caddx / HiSilicon proprietary binaries** extracted from hardware you own. Private fork only; no redistribution without rights from the rights holder.
