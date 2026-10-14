# Claude → Codex handoff — 2026-10-15: v5 texturing of six characters

Owner request: run every character except the grandma through the Texturing v5 pipeline,
compare with the sheets, fix until deliverable. Claude did it; the art split is unchanged.

## Added / changed
- `assets/characters/human/models/{office_worker,market_auntie,retired_fisher,delivery_rider,gym_coach,xiaomi}/<c>.glb`:
  v5 output (one game material, base colour 2048 sRGB + roughness 512 Non-Color, 53-bone rig,
  19 clips). Godot extracts `<c>_<c>_basecolor.png` / `_roughness.png`. The old
  `<c>_<c>_game_base.png` stays: it is the v5 `reference_texture`.
- Configs `art_pipeline/config/characters/<c>.json`; reports with QA, before/after and Godot
  turnarounds in `art_pipeline/reports/<c>/`. New config keys: `art_pipeline/README.md`.
- Gym coach: face redrawn in the mesh's own front-mapped pixels (the sheet head is tilted);
  re-rigged with `--neck-range 0.80,0.89`. Xiaomi: re-rigged with `--neck-range 0.55,0.66`
  after the factory's distance skinning fix (world space, head above the head joint).
  Factory backups: `good_human_stylized_factory/backup_2026-10-15/gym_coach/`.

## How it is rebuilt
Factory (gym coach only): `paint_stylized.py` (profile above) → copy `lod0_toon.glb` to
`lod0_toon_prop.glb` → `rig_lods.py ... --neck-range 0.80,0.89 --rebake-game 2048 --game-lod lod1`.
Then v5 stages A–G per `art_pipeline/README.md`.

## Must not change
- Bone names/count and clip names (the game's `P04HumanVisual` drives them).
- The drawn faces (skin/eyes regions keep their texels; `keep_reference`).

## Requests
- **CX-10** Geometry the paint cannot fix: the auntie's towel is a flat band (sheet: towel on one
  shoulder), the gym coach's neck/trapezius lump, mitten hands; props left out (basket, rod case,
  net, shaker, satchel volume).
- **CX-11** Optional: per-character idle poses from the sheets (office slouch, coach hands-on-hips).
- **CX-12** The v5 shiba (`art_pipeline/assets/export/shiba_01.glb`, 2026-10-14) is still waiting
  for your decision.
