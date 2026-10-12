# Art Status

## Owner head refinement r1 (Claude) — 2026-10-12

Owner asked Claude to refine the human characters this round. Owner model:
curly hair built from the skull (bald crown/forehead fixed), round glasses,
brows; jacket collar points, zip and seams laid onto the body. Body, rig and
clips unchanged; 47 test scenes pass. REVIEW / B.
[Record](OWNER_HEAD_R1_2026-10-12.md).
## Dog visual polish r35 taken — 2026-10-12

IN_PROGRESS, owner priority: dogs before other handoff work. Start with Chihuahua
cheek/eye-socket/muzzle surface transitions, preserving identity and the current
r34 skin, rig and motion contracts. Inspect clay and textured views before deciding
whether a candidate is suitable for publication.

## CX-01 umbrella readability completed — 2026-10-12

Published warm-ochre canopy and compact honey-colored J-hook. Grip origin,
+Y axis and 0.60 m tip retained; rear end shortened from -0.10 to -0.08 m.
405×720 showcase and real-fight captures reviewed. Seven required suites pass
(346 assertions). Wide-hook trial rejected for self-contact; final hook passes.
REVIEW / B: compact hook can be occluded by the hand; fabric finish remains simple.
[Record and comparisons](UMBRELLA_CX01_2026-10-12.md).

## CX-04 r34 continuation completed — 2026-10-12

Published eight dog motion libraries with 120 Hz baking/import and measured
between-key Run ground correction. Chihuahua/Poodle Run limb limits reduce
stretching; Chihuahua receives the existing r30 cheek texture on r33 skin.
Fresh 720-image review, dense Run skin audit and seven regression suites
(346 assertions) completed; published-path Chihuahua capture checked.
REVIEW / B: inherited geometry/material defects, sliding and missing jaws remain.
[Completion record and evidence](DOG_MOTION_R34_2026-10-12.md).

## CX-04 dog deformation repair r33 — 2026-10-10

Published seven breed skin repairs and eight rebuilt Mesh2Motion libraries.
Smoothed eight-influence weights, corrected front-leg pivots in baked translations,
world-space joint limits and actual-skin ground correction. Rest art and original
clips preserved. Seven regression suites PASS (346 checks); 720 Godot captures,
all nine corrected contact sheets reviewed; byte-identical Chihuahua re-bake.
Grade B: local stretch, contact polish, original material/mesh defects remain.
[Record and before/after images](DOG_MOTION_R33_2026-10-10.md).

CX-06 record: Claude had published frenchie r18, corgi r21, opponent shiba r23,
golden r25, poodle r28, chihuahua r29; pomeranian r10 and player shiba_01 unchanged.
Those seven breed revisions are now the fixed sources for r33 weights.
Claude's generated owner fight clips and 21-clip human Mesh2Motion library remain
as documented in [the handoff](CLAUDE_HANDOFF_TO_CODEX_2026-10-09.md); this task did
not alter them. Mesh2Motion provenance added to ASSET_LICENSES.md.

## Chihuahua Rigify gestures r31 — 2026-10-09

Installed Rigify used for two project-authored upper-body gestures: HeadLook
(3 s) and Sniff (2 s), baked onto existing deform joints. TailWag rejected due
to ineffective tail weights. Original clips and r30 art preserved. Candidate
checks pass (14); published breed checks pass (81). REVIEW / B; existing Sit,
leg fitting, weights and material issues remain. No runtime replacement.
[Record and animated previews](CHIHUAHUA_RIGIFY_R31_2026-10-09.md).

## Chihuahua Ucupaint cheek repair r30 — 2026-10-09

Restarted Blender with installed plugins enabled. Ucupaint base/repair/mask
layers reduce duplicate side-mouth projections; packed editable blend saved in
the separate workshop. Geometry/UVs/rig/animation retained. Godot 29 captures
reviewed; breed model test 81 checks and candidate test 10 checks pass.
REVIEW / B: patch outlines, tooth specks and inherited Sit defects remain.
No runtime replacement by this task. [Record](CHIHUAHUA_UCUPAINT_R30_2026-10-09.md).

## Chihuahua nose and bridge r29 — 2026-10-08

