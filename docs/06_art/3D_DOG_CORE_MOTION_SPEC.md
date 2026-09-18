# GOOD HUMAN! — 3D Dog Core Motion Spec v0.1

Status: REVIEW
Deliverable: ART-037
Target: player Shiba prototype in the dog-height 3D slice

## Motion language

The player dog leads with its nose, chest and ears. Motion should feel eager and curious rather than disciplined or mechanical. Animation changes visual transforms only; movement speed, collision and interaction timing remain owned by `DogController3D`.

| Motion | Driver | Visual read |
|---|---|---|
| Idle | Ground speed below 0.25 m/s | Small breathing arc, asymmetric head drift, loose curled-tail motion |
| Walk | Ground speed above 0.25 m/s | Readable diagonal gait, light body bob, nose leading the chest |
| Run | Sprint input or speed above 4.2 m/s | Larger compression/extension, stronger stride and stabilizing tail |
| Sniff | World interaction | Head and muzzle lower toward the ground while paws make small corrective steps |

## Construction

- `Greybox.dog()` exposes stable names for Body, Head, Muzzle, four legs and tail pieces.
- `DogMotion3D` records each part's authored transform and restores it before evaluating every frame, preventing cumulative drift.
- The controller reads planar speed and sprint state, then selects the visual motion.
- Sniff is a short overlay triggered by the existing interact input and does not delay the interaction.

## Acceptance

- Idle, walk and run remain distinct at the default chase-camera distance.
- Walk and run show alternating diagonal leg pairs rather than whole-body sliding.
- Sniff keeps the Shiba head silhouette recognizable while lowering the nose.
- Harness and collar position remain stable enough for leash readability.
- Changing motion never changes velocity, collision, input timing or interact range.
- No body part accumulates transform drift during extended play.

## Upgrade path

This is the motion baseline for the code-native prototype. An imported S-level rig should preserve the same state contract and motion character while replacing procedural part rotation with authored animation clips.
