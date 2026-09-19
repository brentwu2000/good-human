# P03-D05 — Hit / Impact Language v0.1

Status: REVIEW

Runtime integration:

- `assets/fx/encounter/encounter_presentation_3d.gd`
- `world/encounter/opponent_pair_3d.gd`
- `core/combat/combat_coordinator_3d.gd`

## Goal

A first-time viewer should distinguish miss, dodge, block, light hit, heavy hit/stagger and a dog-created opening without combat text. Physical motion carries the event; FX and camera only reinforce it.

## Read hierarchy

1. attacker anticipation and committed contact pose;
2. defender compression, balance loss or avoidance;
3. contact-local material response and restrained accent;
4. damage-scaled hitstop and camera impulse;
5. recovery or stagger that confirms magnitude.

If the first two layers fail, larger FX are not an acceptable repair.

## Outcome language

| Outcome | Body response | Contact accent | Camera / time | Recovery |
|---|---|---|---|---|
| Miss | attacker follows through into empty space | none | none | attacker regains balance |
| Dodge | defender's centre leaves attack line | none | none | defender keeps opponent-facing awareness |
| Block | guard compresses; feet absorb force | short teal accent at guard contact | light impulse; minimal pause | guard opens back into stance |
| Light hit | localized torso/shoulder recoil | small coral accent at body contact | 60–90 ms feel target | one clean balance catch |
| Heavy hit | whole-body balance breaks | larger coral accent, dust/cloth secondary | up to existing 160 ms cap | recovery step or stagger |
| Dog opening | strongest honest contact and recoil | warm amber contact accent replaces coral | strongest existing graded impulse | receiver clearly exposes the dog's causal payoff |
| Down | impact leads into an uneven fall | no additional giant burst | resolution hold, not repeated shake | remains in world for emotional beat |

## Runtime change

The impact accent now:

- appears at the midpoint between the two fighting humans instead of the encounter marker;
- scales duration, expansion and opacity from the existing presentation weight;
- uses teal for Block, coral for ordinary hits and amber for the dog-created Opening;
- lets a same-frame Opening replace the ordinary hit pulse with the stronger dog-agency payoff;
- leaves damage, hit confirmation, AI, timing rules and results untouched.

## Physical contact requirements

- Fist/foot arrives before hitstop begins.
- Defender compression precedes positional knockback.
- Clothing and hair settle after the body, with no explosive cloth effect.
- Support feet remain readable at dog-eye height.
- Heavy kick/punch separates bodies along the contact axis where space permits.
- Contact accents stay around torso/guard height and never become a screen flash.

## Dog-eye limits

- Do not cover faces, hands, support feet or the teal leash with FX.
- Near-camera accents reduce opacity rather than growing to fill the screen.
- Behind-opponent view prioritizes owner visibility over exact accent placement.
- Camera shake remains restrained enough to preserve the player's escape direction.
- Opening amber must not resemble loot rarity, desire scent or a quest completion.

## Combat-flow optimization

Use variation to create rhythm rather than nonstop intensity:

1. anticipation stays quiet;
2. misses and dodges create visual breathing room;
3. blocks feel compact and defensive;
4. light hits maintain exchange rhythm;
5. heavy hits punctuate the exchange;
6. Bark/Pull opening is the clearest authored peak;
7. Down removes impact clutter and hands the scene to the emotional resolution.

This rhythm prevents every hit from feeling identical and keeps the dog's intervention more valuable than passive observation.

## Acceptance

With normal combat labels and HP hidden at 405×720:

- Block and Hit differ before color is considered;
- light and heavy hits differ through body and timing, not only effect size;
- the accent originates near physical contact while fighters orbit;
- Bark-created Opening is identifiable as the strongest payoff without a text popup;
- Dodge and Miss produce no false contact accent or hitstop;
- repeated light hits do not create a continuous screen flash;
- Down clears the exchange effects and leaves the dog free to approach.

## Scope guard

This pass changes presentation only. Simulation remains the sole authority for hit, block, dodge, opening, stagger, defeat, damage and timing.