Local material projection removes the dark nasal-bridge stripe and registers
the nose tip. Original geometry/UVs/skin/animation data retained. Godot 29 captures
reviewed. REVIEW / B; duplicated side mouths, muzzle seams and severe inherited
Sit stretching remain. Runtime unchanged. [Record](CHIHUAHUA_NOSE_R29_2026-10-08.md).

## Poodle ear material r28 — 2026-10-08

Shared local fur projection reduces the flat r27 infill strips while preserving
geometry, normals, skin and animation data. Godot 29 captures reviewed. REVIEW / B:
raised infill boundaries, material transitions and inherited defects remain.
Runtime unchanged. [Record](POODLE_EAR_MATERIAL_R28_2026-10-08.md).

## Poodle ear infill r27 — 2026-10-08

Two skinned infills cover the ear openings while retaining original r26 geometry,
skin and animation data. Godot 20 static views and nine animation samples reviewed.
REVIEW / B: smooth strips and material transitions remain; 50,736 triangles is
above budget. Runtime unchanged. [Record](POODLE_EARS_R27_2026-10-08.md).

## Poodle nose r26 ? 2026-10-07

Local nose projection alignment; original geometry/rig/animations retained.
REVIEW / B. Ear openings, muzzle seams and inherited Sit pose remain.
Runtime unchanged. [Record](POODLE_NOSE_R26_2026-10-07.md).

## Golden nasal bridge r25 — 2026-10-07

Local material cleanup reduces the dark nasal-bridge projection while retaining
r24 chin cleanup and original geometry/rig/animation. REVIEW / B; flat donor
color and muzzle seams remain. Runtime unchanged.
[Record](GOLDEN_BRIDGE_R25_2026-10-07.md).

## Golden Retriever chin material r24 — 2026-10-06

Local rear-chin texture cleanup removes the duplicate lower mouth/tongue
projection. Original r6 geometry, UV, skin and animation retained. REVIEW / B;
muzzle material seams, mouth fragments and coarse fur remain. Runtime unchanged.
[Record](GOLDEN_CHIN_R24_2026-10-06.md).

## Opponent Shiba chin material r23 — 2026-10-06

Local texture cleanup reduces duplicate tongue projection on the rear chin;
original r6 geometry, UV, skin and animation retained. REVIEW / B. Mouth-corner
seams and inherited defects remain. Neither runtime Shiba model was changed.
[Record](SHIBA_CHIN_R23_2026-10-06.md).

## Corgi tongue-root web r22 — 2026-10-06

REJECTED: local 5.57 mm retraction creates a visible chin dent in Godot.
UVs, textures, topology, skin and animation retained, but visual review fails.
R21 remains the latest review candidate. Runtime unchanged.
[Record](CORGI_WEB_R22_2026-10-06.md).

## Corgi mouth-corner material r21 — 2026-10-06

Small bounded inner-mouth color adjustment over r20. Original geometry, UV,
skin and animation retained. REVIEW / B: pale surface behind the tongue and
mouth-corner geometry remain unresolved; runtime unchanged.
[Record and comparison](CORGI_MOUTH_R21_2026-10-06.md).

## Corgi local texture repair r20 — 2026-10-06

Returned to original r6 geometry after owner rejected r19. Local material edits
reduce duplicate nasal projection and remove the painted second tongue/mouth
on the rear chin. All original geometry/UV/skin/animation data retained.
REVIEW / B: mouth-corner transition and flat chin coloration remain. Runtime
unchanged. [Record and comparison](CORGI_LOCAL_R20_2026-10-06.md).

## Corgi whole-face experiment r19 — 2026-10-06

REJECTED by owner: r19's simplified face worsens the original appearance.
A continuous face replaces fragmented nose/mouth projections,
using the owner's Corgi front sheet. Forehead seam, side stretching and chin
transition remain conspicuous; not appearance-approved or runtime-published.
Original skeleton and animation values retained; rebuilt facial weights blend
to the retained rim. [Record](CORGI_FACE_R19_2026-10-06.md).

## Frenchie ear-root geometry r18 — 2026-10-06

Localized depth smoothing reduces ear-root unevenness; maximum displacement
7.90 mm. All frontal coordinates, lower-face positions, UVs, textures, skin
and animation data retained. REVIEW / B; residual folds, ear texture and Sit
issues remain. Runtime unchanged.
[Record and before/after](FRENCHIE_EAR_ROOT_R18_2026-10-06.md).

