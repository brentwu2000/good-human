# Blender toolchain — installed add-ons

Installed 2026-10-08 by Claude on the owner's request (「請看 Blender_Toolchain_Research_GOOD_HUMAN 把相關的插件裝好」), following the research report's minimum set (§1, §11 stage A) plus the scene and retopology tools it recommends. Research: `.claude/Blender_Toolchain_Research_GOOD_HUMAN.md`.

## Environment

- Blender **5.2.0 LTS** (build 2026-07-14), `C:\Program Files\Blender Foundation\Blender 5.2\` — the one already used by the art pipeline and `tools/art/*.py`.
- The report recommends a fixed 4.5 LTS production environment with 5.x kept for experiments (Retarget 2.x). That was **not** set up: everything here is installed into the existing 5.2, which every listed add-on supports (all declare 4.2–5.0 minimums). Setting up a separate 4.5 LTS is a separate decision.
- Source: extensions.blender.org (repository `blender_org`), installed with `blender -c extension install -s`. Hashes are the platform's published archive hashes.
- Install folder: `%APPDATA%\Blender Foundation\Blender\5.2\extensions\blender_org\`.

## Installed and enabled

| Add-on | Version | Min Blender | Licence | Archive SHA-256 | Role here |
|---|---|---|---|---|---|
| Rigify | bundled with 5.2 | — | GPL-2.0-or-later | — | Human and dog rigs (enabled; was off) |
| MPFB | 2.0.17 | 4.2 | GPL-3.0-or-later (bundled assets CC0) | `4f0a879d64a39bf646fbf5f53601ac678855da329d650617dca5737548239a87` | Human base bodies (was already installed) |
| LoopTools | 4.7.7 | 4.2 | GPL-2.0-or-later | `ff1ca3b3fff73094379da8b1fa2c1acbc9d88d26b7dfc73bb9de5941a6b50108` | Mesh clean-up (circle, relax, bridge) |
| Bool Tool | 2.1.0 | 4.5 | GPL-3.0-or-later | `d3a282db25925d115dd1a7638aa28116f2f9198423b0afb6179e8127d59c06e1` | Boolean props |
| Magic UV | 6.7.1 | 4.2 | GPL-2.0-or-later | `09451ad3876aa1a1f693cdce4a5837e9a6c69cfc96cfc292ebc398a529d28571` | UV tools |
| Ucupaint | 2.4.9 | 4.2 | GPL-3.0-or-later | `c4d87fd9d73b4855b5ed096a52e4374aadb099babeb924674a7674a9b50eb5f8` | Layered texture painting (bake before export) |
| PolyQuilt (fork) | 1.46.8 | 4.5 | GPL-3.0-or-later | `83e5a5f0f87d8c2358bef19fe595d61f7ab82138e32c7173c764be130d2ca1f5` | Manual retopology (see note) |
| Archimesh | 1.2.5 | 4.2 | GPL-2.0-or-later | `44745a86dd472e296e06cd45c511e002a1105512a73009cb0018c87611d18d87` | Building blockouts (clinic, houses) |
| Sapling Tree Gen | 0.3.7 | 4.4 | GPL-3.0-or-later | `27a478262e1c86612a9c3daffe7f4dce2802f5bc2294033462e5adc6d9c0080f` | Trees (reduce before Godot) |
| A.N.T. Landscape | 0.2.0 | 4.2 | GPL-2.0-or-later | `230571bc14c50952f3af99b70fdb365cf0cee503382975dc38149407a5a4c8c0` | Park relief, distance terrain |
| Extra Mesh Objects | 0.4.1 | 4.2 | GPL-3.0-or-later | `c85ce4bb2820d5af26b4dad66bf1a0fdeb4bfeffc668c5e4f098f1e416ed434b` | Parametric prop blockouts |
| Retarget | 5.2.0 | 5.0 | GPL-3.0-or-later | `521ec8ff5c2373893ea8022b3f71d27ed191fb73f3a5634cac31585e0dcb7af3` | Rig conversion and animation retargeting |

Already present and left as they were: Blendkit (legacy add-on), Codex's `blender_codex_mcp.py`.

Verified with a background script: every add-on above is installed, enabled in the saved preferences and loads, except PolyQuilt, which only loads with the UI (it draws in the viewport and fails to register in `--background`, "GPU functions for drawing requires the gpu module"). It is enabled and loads in a normal Blender window; batch scripts should not rely on it — the report rates it low for automation anyway.

GPL add-ons do not put the game under the GPL: the art made with them is ours. Redistributing the add-ons themselves would carry their GPL obligations.

## Deliberately not installed (per the report)

- Retopoflow 4 — non-code assets are not open source and there is a paid tier; PolyQuilt covers the free core (§6).
- TexTools, Instant Mesh Bridge — no confirmed compatibility matrix for current versions; need a pinned-commit test first (§6, §12).
- Instant Meshes, TripoSR — external tools, not Blender add-ons; run from the command line when needed.
- Hunyuan3D-2 add-on — Tencent community licence with territory exclusions and commercial conditions (§8).
- Auto-Rig Pro — paid, licence not checked (§7).
- Poly Haven Assets — optional; materials and HDRIs can be fetched through the MCP server already set up.

## Caveat while installing

Codex had a Blender window open (`chihuahua_r29_02_baked`). Blender saves preferences on exit when auto-save is on; if that window saves its older preferences, these add-ons stay installed but may show as disabled. Re-check with Edit ▸ Preferences ▸ Add-ons, or re-run the enable step.
