# Sprint 01 — WALK

## Goal
Build the first complete walking extraction loop without combat.

Home → go out → move dog → search → loot → inventory → dog safe slots → extraction unlock → extract → result → stash → second run.

## Required Content
- 1 greybox neighborhood/park map
- 16 search points (tuned up from ~10 after owner playtest)
- 12 prototype items
- 2 loot tables
- Human run inventory: 8 slots
- Dog safe inventory: 2 slots
- Home stash: 30 slots
- Extraction A: bus stop, unlock at 3:00 (tuned from 5:00 after owner playtest)
- Extraction B: north exit, unlock at 5:00 (tuned from 8:00 after owner playtest)
- Run seed
- Debug panel

## Architecture
- Game / SaveManager / DataRegistry may be Autoloads.
- RunManager belongs to the run scene and is destroyed when the run ends.
- One reusable Inventory implementation.
- Item and LootTable are data-driven Resources.
- SearchPoint references LootTable.
- Run RNG drives loot rolls.

## Golden Path
1. Boot → Home.
2. Start walk.
3. Move dog.
4. Search trash and obtain an item.
5. Search another point and obtain a valuable item.
6. Move valuable item to Dog Safe Inventory.
7. Reach 3:00.
8. Bus extraction opens.
9. Ignore it and continue searching.
10. Obtain another valuable item.
11. Return to bus stop.
12. Extract successfully.
13. Result shows run time, seed and loot.
14. Return Home.
15. Items exist in stash.
16. Start second run.
17. Search points reset and loot rerolls.
18. Restart application and confirm stash persists.

## Sprint Acceptance
- Full loop works for three consecutive runs.
- No blocking bug.
- Android build can complete the loop. (Deferred by owner decision 2026-09-17; Sprint 01 is validated on the Windows build for now.)
- Art may be placeholder; art pipeline runs in parallel.
- Sprint is not considered validated until independent Codex QA is completed.
