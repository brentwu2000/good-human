# D4-11 — Combat Focus Composition v0.1

Status: REVIEW

Visual board: `assets/_source/design/dog_agency/combat_focus_composition_01.svg`

## Composition decision

During seamless combat, the camera continues to follow the player dog while composition gives the owner the visual focus. The opponent shares the owner's middle-distance plane. The dog stays controllable in the near foreground or near-side edge, and the teal leash remains the connective line between player intent and human consequence.

This composition supports ADR-014 as a prototype direction. It does not approve the camera system or change combat rules.

## Portrait frame hierarchy

| Layer | Subject | Target screen region | Read |
|---|---|---|---|
| Foreground | Player dog | lower 25–38%; may sit left or right of centre | movement author and emotional witness |
| Connector | Teal leash | dog harness to owner's near hand, visible for at least 60% of its length | relationship and pull direction |
| Focus plane | Owner | central 32–58% width, middle 35–62% height | primary emotional/combat focus |
| Conflict plane | Opponent human | 0.8–1.4 owner widths from owner | source of impact and threat |
| Secondary witness | Opponent dog | outer middle edge, never between owner and player dog | reaction and pair ownership |
| Background | Street/park/interactables | low contrast behind the focus plane | confirms combat remains in the Run World |

The owner's head and torso must stay out of the top status band and lower action controls. The dog may touch the lower action-safe region visually but its head, ears and harness cannot sit beneath a button.

## Left/right orbit proof

The player may circle either direction without the camera enforcing a preferred side.

### Dog on left foreground

- Owner sits just right of centre; opponent remains farther right or upper-right.
- Leash travels upward and inward, avoiding the owner's face.
- Opponent dog occupies the far-right edge or drops behind its human.
- Open movement space remains in the dog's leftward travel direction.

### Dog on right foreground

- Mirror the screen-space hierarchy, not the character poses.
- Owner sits just left of centre; opponent remains farther left or upper-left.
- Handed animations, clothing asymmetry and hit direction stay physically correct; do not mirror rendered characters merely to repair composition.
- Open movement space remains in the dog's rightward travel direction.

When the dog crosses behind the opponent, prefer a short neutral/wide composition over a rapid 180-degree camera swing. Re-establish the hierarchy after the angular dead-zone is crossed.

## Framing states

| State | Owner focus | Distance | Composition behavior |
|---|---:|---:|---|
| Tension | 0.55 | explore minus 5–8% | leash and both humans enter one readable diagonal |
| Snap | 0.75 | blend inward over 0.5–1.0 s | owner moves into focus region; never cuts |
| Active | 0.68 | stable combat distance | soft dead-zone absorbs dog strafing and circling |
| Crisis | 0.78 | up to 8% tighter | protect owner's full body and unstable footing |
| Resolution | 0.82 briefly | hold | show acknowledgement or downed-owner beat |
| Release | 0.30 → explore | blend outward | leash relaxes and world navigation regains priority |

Values are visual tuning targets, not gameplay constants.

## Impact compatibility

- Hitstop freezes the landed-contact pose; composition must already contain both torsos before the pause.
- Camera shake offsets the composed frame but must not push the owner outside the focus region.
- Damage-scaled knockback should expand along the owner–opponent axis, not toward the camera whenever a readable side direction is available.
- Coral hit rays and teal block rays remain torso-local. They cannot cover the dog or replace the physical contact pose.
- Heavy opening impact may momentarily widen the human separation; the leash remains the stable reference line.

## Occlusion priority

1. preserve the owner's head and torso;
2. preserve the player's dog head, harness and facing direction;
3. preserve both leash anchors and most of the leash line;
4. preserve the opponent torso and striking limb;
5. fade or reframe background geometry;
6. move the opponent dog toward the outer edge before hiding a primary subject.

Owner occlusion fade used during exploration must not erase the owner during combat focus. If the dog and owner overlap in projection, allow the dog to move toward the lower corner and use the owner's silhouette as the stable anchor.

## Failure conditions

- Rigidly centering the owner so every dog movement rotates the camera.
- Losing the player dog entirely for more than a brief foreground crossing.
- Letting the opponent dog read as the player's pair because it sits on the teal-leash side.
- Cropping feet so knockback, balance and DOWN states cannot be read.
- Routing the leash across either human face or through the impact point.
- Hiding nearby interactables with a combat vignette or arena boundary.
- Using a COMBAT START card, target lock, health-bar stack or cinematic letterbox.

## Mobile acceptance

At the 405×720 window override:

- left and right orbit frames read as the same relationship with reversed screen positions;
- owner, opponent, player dog and at least 60% of the leash are visible simultaneously;
- the owner's condition remains readable from full-body pose;
- hit/contact stays readable under shake without relying on text;
- joystick, Bark and contextual Interact regions do not cover the dog's head or either human torso.

## Handoff to D4-12 and P-02

D4-12 should storyboard the transition into this selected active frame: walk → tension → leash tighten → camera push/focus → first contact. P-02 captures should include clockwise orbit, counter-clockwise orbit and a behind-opponent crossing so D4-17 can measure angular velocity, subject loss and leash visibility against this sheet.
