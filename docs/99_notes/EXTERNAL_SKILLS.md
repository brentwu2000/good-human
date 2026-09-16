# External Claude Skills

Installed in `.claude/skills/` (`.claude/.gdignore` keeps Godot from scanning skill `.gd` samples).

**Authority:** accepted decisions (`DECISIONS.md`) > current sprint doc > `CLAUDE.md` > external skills.
External skills are generic Godot 4.x references only; they never authorize scope beyond the current sprint.

## Sources
| Source | License | Content |
|---|---|---|
| [Aetik-yue/GodoMaster](https://github.com/Aetik-yue/GodoMaster) | MIT | `godomaster` (copied from pet-survival) |
| [thedivergentai/gd-agentic-skills](https://github.com/thedivergentai/gd-agentic-skills) @ `4c4d0ff` | LGPL-3.0 (`.claude/skills/LICENSE-gd-agentic-skills.txt`) | 24 of 99 skills |

## Sprint 01 mapping
| Skill | Tasks |
|---|---|
| `godot-gdscript-mastery`, `godomaster` | All |
| `godot-autoload-architecture` | P0-002, P0-003 |
| `godot-save-load-systems` | P0-003, P0-016 |
| `godot-scene-management` | Boot → Home → RunMap → Result |
| `godot-characterbody-2d`, `godot-camera-systems` | P0-004 |
| `godot-input-handling`, `godot-platform-mobile` | P0-004, P0-005 |
| `godot-2d-physics`, `godot-composition` | P0-007 (InteractionDetector / Interactable) |
| `godot-resource-data-patterns` | P0-008, P0-010 |
| `godot-inventory-system` | P0-009, P0-012, P0-016 |
| `godot-signal-architecture` | RunManager / HUD communication |
| `godot-ui-containers`, `godot-ui-theming` | Home / HUD / Inventory / Result / Debug UI |
| `godot-export-builds`, `godot-platform-mobile` | P0-019 Android |
| `godot-testing-patterns` | P0-020, Golden Path (GdUnit4-based; not installed in project) |

## Later sprints (installed, do not use yet)
`godot-combat-system`, `godot-ability-system`, `godot-rpg-stats`, `godot-state-machine-advanced` (Sprint 02–04).
`godot-navigation-pathfinding`, `godot-platform-web`, `godot-performance-optimization`: low relevance now.

## Not installed (add when needed)
`godot-tilemap-mastery` (if greybox moves to TileMapLayer), `godot-debugging-profiling`, `godot-2d-animation`, `godot-procedural-generation` (ADR-003: do not generate the city).

Add more:
```bash
git clone --depth 1 https://github.com/thedivergentai/gd-agentic-skills.git
cp -r gd-agentic-skills/skills/<skill-name> .claude/skills/
```
