# P-01 Camera Gate — Review

Date: 2026-09-17
Evidence: owner playtests of `build/p01_camera` (A/B/C, background people and dogs). Codex blind QA (CAM-015) not run.

## Owner evidence
- "我覺得可以在遊戲中自由切換視角 A 跟 B 都很不錯" — A (3/4 top-down) and B (dog-height chase) both work; the owner wants to switch freely between them in the game.
- Adding background people and dogs made the views "更有感覺".

## Engineering observations from building P-01
- B/C: the leashed owner walks between the dog and the camera. Fading the owner while it blocks the view is required.
- B: park foliage and close walls block the view (camera collision + climb-up helps for walls; foliage would need fading).
- B: fights at dog height are close and partial; C's combat framing (pull back and frame dog + fight) reads better. A switchable A/B game should still auto-frame fights.
- A in 3D: buildings in front of the dog need roof/wall fading or cutaways (the 2D game never had occlusion).
- Switching A↔B changes what "up" on the joystick means (screen-north vs. dog-forward). The switch needs a clear rule so players are not disoriented.

## Gate outcome (proposed)
Direction: **A + B switchable in production** (with C-style automatic combat framing).
This means a production move from 2D to 3D (B cannot exist in 2D). Per the Camera Gate, the impact below must be reviewed before any migration starts. ADR-010 stays PROPOSED until the owner approves.

## 2D → 3D impact estimate

### Reusable as-is (engine-agnostic logic, ~half of gameplay code)
RunManager, RunResult, Inventory/ItemStack, SaveManager, DataRegistry, Game, loot tables and all data resources, CombatSimulation/CombatFighter (1D fight line), training (tracker, summary, growth, resolver, traits), goals (desire tracker, progress, catalog). Their logic tests (combat_sim, training_core, goals_core, inventory, save, data_loot, run_core in part) carry over.

### Must be ported (2D nodes, pixel units)
- Dog controller → CharacterBody3D with camera-relative movement for B and screen-relative for A.
- Owner follower + leash, OwnerBehavior distances (px → m).
- Interaction (Area2D → Area3D), search points, extraction points, opponent pairs, scent cues, squirrel, place markers.
- CombatCoordinator/Engagement world placement (Vector2 → Vector3 on the ground plane), combat presentation (puppets → 3D characters).
- TrainingObserver / GoalDirector distance thresholds (px → m).
- Run map: rebuild the neighbourhood as a 3D level (same layout).
- Camera: production rig with A/B switch, collision, occluder fading (owner, foliage, buildings), combat framing.
- World-space text (Label → Label3D), HUD arrow projection. Screen UI (HUD, inventory, result, Home, debug, touch controls) is reusable.
- Scene-level tests (golden path, combat_world, training_world, goals_world, dog movement) need rewriting against 3D scenes.

### Art (largest cost and schedule risk)
- Current Codex 2D sprite sequences (owner walk/combat/growth, dog) cannot be used in B; a low camera shows flat billboards.
- Needed: 3D dog (quadruped rig: walk, run, sniff, bark, pull), owner (walk, dragged, stumble, punch/kick/block/dodge, down, growth variations), opponent humans incl. the Old Master (appearance ≠ strength), opponent dogs, squirrel.
- Environment kit: street, sidewalks, houses with roof fade for A, alley, park props, trees/bushes with fade for B.
- Free CC0 3D sources (e.g. Kenney, Quaternius) can cover greybox → stylized placeholders; final style needs an art direction update (ART_DIRECTION is 2D).

### Level design
Both views must work in one level: landmarks readable at dog height (B) and from above (A), open sightlines around encounters, fade/cutaway rules for buildings and foliage.

### Mobile performance
Mobile renderer, portrait 3D: low-poly budgets, limited real-time shadows, simple foliage. Android has never been validated (P0-019 deferred); a 3D migration makes an early Android performance check necessary.

### Suggested staging if approved
1. P-02 3D vertical slice: port dog, owner, leash, one street + park area, search, one opponent pair, A/B switch — reusing the engine-agnostic systems unchanged.
2. Port remaining world systems and scene tests; retire the 2D run map.
3. Art pipeline switch (Codex): 3D style target, dog/owner models, environment kit.
4. Android performance check before content expansion.

Decision: **APPROVED by owner (2026-09-17)** — move to 3D, starting with the P-02 vertical slice (`docs/03_sprints/P_02_3D_VERTICAL_SLICE.md`).
