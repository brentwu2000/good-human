# GOOD HUMAN! — Codex Guide

Codex has TWO separate roles in this project:

1. ART — art production / asset engineering.
2. QA — independent blind validation after a playable sprint is delivered.

These roles must use separate sessions/contexts.

# ROLE A — ART

## Mission
Produce and integrate high-quality art assets for GOOD HUMAN! while Claude Code develops gameplay.

## Priority
Dog and human characters are the highest-value art in the game. Free does not mean low quality.

## Asset Rules
Third-party assets must:
- be obtainable for free;
- permit commercial game use;
- permit modification;
- preferably be CC0;
- never be NC or ND;
- have source, author, license and retrieval date recorded.

Do not import a third-party character as final art merely because it is usable.

Asset grades:
- S: final candidate
- A: strong base requiring GOOD HUMAN! adaptation
- B: prototype only
- R: reference only

Dog/human assets require S-level final quality. A-level bases may be transformed into original unified production art.

## Art Read Order
1. `docs/00_project/PROJECT_OVERVIEW.md`
2. `docs/00_project/DESIGN_PRINCIPLES.md`
3. `docs/06_art/ART_DIRECTION.md`
4. `docs/06_art/ART_STATUS.md`
5. `docs/06_art/ASSET_LICENSES.md`

## Blender (MCP)
A Blender bridge is wired into Codex as the `blender` MCP server, so the ART
role can model, inspect and export without leaving the session.

The add-on is already installed and enabled in Blender 5.2 — the manual
Preferences step that used to be described here is done. What remains is that
the bridge only works while **Blender is actually open**, because the server
talks to it over TCP 9876:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\b\Documents\good-human-3d-pipeline\tools\scripts\start_blender_mcp.ps1
```

That launches Blender, presses Connect, restores the window and clears the
startup popups. By hand: open Blender → N in the 3D viewport → **Blender Codex
MCP** tab → **Connect to Codex**. Either way, call `blender_health_check` and
see `"connected": true` before trusting anything else.

Two things that look like a broken bridge and are not: a **solid black**
`get_viewport_screenshot` means the Blender window is minimised (it grabs the
real OS window and does not raise an error), and a dialog across the middle of
the first screenshot of a session is Blender's splash or BlenderKit's update
popup — two Escapes clear it.

Tools: `get_scene_info`, `get_object_info`, `get_viewport_screenshot`,
`execute_blender_code`, `blender_health_check`, `sync_camera_to_viewport`,
`export_glb`, plus Hunyuan/PolyHaven/Sketchfab helpers. Usage telemetry in that
package is switched off in both the config and the add-on preferences.

Work the loop — inspect, change, screenshot, evaluate — rather than emitting a
wall of Blender Python and calling it done. Save a `.blend` before anything
destructive.

Use it for what the code-built primitives cannot do. The characters are
currently assembled from boxes and capsules by `Greybox`/`HumanModular3D`, and
gameplay now poses them through named joints (`Hips`, `Torso`, `Head`, `ArmL`,
`ArmR`, `LegL`, `LegR` — see `Greybox.part()`). Anything exported to replace
them has to keep those joint names reachable, or the combat animation stops
working. Record any imported asset in `ASSET_LICENSES.md` as usual, and keep
`.glb` output under the normal `assets/` folders.

## The 3D character pipeline
Reference images → AI mesh → Blender → rig → GLB → Godot lives in a separate
directory, `../good-human-3d-pipeline`, kept out of this repository so model
weights and large intermediates stay out of the game's history.

Read `good-human-3d-pipeline/AGENTS.md` before working there. Two constraints
set the plan: this machine's 8 GB of VRAM makes the pipeline geometry-only (no
texture generation), and the AI meshes land around 300k faces against an 8-20k
triangle target, so retopology is the substance of the Blender stage rather
than a tidy-up at the end.

The specification is `.claude/GOOD_HUMAN_3D_CHARACTER_PIPELINE.md`; current
state is `good-human-3d-pipeline/docs/INSTALL_STATUS.md`.

## Art Output
Production-ready files go under:
- `assets/characters/`
- `assets/environment/`
- `assets/items/`
- `assets/ui/`
- `assets/fx/`

Untouched third-party originals/reference material go under:
- `assets/_source/`

Never overwrite source material.

# ROLE B — QA

Start a NEW clean Codex session/context.

Before exploratory testing:
- DO NOT read Claude implementation notes.
- DO NOT inspect source code.
- DO NOT read prior QA reports.
- DO NOT read hints about known bugs.
- DO NOT use developer debug tools unless the QA brief explicitly asks.

Also do not open (they contain implementation notes): `CLAUDE.md`, `docs/03_sprints/SPRINT_STATUS.md`, `docs/99_notes/`, `tests/`, any `.gd` / `.tscn` / `.tres` file, git history.

Read only:
1. `docs/07_qa/QA_RULES.md`
2. current `QA_BRIEF` (Sprint 01: `docs/07_qa/SPRINT_01_QA_BRIEF.md`)

Phase 1: exploratory blind test.
Phase 2: acceptance/golden-path test.

Write findings to `docs/07_qa/reports/`.

QA must report what actually happened. Never fix the code while acting as blind QA.

## QA Setup (do this first)

### Build under test
- Windows QA build: `build/windows_qa/GoodHuman.exe` (portrait window).
- `build/` is not in git; the owner has Claude produce it. If the file is missing, stop and ask the owner for a fresh QA build. Do not build or run the project from source/Godot editor yourself.
- Record the build file's modified date/time in the report header.

### Save data
- Save file: `%APPDATA%\Godot\app_userdata\Good Human\save.json` (shared with the owner's own builds).
- Before Phase 1, if `save.json` exists, rename it to `save.owner_backup.json` (do not delete) so testing starts from a fresh save. Record that you did this.
- To test "restart the application": fully close the game window and launch the exe again. Do not edit the save file by hand.
- After all QA is finished, delete the QA `save.json` and rename `save.owner_backup.json` back to `save.json`.

### Operating the game
- Controls must be discovered from the game itself (Phase 1 is blind).
- You need to see the window and send keyboard/mouse input (screenshots + input tools). If your environment cannot do that, stop and tell the owner instead of guessing results.
- Capture screenshots for every bug; save them under `docs/07_qa/reports/screenshots/SPRINT_XX_YYYY-MM-DD/` and link them from the report.

### Report
- File: `docs/07_qa/reports/SPRINT_XX_QA_YYYY-MM-DD.md` (one report, Phase 1 section written before Phase 2 starts).
- Header: date, build path + modified time, OS, whether a fresh save was used.
- Phase 1: answer every question in the QA brief, then list what was tried / expected / happened.
- Phase 2: table with every Golden Path step → PASS / FAIL / BLOCKED + note.
- Bugs: ID, severity (per `QA_RULES.md`), steps to reproduce, expected, actual, screenshot.
- Do not change code, data, docs other than your report, or task statuses.
