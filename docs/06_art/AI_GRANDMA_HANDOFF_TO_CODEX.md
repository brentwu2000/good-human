# AI Grandma — handoff to Codex (ART)

From: Claude (gameplay/code). Date: 2026-09-30. Owner request: "hand the grandma over to Codex to keep improving".
Codex owns the art pipeline (CLAUDE.md). This document hands over a working **trial character** made by an AI image-to-3D pipeline, with everything needed to continue: files, commands, current state, known problems, suggested next steps, and hard rules.

---

## 1. What exists

A park grandma ("looks frail, secretly strong") built from the owner's character sheet. She is rigged on **your P-04 OwnerSkeleton** (same 53 bone names), so `P04HumanVisual` and all 17 authored clips drive her unchanged. She is textured and carries a separate tote.

| | |
|---|---|
| Game-ready file (current best) | `C:\Users\b\Documents\good_human_ai3d_poc\blender_work\rig6\grandma_rigged.glb` (2.5 MB) |
| Copy used by the game (local only, git-excluded) | `good-human/assets/characters/human/models/ai_grandma_research/grandma.glb` |
| Height | 1.55 m (P-04 skeleton scaled ×0.871, joints moved into her mesh) |
| Body | ~10k tris, one material, 1024² albedo (`grandma_rigged_albedo.png` next to the GLB) |
| Tote | separate mesh "Tote", ~2.5k tris, own 512² texture, rigidly on `clavicle_r` |
| Clips | all 17 P-04 clips retargeted (Idle…Walk, Jab, HeavyHook, Kick, Block, Dodge, Hit*, Stumble, Down) |
| QA images | `good_human_ai3d_poc/reports/rig6/` — `poses_all.png` (8 clips front/side), `flat_all.png` (unlit texture), `closeups.png`, `in_game_front.png`, `fit_both.png` (joint fit) |
| Preview build | `good-human/build/windows_grandma_preview/GoodHuman.exe` — the old master pair (大樹下) is the grandma |

### How she gets into the game
- **Committed (generic, dae959a):** `FighterData.skeletal_model` — a fighter can bring its own model on the OwnerSkeleton. `HumanModular3D.build` passes it to `P04HumanVisual.new(scene)`; such a model is not scaled by `body_scale`. Test: `tests/skeletal_model_test`.
- **Local only (not committed):** `good_human_ai3d_poc/scripts/grandma_preview.py on|off|status`.
  - `on` edits five tracked data files in the working tree: the old master fighter (model, name 老奶奶), his encounter intro, and three desire lines (老爺爺 → 老奶奶).
  - `off` restores them from git.
  - **Always turn it `off` before committing or running `tests/run_all.sh`**: `combat_world_test` asserts the name 老爺爺.

---

## 2. Hard rules (read before touching anything)

1. **Licence class RESEARCH_ONLY.** Her four views come from **Qwen-Image-2.1**, whose licence is non-commercial research only.
   - Every file carries a `<file>.provenance.json`, and the class propagates through the whole chain.
   - See `good_human_ai3d_poc/reports/licenses.md`.
   - She **must not ship**, and her files **must not be committed**: `brentwu2000/good-human` is a **public** repository. The asset folder is excluded through `.git/info/exclude`.
2. **Commercial-safe path** (use it for anything meant to ship):
   - **Views:** Qwen-Image-Edit-2509 (Apache-2.0; not downloaded yet), or drawn by you.
   - **3D:** TripoSG with **Marching Cubes** (MIT/BSD). Never `diso`, which is CC BY-NC; a stub is installed instead.
   - **Rig and texture:** Blender (GPL tool; output is ours).
   - **Research only:** Hunyuan3D-2mini (territory clause excludes EU/UK/KR), TRELLIS.2 (nvdiffrast is non-commercial), Qwen-Image-2.1.
3. **Only `good_human_ai3d_poc/export_commercial/` may ever reach the game repo.** `process_character.py` refuses to write there unless the chain is COMMERCIAL_OK/owner-supplied.
4. **The character sheet** (`good_human_ai3d_poc/input/grandma_character_sheet.png`) is owner-supplied. The owner still has to confirm its rights: if an AI tool made it, that tool's terms apply.
5. **Characterisation (v2 spec §3):** the base stays frail, kind, ordinary. Do not "fix" her into a fighter: no muscles, no heroic stance, no fierce face, keep the slight hunch. The contrast belongs to animation, timing, camera and VFX.

---

## 3. Known problems (where your help is wanted)

