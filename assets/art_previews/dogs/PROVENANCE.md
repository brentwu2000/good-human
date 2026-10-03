# Breed-sheet dogs — preview only

Output of the AI 3D dog factory (`good_human_stylized_factory/scripts/batch_dogs.sh`),
shown by `dog_lineup.tscn` (open with `tools/art/open_dog_lineup.bat`). The models now
live in `assets/characters/dog/models/breeds/` and five of them are the opponent pairs'
dogs in the 3D walk (see "In the game" below); the player's dog is still `shiba_01`.

| Stage | Tool | Licence |
|---|---|---|
| Breed character sheets | Owner supplied (`.claude/*角色*.png`, 2026-10-01), made by the owner with ChatGPT (OpenAI image generation) | OpenAI terms: output rights assigned to the user |
| 3/4 front view | Qwen-Image-Edit-2509 Q3_K_S + Lightning 4-step LoRA | Apache-2.0 |
| Geometry | TripoSG via Modly, Marching Cubes extractor (diso not installed) | MIT / BSD-3 |
| Low-poly | Instant Meshes | BSD-3 |
| Texture | Projection of the sheet's front / side / back views (`dog_project.py`) | — |
| Skeleton, clips, skin weights | The game's `shiba_01` rig, fitted per breed (`rig_dog.py`) | Weights copied from shiba_01, whose mesh is Hunyuan3D-2mv output (grade B, territory-restricted) |

Before any of these dogs is used in the game: re-paint the weights instead of copying shiba_01's (or accept its licence), as was
done for the owner's other AI characters.

## Codex texture repair — 2026-10-01

Preview models now use a texture-only revision derived from the same owner-made
breed sheets and factory projection PNGs, retrieved locally on 2026-10-01.
Author: Codex ART, for the owner. Tools: Blender 5.2 surface-space projection and
procedural palette fills, with Python packaging. No additional external assets,
generative model, normal map, or RESEARCH_ONLY material was introduced.

The factory's `<breed>_game.glb` and `projection/basecolor.png` remain unchanged.
New deliverables use `<breed>_game_codex.glb` and `basecolor_codex.png`.
Only the embedded JPEG changes: all original geometry, UVs, rig, skin weights,
and animation data are preserved byte-for-byte. The inherited licence chain and
grade-B / territory restriction above still apply. These are review candidates,
not S-grade production approval.

See [repair report](../../../docs/06_art/BREED_DOGS_TEXTURE_REPAIR_CODEX_2026-10-01.md)
for comparisons, remaining defects, checksums and validation.

## Eye texture revision r5 — 2026-10-02

Codex ART repainted each eye from the same owner-supplied front reference using
local surface projections in Blender, removing competing old eye projections.
The poodle eyes were moved off the sloping muzzle onto the forward head surface;
the Frenchie's nose was registered separately. No new external assets or models
were used. Geometry, UVs, rig, weights and clips remain byte-identical to the
factory GLBs. The existing licence restrictions and preview-only grade remain.
See the [r5 report](../../../docs/06_art/BREED_DOGS_EYE_REPAIR_CODEX_2026-10-02.md)
for actual both-side 45-degree screenshots and unresolved mouth/geometry defects.

## Complete-eye revision r6 — 2026-10-03

The r5 eye-quality claim is superseded. Its front-reference crops included
occluding muzzle pixels, most visibly a diagonal cream cut across Frenchie eyes.
R6 uses a complete puppy eye generated with the built-in OpenAI imagegen tool
from the owner's chihuahua style reference, then bakes it into the existing UV
atlas with per-side ray-cast placement, visibility checks and alpha filtering.
The source and exact prompts are preserved in
[`dog_eyes_r6/PROVENANCE.md`](../../_source/generated/dog_eyes_r6/PROVENANCE.md).

Only the embedded base-colour image changes. No experimental eye mesh is
delivered; all original geometry, UVs, materials, skeleton, weights and clips
remain byte-identical. The inherited licence restrictions and preview-only
grade remain. See the [r6 report](../../../docs/06_art/BREED_DOGS_EYES_R6_2026-10-03.md)
for actual runtime captures and remaining surface/texture limitations.

## In the game — 2026-10-03

The owner accepted the inherited shiba_01 licence (grade B, territory-restricted, the
same terms as the player's shiba) and put the r6 models in the game. They moved to
`assets/characters/dog/models/breeds/` (this folder is excluded from export); each
`data/encounters/*.tres` names its dog through `EncounterData.dog_model`:

| Pair | Dog | Breed |
|---|---|---|
| Jogger | 小柴 | shiba |
| Gym | 阿鬥 (was 比特) | frenchie |
| Old Master | 小白 | pomeranian |
| Delivery | 短腳 (was 米克斯) | corgi |
| Rival | 阿金 (was 阿黑) | golden |

Chihuahua and poodle are unused. Re-paint the weights before release, as above.
