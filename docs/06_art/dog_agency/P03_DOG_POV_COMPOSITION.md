# P03-D03 — Dog POV Composition Sheet v0.1

Status: REVIEW

Composition sheet: `assets/_source/design/dog_agency/p03_dog_pov_composition_sheet_01.png`

## Layout key

The sheet contains five dog-eye positions without printed labels:

| Sheet position | Dog position | Primary proof |
|---|---|---|
| top-left | Front | both full bodies, hands and feet readable |
| top-centre | Left flank | diagonal contact axis without body overlap |
| top-right | Right flank | reversed diagonal and correct rival-dog ownership |
| bottom-left | Behind opponent | owner face/torso protected past opponent foreground |
| bottom-right | Owner-side flank | owner large nearby, rival readable across an intervention lane |

These are composition targets, not fixed camera sockets. The player dog moves continuously between them.

## Shared frame contract

- Eye height remains approximately 35–45 cm above the ground.
- CombatCenter stays between the two active humans, biased modestly toward the owner.
- Owner is the emotional priority, but the opponent's striking torso/limb remains readable.
- Preserve both feet whenever balance, kick, dodge, stagger or Down depends on ground contact.
- Keep 15–25% of the horizontal frame available as a movement/intervention lane where practical.
- A small ear/muzzle edge may establish dog POV; it never becomes a permanent centre obstruction.
- Teal leash appears only when its relationship or tension matters and never crosses a face/contact point.
- Rival dog remains on the rival side of the composition or moves outward before it can confuse ownership.

## Position rules

### Front

- Default active-fight read and easiest mobile composition.
- Place humans on opposing thirds with full stance width.
- Keep the immediate foreground open for Bark, approach or retreat.
- Avoid flattening the fight into two symmetrical combat-idle statues; one body should lead the current action.

### Left flank

- Owner may move closer to the left/near plane while opponent sits deeper/right.
- Maintain a clear shoulder–hip–foot line for the active strike.
- If the teal leash enters frame, route it up the near edge rather than through the humans.

### Right flank

- Reverse the spatial hierarchy without mirroring character animation.
- Rival dog and dark leash stay on the opponent's outer side.
- Protect the owner's face from the opponent's back/shoulder overlap.

### Behind opponent

- This is the highest-risk occlusion case.
- Opponent back or shoulder may fill up to roughly one third of the frame, but cannot hide the owner's head and torso simultaneously.
- Shift CombatCenter toward the visible owner rather than lifting the camera above dog height.
- Preserve a peripheral escape lane; do not lock the camera between the opponent's legs or body.
- If occlusion persists, widen modestly before rotating aggressively.

### Owner-side flank

- Owner may be the large near-edge mass, reinforcing attachment and scale.
- Rival must remain fully readable across the open middle.
- Leave space along the teal-leash side for pull/intervention feedback.
- Do not allow owner clothing to fill more than half the frame or obscure the rival's attack anticipation.

## Auto-framing behavior

The camera follows dog position and only orients toward CombatCenter. It does not move the dog, rewrite locomotion input or force a preferred orbit.

Priority when the ideal two-body composition cannot fit:

1. owner head and torso;
2. active contact/windup limb;
3. player navigation lane;
4. opponent torso;
5. relevant leash segment;
6. feet;
7. rival dog reaction.

Feet rise above rival-dog visibility only when an active balance state needs them. During ordinary upper-body exchanges, a momentary foot crop is preferable to losing the owner's face or the player's escape direction.

## Rotation comfort

- Use a soft yaw/pitch dead zone around CombatCenter.
- Cap angular velocity and acceleration; a circling dog should see a stable fight, not a continuous pan.
- When crossing behind an actor, allow brief screen-space drift before correcting.
- Backing away widens framing before it increases rotational urgency.
- Approaching clamps near-plane body size so a human cannot fill the entire screen.
- Wall collision or fade cannot produce a vertical jump that breaks dog-eye scale.

## Leash and intervention compatibility

- Slack leash may leave the combat view.
- Tension/max tension re-enters through a lower corner with a physically traceable direction.
- Bark reaction turns the affected head/upper body toward the dog/camera without forcing the camera to centre that face.
- Pull reaction should move the owner's balance line laterally within frame; camera lag must be sufficient for the displacement to read.
- Nearby interactables remain peripheral world objects, not target markers over the fighters.

## Mobile acceptance

At 405×720, test all five positions while stationary and moving:

- viewer identifies owner and opponent without labels;
- attack anticipation and contact remain readable;
- player can infer a forward/side/back movement escape route;
- camera does not oscillate when the dog strafes through the dead zone;
- behind-opponent framing never loses owner head and torso together;
- rival dog never reads as attached to the teal player leash;
- no human fills more than approximately 70% of screen height during normal active combat.

## Runtime handoff

P03-E04/E05 should expose capture telemetry for dog bearing relative to CombatCenter, target/current yaw and angular velocity. P03-D10 must capture the five sheet positions at the mobile window override, plus transitions front→left→behind and front→right→owner-side. Failures should be annotated against subject loss, occlusion, leash ambiguity, navigation loss or excessive angular correction.

## Generation record

Generated with the built-in OpenAI image tool using P03-D01 to lock realism, characters, clothing, lighting and materials, and P03-D02 to lock dog-eye height and identity continuity. No third-party asset was imported.
