# Park grandma (old master slot): provenance and licence risk

Asset: `assets/characters/human/models/ai_grandma/grandma.glb`. It replaces the old master's look and name (老爺爺 → 老奶奶); his stats, skills and dog are unchanged. Added 2026-09-30.

## Owner decision
The owner chose to ship this version in the repository and the game **accepting the licence risk** below ("承擔風險，現在就推送", 2026-09-30). Claude had recommended regenerating the views with a commercial-licensed image model first.

## How it was made
1. **Character sheet**: supplied by the owner. Its origin and rights are not documented.
2. **Four views (A-pose)**: Qwen-Image-2.1 UC GGUF, a community build, run in ComfyUI. The Qwen Research License is **non-commercial**. ← the risk
3. **3D shape**: TripoSG via Modly (MIT; Marching Cubes / scikit-image, BSD-3).
4. **Retopology**: Instant Meshes (BSD-3).
5. **Blender** (own scripts): bake; Style Bible v1/v2 stylization (head ×1.2, hands, feet, bun, rounded jaw); a painted texture in flat colours; oversized glasses geometry; rigged on the P-04 OwnerSkeleton with all P-04 clips plus Idle_Relaxed / Walk_Relaxed.

Pipeline workspaces, all outside the repo:
- `C:\Users\b\Documents\good_human_ai3d_pipeline` (v4)
- `C:\Users\b\Documents\good_human_stylized_factory` (v5): scripts, reports, `licenses/SOURCE.md`, per-file `.provenance.json`

## Why the stylization does not clear the risk
Visual distance from the reference is not what the licence turns on. The shape and colours still derive from outputs of a non-commercial model: retopology, restyling and repainting do not remove the licence of the source (pipeline v4 §6).

## Clean replacement (ready to run)
1. Regenerate the four views with Qwen-Image-Edit-2509 (Apache-2.0): `comfy_qwen.py --model edit2509`.
2. Rerun the v5 scripts unchanged: TripoSG → retopo → bake → stylize → texture → rig.
3. Swap `grandma.glb`.
4. Confirm the character sheet's rights.

## 2026-10-01: Codex surface v4
The shipped `grandma.glb` is now Codex's surface v4:
- a cleaner re-unwrap, and a flat-material rebake (2048 base colour, no normal map);
- the same mesh, skeleton, glasses and 19 clips, with the relaxed idle and arm splay unchanged.

The source chain is the same as above, so the licence note still applies.
