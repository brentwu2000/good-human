# GOOD HUMAN! — 3D Encounter Presentation Spec v0.1

Status: REVIEW
Deliverable: ART-035
Target: dog-height 3D chase camera

## Intent

An encounter should read as a situation the dog can disrupt, not a combat arena or RPG target. The dog, owner and teal leash remain the primary composition. Presentation cues stay in world space and never pause exploration.

## Visual states

| State | Presentation | Purpose |
|---|---|---|
| Idle | Low-opacity broken amber corners | Makes a nearby pair legible without demanding action |
| Desire hint | Brighter, gently breathing amber corners | Connects the dog's current curiosity to the pair |
| Combat | Warm coral focus corners with a teal dog-side notch | Frames the human fight while retaining dog authorship |
| Beaten | No encounter framing | Removes visual noise after resolution |

## Impact feedback

- A successful hit produces five short coral directional rays for 0.22 seconds.
- A blocked hit uses teal rays so defense reads differently without text.
- Rays appear around torso height and expand once; they do not cover the dog, leash or HUD.
- Misses and dodges do not produce impact rays.

## Palette

- Attention amber: `#F2B84B`
- Combat coral: `#E6785F`
- Dog-agency teal: `#3D9B91`
- Resolved/muted: `#7E8681`

These colors communicate presentation state only. They must never reveal hidden combat power, encounter rewards or difficulty.

## Runtime integration

- Code-native art lives at `assets/fx/encounter/encounter_presentation_3d.gd`.
- `OpponentPair3D` owns the presentation and maps its existing state transitions to visual states.
- `CombatCoordinator3D` triggers impact feedback from existing `hit` and `blocked` events.
- Combat simulation, timing, damage, encounter data and player input are unchanged.

## Acceptance

- A pair is recognizable at normal dog-view distance without reading its name label.
- A desire-hinted pair is visually distinct from an ordinary pair.
- During combat, both humans, the player dog and the leash remain visually dominant over the framing effect.
- Hit and block feedback are distinguishable at mobile size.
- Presentation disappears after victory and returns to idle after disengagement or defeat.
- No effect resembles an arena wall, danger radius, stat aura or mandatory quest marker.
