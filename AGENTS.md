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

Read only:
1. `docs/07_qa/QA_RULES.md`
2. current `QA_BRIEF`

Phase 1: exploratory blind test.
Phase 2: acceptance/golden-path test.

Write findings to `docs/07_qa/reports/`.

QA must report what actually happened. Never fix the code while acting as blind QA.
