# P03-D02 — Tension / Confrontation Storyboard v0.1

Status: REVIEW

Storyboard: `assets/_source/design/dog_agency/p03_tension_confrontation_storyboard_01.png`

## Sequence

The four frames show one uninterrupted escalation from an ordinary walk into dog-eye combat framing. No strike lands in this sequence.

| Frame | Phase | Target duration | Visual event | Camera event | Audio / atmosphere |
|---|---|---:|---|---|---|
| 1 | Explore | open-ended | Player dog follows owner; rival pair reads ahead as part of the park | third-person dog-height chase, dog fully visible | normal park bed, footsteps, loose leash hardware |
| 2 | Notice | 0.3–0.7 s | dogs lock attention; owner pauses; leash sag begins to lift | lowers behind ears and biases toward encounter | ambience begins to duck; breath and collar detail enter |
| 3 | Confrontation | 0.5–1.0 s | both leashes pull taut; rival dog vocalizes; humans close and brace | advances and lowers while preserving both pairs | growl/bark, shoe scrape, leash hardware tension |
| 4 | Combat Snap | 0.35–0.8 s | dogs remain causal; humans enter readable pre-contact guards | reaches dog-eye first person and settles on CombatCenter | restrained low pulse enters; no impact sound yet |

Durations are presentation targets and may compress when the encounter starts at close range. Gameplay remains authoritative for engagement and dog input.

## Continuity lock

- Player owner: ordinary light tan jacket, charcoal shirt, blue denim and worn light sneakers.
- Rival human: dark cap, dark jacket, grey shirt and dark trousers.
- Player dog: warm brown-and-white coat; teal harness/leash.
- Rival dog: black-and-tan coat; dark collar/leash.
- Environment: the same park path, trees, benches and late-afternoon sun direction.

Production assets may refine exact faces or breed, but all four frames in any implementation capture must maintain identity, clothing, leash ownership and travel direction.

## Camera transition

The camera path is a descending forward curve rather than a cut:

1. begin behind and above the player's dog;
2. lower until ears enter the lower frame;
3. advance as the dogs and leashes form the foreground conflict axis;
4. settle at eye height with only a restrained muzzle/ear edge if it improves identity.

FOV changes gradually. Human scale should increase primarily through camera movement, not lens distortion. Avoid a sudden fisheye effect at the fourth frame.

## Leash storytelling

- Frame 1: player leash hangs with visible slack.
- Frame 2: the upper curve lifts as owner and dog attend to different subjects.
- Frame 3: teal and dark leashes create opposing diagonals without crossing faces.
- Frame 4: player leash may enter the lower edge only when tension remains meaningful; it cannot divide the human fight.

The leash is physical relationship evidence, not a meter or attack effect.

## Performance beats

- Player dog notices before the humans fully commit.
- Owner reaction is ordinary and slightly uncertain—not a trained fighting stance in Frame 2.
- Rival dog supplies the clearest first outward escalation through stare, lowered weight and bark/growl.
- Human guards form only by Frame 4, immediately before active motion begins.
- Background witnesses may stop or look, but must not become additional encounter participants.

## Transition failures

- Entering first person before a rival pair is readable.
- Cutting or teleporting between frames.
- Humans adopting combat idles while both dogs remain relaxed.
- Starting impact sound, camera shake or hit rays before contact.
- Losing either leash relationship during confrontation.
- Treating Bark as a floating word or conventional skill effect.
- Allowing the foreground ears/muzzle to obscure feet, hands or CombatCenter.

## Mobile acceptance

At 405×720:

- each phase is distinguishable without labels or UI;
- the same two humans and two dogs remain identifiable across frames;
- human scale increases smoothly from Explore to Combat Snap;
- both leash relationships read in Frames 2 and 3;
- Frame 4 leaves sufficient peripheral space for Bark, pull, flank and retreat;
- no frame reads as a scene transition or loss of dog control.

## Runtime handoff

P03-E04/E05/E06 should use the four frames as checkpoints for camera height, dog visibility, CombatCenter acquisition and transition pacing. P03-D10 captures should include the same encounter from rest, close-start and player-circling cases to verify the camera still reaches the fourth-frame composition without a violent correction.

## Generation record

Generated with the built-in OpenAI image tool using the owner-supplied P-03 storyboard for narrative/camera beats and P03-D01 for realism, characters, lighting, materials and palette. No third-party asset was imported.
