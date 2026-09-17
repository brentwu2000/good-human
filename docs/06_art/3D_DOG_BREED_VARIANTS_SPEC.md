# GOOD HUMAN! — 3D Dog Breed Variants Spec v0.1

Status: REVIEW  
Target: dog-height 3D chase camera

## Identity rule

The player dog is a fixed Shiba-like companion: compact body, pointed ears, upright curled tail, cream/tan face, and teal harness. Its silhouette must remain identifiable before color is read.

NPC dogs use an appearance-only `EncounterData.dog_breed` value. Breed never changes combat stats, bark range, AI or rewards.

| Variant | Current use | Silhouette cues |
|---|---|---|
| MIX | Delivery dog | medium body, neutral ears and straight tail |
| SHIBA | Player dog / jogger | compact body, pointed ears, curled upright tail |
| PIT | Gym dog | broad chest, blockier head, short ears, low stance |
| SMALL_WHITE | Old Master dog | small round body, shorter ears, compact legs, white fluff cue |
| BLACK_DOG | Rival 阿黑 | lean longer legs, pointed ears, dark silhouette |

## Runtime integration

- `Greybox.dog(color, scale, breed)` generates the variant geometry.
- Player `DogController3D` requests `SHIBA` explicitly.
- `OpponentPair3D` passes the encounter's `dog_breed` to the same generator.
- Existing 2D behavior and art remain unchanged while the 3D slice is evaluated.

## Acceptance

- Five dogs are distinguishable in a single dog-height scene without name labels.
- Color supports recognition but does not carry the entire identity.
- NPC variants remain readable during owner fade and combat camera pullback.
