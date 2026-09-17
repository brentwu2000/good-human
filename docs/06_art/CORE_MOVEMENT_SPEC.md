# GOOD HUMAN! — Core Movement Spec v0.1

Status: `IN_PROGRESS`  
Visual reference: `assets/characters/movement/core_movement_keyposes_01.png`

## Engine Integration v1

The first playable art pass is integrated in `actors/dog/dog.tscn`:

- transparent 192×128 fixed-cell frames under `assets/characters/dog/sprites/player_dog_v1/`;
- one-frame `idle` and four-frame `walk` animations on `AnimatedSprite2D`;
- visible dog silhouette height of approximately 112 px;
- speed-driven Idle/Walk switching in `dog_controller.gd`;
- leash attachment offset to the teal harness area;
- original Polygon2D greybox retained but hidden as a fallback.

The first owner exploration pass is integrated in `actors/human/human_follower.tscn`:

- transparent 224×240 fixed-cell frames under `assets/characters/human/sprites/owner_v1/`;
- one-frame `idle` and four-frame `walk` animations at approximately 210 px visible height;
- speed-driven Idle/Walk switching and horizontal facing;
- exploration sprite shown in `FOLLOW`, with the existing `FighterPuppet` restored for `COMBAT` and `DOWN`;
- speech bubble and leash hand anchor repositioned for the taller production-art silhouette.

This is a production prototype. The walk uses three unique key poses and one repeated frame; it must be replaced by a cleaned eight-unique-frame loop before `ART-004` or `ART-016` can enter `REVIEW`.

This sheet establishes silhouette, weight, and motion character. It is not an import-ready spritesheet. Production animation still requires consistent cell bounds, completed in-betweens, cleanup, transparent backgrounds, and engine validation.

## Shared Rules

- Author at the baseline sizes in `DOG_HUMAN_SCALE_GUIDE.md`: dog 112 px and human 210 px visible height in the 720×1280 viewport.
- Keep the ground contact point stable inside a fixed cell. Movement comes from pose change, not uncontrolled sprite drift.
- Use a consistent 3/4 top-down gameplay angle for all directional sets.
- The dog leads with nose, chest, and ears. The owner follows with delayed shoulders and backpack overlap.
- Preserve the dog's teal harness and the owner's glasses, sage overshirt, cuffed jeans, shoes, and backpack in every frame.
- Mirror only after checking asymmetric details. The dog's facial markings, harness hardware, backpack straps, and owner hair part must remain intentional.

## Proposed Loops

| Animation | Production frames | Playback | Loop | Motion character |
|---|---:|---:|---|---|
| Dog Idle | 6 | 8 fps | Yes | Small breathing arc; ears and tail offset by one frame. |
| Dog Walk | 8 | 12 fps | Yes | Eager four-beat gait; head slightly leads the chest. |
| Dog Run | 8 | 16 fps | Yes | Clear compression and extension; tail stabilizes the silhouette. |
| Dog Sniff | 8 | 10 fps | Yes | Nose traces a small uneven arc; paws take tiny corrective steps. |
| Human Idle | 6 | 8 fps | Yes | Subtle breathing and weight shift; backpack settles late. |
| Human Walk | 8 | 12 fps | Yes | Slight hesitation, ordinary stride, relaxed arm swing. |

## Contact and Silhouette Checks

- Dog walk must include two distinct contact poses and two passing poses.
- Dog run must include compression, launch, extended airborne, and landing poses.
- Sniff keeps the nose close to the ground without collapsing the readable head silhouette.
- Human heel strike and toe-off must be distinct; avoid foot sliding.
- Keep at least 3 px of clear separation between overlapping limbs at baseline display size where anatomy allows.
- Test every loop at 100%, 50%, and 33% display scale before approval.

## Remaining Work Before Review

1. Draw missing in-betweens for all six loops.
2. Normalize each character to fixed transparent cell bounds.
3. Produce right, up-right, up, and mirrored directional variants as required by gameplay.
4. Verify leash attachment positions against dog harness and owner hand throughout locomotion.
5. Export engine-ready sheets and test ground-point stability in motion.
