# Accepted Decisions

## ADR-001 — RunManager is not Autoload
A run is temporary session state and is destroyed after leaving the run.

## ADR-002 — Fixed map, semi-random run
Do not procedurally generate the city. Randomize content such as loot, encounters, events and extraction availability.

## ADR-003 — Human combat is autonomous
The player remains the dog. Human combat must not become direct player-controlled action combat.

## ADR-004 — Appearance != strength
A frail-looking human may be extremely strong and a muscular human may be weak.

## ADR-005 — Engineering and Art run in parallel
Claude Code owns gameplay engineering. Codex owns the art pipeline. Missing final art does not block engineering.

## ADR-006 — Codex performs independent QA
After each playable sprint, Codex uses a fresh context and tests without reading implementation details first.

## ADR-L01 — Portrait 720×1280, Mobile renderer
> Local decision. Renumbered (was ADR-007, then ADR-010) so numbered ADRs stay reserved for update packages (ADR-007 seamless combat, ADR-008 training, ADR-009 dog desires, ADR-010 camera evaluation).
The game is portrait (base viewport 720×1280, `canvas_items` stretch, `expand` aspect) for single-hand play. Renderer is Godot Mobile. Art and UI are produced for this frame.

## ADR-007 — Seamless real-time combat
No separate Battle Scene: encounters, human combat, dog control and disengagement all happen in the Run World. Full record: `ADR_007_SEAMLESS_REALTIME_COMBAT.md`.

## ADR-008 — Behavior-driven human training
Human growth comes from meaningful dog behavior in normal runs, not a minigame or XP screen. Full record: `ADR_008_BEHAVIOR_DRIVEN_TRAINING.md`.

## ADR-009 — Dog desires, not quest checklists
Short-term progression is framed as optional dog desires, discoveries and causal threads that persist and fork, not generic quest checklists. Full record: `ADR_009_DOG_DESIRES_NOT_QUEST_CHECKLISTS.md`.

## ADR-010 — Camera perspective: switchable A (3/4 top-down) + B (dog-height chase) in 3D (ACCEPTED 2026-09-17)
Evaluated in P-01; owner chose free switching between A and B, which moves production to 3D, starting with the P-02 vertical slice. Full record: `ADR_010_CAMERA_PERSPECTIVE_UNDER_EVALUATION.md`.