| # | Problem | Why | Suggested fix |
|---|---|---|---|
| 1 | **Topology is an isosurface** (voxel remesh + decimate): no edge loops at shoulders, elbows, knees or neck | AI mesh | Proper **retopology**, ideally to the P-04 human's modular conventions, then re-skin to OwnerSkeleton (keep bone names) |
| 2 | **Texture is a projection** of two views (front, back), so it is soft; the crown is flat hair colour; hands are one flat skin tone; a little cardigan print bleeds onto the shoes; seams between front and back projections | Only front/back line up with the mesh; the A-pose true profile could not be generated | Repaint or bake over the projection in Blender; add hair strands/cards for the bun; separate materials or UV islands for skin, hair, cardigan, trousers and shoes |
| 3 | **Face is soft** (the source view's face is ~60 px) | Source resolution | Hand-paint the face, or bake from a dedicated face close-up |
| 4 | **Weights are automatic** (bone heat on the remeshed body) | — | Clean weights at shoulders/hips; check Down/Stumble/HitHeavy for collapse |
| 5 | **Clip retargeting is procedural**: arms copy each clip's absolute direction (her rest is an A-pose like P-04's); spine, legs and pelvis copy the clip's change from rest, which keeps her hunch; pelvis motion is scaled to her height | — | If you author grandma-specific clips (v2 §14: Idle_Frail, Walk_Slow, Pet_Dog, Threatened, Posture_Straighten, Counter, Return_To_Frail…), keep them on the OwnerSkeleton so the adapter keeps working |
| 6 | **Tote** is a rigid prop on `clavicle_r`; the arm can pass through it | Simple attachment | Proper strap, or a second bone; or keep it a separate `grandma_bag.glb` (v2 §13) |
| 7 | **Top of the head** is unwrapped at 2.5× density, but the bun shape from TripoSG is lumpy (reads as two lumps) | AI mesh | Remodel the bun |

What already works and is worth keeping: the joint fit (`reports/rig6/fit_both.png`); the bone names; the 1.55 m scale with feet at the origin; front facing +Z in glTF (same as `p04_owner.glb`); a single body material; the tote as its own mesh.

---

## 4. The pipeline, if you want to regenerate rather than hand-fix

Working folder: `C:\Users\b\Documents\good_human_ai3d_poc\` (outside the repo). Runbook: `reports/PIPELINE_V2.md`. Full history: `reports/final_report.md` (three addenda).

```bash
cd /c/Users/b/Documents/good_human_ai3d_poc
bash scripts/start_comfyui.sh &    # ComfyUI (owner's install) headless on :8000, UTF-8 forced (cp950 crashes it)
bash scripts/start_modly.sh &      # Modly backend on :8765 (install lives in ../ai_3d_pipeline_poc/tools)
# One GPU model at a time (8 GB): unload Modly before Qwen, free ComfyUI before Modly
curl -X POST http://127.0.0.1:8765/model/unload-all
curl -X POST http://127.0.0.1:8000/free -H 'Content-Type: application/json' -d '{"unload_models":true,"free_memory":true}'

# 1. Views (A-pose set used now: references/prompts/grandma_apose_*.txt, seeds 701-704)
python scripts/comfy_qwen.py --model qwen21 --research --image references/raw/grandma_raw_main.png \
  --image references/raw/grandma_raw_turnaround.png --prompt references/prompts/grandma_apose_34.txt --prompt-file \
  --seed 701 --out references/generated/X.png           # default --model edit2509 once Qwen-Image-Edit-2509 is installed
python scripts/ref_precheck.py references/generated/X.png   # then visual PASS/RETRY/REJECT (reports/reference_qa.md)

# 2. Image → 3D (TripoSG, Marching Cubes forced)
bash scripts/run_modly.sh "$(pwd -W)/references/approved_apose/grandma_34.png" triposg/generate TAG --no-texture

# 3. Clean-up, 1.55 m, 10k tris, ortho renders
"/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup --python scripts/process_character.py -- \
  --input modly_output/TAG.glb --output export/TAG_base_10000.glb --report reports/TAG.json --height 1.55 --decimate 10000 --renders reports/renders_TAG

# 4. Rig + retarget + texture + tote (fit first and check reports/<qa>/fit_both.png)
BL="/c/Program Files/Blender Foundation/Blender 5.2/blender.exe"
"$BL" -b --factory-startup --python scripts/rig_character.py -- --stage fit  --mesh export/TAG_base_10000.glb --out blender_work/rigN/grandma_rigged.glb --qa reports/rigN
"$BL" -b --factory-startup --python scripts/rig_character.py -- --stage full --mesh export/TAG_base_10000.glb --out blender_work/rigN/grandma_rigged.glb --qa reports/rigN \
  --refs references/approved_apose --views front,back \
  --bag modly_output/grandma_tote_triposg_s1.glb --bag-image references/generated/grandma_tote_try1.png --arm-absolute 1.0
