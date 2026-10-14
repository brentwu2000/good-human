# GOOD HUMAN! — Blender texturing pipeline v5

Implements `.claude/GOOD_HUMAN_Blender_Texturing_v5.md` (owner, 2026-10-14). Stage-gated:
each stage writes a checkpoint and a report and waits for approval before the next.
Sources are never written: `assets/source/` holds copies, work happens in `assets/work/`.
`assets/` is git-ignored and rebuilt from the game files by the commands below.

| Stage | Script | Writes |
|---|---|---|
| A inspect (read-only) | `scripts/inspect_asset.py` | `reports/<asset>/inspection.json`, `view_*.png` |
| B semantic regions | `scripts/segment_regions.py` | face attribute `region_id`, `region_map.json`, `regions_*.png`, `assets/work/<asset>_B_regions.blend` |
| C flat materials | `scripts/assign_materials.py` | `M_<region>` Principled materials, `materials.json`, `solid_*.png`, `assets/work/<asset>_C_materials.blend` |
| B gate | `scripts/approve_regions.py` | `approval.json` (who, when, decision); D–G refuse to run without it |
| D+E detail, UV, bake | `scripts/paint_regions.py` | region-masked palettes from the reference texture, texel-level boundaries between *adjacent* regions only; Base Color (sRGB) + Roughness (Non-Color), 16 px padding; one game material; `assets/export/<asset>.glb` |
| F+G QA, GLB | `scripts/qa_export.py` | `qa_report.json` (PASS/WARN/FAIL): blank texels, bleed check by region id, six-view silhouettes vs source, re-import (skin, bones, clips, materials, colour spaces) |

Grandma pilot (2026-10-14): owner approved the 193 review faces' candidates; first D/E run
gave a jagged hairline in Godot (face-level regions on 6k triangles) → retry 1 lets boundary
texels take an *adjacent* region → QA PASS, Godot matches the previous grandma; installed
(2.7 → 1.3 MB). `reports/grandma/godot_before_after.png`.

```bash
B="/c/Program Files/Blender Foundation/Blender 5.2/blender.exe"
cp assets/characters/human/models/ai_grandma/grandma.glb art_pipeline/assets/source/grandma.glb
"$B" -b --factory-startup --python art_pipeline/scripts/inspect_asset.py -- --input art_pipeline/assets/source/grandma.glb --output art_pipeline/reports/grandma/inspection.json
"$B" -b --factory-startup --python art_pipeline/scripts/segment_regions.py -- --config art_pipeline/config/characters/grandma.json --work art_pipeline/assets/work/grandma_B_regions.blend --report art_pipeline/reports/grandma
"$B" -b --factory-startup --python art_pipeline/scripts/assign_materials.py -- --config art_pipeline/config/characters/grandma.json --regions art_pipeline/assets/work/grandma_B_regions.blend --work art_pipeline/assets/work/grandma_C_materials.blend --report art_pipeline/reports/grandma
"$B" -b --factory-startup --python art_pipeline/scripts/approve_regions.py -- --regions art_pipeline/assets/work/grandma_B_regions.blend --report art_pipeline/reports/grandma --work art_pipeline/assets/work/grandma_B_approved.blend --approver owner --decision accept_candidates
"$B" -b --factory-startup --python art_pipeline/scripts/paint_regions.py -- --config art_pipeline/config/characters/grandma.json --approved art_pipeline/assets/work/grandma_B_approved.blend --report art_pipeline/reports/grandma --work art_pipeline/assets/work/grandma_E_baked.blend --export art_pipeline/assets/export/grandma.glb
"$B" -b --factory-startup --python art_pipeline/scripts/qa_export.py -- --config art_pipeline/config/characters/grandma.json --baked art_pipeline/assets/work/grandma_E_baked.blend --export art_pipeline/assets/export/grandma.glb --report art_pipeline/reports/grandma
bash art_pipeline/tests/smoke_test.sh   # A-C on the grandma; source hash must not change
```

Region sources (v5 §3, most reliable first): separate meshes (the glasses) → skin weights
(each face's dominant bone class limits which regions are possible: config `bone_priors`) →
the existing base colour as a candidate only (four samples per face, shaded copies matched).
World height is never used. Faces whose candidate is not allowed or not confident, and
islands under 3 faces, are `NEEDS_REVIEW` (region 0, magenta) — never guessed.
Config colours are sRGB; stage C converts them to linear for Base Color.
