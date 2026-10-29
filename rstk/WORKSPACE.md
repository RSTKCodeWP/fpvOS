# Fork workspace model

## Design goals

- **Manufacturer-grade traceability** — manifests (`SHA256SUMS`), version pins (stock 18.21.7), live factory captures dated by device session.
- **Modularity** — each product line is a self-contained module under `rstk/modules/<name>/`.
- **Clean upstream boundary** — sync job never writes under `rstk/`; upstream never depends on `rstk/`.

## Branch diagram

```text
gehee/fpvOS (main)
       │  fpvOS-sync (every 5 min)
       ▼
RSTKCodeWP/fpvOS (main)  ──rebase──►  GT-Rev  (+= rstk/)
       │
       └── topic branches ──PR──► gehee/fpvOS
```

## What belongs in `rstk/`

- Vendor firmware dumps and unpacked trees
- Board-specific drivers not yet accepted upstream (`source/`)
- Product documentation, live probe logs, factory JSON from your units
- RSTK automation (VTX serial pull, UBI extract)

## What stays in fpvOS root

- Buildroot / build.sh integration accepted for upstream
- Generic docs patches destined for `gehee/fpvOS`
- Changes under `br-external/` intended for PR upstream

When a change is ready for the community, **move the implementation to the fpvOS tree** and leave only a pointer or thin wrapper in `rstk/` if still needed for private blobs.
