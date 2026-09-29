# D4-19 — Footwork Board v0.1

Status: REVIEW · 2026-09-28 · Codex ART

An 8-second authored exchange proposal. Durations and positions are staging references, not simulation configuration. O = owner; R = rival. [Open the spatial board](p04/p04_footwork_01.svg).

## Coordinate convention

Metres on a level ground plane; +X is screen-right in the overhead diagram, +Z away from the initial dog viewpoint. Values specify approximate pelvis ground projections, not contact points or collision radii. Facing continually follows the other person, with bounded turns. The dog observes from (0, −2.3); this is a composition reference, not a forced camera or player position.

| Time | O (X,Z) | R (X,Z) | Beat | Foot / angle read |
|---|---|---|---|---|
| 0.0 s | (−0.85,0) | (0.85,0) | Size up | Staggered bases; quiet guard, 1.70 m separation |
| 1.0 s | (−0.55,0.10) | (0.65,0.10) | Approach | Each lead foot advances then trailing foot follows; 1.20 m |
| 2.0 s | (−0.45,0.35) | (0.45,−0.15) | Circle | O steps up, R steps down; line rotates about 29°; 1.03 m |
| 2.8 s | (−0.30,0.27) | (0.45,−0.15) | Jab / block | O plants lead foot, R receives on guard; about 0.86 m |
| 3.6 s | (−0.45,0.40) | (0.70,−0.35) | Backstep / reset | R rear foot opens gap, lead follows; 1.37 m |
| 4.8 s | (−0.05,0.20) | (0.75,−0.55) | Heavy hook / miss | O commits; R steps diagonally away before fist arrives; 1.10 m |
| 6.2 s | (0.05,0.30) | (0.65,−0.35) | Counter / stagger | R closes after O misses; O catches weight with outward step; 0.88 m |
| 8.0 s | (−0.25,0.55) | (0.75,−0.25) | Separation | O regains guard; both settle, 1.28 m; exchange remains unresolved |

## Continuous movement

0–2 seconds build distance and angle; 2–3.6 seconds produce a compact jab/block followed by release. 3.6–4.8 seconds expand into the unmistakable heavy miss. 4.8–6.2 seconds expose overcommitment and a counter, then 6.2–8 seconds let the weight settle. No compulsory defeat, damage value or new attack selection logic is implied.

Coordinates are checked against the final rig reach and actual collision capsule before implementation. The close beats may need spacing adjustment; never overlap bodies to preserve a number. Each step moves the pelvis only after a receiving foot is available. Do not cross the feet during circling or snap facing across the action axis.

## Dog-height camera check

At each key, check feet, striking hand and receiving guard/body at 405×720. Let the fight rotate in world space; do not orbit the camera simply to preserve the sheet's composition. If the player moves behind a person, use the established P-04 camera behavior and validate that owner identity remains readable. Do not hide the obstruction by rendering people transparent or forcing the dog aside.

## Validation boundary

Diagram verifies proposed sequencing and changes in spacing/angle only. Actual 8-second playback, collision clearance, foot plants, contact reach and dog POV readability remain implementation review items.