```

Script map:
- `rig_character.py`: skeleton fit (spine follows the hunch; arms fitted along the spread arm; midline from the feet).
- `rig_full.py`: watertight remesh, bone heat (distance-skinning fallback), retargeting, texture projection (head fitted separately, hands in skin tone, crown in hair colour, per-view colour matching), tote, export.
- `compare_silhouette.py`: reference vs mesh width profiles.
- `provenance.py`: licence chain.

Dead ends already tried (don't repeat):
- A mesh with arms against the body. It cannot be rigged cleanly:
  - lowering how far the arms follow the clip, distance skinning and cutting the arms free all failed (`reports/rig3..5`);
  - A-pose source images fixed it.
- Hunyuan3D and TRELLIS.2 as the 3D step: licence problems. TRELLIS.2 also produces torn non-manifold surfaces.

---

## 5. Putting a new version in the game (local preview)

```bash
cp <new>.glb good-human/assets/characters/human/models/ai_grandma_research/grandma.glb   # stays git-excluded
python good_human_ai3d_poc/scripts/grandma_preview.py on
"$GODOT" --headless --path "$(pwd -W)" --import
"$GODOT" --headless --path "$(pwd -W)" --export-debug "Windows Desktop" "$(pwd -W)/build/windows_grandma_preview/GoodHuman.exe"
python good_human_ai3d_poc/scripts/grandma_preview.py off      # before any commit or test run
```

Contract with the game code (please keep it):
- glTF front is **+Z**; the adapter turns the model to the game's −Z.
- Skeleton3D with the **OwnerSkeleton bone names**. `P04HumanVisual.BONE_MAP` uses `pelvis`, `spine_03`, `head`, `upperarm_l/r`, `thigh_l/r`.
- AnimationPlayer with the **same clip names** as `p04_owner.glb`.
- Feet at y = 0, real height in metres (`body_scale` is not applied to a `skeletal_model`).

When a **commercial-safe** version exists (section 2), it can go through `export_commercial/` → the repo, and `FighterData.skeletal_model` can point at it for real. Whether she becomes the old master (a narrative change: 老爺爺 → 老奶奶) or a new encounter is the **owner's call**.

---

## 6. Owner direction (2026-09-30): fewer polygons, more cartoon

Claude tried an automatic pass: `good_human_ai3d_poc/scripts/toonify.py`. It decimates a rigged GLB (weights, UVs and clips survive) and reduces the texture to N flat colours (median filter, then k-means). Comparison: `good_human_ai3d_poc/reports/toon/compare.png` and `compare_c6.png`.

| Variant | Body tris | File | Read |
|---|---|---|---|
| rig6 (current) | 10,000 | 2.5 MB | reference |
| toon 5000 | 5,000 | 1.7 MB | nearly identical: **safe budget cut** |
| toon 3000 | 3,000 | 1.3 MB | fine at game distance, slightly faceted |
| toon 1500 | 1,500 | 1.1 MB | breaks: jagged hair and shoes |
| toon 3000, 6 colours, smooth | 3,000 | 0.9 MB | flatter, but cardigan and blouse merge and the glasses disappear; **still not cartoon** |

Conclusion:
- The polygon count can drop to **3–5k** with no rework.
- The **cartoon look cannot come from post-processing**: the AI mesh has realistic lumpy forms, and colour quantisation erases features instead of stylising them.

Suggested direction for you (it matches the P-04 human's own flat-colour look):
- **Remodel or retopo in simple, readable forms**: a rounder head, a bun as one or two clean shapes, the cardigan as a simple shell, chunky shoes. Use the AI mesh only as a proportion and silhouette guide (`export/grandma_apose_base_10000.glb` plus the approved A-pose views).
- **Flat colours by material region**, not a projected photo texture: hair, skin, cardigan (lavender; a few large painted flowers optional), blouse (cream), trousers (charcoal), socks, shoes (white/pink), glasses (dark), tote. Palette sampled from the approved views: skin ≈ (0.84, 0.60, 0.49), hair ≈ (0.63, 0.59, 0.61).
- **Keep the face readable at low poly**: glasses as geometry, eyes as small painted shapes.
- **Optional engine side (decide with Claude, since it affects every character)**: Godot `StandardMaterial3D.diffuse_mode = DIFFUSE_TOON` with toon specular gives a cel-shaded read across all characters with no asset change.
- **Budget**: ≤ 5k tris body + ≤ 600 tote, 1 to 3 materials or one small palette texture, on the OwnerSkeleton with the same clip names (section 5 contract).
