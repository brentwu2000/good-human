# Breed dogs — texture fix handoff to Codex (ART)

From: Claude (gameplay/code). Date: 2026-10-01.
Owner request: 「有些貼圖還是有點瑕疵，我想請 codex 修」.

Codex owns the art pipeline (CLAUDE.md). This document hands over seven rigged trial dogs made by the AI 3D dog factory from the owner's breed sheets. The task is to **repair the base-colour textures**. Geometry, rig and animation are out of scope unless the owner asks.

---

## 1. What exists

Seven dogs:

| id | breed | target height |
|---|---|---|
| `chihuahua` | 吉娃娃 | 0.35 m |
| `pomeranian` | 博美犬 | 0.38 m |
| `poodle` | 貴賓犬 | 0.45 m |
| `frenchie` | 法國鬥牛犬 | 0.45 m |
| `corgi` | 柯基犬 | 0.45 m |
| `shiba` | 柴犬 | 0.55 m |
| `golden` | 黃金獵犬 | 0.75 m |

Every dog has the same build:
- **Mesh:** one mesh `DogBody`, about 12k triangles (Instant Meshes quads).
- **Texture:** one material with a 1024² base colour, stored as JPEG inside the GLB. There is **no** normal map in the GLB.
- **Rig:** the game's shiba skeleton (`Shiba_Rig`, 23 bones), fitted to each body, with the clips `Idle`, `Walk` and `Sit`.
- **Size:** about 2 to 2.4 MB per dog.

They are shown in a **preview scene only**:
- Scene: `assets/art_previews/dogs/dog_lineup.tscn`.
- Open it with `tools/art/open_dog_lineup.bat`.
- Controls: Enter changes the clip, Space toggles the soft toon, the arrows orbit and zoom.
- `assets/art_previews/*` is excluded from every export preset, so nothing here ships. The game's player shiba (`assets/characters/dog/models/shiba_01/`) is untouched.

### Files per dog
`F` is `C:\Users\b\Documents\good_human_stylized_factory`.

