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
| Grandma | runtime GLB | sheet views have a near-white background: the subject stayed at 37 % of the Trellis2 input (fixed: re-framed to 85 %); silver hair came out dark → `hair_tone` (sheet silver) after the white balance; face ellipse measured on the runtime face (the automatic one reached the hair) |
| Delivery rider | runtime GLB | helmet/headphones now dark like the sheet front (old texture: orange cap); generated brows show above the drawn ones |
| Gym coach | Codex refine 2026-10-15 candidate (neck/shoulder shelf reduction) | its refined texture superseded |
| Office worker | runtime GLB | — |
| Retired fisher | runtime GLB | — |
| Xiaomi | runtime GLB | — |

Sheet skin per character = median of the largest face-skin blob on the sheet front (the first,
top-30 % measure took the rider's orange jacket and the grandma's blouse).

## Check

Godot (`tools/art/capture_auntie_r3.gd` on each runtime GLB): all 19 clips captured, no failures,
for all seven. Full front/back/Jab overview reviewed. 47 test scenes pass.

## Open

- Delivery rider: generated brows above the drawn ones (CX-13).
- Grandma: a small bluish spot at the right temple (old texture edge under the face mask).
- Market auntie: floral print softer than the sheet (CX-14).
- Poodle: not part of the pass (Codex's r40 refinement is in progress).

## Dogs (breed opponents)

Same tools, per-dog configs `tools/art/t2_configs/dog_<breed>.json`:
- **Two Trellis2 runs, blended by normal**: front+back views give the head and rear; a dog's
  long flanks need the side view, so a second run uses the side view and its mirror as
  "front"/"back" with the mesh unturned (its left flank is already +X); `t2_bake` weighs the
  first run by normal·body axis², the second by normal·side axis².
- White balance against the sheet's whole-subject median (`sheet_body`; there is no skin).
- Codex's drawn face stays: face ellipse `face_auto` {zc 0.44, az 0.56, ax 1.3} of the head
  (covers eyes, muzzle, mouth), no tone matching. Trellis2 alone paints small brown eyes and a
  grey nose.
- Frenchie, pomeranian: the face is a separate material/texture; only the coat material is
  baked (`bake_materials`). Chihuahua: coat and head are two textures behind a Mix with the
  vertex colour; two passes (`dog_chihuahua.json`, then `dog_chihuahua_head.json` with the same
  colours and gain, face kept).

| Dog | Result |
|---|---|
| Corgi, shiba, golden | coat as before or cleaner, Codex face kept |
| Frenchie | the flat cream body now carries the sheet's brown patches |
| Chihuahua | white chest/legs of the sheet (was flat tan); a light smear on the muzzle side |
| Pomeranian | slightly paler than before, within the sheet's range |

## Player shiba (`shiba_01`, `shiba_01_stylized`)

The coat was vertex colours (eyes and nose are separate meshes): `create_base` gives the coat an
image texture and removes the colour attribute. The shiba sheet's eyes, a collar bar along the
spine (side run) and dark tail marks were painted on the body: refilled from the coat around
them (`eye_objects`/`nose_object` band, `stray_red`, `clear_dark_bones`). Taking the back from
the front/back run instead (`top_from`) was tried and rejected: that run sees the back edge-on
and paints it dark brown. The game uses `shiba_01.glb` (soft toon is off); the stylized one
keeps a faint spine bar and hard-edged fill patches on the forehead (CX-16).

Tests: 47 scenes; `combat_motion_3d_test` failed once ("leaning into being dragged") and
passed on three reruns (timing, not art).

## Owner fixes (same day)

Owner: 「阿姨肩上披著的毛巾，阿嬤的臉色看起來很臭，外送員背面包包的圖案沒有原本漂亮，健身教練的嘴巴斜一邊，退休阿伯的鬍子」.

| Problem | Cause | Fix |
|---|---|---|
| Auntie's towel read as a white board | Codex's r2 towel is a flat slab; the body's own towel lump under it was painted blouse print | slab removed (`delete_materials`), the lump on her right shoulder painted white keeping the generator's shading (`paint_boxes`) |
| Grandma looked grumpy | face mask stopped above the mouth corners; Trellis2's shading there read as a frown | mask brows to chin, below the hairline |
| Rider's bag print blurred | Trellis2 smears the corgi illustration | old texture kept on the box back (`keep_boxes`, measured) |
| Coach's mouth slanted, double brows | drawn mouth spans x -0.04..+0.13, past the mask's +0.09 | mask measured from the drawn features (ray grid over the old texture) |
| Fisher's beard a white wedge | old drawn wedge, off-centre | mask ends under the mouth: the beard is Trellis2's (the sheet's) |

Sources are now pinned to the version before the pass (`"src": "git:<rev>:<path>"`): after
installing, the runtime GLB already holds the new texture, and a re-run "kept" that instead
of the drawn face. Comparison: `good_human_stylized_factory/renders/trellis2_compare/five_fixes.png`.
47 tests pass; Godot captures of all clips for the five, no failures.

### Coach's mouth (owner: 「人的嘴是可以像教練這樣嗎…需要改嘴型」)

Texture, not geometry: the clay head has only a faint smile groove. The drawn mouth (texturing
v5) was a flat-topped trapezoid 4.5 cm right of the eyes' midpoint with a stray line beside it.
`redraw_mouth` in `t2_finish.py` erases it (skin fill = linear colour-vs-height fit over the
skin around it) and paints a symmetric grin in the face's front coordinates: lifted corners,
upper teeth, dark mouth, small tongue, dark lip line. Comparison: `coach_mouth.png`.

### Gym coach arm joints (owner: 「戰鬥時候手的方向錯誤」, 「請你檢查每一個角色」)

Every human checked with the same fight clips and the same camera (guard, jab, hook, block) and
by where the elbow/wrist joints sit along the arm (office worker 40 % / 78 %, rider 39/80, fisher
40/75, auntie 48/80, grandma 36/72, coach 24/48 → 57). Bone rest rotations of all 16 models are
identical before and after the Trellis2 re-export (so the pass did not cause it; the coach had it
in every earlier version). Coach fixed with `tools/art/refit_arms.py` (now a `refit_arms` step in
his t2 config). Grandma's guard sits at face height and her block crosses over her head: her
joints are right, her arms are long for her height (0.66 m) — a proportion matter, left as is.
Dogs use their own clips (dog motion tests pass).
