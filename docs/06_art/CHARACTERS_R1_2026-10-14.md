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
