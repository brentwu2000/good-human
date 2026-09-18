# Sprint 05 — Territory Visual Language v0.1

Status: REVIEW
Deliverables: D5-01, D5-02, D5-07

## Landmark

Big Banyan Tree is identified by three fused trunks, exposed radial roots, hanging aerial roots, an uneven broad canopy and one pale bark scar facing the main approach. It is substantially wider than ordinary park trees and remains recognizable before labels or territory effects appear.

The tree is a relationship landmark, not a capture point. Do not add a flag, crown, glowing tower, faction banner or map-control ring.

## Scent ownership exploration

Three directions were considered:

1. Colored canopy lighting — readable at distance, but too close to faction control and disconnected from dog behavior.
2. Collars/tags tied to the trunk — personal and readable, but suggests human ownership or decoration.
3. Root-level scent knots — small repeated scent traces attached to familiar roots; readable from dog height and naturally connected to marking behavior.

Selected direction: root-level scent knots. Color supports ownership but repetition and overlap carry the state transition.

## State variants

| State | World read |
|---|---|
| UNKNOWN | Landmark only; no scent knots |
| DISCOVERED | One muted violet trace |
| CONTESTED | Rival coral and player teal alternate at the roots |
| CLAIMING | Teal becomes the majority but rival trace remains |
| OWNED | Four teal traces form a familiar repeated route around the roots |

State color never communicates combat difficulty or reward value. Runtime territory logic may select these variants later without changing the landmark model.
