# Sprint 04 — Mobile HUD Exploration v0.1

Status: REVIEW  
Deliverable: D-07  
Visual board: `assets/_source/design/dog_agency/mobile_hud_exploration_01.svg`

## Decision

Use **C — contextual dog-height HUD** for the accepted dog-height chase camera.

The HUD has one persistent movement region and at most two dog actions. It must read as a dog controlling a relationship, not a human combat hotbar. Bark is available when it can produce a response; Interact appears only for the current nearby target.

## Explored layouts

| Variant | Camera path | Layout | Result |
|---|---|---|---|
| A — split corners | 3/4 top-down | Fixed left movement pad; one right action that changes label | Legible, but the changing action hides the difference between Bark and Interact |
| B — paired actions | hybrid | Floating left movement; small Bark above a large Interact | Clear but visually resembles a two-skill combat stack |
| C — contextual dog-height | dog-height chase | Floating left movement; quiet Bark button; Interact expands only near a valid target | Selected — preserves world view and keeps actions semantically distinct |

Variants A and B remain comparison records only. They are not parallel production targets after the Camera Gate decision.

## Selected layout at 720×1280

- **Movement region:** left 62% of the lower 45% of the screen. The joystick appears at first touch, has a 110 px travel radius and returns to near-invisible when released.
- **Interact:** lower-right thumb zone, 180×180 px maximum touch target, inset 40 px from the right and 80 px from the bottom. Disabled state is hidden rather than presented as a dead button.
- **Bark:** 132×132 px touch target, placed above-left of Interact with at least 24 px visual separation. It uses an amber muzzle/ray symbol, not a sword, lightning bolt or cooldown dial.
- **Top status:** timer and carried bag remain in the top 88 px. Risk/desire content may use the band immediately below but cannot grow into the central action view.
- **World-safe centre:** no persistent control may cover x = 160–640, y = 190–930, where the dog, leash, owner and encounters need to read.

At the 405×720 window override, minimum physical touch targets are 74 px for Interact and 58 px for Bark after scaling. Labels must remain optional; icon silhouette and placement carry the first read.

## State model

| State | Bark | Interact | Movement |
|---|---|---|---|
| Free exploration | Quiet amber, available when Dog Agency is active | Hidden | Available |
| Search target nearby | Quiet amber | Appears with target-specific verb | Available |
| Seamless encounter | Brightens only when Bark can affect attention | Appears only for a valid intervention | Available |
| Bark resistance | One short muted ring, then returns to quiet | Unchanged | Available |
| Strong leash tension | No HUD meter; world leash and owner pose carry it | Unchanged | Available |
| Inventory/modal open | Hidden and releases held input | Hidden and releases held input | Hidden and releases held input |

## Visual language

- Movement uses neutral chalk-white rings at low opacity so it never competes with world scent.
- Bark uses warm amber and a muzzle/ray glyph. Its pressed response compresses to 92% and releases quickly.
- Interact uses a dark dog-tag shape with a warm off-white verb. Target rarity color may appear as a small edge notch, never as the whole button.
- Teal is reserved for dog-owner relationship cues and the leash; do not recolor Bark or the entire Interact button teal.
- No health bar, mana bar, skill slots, attack button, numeric leash meter or radial ability cooldown.

## Context priority

When several targets overlap, gameplay selects the nearest valid target. The HUD only displays that target's verb; it does not open a target list. Suggested verb hierarchy:

1. encounter intervention;
2. extraction when directly inside its interaction area;
3. search/sniff;
4. territory mark;
5. social/environment interaction.

The hierarchy is presentation guidance, not authority to change gameplay targeting rules.

## Acceptance checks

- A new player can move and use a nearby object with one hand without covering the dog.
- Bark and Interact are distinguishable by position and shape before color or text.
- The player can keep moving while pressing Bark or Interact with another finger.
- During combat, the controls do not obscure either leash anchor or resemble human combat commands.
- With no nearby target, the lower-right area does not show a large disabled Interact button.
- Desire scent, search scent, encounter corners, extraction beacon and controls remain separable in greyscale.

## Runtime handoff

Existing `TouchControls` already supplies the floating movement region and contextual Interact input. Engineering work needed after review:

1. add a distinct `bark` touch action;
2. hide Interact when it has no focus instead of only disabling it;
3. apply the selected dog-tag and amber-ray styles;
4. validate simultaneous joystick plus action input on a physical mobile device.

This document defines presentation and input affordance only. Dog Agency remains authoritative for whether Bark can affect a target, and the interaction system remains authoritative for target selection.
