# Owner head refinement r1 — 2026-10-12 (Claude)

Owner: 「請你負責精修人物」 (2026-10-12) — Claude refines the human characters
this round (owner, opponents, grandma); the art split is otherwise unchanged.

## What changed
The in-game owner had a bald crown and forehead with two dark lumps at the
sides (the 2026-09-29 hair cap sat behind and below the skull), no glasses, and
collar points floating off the chest. Target: `assets/characters/human/concepts/owner_visual_target_01.png`.

- **Hair_Curls** (5.4k tris): scalp shell shrink-wrapped to the skull and cut at
  a hairline (high at the brow, over the ears, low at the nape), ~260 seeded curl
  clumps, a forelock, voxel-remeshed, smoothed, decimated; pushed outside the
  skin. Old `Hair_Module`, `Hair_Cap_Refined`, `Hair_Fringe_*` removed.
- **Glasses** (round rims, bridge, temples) and **Brows**. All skinned 100 % to `head`.
- **Jacket details**: collar points, zip and pocket seams laid onto the jacket
  body (were floating boxes). Hem/cuff bands untouched.
- Stubble tried and dropped (coarse face mesh, `ArtTone` unused by the skin material).

Body, skeleton, bone names and every clip are unchanged.

## Files
- Tool: `tools/art/refine_owner_head.py` (Blender 5.2, background; deterministic seed)
- Source: workshop `owner_11_hair_fix.blend` → `owner_12_head_refine.blend`
- Runtime: `assets/characters/human/models/p04_owner/p04_owner_refined.glb`, now
  `P04HumanVisual.MODEL` (the old `p04_owner_hairfix.glb` is kept, unused).
- Review capture tool: `tests/capture/human_portraits.tscn` (front/¾/side/back/face per fighter).

## Check
All 47 headless test scenes pass. Before / after: `owner_head_r1_2026-10-12/`.

## Open (not done in r1)
- Outfit: the concept is an olive overshirt over a cream tee, cuffed jeans, white
  sneakers, backpack; the game tints the jacket from `FighterData.shirt_color`
  (owner: coral). Changing the owner's colour is an owner decision.
- The four ordinary opponents use the same head; they differ only by tint.
- The grandma (old master) has her own model; not yet reviewed in detail.