## Frenchie temple material r17 — 2026-10-06

Continuous local temple projection over r15 reduces pink temple ghosting;
ear-root bands and coarse ear surfaces remain. REVIEW / B candidate only.
Blender and 29 Godot captures reviewed; corner geometry/normals/skin and
original skeleton/animation data retained. Runtime unchanged.
[Record and before/after](FRENCHIE_TEMPLE_R17_2026-10-06.md).

## Frenchie material experiment r16 — 2026-10-05

REJECTED after Blender/Godot comparison: narrower side-reference sampling and
broader rear projection create a flatter brown patch without resolving temple
streaks. Geometry, skin and animation retention checks pass, but appearance does
not. R15 remains the latest review candidate; runtime unchanged.
[Experiment and comparisons](FRENCHIE_MATERIAL_R16_2026-10-05.md).

## Frenchie seam geometry r15 — 2026-10-05

Clay inspection identified a real serrated transition across the face/body rim.
R15 relaxes that boundary and brow depth, recomputes shared normals and rebakes
UVs. Central frontal coordinates and core eyes/nose/mouth positions preserved;
skin and animation data verified. REVIEW / B; residual temple/ear issues and
inherited Sit limitations remain. Runtime unchanged.
[Geometry repair and comparisons](FRENCHIE_SEAM_R15_2026-10-05.md).

## Frenchie side material r14 — 2026-10-05

Shared side-reference projection and Blender UV baking reduce the pasted-on
light cheek region across the face/body boundary. Geometry, normals, skin and
animation values remain unchanged; retained-body UVs repacked. REVIEW / B:
left-side hard boundary and temple streaks remain, so the owner's pasted-skin
concern is improved but not fully resolved. Runtime unchanged.
[Material repair record](FRENCHIE_SIDE_MATERIAL_R14_2026-10-05.md).

## Frenchie profile revision r13 — 2026-10-05

Owner accepted r12 frontal appearance and requested profile work. R13 preserves
frontal vertex coordinates, retracts the tongue and fills excessive cheek depth.
Blender review, Godot 29 captures and skeleton/animation validation completed.
REVIEW / B candidate; ear-root texture stretching and inherited limitations remain.
[Profile comparison and record](FRENCHIE_PROFILE_R13_2026-10-05.md).

## Frenchie face and chin revision r12 — 2026-10-05

Extended the r11 face repair through residual mouth corners and chin islands.
Blender five-view review and Godot 29 captures completed; original skeleton and
animation values verified unchanged. REVIEW / B, staged separately; runtime
Frenchie remains r6. Ear-root texture stretching, tongue profile, inherited Sit
deformation and 46k triangle count remain outstanding.
[Repair record and comparisons](FRENCHIE_FACE_R12_2026-10-05.md).

States: `RESEARCH`, `CANDIDATE`, `IN_PROGRESS`, `REVIEW`, `APPROVED`, `REJECTED`

| ID | Asset | Priority | Status |
|---|---|---:|---|
| ART-001 | Visual Target 01 | P0 | REVIEW |
| ART-002 | Dog Base 01 | P0 | REVIEW |
| ART-003 | Human Modular Base | P0 | IN_PROGRESS |
| ART-004 | Dog Idle/Walk/Run/Sniff | P0 | IN_PROGRESS |
| ART-005 | Environment starter kit | P1 | IN_PROGRESS |
| ART-006 | Search props | P1 | RESEARCH |
| ART-007 | Bus stop extraction | P1 | RESEARCH |
| ART-008 | Sprint 01 loot icons | P1 | RESEARCH |
| ART-009 | HUD visual prototype | P1 | RESEARCH |

Codex Art owns this status file. Art work must not silently change game design.

## Pomeranian whole-face revision r10 — 2026-10-04

Owner approved r10 on 2026-10-04; it now replaces the runtime pomeranian used by
enc_old_master (小白). Godot resolved the encounter to the published model and
captured both materials and Idle/Walk/Sit. Geometry/texture quality remains B:
cheek/mane and chin/neck transitions still need work.
[Whole-face candidate and runtime comparisons](POMERANIAN_FACE_R10_2026-10-04.md).

