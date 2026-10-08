# How people hold the improvised weapons — reference

Owner, 2026-10-09: 「拿武器的樣子不符合現實拿物品的樣子，請去找參考再回來做」. Collected before reworking the grips in `tools/art/make_fight_clips.py`. The old dumbbell is training kit, not a weapon (owner, same day), so it is not covered.

## What was wrong

- Every hand in every fight clip was **open**: the clips posed the hand bone but never the fingers.
- A held prop was fixed **along the hand bone** (out past the fingertips), so in the raised guard the umbrella stood up from the fingertips like a torch, and nothing was ever gripped.
- The broom was held in **one hand halfway along the handle**.

## Reference

| Thing | How it is really held | Source |
|---|---|---|
| Stick / umbrella | In the hand "with the thumb overlapping the fingers, and not, as in single-stick or sword-play, with the thumb resting on the blade"; manipulated with the wrist, and "the blows are given by swinging the body on the hips". Front guard: arm extended. Almost every walking-stick technique works unaltered with an umbrella. | Barton-Wright, *Self-Defence with a Walking Stick* (Bartitsu) — [sirwilliamhope.org](https://sirwilliamhope.org/Library/Bartitsu/stick/stick_1.html); [Bartitsu Society, umbrella self-defence](https://bartitsusociety.com/are-you-in-danger-a-curious-article-on-umbrella-self-defence-1900/) |
| Stick (general) | Held about a fist from the butt and closed with the thumb. (Our reading, for the rig: in that closed hand the shaft runs across the palm and leaves the fist between thumb and index, well off the line of the fingers.) | Arnis basics — [slideshare](https://www.slideshare.net/slideshow/fundamental-skills-in-arnis/130334147) |
| High guard | The hand held above the head, the stick slanting down across the front (Vigny's guards), keeping the hand away from blows. | [Bartitsu Society](https://bartitsusociety.com/?p=1217) |
| Broom | "Two handed, wide spaced" grip; best used like a short bayonet — "thrusting techniques actually are best suited for the broom with occasional short chopping motions". | [MartialTalk, "broom-fu"](https://www.martialtalk.com/threads/im-gonna-create-broom-fu.78871) |
| Fists | Empty hands punch with closed fists, thumb outside. | (common) |

## What the game does now

- **Fingers close**: every fight clip curls the fingers — a fist when empty-handed, round a ~3 cm shaft when holding something, the thumb swung across over the fingers. Each finger bends about one fixed hinge (a knuckle is a hinge).
- **Through the fist**: the shaft runs through the curled fingers. Its axis and centre are measured from the curled middle finger and written to `assets/characters/human/animations/p04_fight_grip.json`; Godot (`WeaponProp3D.grip`) mounts the prop there, and the clips turn the hand so that axis points where the weapon should.
- **Umbrella** (one hand, walking-stick style): front guard with the arm forward and down, the point lifted at the other person's face; thrusts off a straighter arm; cuts from high, driven by the hips; a hanging high guard to block.
- **Broom** (two hands, short-bayonet style): lead hand in front of the belly, rear hand on the shaft at the right hip, head forward; thrust with both hands as the main blow, a chop from overhead, a shove with the shaft up close; the shaft raised across the face to block.
- **On the walk**: Codex's relaxed Idle/Walk with the lead hand closed round it — the umbrella point-down like a walking stick, the broom round the middle, head down.

Previews: `blender -b --factory-startup --python tools/art/preview_fight_hands.py -- <out dir>`. Checks: `tests/weapon_test.gd` (`_test_grip`, and the drawn reach of every thrust).
