# P-04 / Sprint 05 Territory Variants Implementation 01

Date: 2026-09-29

D5-07 now has a reviewable four-state world presentation in the P-04 showcase:

- `UNKNOWN`: landmark only;
- `DISCOVERED`: one muted violet root trace;
- `CONTESTED`: alternating rival coral and player teal traces;
- `OWNED`: repeated teal route with the small reward cluster.

Mode `7` / `Territory variants` cycles the states with `T`. It reuses the Blender-authored scent-state GLB and keeps all signals at root level. No flag, crown, tower, faction banner, control ring, or gameplay mutation was added.

## Verification

- Showcase parses and launches after the new mode and input path.
- Existing P-04 targeted asset validation remains passing.
- The territory mode is art-only; runtime territory logic remains authoritative.
