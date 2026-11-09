# Six human refinement candidates — 2026-10-15

Owner requested refinement of the six characters in Claude’s 2026-10-15 handoff because their appearance remained unclear. ART work, not blind QA. **B / review candidates; runtime models are unchanged.**

## Review

[Full before/after comparison](../../assets/art_previews/humans/refine_2026_10_15/comparison.jpg). Each pair is labelled 精修前 / 精修後, captured in Godot with identical square camera, lighting and pose. Top view is front; lower view is three-quarter.

| Character | Retained refinement |
|---|---|
| Office worker | Continuous shirt/trouser colours, striped blue tie, pocket and cleaner cuffs/shoes; original rear bag retained. |
| Market auntie | Purple blouse, authored floral apron and pocket, cleaned forearms; new striped shoulder towel, 640 triangles. Fused side-bag patch rolled back. |
| Retired fisher | Olive vest, pocket seams/buttons, shirt opening, hat band and cleaner leg/shoe borders. |
| Delivery rider | Orange jacket, light hoodie opening, dark straps, buckles and sleeve bands; cleaner shoes. |
| Gym coach | Cleaner tank top and curved neckline, retained chest print, bounded neck/shoulder shelf reduction (under 20 mm). Lower-body masks rolled back after visual regression; shoes cleaned. |
| Xiaomi | Yellow top, denim bib pocket/stitching, straps and cleaner socks/shoes. Back/bag patch rolled back after visual regression. |

## Evidence and limits

- Candidate GLBs and per-file provenance: assets/art_previews/humans/refine_2026_10_15/. No original source overwritten.
- Saved originals: build/human_refine_2026_10_15/before/character/.
- Texture checkpoints: build/human_refine_2026_10_15/character/refined.blend. Final towel/coach geometry is applied to the GLB by the separate geometry script; texture checkpoints alone do not contain that patch.
- All original GLB binary payloads remain intact as prefixes; new textures/geometry are appended. Original nodes, skin and animation JSON are exactly equal. Office worker has **54** original skin joints (handoff said 53); the other five have 53. No joint renamed or removed. All six retain 19 clips.
- Protected drawn face/eye samples have zero floating-point pixel change before PNG encoding. Hand/leg skin outside the drawn face was cleaned where reviewed; this does not claim all skin texels were unchanged.
- Final Godot: **2,052 sampled poses**, finite bone transforms, exact before/after bone names and clip lists, no failures. This is a bone-transform check, not proof of collision-free skinned surfaces.
- 60 static before/after captures plus 42 candidate idle/walk-family screenshots. [Five-view overview](../../assets/art_previews/humans/refine_2026_10_15/all_views.jpg); [idle/walk overview](../../assets/art_previews/humans/refine_2026_10_15/motion_review.jpg).
- Machine-readable evidence: binary_validation.json, godot_validation.json, per-character verification.json and geometry.json under the build folder.

## Remaining art work

This is a readability/refinement candidate, **not S-level final character art**. Existing hair shreds, face/hair boundary speckles, irregular shoulders, fused side props and mitten hands remain visible. Texture-region approval did not guarantee correct semantic boundaries: some skin-labelled texels were clothing, and some body/prop geometry is fused. Failed broad mask edits were rolled back to original patches after two correction passes; do not repeat blind region expansion.

CX-10 is partial: auntie towel and coach neck received local work. Anatomical hand reconstruction and missing basket, rod case/net, shaker and satchel volumes remain open. CX-11 optional idle changes and CX-12 shiba decision were not part of this pass.

## Rebuild

1. Blender 5.2: tools/art/inspect_humans_1015.py for the read-only baseline report.
2. Blender 5.2: tools/art/refine_humans_1015.py rebuilds six texture candidates from immutable v5 checkpoints and saved runtime GLBs.
3. Blender 5.2: tools/art/refine_human_geometry_1015.py appends towel and coach patch **once after step 2**; do not run repeatedly on its own output.
4. Godot import, then --resolution 640x640 --script res://tools/art/capture_humans_1015.gd.
5. Python: tools/art/contact_humans_1015.py.

No new external assets, downloads or model-generation services. Reference-sheet rights remain inherited and undocumented; see ASSET_LICENSES.

## Final visual review

Reviewed the final five-view overview, six labelled comparisons, and Idle/Walk overview. Front clothing readability improves, but coach rear torso still has a large inherited dark/skin patch, auntie rear apron edges remain irregular, and Xiaomi retains noisy back-pack projection and loose hair fragments. Coach Idle/Walk also exposes high shoulder/arm posing in the inherited animation/rig. These candidates are deliberately not promoted to runtime or S grade on the strength of finite-transform checks.