Frenchie r11 uses the same continuous-face method with breed-specific short muzzle
proportions. REVIEW / B; staged separately for visual review, runtime Frenchie remains
r6. [Repair record](FRENCHIE_FACE_R11_2026-10-04.md).
[Repeatable workflow](DOG_WHOLE_FACE_REPAIR_WORKFLOW.md).

## Pomeranian face geometry r9 — 2026-10-04

Owner authorized face geometry edits. Reduced the projecting nasal bridge and
shortened the nose while retaining r6-style eyes, topology, UVs, weights and all
three clips. Game pomeranian updated after Blender/Godot review; other dogs are
unchanged. REVIEW / B: ear surfaces, mouth/tongue seams, Sit and the inherited
47k-triangle mesh remain unresolved. [r9 report](POMERANIAN_FACE_R9_2026-10-04.md).

## Pomeranian muzzle candidate r8 — 2026-10-04

Local texture cleanup and nose-detail pass staged separately in
`assets/art_previews/dogs/candidates/r8/`; runtime remains r6. Blender and Godot
comparisons show reduced projection artifacts, but the elongated nose and raised
bridge need geometry repair. Candidate has not passed appearance review.
See [r8 findings and comparison](POMERANIAN_MUZZLE_R8_2026-10-04.md).

## Blender implementation 2026-09-29

[P04 / D5-01 implementation record](P04_BLENDER_IMPLEMENTATION_01.md): actual modular human GLB with 17 clips, Banyan GLB, opt-in human compatibility layer and a running ART showroom. Assets are grade B candidates; no S/final-art approval. Human and environment remain IN_PROGRESS because reference-quality finish and full runtime integration are outstanding. Existing dog model is reused for interaction staging.

## Current reference for combat (pointer added by Claude, no status changed)
P-03 Street Brawl is the live combat direction (Update 006 Patch 02, 2026-09-18).
The owner's storyboard is the concept reference for every combat deliverable:

`docs/06_art/dog_agency/P03_STREET_BRAWL_STORYBOARD.png`

It establishes "Explore as the dog. Fight through the dog's eyes." — twelve beats
from Explore through the Combat Snap into dog-eye first person, impact, crisis,
the owner petting the dog, and the pull back to third person. The P03-D01..D10
deliverables in `DESIGN_STATUS.md` all hang off it, and the brief that explains
how to use it is `docs/06_art/dog_agency/P03_DESIGN_BRIEF.md`.

This section exists only because the storyboard arrived in an owner update
package rather than from Art, so nothing in the Art Read Order pointed at it.

## Breed-dog eye revision r5 — 2026-10-02

Seven preview dog eye textures updated and checked in Godot at front and both
45-degree views with standard and SoftToon materials (42 captures). Factory
_codex GLBs/PNGs and preview files are synchronized; originals retained. All 32
test scenes pass. Eye ghosts corrected; mouth seams, ear/geometry defects and
existing Sit deformation remain. Overall status: REVIEW, not final approval.
The r3/r4 eye-validation claims are superseded by
[the r5 report](BREED_DOGS_EYE_REPAIR_CODEX_2026-10-02.md).

## Breed-dog complete-eye revision r6 — 2026-10-03

Owner rejected r5; its eye-validation claim is superseded by the
[r6 report](BREED_DOGS_EYES_R6_2026-10-03.md). Front-sheet eye crops included
occluding muzzle pixels. R6 replaces them with an unobstructed eye source and
per-mesh surface projection. Geometry/rig/animation data remain unchanged.
Preview status remains REVIEW; mouth/nose seams, head geometry defects and
limited close-up atlas resolution still prevent final-art approval.

## Breed dogs in the game — 2026-10-03

Owner decision: the r6 breed models are the opponent pairs' dogs (shiba, frenchie,
pomeranian, corgi, golden); the player keeps `shiba_01`. Models moved to
`assets/characters/dog/models/breeds/`; mapping and licence note in
`assets/art_previews/dogs/PROVENANCE.md`. Still REVIEW / grade B art: the r6 report's
mouth seams, ear gaps and face defects now show in the game. The rival's neckerchief
is the greybox accessory placed on the golden's neck bone and wants an art pass.





## CX-04 taken — 2026-10-09

Resolved with r33 bounded deformation repair; see the 2026-10-10 record above. The standalone r32 smoothing trial remains rejected.
