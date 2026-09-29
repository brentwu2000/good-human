# P-04 / D5-01 Blender implementation 01

Date: 2026-09-29. Status: REVIEW, grade B implementation candidates. This is actual Blender geometry/rig/animation and a running Godot scene, not imagegen artwork. It is not S-level final character art and does not claim full production integration.

## Deliverables

| Asset | File | Contents |
|---|---|---|
| Human | `assets/characters/human/models/p04_owner/p04_owner.glb` | 1.76 m, 19,620 triangles, five mesh modules, one 53-bone skin, 17 animation clips |
| Banyan | `assets/environment/territory/models/banyan_01/banyan_01.glb` | Three meshes, 35,943 triangles, embedded bark albedo/normal, three-trunk/root/leaf construction |
| Review scene | `assets/art_previews/p04/p04_asset_showcase.tscn` | Motion selection, 8-second staging, dog-eye camera, existing dog with review collisions, landmark and personality views |
| Legacy adapter | `assets/characters/human/modular/p04_human_visual.gd` | Reachable Hips/Torso/Head/ArmL/ArmR/LegL/LegR controls mapped to skeletal rotation |
| Validation | `tools/art/validate_p04_assets.gd` | Import, animation existence/finite poses, control-to-bone response, legacy binding and clean tree export checks |

The numbers above come from exported GLB data / manifest, not the image references. Images and shaders in the references are not automatically reproduced by this first mesh pass.

## Open the implementation

Run `powershell -ExecutionPolicy Bypass -File tools/art/open_p04_preview.ps1` from the repository, or open the review scene in Godot. Controls are on-screen: 1–5 choose view, Space cycles the 17 actions, G cycles five dog situations, WASD moves the dog, V switches to dog-eye view. It uses no save/load calls, combat results or territory rewards.

The dog is the existing imported Shiba; no replacement dog model was authored. Review collision uses a human capsule, not per-leg collision. The five dog cases stage blocked/around/retreating/behind/crossing for inspection. Leash endpoint tracks the owner's actual hand bone, while slack and wrap handling remain a simplified study. This is not a claim that production dog collision/camera behavior changed.

## Animation library

Idle, Idle_Untrained, Idle_Scrapper, Idle_Calm, Walk, Approach, Circle, Backstep, Jab, HeavyHook, Kick, Block, Dodge, HitLight, HitHeavy, Stumble and Down.

These are first-pass authored skeletal studies. Personality poses share the same character and do not alter stats. The showroom reuses the D4-19 position keys; it does not simulate damage or hit success. Authored clip playback and legacy procedural joint driving are explicitly exclusive in the adapter.

## Integration boundary

`HumanModular3D.build()` can use the candidate when the in-memory/project setting `art/use_p04_candidate` is true. It defaults false because project rules require S-quality dog/human final art. `Greybox.bind_parts()` preserves the imported skeletal subtree. This enables concrete integration review without silently installing a B-grade model as final art.

Normal combat still uses existing procedural choreography under this opt-in; the 17 authored clips are played in the ART scene. Replacing combat animation arbitration requires a separate carefully tested integration with the gameplay owner. The Banyan is imported and instantiated in the review scene; the live territory builder is unchanged while Sprint 05 engineering remains gated.

## Source and milestones

Blender source lives outside the game repository:

- `../good-human-3d-pipeline/blender/human/p04_owner/owner_01_base.blend` — preserved CC0 MPFB base.
- `../good-human-3d-pipeline/blender/human/p04_owner/owner_10_surface_fix.blend` — current clothed, rigged, animated export source.
- `../good-human-3d-pipeline/blender/environment/banyan_01/banyan_05_godot_material.blend` — current tree source.

Earlier numbered files retain construction, detail, rig/animation and export stages. Scripts in `tools/art/` document construction. Final material and overlap corrections were performed through Blender MCP and saved in these final milestones; rerunning early scripts alone does not include every final correction. No .blend is committed into the game tree.

MPFB core graphical assets are CC0; original clothing details/animation and original tree authoring are recorded in [ASSET_LICENSES.md](ASSET_LICENSES.md). No Hunyuan generation or external clothing pack was used for this human.

## Verification performed

- Blender bridge connected; inspected base, clothed body, idle, kick, hook and Down poses, and tree from full/close views.
- Corrected rotation-mode leakage between clips, rig double-scaling, clothing overlap and an accidental other-scene inclusion during tree export.
- Parsed exported GLBs for meshes, skins and all 17 animations.
- Headless Godot asset checks pass; actual OpenGL rendered review scene opens, captures frames and exits without errors.
- Actual screenshots: [human](../../assets/art_previews/p04/capture_0.png), [dog-eye exchange](../../assets/art_previews/p04/capture_1.png), [dog study](../../assets/art_previews/p04/capture_2.png), [banyan](../../assets/art_previews/p04/capture_3.png), [personality comparison](../../assets/art_previews/p04/capture_4.png).
- Full editor import also reports the pre-existing `VirtualJoystick` global-class collision with installed Godot 4.7.1. New scene and targeted validation run independently; no full-game pass is claimed.

## Remaining production work

Human face/hair/garment materials and silhouette still need a substantial realism pass to meet the photographic reference. Shoe/cuff deformation, contact reach, finger shapes, grounded Down and all clip transitions need further pose review; finite-transform checks alone do not prove animation quality. The old modular wardrobe variants are not all represented by this one outfit.

Tree needs better bark variation, denser natural leaf distribution, root refinement and measured LOD/performance work. Dog collision uses coarse capsules and the leash has no obstacle wrap. D4-22 normal gameplay-camera acceptance remains pending; the showroom's framing is an art review setup, not a runtime camera rewrite. These limitations prevent S/final approval.