| What | Path |
|---|---|
| Owner's breed sheet | `F\input\dogs\<id>_sheet.png` (ChatGPT, owner-made) |
| Sheet crops used for projection | `F\references\dogs\<id>_front.png`, `_side.png`, `_back.png`, `_back34.png` |
| 3/4 view sent to TripoSG | `F\references\dogs\<id>_34.png` |
| Raw TripoSG mesh (~1.2M tris) | `F\modly_output\dogs\dog_<id>_s1.glb` |
| Low-poly with UVs (unrigged) | `F\blender_work\dogs\<id>\lod0_uv.glb` |
| Low-poly textured (unrigged) | `F\blender_work\dogs\<id>\lod0_textured.glb` |
| **Base colour to repair** (PNG, 1024², on the dog's own UVs) | `F\texture_work\dogs\<id>\projection\basecolor.png` |
| Baked normal / AO from the high-poly (same UVs, not used yet) | `F\texture_work\dogs\<id>\bake\normal.png`, `ao.png` |
| **Rigged game file** (factory output, keep as is) | `F\export\dogs\<id>_game.glb` |
| Copy shown in the preview | `good-human\assets\art_previews\dogs\models\<id>.glb` |
| QA sheets: 3/4, side, back, low (belly) | `F\renders\dog_qa\handoff\_<id>_sheet.png` |

---

## 2. How the textures were made, and why they have flaws

`F\scripts\dog_project.py` projects the sheet's **front, side and back** crops onto the low-poly. The side view is mirrored for the other side. Each texel takes the view that faces it best; gaps are filled from their neighbours. Typical flaws follow from that:

1. **Hidden areas are invented:** belly, inner legs, paw soles, under the chin and the backs of the ears. No view sees them, so they get smeared or flood-filled colour.
2. **Hard seams** where one view takes over from another: front to side across the shoulders, side to back on the haunches, often as straight vertical lines.
3. **Misfits:** the sheet view and the mesh disagree a little, so a feature lands twice or in the wrong place (poodle face, corgi collar on the tail).
4. **Sheet lighting is baked in:** highlights and shadows from the sheet's renders.

---

## 3. Defects per dog

Seen on the QA sheets `renders\dog_qa\handoff\_<id>_sheet.png` (3/4, side, back, low):

| Dog | Defects (most visible first) |
|---|---|
| **poodle** | **Double face**: the front view's eyes and muzzle repeat on the side of the head. Torn light patches on the ear flaps and the back. Flower hair clip duplicated. Inner legs and belly smeared. |
| **pomeranian** | Ragged, washed-out fur on the head top and ears (texture and spiky geometry together). Dark streak or hole at the muzzle in profile. Tail pale and blotchy. |
| **corgi** | **Tail carries collar-blue stripes**: the side view's collar was projected onto it. Hard vertical seam on the flank (side view). Black streak along the muzzle in profile. Pale smears on the inner hind legs and paws. |
| **frenchie** | Harness straps stretched over the back and rump, and harness pattern on the tail. White band along the lower flank. Back view of the head has smeared strap pieces. |
| **chihuahua** | Legs and paws heavily smeared white and grey (side and low views). Streaky ear backs. Light patches on the back of the head. |
| **shiba** | White smear on the ear backs. White wedge on the tail seen from behind. Pink or red smudges on the inner legs (low view). |
| **golden** | Best of the seven. Grey paw soles, a few seams on the back, flat colour under the belly. |

---

## 4. The task

For each dog, repair `basecolor.png` so the dog reads like its sheet from every game angle. The camera is at dog height, so the **side, 3/4 and low views matter most**.
- Remove the doubled features, the wrong-colour pieces and the hard seams.
- Paint the hidden areas (belly, inner legs, paw pads, ear backs, under the tail) in the breed's colours from the sheet's palette swatches.
- Soften the baked-in sheet lighting where it fights the game's light.
- Keep the stylized look of the sheets: large clean colour areas. The game also has a soft toon mode (`world/art/soft_toon.gd`) that should still read well.

Tools are your choice: texture paint in Blender, reprojection with more views, or painting in an image editor on the UV layout. The UVs come from `bake_maps.py` (Blender smart UV). If an island is too broken to paint, re-unwrapping is fine. In that case rebuild from `lod0_uv.glb`, then run `rig_dog.py` (section 5).

Optional, only if time allows:
- Add the baked `normal.png` / `ao.png`. They are already on the same UVs.
- Pomeranian head-top geometry spikes, if a light smooth fixes them without touching the rig.

### Out of scope (ask the owner first)
- Changing the skeleton, the bone names or the clips.
- The `Sit` clip deforming the rear on dogs far from the shiba's proportions. That is an animation and weights matter.
- Putting any dog into the game proper.

---

## 5. Putting a repaired texture back

**Texture only**, which keeps the rig, weights and clips exactly:

```
blender -b --factory-startup --python F\scripts\swap_dog_texture.py -- ^
    F\export\dogs\<id>_game.glb  <your_basecolor.png>  F\export\dogs\<id>_game_codex.glb
copy F\export\dogs\<id>_game_codex.glb  good-human\assets\art_previews\dogs\models\<id>.glb
```

`swap_dog_texture.py` refuses to overwrite its input.

**After re-unwrapping:** project or paint onto `lod0_textured.glb`, then rig it with
```
blender -b --factory-startup --python F\scripts\rig_dog.py -- --mesh <textured.glb> --out F\export\dogs\<id>_game_codex.glb --keep-orient
```
The script fits the skeleton, copies the shiba's weights, smooths them, and retargets Idle, Walk and Sit.

---

## 6. Hard rules

1. **Do not overwrite the factory originals:** `export\dogs\<id>_game.glb`, `projection\basecolor.png` and the others. Write new files with a `_codex` suffix, and keep the originals for comparison. (The grandma's `grandma_game.glb` was once replaced in place without notice, which made the two versions hard to compare.)
2. Only `assets/art_previews/dogs/models/<id>.glb` in the repo is replaced. Do not touch `assets/characters/dog/models/shiba_01/` or any game data.
3. **Licence chain:**
   - Sheets: owner-made with ChatGPT (output rights assigned to the user).
   - Edit-2509 + Lightning LoRA: Apache-2.0.
   - TripoSG with **Marching Cubes only**: MIT / BSD-3. Never `diso`, which is CC BY-NC.
   - Instant Meshes: BSD-3.
   - The skin weights are copied from shiba_01, which is Hunyuan3D output (grade B, territory-restricted); see `assets/art_previews/dogs/PROVENANCE.md`.
   - Do not bring in any RESEARCH_ONLY model or texture (Qwen-Image-2.1, Hunyuan3D, TRELLIS). Record what you used in that PROVENANCE.md.
4. **Budget:** keep each GLB at or below about 2.5 MB, with a base colour of 1024² or smaller (JPEG inside the GLB).
5. Keep the mesh name `DogBody`, the armature `Shiba_Rig` (23 bones, same names) and the clips `Idle`, `Walk`, `Sit`. The preview finds the `AnimationPlayer` and plays those clip names.

---

## 7. Validation

1. **QA renders** (3/4, side, back, low):
   ```
   blender -b --factory-startup --python F\scripts\render_pose_base.py -- <glb> <out.png> --view 34|side|back|low
   ```
   Compare with the current `_<id>_sheet.png`.
2. **Clips:**
   ```
   blender -b --factory-startup --python F\scripts\qa_dog_clip.py -- <glb> <out prefix>
   ```
   This renders Idle, Walk and Sit from the side.
3. **Godot:** run `"$GODOT" --headless --path . --import`. Then capture the lineup:
   ```
   "$GODOT" --path . --resolution 1280x720 res://assets/art_previews/dogs/dog_lineup.tscn -- --capture <png>
   ```
   Or open `tools/art/open_dog_lineup.bat` and check every dog with the toon on and off.
4. `tests/run_all.sh` must stay green. The preview is not covered by tests, but the import must not break other scenes.
5. Write a short report in `docs/06_art/` that lists, per dog, what was fixed, the before and after QA images, and the file sizes.
