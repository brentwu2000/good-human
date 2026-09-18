# Sprint 05 — Mark, Rival and Reward Presentation v0.1

Status: REVIEW
Deliverables: D5-03, D5-06, D5-08 / ART-042, ART-043

## Mark Territory storyboard

1. Approach — existing root-level scent knots remain the only passive prompt.
2. Sniff — dog lowers its head using the existing sniff motion; five short amber recognition rays expand close to the roots for 0.85 seconds.
3. Recognize — owner and rival reactions remain in world space; no modal panel appears.
4. Mark — five teal scent beads and one horizontal scent stroke expand for 1.15 seconds.
5. Resolve — gameplay decides whether the result is discovery, challenge, progress or ownership. Presentation never increments progress itself.

Runtime hook: the Banyan contains `TerritoryPresentation3D` with `play_recognize()`, `play_mark()` and `play_reward_reveal()` methods.

## Banyan rival pair

The existing black-dog/student pair remains the persistent rival. Recognition comes from an ordinary indigo hoodie and tote, folded park map and enamel pin on the human, plus a worn coral neckerchief and leaf-shaped teal tag on the dog.

No scars, armor, aggressive spikes, weapons, aura or muscular exaggeration are used. The pair is recognizable but does not reveal combat strength.

## Reward reveal

Ownership reward uses nine small teal and cream leaf shapes rising from the roots over 1.8 seconds. It is a place acknowledging a familiar dog, not a loot-box opening: no chest, rarity beam, shower of currency or full-screen interruption.

Gameplay remains authoritative for reward selection, persistence and timing. The reveal runs only after an explicit runtime call.
