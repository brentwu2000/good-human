# Breed-sheet dogs — preview only

Output of the AI 3D dog factory (`good_human_stylized_factory/scripts/batch_dogs.sh`),
shown by `dog_lineup.tscn` (open with `tools/art/open_dog_lineup.bat`). This folder is
excluded from every export preset; nothing here ships or replaces the game's shiba.

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
