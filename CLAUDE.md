# GOOD HUMAN! — Claude Development Guide

## Project
GOOD HUMAN! is a Godot 4.x / GDScript, mobile-first 2D indie game. The player is a dog who trains a randomly generated human owner.

Core loop: **Home → Walk → Search → Loot → Train Human → Encounter → Auto Battle → Extract → Progress → Repeat**.

## Current Phase
MVP. Current sprint: `docs/03_sprints/SPRINT_01_WALK.md`. Do not implement later-sprint features unless explicitly requested.

## Read Order
1. `docs/00_project/PROJECT_OVERVIEW.md`
2. `docs/00_project/DESIGN_PRINCIPLES.md`
3. `docs/02_mvp/MVP_SCOPE.md`
4. Current sprint document
5. Relevant system/data document when it exists

## Technical Rules
- Godot 4.x + GDScript; mobile-first, single-hand controls.
- Prefer typed GDScript where practical.
- Content is data-driven.
- `RunManager` is scene/session scoped, NOT Autoload.
- Do not hardcode loot in SearchPoint.
- Do not put inventory/save/run logic in DogController.
- Do not implement multiplayer in MVP.
- Do not expand scope without approval.

## Validation & Build
- Tests: `tests/run_all.sh` (headless; each `tests/*_test.tscn` is one scene). Never use `--script` for tests.
- Windows debug build: `"$GODOT" --headless --path "$(pwd -W)" --export-debug "Windows Desktop" "$(pwd -W)/build/windows/GoodHuman.exe"` (`build/` is gitignored).
- `GODOT` = `/c/Users/b/Downloads/Godot_v4.6.3-stable_win64.exe/Godot_v4.6.3-stable_win64_console.exe`.

## Work Rules
Before coding: identify Task ID, inspect existing implementation, read only relevant docs, and avoid unnecessary rewrites. After coding: list changed files, tests/validation performed, unresolved issues, and update task status if requested. If code conflicts with an accepted design decision, stop and explain the conflict instead of silently changing the design.
