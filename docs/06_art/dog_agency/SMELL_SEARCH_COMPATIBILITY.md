# Sprint 04 — Smell / Search Compatibility v0.1

Status: REVIEW
Deliverable: D-09

## Channel separation

| Cue | Color family | Height / location | Motion | Meaning |
|---|---|---|---|---|
| Bark | Warm amber | Near dog muzzle | One short directional burst | Dog emitted attention |
| Leash | Teal | Physical collar-to-hand connection | Sag / straighten | Dog-owner relationship |
| Search rarity scent | Item rarity color | Directly above searchable prop | Gentle vertical breathe | Something may be found here |
| Desire / strange scent | Dusty violet or mint | Low, ground-tracing path | Drift toward world target | Dog curiosity / remembered trail |
| Encounter focus | Coral broken corners | Ground around pair | Low pulse during fight | Current human conflict |
| Territory ownership | Teal/coral root scent knots | Attached to Banyan roots | Mostly static repetition | Repeated relationship with place |
| Extraction | Muted grey → green | Paw beacon at safe exit | State change, no pulse spam | Going home is available |

## Conflict rules

- Bark feedback lasts under one second and may overlap any state because it originates at the dog.
- Search rarity scent stays anchored to the object; desire scent travels across the ground. Shape and placement must distinguish them before color.
- When a desire points to a searchable object, do not add a second marker on the object. Use the desire card/off-screen nose arrow plus the existing object scent.
- Encounter ground corners must leave the centre clear so a nearby scent trail can pass through without becoming a target ring.
- Territory scent knots attach to roots and never animate like a trail until Mark is explicitly played.
- Extraction green communicates availability only; it must not recolor the whole scene or suppress temptation cues.

## HUD compatibility

- Primary Desire Card occupies the upper safe area below timer/bag.
- Risk tag shares that upper region but remains a single short line and hides when empty.
- Bark and Interact remain contextual lower-right controls; neither uses scent colors as its idle state.
- Off-screen nose arrow hides once the target is near enough to read through world cues.
- Toasts are temporary outcomes. They never become persistent instructions or cover the primary desire card for more than one message cycle.

## Mobile acceptance

- At 405×720, Bark amber, teal leash, violet desire scent and object rarity scent remain distinguishable in greyscale by position and motion.
- A player can search during combat without mistaking encounter framing for the searchable target.
- A territory scent, an active desire and an available exit may coexist without any one becoming a full-screen alert.
