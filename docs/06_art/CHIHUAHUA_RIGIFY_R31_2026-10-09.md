# Chihuahua Rigify gesture study r31 — 2026-10-09

REVIEW / B animation experiment. Runtime model not replaced; not S-grade final art.

## Result

- HeadLook: 3-second subtle left/right head turn.
- Sniff: 2-second seated air-sniff/nod; not a ground-sniff or locomotion animation.
- Project-authored gestures using the installed Rigify basic quadruped template. No downloaded motion asset was used. The installed add-ons do not supply a ready-made dog motion library.
- Generated 284-bone Rigify control rig, partially fitted for neck/head/tail experimentation. Template limbs were not fully fitted or rebound: this is not a complete new quadruped rig.
- Sampled and baked local rotation deltas onto 23 existing skin joints. Plugin control bones are not exported.
- Original r30 binary buffer, mesh, skin, materials, textures and three existing animation descriptors preserved. Appended only two clips.

## Limitations

TailWag was rejected and excluded from the final GLB: tail_01 and tail_02 have no weights above 0.01; tail_03 influences only 68 vertices near the back. The diagnostic TailWag action remains in the workshop blend and raw bake data.

Existing front-leg bone placement and below-ground paw endpoints appear poorly fitted and need a separate weight/rig repair. Existing Sit stretching is not fixed. Small head gestures are visually usable as a study; muzzle material seams and inherited mesh defects remain.

## Files

- Candidate: `assets/art_previews/dogs/candidates/r31/chihuahua.glb`
- SHA256: `dfd5d1887e641f1c4980eace59d3b9a6d44ea8c282fa56ac50cd0e6013abaf86`
- Editable rig: `C:/Users/b/Documents/good-human-3d-pipeline/blender/dog/chihuahua_r31/chihuahua_r31_rigify_gestures.blend`
- [HeadLook GIF](chihuahua_r31_2026-10-09/HeadLook.gif), [Sniff GIF](chihuahua_r31_2026-10-09/Sniff.gif)
- [HeadLook sampled frames](chihuahua_r31_2026-10-09/HeadLook_frames.png), [Sniff sampled frames](chihuahua_r31_2026-10-09/Sniff_frames.png)
- Build/package/capture/contact scripts: `tools/art/*chihuahua_r31*`.

## Validation

Final candidate Godot import succeeds; candidate model/animation checks pass (14). Published breed model suite passed (81) during this study. Buffer and original descriptor preservation checked by the packaging script; see `build/chihuahua_motion_r31/verification.json`.

Final capture script samples 20 baseline/candidate static views and 34 animation poses (17 per retained gesture), under `build/chihuahua_motion_r31/godot_final`. Earlier three-gesture diagnostic capture remains under `godot`. Both retained gesture contact sheets were visually reviewed; no large Sit-like stretching observed at the sampled poses.

## Provenance

Author: GOOD HUMAN! project ART work via Codex, 2026-10-09. New gesture curves are original project work; no third-party animation download or retrieval. Rigify is the installed authoring tool; its code is not distributed in the GLB. Existing Chihuahua source/license restrictions remain unchanged; see ASSET_LICENSES.md.