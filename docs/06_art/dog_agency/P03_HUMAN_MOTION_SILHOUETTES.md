# P03-D04 — Human Motion Silhouettes v0.1

Status: REVIEW

Motion sheet: `assets/_source/design/dog_agency/p03_human_motion_silhouettes_01.png`

## Layout key

| Sheet position | State | Required read |
|---|---|---|
| top-left | Punch contact | shoulder/hip lead, planted base, full extension |
| top-centre-left | Kick contact | one planted support foot, hip commitment, counterbalanced torso |
| top-centre-right | Block | compact protection of head/ribs, stable feet |
| top-right | Dodge | centre of mass leaves attack line, recovery foot available |
| bottom-left | Light hit | localized recoil, still capable and grounded |
| bottom-centre | Heavy stagger | large balance loss, recovery step required |
| bottom-right | Down | broad low collapse, face/profile and approach lane preserved |

The board fixes silhouette intent and material quality. It is not a literal animation sprite sheet.

## Motion principle

The owner is an ordinary person under pressure. Movement must be mechanically readable without looking trained, athletic by default or choreographed for spectacle.

Every attack follows:

1. perceive / choose;
2. plant or shift weight;
3. wind up with readable direction;
4. accelerate the striking mass;
5. form a clear contact pose;
6. recoil / follow through;
7. recover balance into the current condition state.

Skipping weight preparation makes attacks feel like limb-only animation. Skipping recovery makes humans feel mechanical and removes the dog's intervention window.

## Punch

- Rear heel and hip begin the action before the fist.
- Shoulder travels with the arm; do not detach the hand from torso mass.
- Contact silhouette preserves a readable bend in the non-striking arm.
- Head remains oriented toward the opponent but is not locked perfectly level.
- Light punch recovery is short; a missed heavy punch carries the torso farther past centre.

Target phase ratio: windup 30%, strike/contact 20%, recovery 50%. Simulation timings remain authoritative.

## Kick

- Support foot plants before the striking leg leaves the ground.
- Pelvis rotates and torso counterbalances; arms react asymmetrically.
- Contact should read from dog height without lifting the foot above the opponent torso.
- Recovery is visibly longer than Punch and briefly narrows balance.
- A miss continues through follow-through; it cannot snap back to idle.

Target phase ratio: windup 35%, strike/contact 20%, recovery 45%.

## Block

- Hands protect head and ribs without forming a professional boxing shell.
- Elbows and shoulders absorb contact; torso compresses slightly behind the guard.
- Feet remain available for a small reactive step.
- Block reaction must differ from Light Hit: force stops at the guard rather than entering the torso.
- Teal block accent remains secondary to the physical absorption pose.

## Dodge

- Move chest and pelvis off the attack line, not only the head.
- One foot clearly receives weight while the other prepares recovery.
- Preserve opponent-facing awareness; do not rotate into a full retreat unless gameplay disengages.
- Dodge carries no hitstop, coral rays or body compression.
- Return path cannot cross through the opponent's collision space.

## Light hit

- Reaction stays localized near the contact region.
- Both feet mostly retain the ground; one knee or shoulder yields.
- Recovery returns through the current HEALTHY/HURT/CRITICAL base pose.
- Avoid full-body spin, airborne recoil or DOWN silhouette.

## Heavy stagger

- Contact breaks the current base and sends weight outside the original stance.
- A recovery step or near-fall makes the magnitude visible.
- Head, shoulders and hips do not recoil as one rigid unit.
- The pose remains standing and distinguishable from DOWN.
- Camera impulse and hitstop reinforce the moment but cannot replace the balance loss.

## Down

- Fall begins from the last impact direction when space allows.
- Knees, hip, hand or shoulder break the fall in an uneven sequence.
- Final pose is broad, low and non-rigid; avoid rotating the whole mesh like a plank.
- Face/profile remains visible for the dog's approach and owner–dog emotional beat.
- Leash anchor follows the lowering hand and relaxes along the ground.

## Condition layering

HEALTHY, HURT and CRITICAL modify anticipation and recovery, not the honest contact pose:

- HEALTHY finds stance cleanly.
- HURT protects one side and takes an extra settle after recovery.
- CRITICAL shows unstable feet, delayed head reacquisition and a two-part balance catch.
- DOWN overrides every state.

Condition offsets must yield during contact windows so attacks, blocks and hits remain mechanically legible.

## Dog POV readability

- Foot placement is a first-class cue because the camera looks upward from 35–45 cm.
- Preserve negative space between legs where possible; overlapping trousers can hide balance.
- Hands must silhouette against torso or sky/background, not disappear into jackets.
- Avoid attacks aimed directly down the camera axis when a slight side angle can show extension.
- Close humans may crop above the head only in extreme approach; hands, torso and support feet remain the priority.

## Runtime handoff

Map the sheet to `IDLE_COMBAT`, `WINDUP`, `ATTACK`, `BLOCK`, `DODGE`, `HIT_REACT`, `STAGGER`, `DOWN` and `RECOVER`. Authored animation should use root/foot motion intentionally; procedural knockback remains presentation support rather than the sole reaction. Data owns exact timings and damage. Animation events expose windup onset, contact, recovery start and grounded completion without deciding whether a hit succeeds.

## Mobile acceptance

At 405×720 with combat text and HP hidden:

- Punch and Kick are distinguishable before contact;
- Block cannot be mistaken for Light Hit;
- Dodge clearly leaves the attack line;
- Light Hit, Heavy Stagger and Down form an unambiguous magnitude ladder;
- no action loses both support-foot information and striking/contact limb;
- clothing and accessories follow motion without hiding hands, face or balance;
- first-time viewers can order the seven states after two-second clips.

## Generation record

Generated with the built-in OpenAI image tool using P03-D03 as the character identity, outfit, realism and low-camera reference. No third-party asset was imported.
