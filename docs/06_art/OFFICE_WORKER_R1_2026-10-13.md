# Office worker (社畜上班族) r1 — 2026-10-13 (Claude)

Owner: 「下一個人物，範例圖在這，請用之前規畫好的路線做出來」, then chose route A
(the AI 3D factory, not hand-built geometry). Sheet:
`assets/characters/human/concepts/office_worker_visual_target_01.png`.

He is the `office_worker` adopter background (HumanBackgroundData). Everyone of that
background who becomes the dog's human now wears this model; other backgrounds keep
the shared P-04 human in their colours.

## Route (good_human_stylized_factory, v4/v5)
| Step | Tool | Output |
|---|---|---|
| Views from the sheet | crop + rembg cut-out on flat grey | `references/humans/office_worker/office_worker_{front,side,back}.png` (back = the sheet's back *with* backpack) |
| Stylized 3/4 A-pose view | Qwen-Image-Edit-2509 Q3_K_S + Lightning LoRA (Apache-2.0), seed 1, prompt `references/humans/prompt_human_34_v1.txt` | `office_worker_34.png` (QA: identity, glasses, ears, rolled sleeves, tie, belt, trousers, shoes kept; arms clear) |
| Geometry | TripoSG via Modly, Marching Cubes (no diso) | `modly_output/humans/office_worker_s1.glb` (686k tris; backpack generated with the body) |
| Clean + scale 1.65 m | `process_character.py` | 40 loose parts removed |
| Retopology | `retopo.py` (Instant Meshes) | 95k tris quad LOD0 |
| UV + Normal/AO bake | `bake_maps.py` 2048 | |
| Body colour | `project_textures.py --hair dark` (new option) | shirt, tie, backpack, trousers |
| Stylized texture | **new** `paint_stylized.py` + `paint_profile.json` | head and shoes from geometry, body snapped to the sheet palette (below) |
| Rig + clips + LODs | `rig_lods.py --name office_worker --measure-neck --no-game-normal` (new options), owner_plus_relaxed source | 19 clips incl. Idle/Walk_Relaxed; LOD0 95k / LOD1 12k / LOD2 6k / LOD3 2.5k |
| Game | LOD2, 1024 base, matte, no normal map | `assets/characters/human/models/office_worker/office_worker.glb` (1.1 MB) |

### Why the head is painted, not projected
The sheet's front view and the generated 3/4 view have different head proportions,
so projection put the glasses a few centimetres off (doubled rims, hair on the face).
`paint_stylized.py`: rims found as rings in a front depth high-pass (circle
Hough, `rim_depth_highpass.png`), made symmetric; eye whites, pupils with a glint,
frame and bridge, worried brows, small frown, blush and pink ears; hair vs skin from
the baked normal's bumpiness, neighbour vote, a face ellipse and ear zones; white
uppers and grey soles; trouser-coloured hem band.

### r2 polish (owner: 「先把人物打磨完成再討論」 size)
- **Body as flat colour blocks** (v5 §14): each projected texel snaps to the sheet palette
  allowed in its zone — chest: shirt, tie only on the centre line (then navy with diagonal
  stripes), straps; collar and neck: skin; backpack (what stands off the back, measured at
  the waist below it): black; belt band; below the belt: trousers, inside the trousers'
  measured edge per centimetre (the hanging arms are outside it); arms: shirt above the
  elbow (rolled sleeves), skin below. Majority filter, soft AO. UV islands dilated 16 px.
- **Matte game material, no normal map**: LOD0's baked normals on the 6k LOD showed as
  shiny cracked facets in the hair.
- **Neck and shoulders measured on the mesh** (`rig_character.measure_neck`): scaled
  from the owner, his neck joint sat at eye height (1.38 m) and would have folded the
  face; now neck 1.10, skull base 1.19, shoulder 1.05 m. Spine spaced pelvis → neck.
- Tried and dropped: decimating with the head protected (Decimate vertex group) —
  the head already takes ~47 % of 6k, and chained LODs broke the face.
- The watch is not painted separately; a dark band at the left wrist reads as one.

## Game
- `HumanBackgroundData.skeletal_model` (new); `HumanCandidate.to_fighter_data` passes it on.
- `office_worker.tres`: model + sheet palette (light grey / pale blue shirt, charcoal trousers —
  used only if the shared model is ever shown for this background).
- Test: `skeletal_model_test` (+6: background → model, clips, relaxed ambient, others shared).
- Review capture: `tests/capture/human_portraits.tscn -- <dir> office_worker`.

## Licence (same gate as the grandma)
Qwen-Image-Edit-2509 Apache-2.0, TripoSG MIT, Instant Meshes BSD-3, rembg MIT: commercial OK.
diso (CC BY-NC) not installed. **The sheet's own rights are not documented** (provenance class
UNKNOWN): the owner needs to confirm them before release, as for the grandma sheet.

## Open (grade B)
- 6k-tri game LOD is faceted in face close-ups; a few dark specks remain on the shirt.
- File size: to discuss with the owner after this polish (he is 1.1 MB vs the grandma's 2.7 MB).
- The procedural r1 attempt (owner-mesh edits) was dropped for this route; its script is gone.

Images: `office_worker_r1_2026-10-13/` (`*_r2.png`, `lineup_owner_office_grandma.png` for r2).
