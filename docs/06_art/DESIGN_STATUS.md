# DESIGN STATUS

## Active Now
| ID | Deliverable | Owner | Status | Dependency |
|---|---|---|---|---|
| D-01 | Dog Agency Interaction Map | Design/Codex ART | REVIEW | none |
| D-02 | Bark Visual Language | Design/Codex ART | REVIEW | none |
| D-03 | Leash Visual Language | Design/Codex ART | REVIEW | none |
| D-04 | Combat Readability A + B/C | Design/Codex ART | REVIEW | none |
| D-05 | Opponent Dog Reactions | Design/Codex ART | REVIEW | none |
| D-06 | Owner Reaction Sheet | Design/Codex ART | REVIEW | none |
| D-07 | Mobile HUD Exploration | Design/Codex ART | REVIEW | Camera Gate accepted: dog-height chase |
| D-08 | Target Screenshot 03 | Design/Codex ART | REVIEW | may explore B/C first |
| D-09 | Smell/Search Compatibility | Design/Codex ART | REVIEW | none |
| D-10 | Design Decision Pack | Design | BLOCKED | Camera Gate |

## Sprint 05 — GREED / TERRITORY
Installed from Update 007 (2026-09-18). Design starts now; it does not wait for Sprint 05 engineering.

| ID | Deliverable | Owner | Status | Dependency |
|---|---|---|---|---|
| D5-01 | Landmark | Design/Codex ART | REVIEW | none |
| D5-02 | Scent ownership | Design/Codex ART | REVIEW | none |
| D5-03 | Mark interaction | Design/Codex ART | REVIEW | none |
| D5-04 | Greed storyboard | Design/Codex ART | REVIEW | none |
| D5-05 | Risk HUD | Design/Codex ART | REVIEW | none |
| D5-06 | Rival pair | Design/Codex ART | REVIEW | none |
| D5-07 | Territory variants | Design/Codex ART | REVIEW | none |
| D5-08 | Reward reveal | Design/Codex ART | REVIEW | none |
| D5-09 | Target Screenshot 04 | Design/Codex ART | REVIEW | none |
| D5-10 | Decision Pack | Design/Codex ART | REVIEW | Gate sign-off pending |

## Combat Experience (Update 006 Patch 01)
Installed 2026-09-18. Start immediately; D4-17 uses the P-02 captures.

| ID | Deliverable | Owner | Status | Dependency |
|---|---|---|---|---|
| D4-11 | Combat Focus Composition | Design/Codex ART | REVIEW | none |
| D4-12 | Combat Snap Storyboard | Design/Codex ART | REVIEW | D4/P02 tension and active contexts |
| D4-13 | Owner Condition Readability | Design/Codex ART | REVIEW | aligns with 34% crisis camera threshold |
| D4-14 | Dog Instinct Feedback | Design/Codex ART | TODO | none |
| D4-15 | Owner↔Dog Feedback | Design/Codex ART | TODO | none |
| D4-16 | Victory/Defeat Release | Design/Codex ART | TODO | none |
| D4-17 | Combat Camera Prototype Review | Design/Codex ART | TODO | P-02 captures |

## P-03 Street Brawl (Update 006 Patch 02)
Installed 2026-09-18. D01–D09 can run in parallel; D10 uses implementation captures.

| ID | Deliverable | Owner | Status | Dependency |
|---|---|---|---|---|
| P03-D01 | Combat mood target | Design/Codex ART | REVIEW | owner storyboard style target |
| P03-D02 | Tension/confrontation storyboard | Design/Codex ART | REVIEW | P03-D01 style lock |
| P03-D03 | Dog POV composition sheet | Design/Codex ART | REVIEW | P03-D01 style lock |
| P03-D04 | Human motion silhouettes | Design/Codex ART | REVIEW | P03-D01 style lock |
| P03-D05 | Hit/impact language | Design/Codex ART | REVIEW | integrated contact-local grading |
| P03-D06 | Owner HEALTHY/HURT/CRITICAL/DOWN | Design/Codex ART | TODO | none |
| P03-D07 | Dog instinct feedback | Design/Codex ART | TODO | none |
| P03-D08 | NPC/world reaction sheet | Design/Codex ART | TODO | none |
| P03-D09 | Victory/defeat emotional beat | Design/Codex ART | TODO | none |
| P03-D10 | Review implementation captures | Design/Codex ART | TODO | implementation captures |

## Rule
Design does not wait idle for engineering. Explore both camera families where needed, then collapse to one direction after P-01.

## P-04 Human Brawl Feel (Update 006 Patch 03)
Installed 2026-09-28. Brief: `docs/06_art/P04_COMBAT_MOTION_DESIGN_WORKSTREAM.md`. Runs in parallel with engineering; append, never overwrite earlier D4 work.

| ID | Deliverable | Owner | Status |
|---|---|---|---|
| D4-18 | [Human Combat Motion Language](P04_MOTION_LANGUAGE_01.md) | Design/Codex ART | REVIEW |
| D4-19 | [Footwork Board](P04_FOOTWORK_BOARD_01.md) | Design/Codex ART | REVIEW |
| D4-20 | [Contact / Impact Frames](P04_CONTACT_FRAMES_01.md) | Design/Codex ART | REVIEW |
| D4-21 | [Dog Physical Presence](P04_DOG_PHYSICAL_PRESENCE_01.md) | Design/Codex ART | REVIEW |
| D4-22 | [Dog POV Brawl Composition](P04_DOG_POV_BRAWL_COMPOSITION_01.md) | Design/Codex ART | REVIEW |
| D4-23 | [Combat Personality Seeds](P04_COMBAT_PERSONALITY_SEEDS_01.md) | Design/Codex ART | REVIEW |

## Sprint 05 Execution Design (Update 008)

Blender implementation update 2026-09-29: [working assets and review scene](P04_BLENDER_IMPLEMENTATION_01.md) now accompany D4-18..D4-23 and D5-01 references. Design REVIEW is not production-art approval; meshes/animations are grade B and their production work remains IN_PROGRESS.
Installed 2026-09-28. Brief: `docs/06_art/SPRINT05_DESIGN_EXECUTION.md`. Design may start before the P-04 Gate; engineering stays gated. Inherit P-04 Dog POV/combat direction; do not reopen combat camera design.

| ID | Deliverable | Owner | Status |
|---|---|---|---|
| D5-01 | [Big Banyan Landmark](D5_01_BANYAN_EXECUTION_01.md) | Design/Codex ART | REVIEW |
| D5-02 | Scent Ownership Language | Design/Codex ART | IN_PROGRESS |
| D5-03 | Mark Territory Storyboard | Design/Codex ART | IN_PROGRESS |
| D5-04 | Greed Moment | Design/Codex ART | IN_PROGRESS |
| D5-05 | SAFE vs UNBANKED HUD | Design/Codex ART | IN_PROGRESS |
| D5-06 | Persistent Rival Pair | Design/Codex ART | IN_PROGRESS |
| D5-07 | Territory World States | Design/Codex ART | TODO |
| D5-08 | Ownership Reward Reveal | Design/Codex ART | IN_PROGRESS |
| D5-09 | Target Screenshot 04 | Design/Codex ART | TODO |
| D5-10 | Design Decision Pack | Design/Codex ART | TODO |
