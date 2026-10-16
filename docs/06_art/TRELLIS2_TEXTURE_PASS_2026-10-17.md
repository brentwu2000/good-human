# Trellis2 texture pass — human characters (2026-10-17, Claude)

Owner: 「使用 Trellis2 會有甚麼問題嗎，我覺得他產出挺不錯」 → 「好，做 B3」 → 「你處理，把它修好」 →
「處理完接續把其他角色都處理，用同樣流程，直到都可以交付進遊戲內」.

Each human keeps its geometry, rig and 19 clips; only the body basecolor is replaced by a
Trellis.2 texture generated from the owner's sheet views, with the drawn face kept.

## Why

Side by side with our projected/flat-palette textures (market auntie, 2026-10-16), Trellis.2 gave
the coherent, shaded "figure" look the owner liked, but dark and colour-shifted. Causes found
and fixed:

| Problem | Cause | Fix |
|---|---|---|
| Blouse brown, print a rust smear | extension's texture guidance default 1.0 (its README says 3.0) | guidance 3.0, 25 steps |
| Whole texture dark/orange | Trellis2 albedo cast | per-channel white balance: Trellis2 skin (inside the face mask) → the sheet's skin |
| Back of the character guessed | single 3/4 image | multi-view: sheet front + back |
| Multi-view "left/right" land on top/bottom | sampler weighs them by the vertical voxel axis | front/back only; mesh turned to face +X before texturing |
| Generated faces lose the drawn features | — | drawn face kept under a soft face mask, tone-matched |
| Hand holding the strap painted on the auntie's chest | the sheet's pose, not our mesh's | hand filled with blouse fabric in the input view |
| Strap painted on the body, offset from the real one | real strap floats ~5 cm off the body | front-view distance; refilled from the mirrored side |

## Licence chain (outputs shipped in the game)

| Part | Licence | Note |
|---|---|---|
| TRELLIS.2 code/weights (Microsoft) | MIT | |
| Aero-Ex/Trellis2-GGUF (quantised weights) | not stated | derived from the MIT weights; recorded as a gap |
| DINOv3 image encoder (Meta) | DINOv3 License (2025-08-19) | commercial use allowed, no claim on outputs; copy kept in the factory folder; mirror file size equals Meta's (hash is gated) |
| o-voxel, cumesh, flex-gemm | MIT | |
| nvdiffrast | NVIDIA, non-commercial | **not used for these outputs**: colours are baked on vertices and transferred with a Blender Cycles bake |
| Modly extension (lightningpixel) | MIT | |
| Input views | owner sheets (grandma's four views: Qwen-Image 2.1, non-commercial — inherited risk, see AI_GRANDMA_PROVENANCE) | |

## Pipeline (rebuild)

```
bash tools/art/t2_run.sh tools/art/t2_configs/<id>.json [out.glb]
```
1. `t2_prep.py` (Blender 5.2): body in rest pose, simple subdivision ×2 → `build/t2/<id>/hi.glb`.
2. `t2_texture.py` (Trellis2 extension venv, `C:/Users/b/tools/modly`): multi-view texture,
   colours on vertices → `colours.npz` (~6 min on the RTX 3070 Ti; reused when present).
3. `t2_bake.py` (Blender): colours → the body's own UVs; prop refill, forearm/hand skin;
   face mask (ellipse from the head, or the config's).
4. `t2_finish.py` (Blender): white balance, drawn face, corner colours, export GLB.

Configs: `tools/art/t2_configs/`. Install = copy the GLB over the runtime path, delete the
orphaned extracted textures, Godot import, `tests/run_all.sh`.

## Characters

| Character | Source geometry | Notes |
|---|---|---|
| Market auntie | r3d checkpoint `build/market_auntie_r3/04_head.blend` | front view without the strap-holding hand; towel plain white (sheet); bare forearms; hands (single-UV) painted |
