# AI Grandma Preview Texture Fix 01

Date: 2026-09-30

The local `windows_grandma_preview` asset had a visibly corrupted projected albedo: front/back projection patches appeared as a mosaic across the cardigan, shoes, face and hands. The handoff identifies this as a known research-pipeline problem.

## Fix

- Preserved the original research GLB as `grandma_mosaic_backup.glb`.
- Rebuilt the preview GLB with clean Blender Principled materials instead of the broken projected image.
- Added readable material regions for silver hair, skin, plum cardigan, charcoal trousers, shoes and canvas tote.
- Preserved the original `OwnerSkeleton`, rig and animation clips.
- Saved a Blender milestone at `../good-human-3d-pipeline/blender/human/grandma/grandma_texturefix_01.blend`.

## Preview build

The first flat-material export was rejected after review because it made the character read worse in the actual preview. The preview build has been rolled back to the original `grandma.glb` at 2026-09-30 11:16. The local grandma preview switch was restored to `off` so tracked gameplay data remains the normal Old Master data.

## Limits

The flat-material pass is retained only as an experimental Blender milestone and is not the active preview asset. The handoff states that the source chain uses non-commercial research references and must not ship.

Blender preview: `assets/characters/human/models/ai_grandma_research/grandma_texturefix_preview.png`.
