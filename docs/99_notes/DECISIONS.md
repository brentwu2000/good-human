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

## ADR-007 — Portrait 720×1280, Mobile renderer
The game is portrait (base viewport 720×1280, `canvas_items` stretch, `expand` aspect) for single-hand play. Renderer is Godot Mobile. Art and UI are produced for this frame.
