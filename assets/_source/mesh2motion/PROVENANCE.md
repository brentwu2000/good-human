# Mesh2Motion animation sources

Untouched copies of four animation libraries from Mesh2Motion by Scott Petrovic.

- Source: https://github.com/scottpetrovic/mesh2motion-app , `static/animations/`
- Commit: 653a969 (2026-10-06), retrieved 2026-10-09
- Licence: art assets (models, rigs, animations) **CC0 1.0**; code MIT — see `LICENSE-CC0.MD`, `LICENSE-MIT.MD` (copied from the repository). Commercial use and modification allowed, no attribution required.
- Used by `tools/art/retarget_mesh2motion.py`, which bakes chosen clips onto the owner rig and every dog model (owner decision 2026-10-09: 「好的，狗的部分也要使用」).

| File | SHA-256 |
|---|---|
| `fox-animations.glb` | `80e80641a5692a14aba7616a46d2a28d3595479764887c578c766b99dba8a0d0` |
| `human-addon-animations.glb` | `a0d64d555e0d492026b72d58bf8e16c5e86779295f9093e376dcc001915c2c95` |
| `human-base-animations.glb` | `406eb0a8dc4ab366e623b79b6e3005a4951392e1bda78ae39c1099d31147733c` |
| `human-mocap-animations.glb` | `814593d62522f5be8d6bd32df2a8fa3c7feb90a8e1a1ba43f4aaf0048555280d` |

This folder is excluded from exports (`assets/_source/*` in `export_presets.cfg`).
