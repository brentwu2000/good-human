# Delivery rider, gym coach, Xiaomi r1 — 2026-10-14 (Claude)

Owner sheets: 「外送英雄」(07), 「健身壯漢」(06), 「孫女小米」(05)
(`assets/characters/human/concepts/{delivery_rider,gym_coach,granddaughter_xiaomi}_visual_target_01.png`).
Same AI 3D factory route as the market auntie and the retired fisher (ADR-L05).

| Character | Background | In the game | Height | Head share | Game file |
|---|---|---|---|---|---|
| Delivery rider | existing `delivery_rider` (energetic, bold) | yes | 1.70 m | 0.20 → 0.24 (×1.24) | 6k tris, 1.2 MB |
| Gym coach | **new** `gym_coach` (32, energetic, friendly, proud; likes playful dogs) | yes | 1.78 m | 0.14 → 0.24 (×1.89) | 6k tris, 1.2 MB |
| Xiaomi | none — owner: model only, not an adopter (a 10-year-old would fight adults) | no | 1.35 m | 0.38, kept (a child) | 6k tris, 1.3 MB |

Stats are rolled as for everyone: the gym coach's build says nothing about how he fights.

## Route notes
- Qwen-Image-Edit-2509 3/4 views: rider 70 min, Xiaomi and the coach ~45 min each (GPU shared with
  an open Blender). The queue's waiting shell was killed once for low system memory (3.9 GB free of 32);
  the images had already been written.
- TripoSG: the rider came out turned 90° (`process_character.py --yaw 90`).
- `project_simple.py --neck-search 0.25,0.50` for Xiaomi: her bun's wisps were taken for the neck and
  her face was projected onto her chest.
- `match_proportions.py --neck-range`: the bun (Xiaomi) and the cap brim (coach) are narrower than the
  neck; per-character ranges 0.50–0.66 and 0.75–0.89.
- `paint_stylized.py` zones accept `y_min` (backpacks behind the body). Palettes: k-means of the sheet,
  Xiaomi's sampled directly (k-means mixed her jacket and skin).

## Check
47 test scenes pass; `skeletal_model_test` +2 (rider, coach wear their models).

## Open (grade B)
- The coach's head at ×1.89 reads cartoon-big on a huge body: matches the grandma's ratio as asked;
  the owner may prefer a smaller head for him.
- Xiaomi's jacket is mottled yellow/skin; the rider's jacket pattern is busy. Faces kept from projection.
- Sheet rights UNKNOWN (owner to confirm). The sheets' combat skills are not built.

Images: `characters_r1_2026-10-14/`.

## Surface r2 — the grandma's fix (owner: 「模型貼皮質感很差 請依照奶奶的調整方式修正」)
Same diagnosis as the grandma's surface v4: the texture was painted on LOD0's 95k-triangle UVs and
squeezed onto the 6k game LOD (triangle fragments, mottled colour). Applied to all six game models
(office worker, market auntie, retired fisher, delivery rider, gym coach, Xiaomi):
1. **Own UVs + rebake** (`rig_lods.py --rebake-game 2048`): the decimated game LOD is smart-unwrapped
   and its base colour baked from LOD0 (Cycles, selected-to-active, 16 px margin) into a 2048 PNG
   (JPEG blotched flat colour). No normal map, matte.
2. **One colour per material**: shade variants output their base colour; shading comes from AO.
   5x5→7x7 majority filter, 4 rounds.
3. **Continuous object-space clothing areas** (`"fixed"` zones in `paint_stylized.py`): jacket,
   helmet, gloves, trousers, vest, tank top, arms, shins are filled by position, not by the noisy
   projection. Patterns that are the design (auntie's florals, the husky print) keep a palette.
Steps 1→3: `surface_step1_rebake.png`, `surface_step3_flat_zones.png` (grandma on the left).

Cost: game files 1.1–1.3 MB → 4.5–5.8 MB (2048 PNG). 1024 PNG would be ~1.5 MB — size is for
the owner to decide later. Open: faces are still the projected painting (softer than the
grandma's drawn features); the market auntie and the office worker keep some blotches.

## Faces r3 — drawn like the grandma's (owner chose plan A)
Flattening the projected faces failed twice (blotches; features vanished): the projected
features are partial. Now each face is **drawn**: `draw_face_map.py` draws simple features
(closed-eye arcs or round eyes with a highlight, brows, mouth, blush; the fisher's white
goatee) as shapes over the front reference, positions read off it on a 20 px grid, stored in
each `paint_profile.json` → `face_drawing`. `paint_stylized.py` `drawn_face` zones fill the
face with flat skin (dark projected texels stay hair) and project the drawing from the front
with project_simple's registration. Gym coach: offset [-12, 10] px (his reference head is tilted).
`surface_step4_drawn_faces.png` (grandma left), `xiaomi_drawn_face.png`. 47 test scenes pass.
