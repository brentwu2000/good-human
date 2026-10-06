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

## ADR-L02 — The dog changes the exchange, not the result
> Local decision (owner, 2026-09-28, during P04-04: "狗本來就不該是左右戰鬥重點").
Barking and leash pulls must visibly change what happens in a fight and help the owner, but they are not what decides who wins: the owner's own strength, grown through the dog's training, does (Design Principles 5 and 6). Tuning and tests hold the dog's edge to "helps, within limits" rather than requiring it to swing a large share of fights.

## ADR-L03 — Walking camera: high chase behind the dog
> Local decision (owner, 2026-10-05, reference `.claude/視角.png`: "調整一下遊戲畫面視角").
Amends ADR-010's walking shot only. The EXPLORE camera hangs higher and further back (pivot 1.2 m, pitch −15°, boom 4.2 m) and aims 14° above the dog, so the dog sits small in the lower third with the way ahead filling the screen, at any boom length. Fight framings (push-in, Combat Snap to dog POV) are unchanged.

## ADR-007 — Seamless real-time combat
No separate Battle Scene: encounters, human combat, dog control and disengagement all happen in the Run World. Full record: `ADR_007_SEAMLESS_REALTIME_COMBAT.md`.

## ADR-008 — Behavior-driven human training
Human growth comes from meaningful dog behavior in normal runs, not a minigame or XP screen. Full record: `ADR_008_BEHAVIOR_DRIVEN_TRAINING.md`.

## ADR-009 — Dog desires, not quest checklists
Short-term progression is framed as optional dog desires, discoveries and causal threads that persist and fork, not generic quest checklists. Full record: `ADR_009_DOG_DESIRES_NOT_QUEST_CHECKLISTS.md`.

## ADR-010 — Camera perspective: dog-height chase camera in 3D (ACCEPTED 2026-09-17)
Evaluated in P-01; owner first chose switchable top-down + dog view, then after playing the P-02 slice kept only the dog view (P-01 "B" framing). Production moves to 3D. Full record: `ADR_010_CAMERA_PERSPECTIVE_UNDER_EVALUATION.md`.

## ADR-011 — Dog agency over QTE
Combat participation comes from continuous dog movement and contextual world actions (Bark, Leash Pull), not isolated QTE prompts. Full record: `ADR_011_DOG_AGENCY_OVER_QTE.md`.

## ADR-L04 — Fight camera: low over the dog's shoulder
> Local decision (owner, 2026-10-06, choosing between options after reviewing captures: 「低角度越肩」).
Amends ADR-015 (still PROPOSED, adoption pending readability review). Captures of real fights in dog-eye first person failed that review: the dog stands within a metre of the fighters, so the view is trousers and shoes and nobody can tell who struck or whether it landed. Fights are now shot from behind the dog at about 0.8–1 m, 2–2.7 m back; the view turns to look past the dog at the fight, swung about halfway to side-on to the two fighters so they stand side by side, and aims at chest height so both are seen head to foot with the dog in the lower foreground. Circling the fight orbits the camera with it. The dog-eye snap stays available from the debug panel (`CameraRig3D.combat_pov`).
