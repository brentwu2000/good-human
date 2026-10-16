# Claude → Codex handoff — 2026-10-17

## What changed

**Human body textures are now Trellis.2-generated** (owner chose it after a side-by-side test;
record: [TRELLIS2_TEXTURE_PASS_2026-10-17.md](TRELLIS2_TEXTURE_PASS_2026-10-17.md)). For each
human the basecolor PNG inside the runtime GLB is replaced; geometry, skin weights, joints and
the 19 clips are unchanged. The drawn faces are kept (tone-matched).

- Market auntie: built from the r3d checkpoint; towel corner colours now plain white (the
  sheet's towel is white; your r2 woven stripes are gone). Your satchel/strap are unchanged.
- Gym coach: built on your 2026-10-15 refine candidate (neck/shoulder shelf reduction kept);
  its refined texture is superseded by the Trellis2 one.
- Grandma, delivery rider, office worker, retired fisher, Xiaomi: built from the runtime GLBs.
  Grandma's silver hair is tone-mapped to the sheet (`hair_tone`), her face ellipse is set by hand.
- The other 2026-10-15 refine candidates (texture-only) are superseded by this pass.

- **Breed dogs** (corgi, shiba, golden, frenchie, pomeranian, chihuahua): coat basecolor
  replaced by a two-run Trellis2 texture; your faces are kept (face ellipse / separate face
  materials untouched). Chihuahua: body_albedo and head_albedo both replaced (face kept),
  coat corner colours were already white. Poodle untouched (your r40).
- **Player shiba** (`shiba_01`, `shiba_01_stylized`): the coat's vertex colours are replaced by
  an image texture (the colour attribute is removed); eyes, nose, rig and clips unchanged.

## How it is rebuilt

`bash tools/art/t2_run.sh tools/art/t2_configs/<id>.json` (needs the Modly Trellis2 extension
in `C:/Users/b/tools/modly`, ~10 GB of weights). Work files in `build/t2/<id>/`:
`colours.npz` (raw Trellis2 vertex colours), `t2_basecolor.png` (raw bake), `t2_facemask.png`,
`t2_final.blend` (the exported scene).

## Must not change

- Do not run Trellis2's own "Texture Mesh" node / UV baking for shipped art: it bakes with
  nvdiffrast (NVIDIA non-commercial licence). The pass bakes colours on vertices and transfers
  them with Blender.
- Texture guidance stays 3.0 (the extension's 1.0 default drifts colours).
- Keep the drawn faces; do not let a generated face replace them (LESSONS 6.14).

## Adjustment requests

- **CX-13** Review the six humans in Godot for texture-level defects the pass cannot see
  (prop paint on the body, seams at UV island borders, hair/skin borders). Local paint fixes
  on `t2_basecolor` are welcome; record them so a re-run does not erase them (a re-run starts
  from `colours.npz`).
- **CX-15** Delivery rider: the generated brows sit above the drawn ones (double brows);
  grandma: small bluish spot at the right temple.
- **CX-16** Dogs: chihuahua muzzle-side light smear; pomeranian a little paler than the sheet;
  stylized player shiba: faint spine bar, hard-edged forehead fill, two dark curl marks;
  check the face/coat border on each dog in motion.
- **CX-14** Market auntie's floral apron is softer than the sheet's print; an authored print
  over the Trellis2 base would be an improvement.
