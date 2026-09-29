# D4-18 — Human Combat Motion Language v0.1

Status: REVIEW · 2026-09-28 · Codex ART

Companions: [8-second footwork board](P04_FOOTWORK_BOARD_01.md), [contact frames](P04_CONTACT_FRAMES_01.md). Extends P03-D04; earlier D4 work remains authoritative where not explicitly refined here.

## Direction

Ordinary people under pressure, in a materially believable neighborhood. Exaggerate separation between limbs, anticipation and balance recovery enough to read at dog height; preserve natural proportions. Clothing does not identify combat strength. These are presentation proposals, not new combat rules or implemented animation clips.

## Pose vocabulary

| Action | Preparation / silhouette | Weight and action | Recovery / distinguishing read |
|---|---|---|---|
| Combat Idle | Uneven open guard; elbows separated from ribs | Soft knees, weight between staggered feet; small breathing | No continuous bouncing; head tracks opponent independently |
| Approach | Chest remains oriented toward opponent | Lead foot advances, trailing foot restores stance; no crossed legs | Decelerate before attack; do not glide into a planted pose |
| Circle | Open negative space between legs | Step toward travel direction, follow with other foot; hips turn progressively | Maintain facing without spinning both feet in place |
| Backstep | Pelvis initiates retreat; guard stays up | Rear foot creates space, front foot follows | Settle before striking; distinguish from involuntary stagger |
| Jab | Small lead-shoulder anticipation | Lead foot supports short extension; rear hand remains readable | Hand retracts along short path; little torso overshoot |
| Heavy Hook | Rear shoulder and hip wind away; bent striking elbow | Hip rotation leads shoulder; rear heel pivots, front knee accepts load | Longer unwind; miss carries shoulder past target line |
| Kick | Support foot and bent striking knee readable before extension | Low torso-height strike, pelvis turns, torso counterbalances | Replant striking foot before stance resumes; no floating pivot |
| Block | Two forearms protect head/upper ribs, elbows compact | Force stops at guard; shoulders compress, feet absorb | Guard releases without torso snapping backward like a direct hit |
| Dodge | Chest and pelvis shift together off attack line | Receiving foot plants diagonally; head keeps opponent in view | Opponent-facing recovery; no contact accent on a successful dodge |
| Hit Light | Contact-side shoulder/ribs yield | Local compression, base largely retained | One settle; no involuntary full turn or flight |
| Hit Heavy | Contact compresses before translation | Torso and pelvis react with a short lag; centre leaves old base | Catch step required; support foot remains understandable |
| Stumble | Guard breaks asymmetrically | Foot searches ahead of displaced weight; shoulders lag | One or two uneven catch steps; may recover if simulation permits |
| Down | Knees soften and one hand reaches toward floor | Knee/hip/hand sequence lowers body, never rigid plank rotation | Broad bent side pose, face and dog approach lane readable |

## Timing and transitions

- Author anticipation, extension/contact, follow-through and recovery as separate readable phases. Relative starting targets: Jab 25/20/55%; Heavy Hook 35/15/50%; Kick 35/20/45%. Percentages describe the existing action duration; they do not change it.
- Block absorbs at contact; direct Hit Light compresses the torso; Hit Heavy breaks balance. Never use one generic backward lean for all three.
- A miss follows through through empty space, then catches balance. It must not trigger receiver recoil, contact FX or a contact pause.
- Interruptions start from the current pose. Down overrides action; a confirmed impact can interrupt recovery according to existing simulation authority.
- HEALTHY recovers cleanly; HURT adds protective asymmetry; CRITICAL delays balance settling. These layers yield during contact and do not alter reach or outcome.

## Handoff contract

Preserve reachable `Hips`, `Torso`, `Head`, `ArmL`, `ArmR`, `LegL`, `LegR` for any future human asset integration. This pass does not replace the human mesh or edit gameplay.

Simulation owns movement, collision, hit result, action duration and damage. Animation follows the actual pair spacing and ground plane. Pose warping is limited to plausible reach; if contact cannot be reached, flag the mismatch instead of stretching arms or teleporting feet. Never apply authored root travel on top of simulation travel twice.

Expose presentation phase markers for anticipation, contact, recovery and settled stance. Markers visualize a resolved event; they do not adjudicate it. Plant feet during their support interval, lift before translating, and release the plant when collision movement forces a correction.

## Review gates — not yet runtime-tested

At 405×720, with labels/HP/FX hidden, inspect front-oblique, side and rear-oblique clips. Jab/Hook/Kick should be distinct before contact; Block/Dodge/Hit distinct at outcome; Stumble/Down distinct after impact. Check shoe contact, nonpenetrating hands and support knees frame by frame. A still board cannot validate timing, root motion or camera occlusion; those remain required after implementation.
