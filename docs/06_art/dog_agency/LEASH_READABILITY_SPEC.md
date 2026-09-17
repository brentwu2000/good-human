# GOOD HUMAN! — 3D Leash Readability Spec v0.1

Status: REVIEW

## Runtime thresholds

The existing gameplay thresholds remain authoritative. Art only communicates them:

- `slack_length`: visible sag and normal follow.
- Past slack: curve tightens and the owner starts leaning.
- Past `max_length`: near-straight teal line, owner reacts.
- Bad sideways/toward-fight pull: short stumble recoil.
- Sustained away pull: owner is visibly dragged out of the engagement.

## Implementation guidance

- Keep leash thickness at approximately 0.035–0.045 m in the 3D slice.
- Use a teal material with a warm highlight at strong tension; do not change hue by hidden stat.
- Keep the line smooth and slightly sagged when slack; avoid a rigid laser line.
- Owner hand and dog collar anchors must remain readable even while either character fades for camera occlusion.
- Tension feedback belongs to the world relationship, not the HUD. A short owner vocal bubble may supplement a reaction but must not replace the leash silhouette.

## Acceptance checks

- A player can distinguish slack, light, strong and dangerous tension at dog-view distance.
- Leash does not disappear behind the owner during normal follow.
- Combat framing keeps dog, owner and leash in one readable composition.
