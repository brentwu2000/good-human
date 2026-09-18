# Sprint 05 — Greed / Territory Design Decision Pack v0.1

Status: REVIEW
Deliverable: D5-10
Date: 2026-09-18

Owner authorized Sprint 05 engineering before Core Experience Gate 02 was formally reviewed. This pack consolidates implementation-ready visual decisions while leaving the Gate outcome and explicitly open product choices unresolved.

## Experience target

The player should understand one moment without a modal explanation:

> Going home is safe now. The owner is carrying something worth keeping. The dog can still smell one more interesting thing.

The choice is voluntary. Nothing closes in, counts down or forces the player deeper into the park.

## Locked visual decisions

| Area | Selected direction | Source |
|---|---|---|
| Landmark | Wide three-trunk banyan with exposed radial roots, aerial roots, uneven canopy and approach-facing bark scar | `SPRINT_05_TERRITORY_VISUAL_SPEC.md` |
| Ownership | Repeated root-level scent knots; state reads through count, overlap and teal/coral balance | `SPRINT_05_TERRITORY_VISUAL_SPEC.md` |
| Mark | Sniff → amber recognition rays → expanding teal scent knot; no modal or capture animation | `SPRINT_05_MARK_RIVAL_REWARD_SPEC.md` |
| Rival | One persistent black dog with coral neckerchief and teal leaf tag; ordinary hoodie/tote owner | `SPRINT_05_MARK_RIVAL_REWARD_SPEC.md` |
| Risk HUD | One quiet dog-tag line stating the consequence; silent when nothing meaningful is at risk | `SPRINT_05_RISK_HUD_SPEC.md` |
| Greed composition | Safe exit and temptation remain simultaneously visible; dog body direction and leash tension author the choice | `SPRINT_05_GREED_STORYBOARD.md` |
| Reward reveal | Nine small teal/cream leaves rise from the roots; no chest, currency shower or rarity beam | `SPRINT_05_MARK_RIVAL_REWARD_SPEC.md` |
| Target frame | Dog-height portrait composition with bus stop left/back and Banyan scent/rival right/ahead | `SPRINT_05_TARGET_SCREENSHOT_04.md` |

## Territory state contract

| State | Landmark presentation | Player-facing meaning |
|---|---|---|
| UNKNOWN | Tree silhouette only | Interesting place, not yet understood |
| DISCOVERED | One muted violet trace | The dog recognizes the place |
| CONTESTED | Alternating rival coral and player teal | Another dog has a relationship with it |
| CLAIMING | Teal majority with one rival trace retained | Repeated successful returns are changing the relationship |
| OWNED | Four teal traces forming a familiar root route | This place recognizes the player dog |

State presentation does not reveal combat difficulty, reward value or exact numerical claim progress.

## Runtime presentation hooks

- `BanyanLandmark3D.build(state)` selects the state variant.
- `TerritoryPresentation3D.play_recognize()` plays the 0.85-second sniff recognition accent.
- `TerritoryPresentation3D.play_mark()` plays the 1.15-second mark accent.
- `TerritoryPresentation3D.play_reward_reveal()` plays the 1.8-second ownership payoff.
- `BanyanRivalPair3D.decorate()` applies persistent rival identity without changing stats.
- `RunHUD` reads `RunValue` and extraction state; it never changes inventory or extraction rules.

Gameplay remains authoritative for eligibility, claim progress, extraction resolution, persistence, reward selection, Goals integration and Dog Agency consequences.

## Mobile composition hierarchy

1. Player dog's head, back, harness and movement intention.
2. Teal leash connection to the owner.
3. Current world opportunity: scent, rival or landmark.
4. Safe extraction kept visible when framing permits.
5. Risk tag and inventory detail.

No territory presentation may cover the dog, leash anchors, interaction button or primary desire card.

## Prohibited directions

- Giant flags, faction banners, crowns or capture rings.
- Passive-income, upkeep or empire-map imagery.
- Red lethal-zone overlays, storms or forced countdowns.
- Risk percentages, power numbers or difficulty colors.
- Rival armor, weapons, scars, aggressive spikes or combat aura.
- Loot-box reveal language, treasure chests or currency showers.
- Separate territory battle scene.

## Reference assets

- `assets/_source/design/territory/greed_moment_storyboard_01.png`
- `assets/environment/concepts/target_screenshot_04_one_more_thing.png`
- `assets/environment/territory/banyan_landmark_3d.gd`
- `assets/fx/territory/territory_presentation_3d.gd`
- `assets/characters/rivals/banyan_rival_pair_3d.gd`

## Open decisions requiring owner or Gate review

1. Final unique park-related ownership reward remains TBD in data and must not be invented by art.
2. Old Master and the resident rival currently share the Banyan area at different offsets. Validate visual crowding and interaction targeting in playtest before approval.
3. Core Experience Gate 02 has not received a formal recorded decision. This pack may guide current engineering, but it becomes final only after Gate review.

## Review checklist

- The owner can describe why leaving is safe and why staying is tempting.
- Big Banyan is recognizable without a label at dog height.
- UNKNOWN through OWNED read as a changing relationship, not conquest.
- Marking feels dog-like and never grants progress before a successful relevant extraction.
- The single persistent rival remains recognizable across the Goals and Territory arcs.
- SAFE and UNBANKED consequences are readable without dashboard overload.
- Reward reveal feels satisfying but small and place-specific.
- The target frame remains legible at the 405×720 window override.
