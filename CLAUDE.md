# GOOD HUMAN! — Claude Code Development Guide

## Role
You are the primary gameplay/code engineer for GOOD HUMAN!.

Codex owns the art pipeline and later performs independent QA. Do not replace final art with self-selected assets unless explicitly requested.

## Project
- Engine: Godot 4.x
- Language: GDScript
- Platform: mobile-first 2D
- Player identity: the dog
- Current phase: MVP
- Current sprint: `docs/03_sprints/SPRINT_01_WALK.md`

## Read Order
Before coding:
1. `docs/00_project/PROJECT_OVERVIEW.md`
2. `docs/00_project/DESIGN_PRINCIPLES.md`
3. `docs/02_mvp/MVP_SCOPE.md`
4. `docs/03_sprints/SPRINT_STATUS.md`
5. Current sprint document
6. Relevant system spec, if present

## Engineering Rules
- Use typed GDScript where practical.
- Gameplay code reads Input Map actions, not physical keys.
- Content is data-driven where practical.
- RunManager is NOT an Autoload.
- Game, SaveManager and DataRegistry may be Autoloads.
- Do not put Inventory/Save/Loot logic in DogController.
- SearchPoint references LootTable; it does not hardcode rewards.
- Run RNG is owned by RunManager.
- Do not implement multiplayer during MVP.
- Do not expand scope without approval.
- Placeholder art is allowed. Final art comes from the art pipeline.
- Art not being ready must not block gameplay implementation.

## Work Protocol
1. Identify the current Task ID.
2. Inspect existing implementation before editing.
3. Mark task IN_PROGRESS in `SPRINT_STATUS.md`.
4. Implement only that task and required dependencies.
5. Validate it.
6. Report changed files and validation.
7. Mark REVIEW when implementation is ready.
8. Within the current sprint, continue to the next task without waiting (mark status, commit and push each). Stop at sprint boundaries, design conflicts or real blockers.

## Validation & Build
- `GODOT` = `/c/Users/b/Downloads/Godot_v4.6.3-stable_win64.exe/Godot_v4.6.3-stable_win64_console.exe`
- Tests: `tests/run_all.sh` (headless; each `tests/*_test.tscn` is one scene). Never use `--script` for tests.
- Windows debug build: `"$GODOT" --headless --path "$(pwd -W)" --export-debug "Windows Desktop" "$(pwd -W)/build/windows/GoodHuman.exe"` (`build/` is gitignored). Rebuild after each playable change so the owner can check progress.
- External Claude skills: `.claude/skills/`, sources/licenses in `docs/99_notes/EXTERNAL_SKILLS.md`.

## Do Not
- Redesign core game rules.
- Directly control the human in combat.
- Infer combat strength from human appearance.
- Build later-sprint systems early.
- Rewrite working systems without a concrete reason.
- Modify Codex QA reports to make a test pass.

If design and implementation conflict, stop and surface the conflict.
