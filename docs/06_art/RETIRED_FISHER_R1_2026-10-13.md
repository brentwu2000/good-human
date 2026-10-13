# Retired fisher (退休釣魚阿伯) r1 — 2026-10-13 (Claude)

Owner sheet 「退休釣魚阿伯角色設定集」 (`assets/characters/human/concepts/retired_fisher_visual_target_01.png`).
He is the existing adopter background `retiree` (patient, gentle — matches the sheet's 隨性·淡定,
dislikes noise); its reveal line now says he fishes on the riverbank, and it wears this model (ADR-L05).

## Route (good_human_stylized_factory), as the market auntie, plus:
| Step | Notes |
|---|---|
| 3/4 A-pose view | Qwen-Image-Edit-2509, seed 1, `prompt_retired_fisher_34_v1.txt` (rod case and net removed). 10 min this time |
| Geometry | TripoSG, Marching Cubes. Came out turned ~35° like the 3/4 view: `process_character.py --yaw -35` faces it front |
| Colour | `project_simple.py` front/back/side/mirrored side |
| Stylized | `paint_stylized.py` zones: face kept; brim (radius from the head axis), hat, grey hair, shirt sleeves, skin forearms, olive vest, grey-brown shorts, skin shins, sandals |
| Proportions | head share (with hat) 0.214 → 0.24 (head ×1.157), height 1.55 m |
| Rig | neck 1.007, skull 1.087, shoulder 0.967 m; 19 clips; game LOD2 6k tris, 1.1 MB |

## Found on the way (also fixes the others)
`project_simple.py` judged "outside" island by island (glTF splits vertices at UV seams), so ~40 %
of his front faces pointed inward and took no colour (17 % coverage). Seams are now welded before
`normals_make_consistent`: 31 % coverage, front/side/back all coloured. Rerunning the market auntie
through it would improve her too (not done here).

## Check
47 test scenes pass; `skeletal_model_test` +1 (the retiree wears him).

## Open (grade B)
Face kept from the projection is more saturated than the flat skin around it; small grey specks
beside the nose; hat lures are just colour. Sheet rights UNKNOWN (owner to confirm). The sheet's
combat ideas (rod pull, fish swarm, net, stool strike) are not built.
