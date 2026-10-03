# Art Status

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

