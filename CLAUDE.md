# GOOD HUMAN! — Claude Code Development Guide

## Role
You are the primary gameplay/code engineer for GOOD HUMAN!.

Codex owns the art pipeline and later performs independent QA. Do not replace final art with self-selected assets unless explicitly requested.

## Project
- Engine: Godot 4.x
- Language: GDScript
- Platform: mobile-first 3D, dog-height camera (ADR-010 in `docs/99_notes/DECISIONS.md`). The Sprint 01–03 2D scenes are still in the repo.
- Player identity: the dog
- Current phase: MVP
- Current sprint: `docs/03_sprints/SPRINT_04_DOG_AGENCY.md` (in the 3D walk); its active blocker is P-04, `docs/01_prototypes/P_04_HUMAN_BRAWL_PHYSICAL_PRESENCE.md` (builds on P-03, `docs/03_sprints/SPRINT_04_P03_STREET_BRAWL.md`). Next is P-05 street loot & improvised weapons (`docs/01_prototypes/P_05_STREET_LOOT_IMPROVISED_WEAPONS.md`, Update 010), whose gate unlocks Sprint 05. `SPRINT_STATUS.md` is authoritative.

## Read Order
Before coding:
1. `docs/00_project/PROJECT_OVERVIEW.md`
2. `docs/00_project/DESIGN_PRINCIPLES.md`
3. `docs/02_mvp/MVP_SCOPE.md`
4. `docs/03_sprints/SPRINT_STATUS.md`
5. Current sprint document
6. Relevant system spec, if present
7. `docs/99_notes/LESSONS_LEARNED.md` — problems already hit and the rules that came out of them

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
6. Report changed files and validation. If the work hit a problem that was not obvious (cost real time, or a test passed while the game was wrong), add it to `docs/99_notes/LESSONS_LEARNED.md` as symptom → cause → rule → check.
7. Mark REVIEW when implementation is ready.
8. Within the current sprint, continue to the next task without waiting (mark status, commit and push each). Stop at sprint boundaries, design conflicts or real blockers.

## Validation & Build
- `GODOT` = `/c/Users/b/Downloads/Godot_v4.6.3-stable_win64.exe/Godot_v4.6.3-stable_win64_console.exe`
- Tests: `tests/run_all.sh` (headless; each `tests/*_test.tscn` is one scene). Never use `--script` for tests.
- Windows debug build: `"$GODOT" --headless --path "$(pwd -W)" --export-debug "Windows Desktop" "$(pwd -W)/build/windows/GoodHuman.exe"` (`build/` is gitignored). Rebuild after each playable change so the owner can check progress.
- External Claude skills: `.claude/skills/`, sources/licenses in `docs/99_notes/EXTERNAL_SKILLS.md`.
- Art-facing changes are handed to Codex in `docs/06_art/CLAUDE_HANDOFF_TO_CODEX_<date>.md` (Codex's art read order points there; SPRINT_STATUS is not in it): what was added, how it is rebuilt, what must not change, and adjustment requests (CX-xx). Add to it whenever gameplay work produces or changes art (clips, rigs, props, imported assets).
- Blender: 5.2 LTS only (`/c/Program Files/Blender Foundation/Blender 5.2/blender.exe`, owner 2026-10-08: no 4.5). Use the installed add-ons (MPFB, Rigify, Retarget, LoopTools, Bool Tool, PolyQuilt, Magic UV, Ucupaint, Archimesh, Extra Mesh Objects, Sapling, A.N.T. Landscape) instead of reinventing them; batch work stays in plain `bpy`/`bmesh`. List, roles and licences: `docs/99_notes/BLENDER_TOOLCHAIN.md`. Do not install others without approval. Codex owns art; check for an open Blender (Codex) before changing preferences.

## Do Not
- Redesign core game rules.
- Directly control the human in combat.
- Infer combat strength from human appearance.
- Build later-sprint systems early.
- Rewrite working systems without a concrete reason.
- Modify Codex QA reports to make a test pass.

If design and implementation conflict, stop and surface the conflict.
