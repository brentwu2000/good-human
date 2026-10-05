# Third-Party Asset License Register

Every third-party asset considered for GOOD HUMAN! must be recorded here before production use.

| Asset | Author | Source | License | Free | Commercial | Modification | Grade | Retrieved | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Shiba 01 pipeline study (raw geometry) | Codex-directed generation; Tencent Hunyuan3D-2mv | `../good-human-3d-pipeline/generated/raw/shiba_01.glb`; references generated with built-in imagegen | Tencent Hunyuan 3D 2.0 Community License; see workshop `docs/LICENSING.md` | Yes, local generation | Territory-restricted; owner acceptance recorded in workshop | Yes, subject to model license | B — prototype, not final art | 2026-09-20 | Workshop licensing record excludes EU, UK and South Korea distribution; do not treat as CC0. Original raw mesh preserved. No runtime replacement approved by this entry. Rigged, animated export now imported at `assets/characters/dog/models/shiba_01/shiba_01.glb` (12,098 tris, 23 bones, Idle/Walk/Sit) and covered by `tests/shiba_model_test.tscn`; still grade B. |

## P-04 / D5-01 Blender implementation — retrieved 2026-09-29

| Asset | Author | Source | License | Commercial / modification | Grade | Notes |
|---|---|---|---|---|---|---|
| Human anatomical base and game-engine rig | MakeHuman Community / MPFB contributors | Locally installed MPFB core assets; [official output license](https://static.makehumancommunity.org/mpfb/faq/can_i_sell_models.html), [license text](https://github.com/makehumancommunity/mpfb2/blob/master/LICENSE.md) | CC0 1.0 core graphical assets; addon code is GPL and is not distributed in GLB | Yes / Yes, free | B implementation candidate | Original base preserved in workshop `blender/human/p04_owner/owner_01_base.blend`; adapted head/hands and weight data in `assets/characters/human/models/p04_owner/p04_owner.glb`. No community clothing/skin downloads used. |
| P-04 clothing, trim, short hair, footwear and animation studies | Codex-directed Blender authoring for GOOD HUMAN!; clothing topology derives from MPFB core helpers | `tools/art/`; numbered workshop Blender milestones | Original project additions over CC0 core geometry | Yes / Yes | B implementation candidate | Five mesh modules, 17 motion clips. Not S final art; no imagegen bitmap used as a production texture. |
| P-04 refined hair pass | Codex-directed original Blender authoring for GOOD HUMAN! | `tools/art/fix_owner_hair.py`; workshop `owner_11_hair_fix.blend` | Original project addition over CC0 core geometry | Yes / Yes | B implementation candidate | Rounded hair cap and three fringe meshes in `p04_owner_hairfix.glb`; replaces the earlier runtime hair reference while preserving the original milestone. |
| Banyan geometry and bark textures | Codex-directed original Blender authoring for GOOD HUMAN! | `tools/art/build_banyan_01.py`, `tools/art/detail_banyan_01.py`; workshop milestones | Original project-authored geometry and procedural textures | Yes / Yes | B implementation candidate | `assets/environment/territory/models/banyan_01/banyan_01.glb`; no third-party tree mesh, leaf pack or photographic texture. |
| Banyan scent states and reward marker | Codex-directed original Blender authoring for GOOD HUMAN! | `tools/art/build_banyan_scent_states.py`; workshop `banyan_06` through `banyan_10` milestones | Original project-authored geometry and materials | Yes / Yes | B implementation candidate | `assets/environment/territory/models/banyan_01/banyan_scent_states.glb`; 35 mesh nodes for discovery, contest, claim, ownership, and reward review states. |
| Greed moment prop kit | Codex-directed original Blender authoring for GOOD HUMAN! | `tools/art/build_greed_props.py`; workshop `blender/environment/greed/greed_props_01.blend` | Original project-authored geometry and materials | Yes / Yes | B implementation candidate | `assets/environment/territory/models/greed/greed_props.glb`; bus stop, bench, full bag, rival neckerchief, scent trail, and exit plaque. |

## Complete puppy eye source — 2026-10-03

Original Codex-directed built-in OpenAI imagegen output, using the owner's
generated chihuahua sheet as style reference; no third-party eye image.
Source, authoring prompts and retrieval record:
`assets/_source/generated/dog_eyes_r6/PROVENANCE.md`. Preview grade B; existing
dog model/rig restrictions remain. Only the RGBA puppy-eye source is baked
into preview atlases; earlier iris experiments are not consumed.

### Continuing asset rules

2026-10-04: owner-approved Pomeranian r10 is published to the runtime breed path.
Frenchie r11 is a separate review candidate. Both reconstruct the anterior face
using the existing owner's breed front references and Codex-authored geometry;
no new third-party source was imported. Existing factory/rig restrictions and
grade B remain. See [workflow](DOG_WHOLE_FACE_REPAIR_WORKFLOW.md) and
[Frenchie provenance and repair record](FRENCHIE_FACE_R11_2026-10-04.md).

Pomeranian r9 (2026-10-04): Codex-authored local facial geometry adaptation and
muzzle texture repair over the existing breed-factory model. Nose detail derives
from the owner's original pomeranian front sheet; eye source remains the r6
project-generated eye. No new third-party assets. Existing breed provenance,
inherited rig/weight restrictions and grade B remain; see
[r9 record](POMERANIAN_FACE_R9_2026-10-04.md).
- Prefer CC0.
- CC-BY is acceptable only when attribution requirements are recorded and satisfied.
- NC and ND assets are prohibited.
- “Free download” alone is NOT proof of commercial/modification rights.
- Preserve untouched originals under `assets/_source/`.
- Record the license text or source evidence when practical.
- Do not redistribute third-party source packs outside what their license permits.
