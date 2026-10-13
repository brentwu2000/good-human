# Market auntie (市場阿姨) r1 — 2026-10-13 (Claude)

Owner sheet 「市場阿姨角色設定集」 (`assets/characters/human/concepts/market_auntie_visual_target_01.png`),
made the same way as the office worker (ADR-L05: each adopter background gets its own character).
She is the new adopter background `market_vendor` (52, 市場攤販, friendly/caring; warms to
food-motivated and affectionate dogs; reaction lines in her voice). Anyone of that background
who becomes the dog's human wears this model.

## Route (good_human_stylized_factory)
| Step | Tool | Notes |
|---|---|---|
| Views | fixed-box crop of the 三視圖 row + rembg | the figures stand too close for the automatic split |
| 3/4 A-pose view | Qwen-Image-Edit-2509 Q3_K_S + Lightning (Apache-2.0), seed 1, `prompt_market_auntie_34_v1.txt` | basket and hand props removed. ~85 min beside an open Blender; client timed out, image taken from ComfyUI's output |
| Geometry | TripoSG via Modly, Marching Cubes | 1.38M tris; headscarf bow, towel, apron, bag strap, boots all present |
| Clean / retopo / bake | `process_character.py` (1.50 m), `retopo.py` 12k, `bake_maps.py` 2048 | |
| Colour | **new** `project_simple.py` (front, back, side, mirrored side) | `project_textures.py` assumes the grandma's clothes layout (cardigan/trousers/socks): it painted her legs skin and trousers grey |
| Stylized | `paint_stylized.py`, **new generic `zones` mode** + `paint_profile.json` | face kept from the projection; head = black curls + headscarf band; body snapped to a 16-colour palette (k-means of the sheet) |
| Proportions | `match_proportions.py --head-share 0.24 --height 1.50` | she was already 0.257 → head ×0.915 |
| Rig + LODs | `rig_lods.py --name market_auntie --measure-neck --no-game-normal` | neck 1.005, skull 1.055, shoulder 0.96 m; 19 clips; game LOD2 6k tris, 1.2 MB |

## Found on the way
- The retopology came out with the lower body's normals inside-out: every view was rejected
  there by the depth test. `project_simple.py` makes normals consistent first.
- Automatic yaw fitting for the side / 3/4 views picked wrong angles (a face on the back of
  the head); fixed yaws (side −90, mirrored side +90) are used.

## r2 — 2026-10-14
Reprojected with `project_simple.py`'s welded-seam normals (found on the retired fisher):
coverage 18 % → 22 %, front of the face and the side view coloured. The square dark specks on
her cheeks and the line by her mouth are gone. Same palette, proportions and rig.
`r2_before_after.png` (top r1, bottom r2).

## Check
47 test scenes pass; `skeletal_model_test` +1 (market vendor wears her). `weapon_fight_contact_test`
failed once in one full run and passed on 4 reruns (with and without her): flaky, not caused by her.

## Open (grade B)
- Apron/blouse pattern is a flat-colour approximation of the sheet's floral print; some smudges.
- Face close-up is soft (projected, 6k LOD).
- Her cross-body bag, towel and headscarf are part of the body mesh (they move with it).
- Sheet rights: UNKNOWN, owner to confirm (as for the other sheets).
- Combat skills on the sheet (wok sweep, food throw, lid block) are design ideas, not built.

Images: `market_auntie_r1_2026-10-13/`.
