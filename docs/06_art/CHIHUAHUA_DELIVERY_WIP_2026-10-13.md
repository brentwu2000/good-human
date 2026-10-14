# Chihuahua delivery refinement — WIP, 2026-10-13

Owner asked to continue until deliverable. This is a checkpoint, not approval.
Runtime remains published r37. No structural candidate GLB is published.

Whole-body inspection finds merged seated hindquarters, shoulder facets, weak
paws and mouth structure. Local face paint cannot resolve these.
[Baseline](chihuahua_delivery_2026-10-13/paint_threequarter.png),
[clay profile](chihuahua_delivery_2026-10-13/clay_side.png),
[structural candidate](chihuahua_delivery_2026-10-13/body_budget.png).

Experiment adapts the existing Mesh2Motion fox's CC0 body topology into a
standing Chihuahua, retaining the r37 head identity. Shortens/scales body,
reshapes tail, joins neck loops and maps required bone names. 49-bone candidate;
body 7,404 triangles plus head 9,359 = 16,763 before further detail work.
This meets a provisional mobile budget, not the appearance/animation gate.

Source: Scott Petrovic / Mesh2Motion, existing fox-animations.glb, commit 653a969,
retrieved 2026-10-09; art CC0 1.0, commercial use/modification allowed. Exact
hash/license in assets/_source/mesh2motion/PROVENANCE.md. Untouched source retained.
No new third-party download or addon. Grade B structural experiment.

Saved checkpoints in build/dog_delivery (ignored): r37_inspection.blend,
chihuahua_body_structure_01/02/03/04.blend, chihuahua_body_rig_01.blend.
Scripts are incremental Blender 5.2 authoring tools, not a one-command build:
1. Load the packed r37 source; render_chihuahua_delivery.py creates neutral views.
   Save the inspection scene as r37_inspection.blend after the render.
2. Load that scene in a separate bridge call, run build_chihuahua_delivery_body.py.
3. Run refine_chihuahua_delivery_body.py (captures the reviewed manual weld,
   neck-loop and budget operations), then rig_chihuahua_delivery.py.

Remaining gates: refine neck/head seam and paws, coherent body fur/materials,
actual mouth/jaw structure, normalize/inspect skin, adapt all required Mesh2Motion
clips, inspect actual-skin motion/contact, export candidate, compare in Godot,
run relevant tests, archive editable source and only then consider publication.
Current structural rig has not been motion-validated and is not deliverable.

## Detail checkpoint

Added baked 2048px body albedo/normal maps, restrained directional fur,
cream paws with individual toes, red collar and a brass identity tag.
Retargeted 10 Mesh2Motion actions at 60 Hz. Reviewed Run, Sit and Howl stills;
this is not full animation/contact validation. Fixed a tail-shaping selection
that incorrectly included lower hind-leg vertices (now requires z > 0.80 in
source coordinates), and tapered 840 lower rear-skull vertices into the neck.
The coordinate repair preserved the detailed mesh's UVs, weights and actions
through a bijective face-corner index mapping. Rebuilding from the corrected
body script avoids needing that one-time repair.

[Side](chihuahua_delivery_2026-10-13/neck_refined_side.png),
[three-quarter](chihuahua_delivery_2026-10-13/neck_refined_threequarter.png),
[run](chihuahua_delivery_2026-10-13/refined_pose_Run.png),
[sit](chihuahua_delivery_2026-10-13/sit_toe_refined.png),
[howl](chihuahua_delivery_2026-10-13/refined_pose_Howl.png).

Latest editable checkpoint: build/dog_delivery/chihuahua_details_checkpoint.blend.
Incremental tools: material -> detail -> animate -> fur -> bake -> accessories ->
refine neck. animate currently requires MotionSource imported separately at 60 Hz
and the exact action names documented in its source. These scripts are authoring
checkpoints, not an unattended build.

Remaining visible issues: rear foot/hock folding in seated poses, rigid mouth
expression, some angular rear-skull contour and head/body material mismatch.
Need full evaluated-skin contact checks, export/Godot validation and source archive.
Runtime remains r37; candidate remains B and has not passed the delivery gate.


Superseded by [r38 runtime delivery](CHIHUAHUA_DELIVERY_R38_2026-10-14.md) on 2026-10-14.
