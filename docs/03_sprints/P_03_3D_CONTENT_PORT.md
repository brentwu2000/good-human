# P-03 — 3D CONTENT PORT

Owner approved (2026-09-17, "開始"): bring the TRAIN and GOALS content into the 3D walk. Follows P-02 (`docs/03_sprints/P_02_3D_VERTICAL_SLICE.md`).

## Goal
The 3D walk plays like the 2D walk: the owner's growth-shaped habits, behaviour-driven training, dog desires with world cues, the squirrel, scent trails, the rival 阿黑 and the Old Master.

## Scope
- Owner behaviour (stumble when dragged, exhaustion, hesitation near pairs, heavy bag) in 3D.
- Training events from 3D world behaviour (same events, same anti-farming and conversion).
- Dog desires in 3D: GoalDirector, desire HUD (card, popups, nose arrow projected from the 3D camera).
- 3D scent cues, squirrel and place markers.
- Opponent content in 3D: three ordinary pairs shuffled per walk, the hidden rival revealed by the scent chain, the Old Master.
- Debug panel hooks work in the 3D walk.

## Engineering approach
- The existing observers (OwnerBehavior, TrainingObserver, GoalDirector, DesireHUD) become dimension-agnostic: distances are defined in meters and scaled by `units_per_meter` (2D map: 80 px per meter, 3D: 1). 2D keeps working until the 2D map is retired.
- 3D actors expose the same methods as their 2D counterparts (duck typing), so rules stay in one place.
- The slice level grows only as much as the content needs (alley gap, big tree); the full neighbourhood is the next step.

## Out of scope
Full neighbourhood layout, retiring the 2D map, 3D art, Android performance.

## Acceptance
- In 3D: dragging/heavy bag/lingering/provoking/escaping/exhaustion produce training; extraction converts it; the owner visibly behaves according to growth.
- In 3D: a walk starts with a desire, cues appear in the world, the Strange Scent chain reveals and resolves the rival, the squirrel can be chased up a tree, discoveries and threads persist.
- All 2D and 3D tests pass.
