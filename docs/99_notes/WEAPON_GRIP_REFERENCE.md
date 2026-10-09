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
- **On the walk**: Codex's relaxed Idle/Walk with the lead hand closed round it — the umbrella point-down like a walking stick, the broom shouldered, its head resting back over the shoulder.

Previews: `blender -b --factory-startup --python tools/art/preview_fight_hands.py -- <out dir>`. Checks: `tests/weapon_test.gd` (`_test_grip`, and the drawn reach of every thrust).

## Compared with other games (owner, 2026-10-09: 「請再研究一下其他遊戲手拿武器的方式，對照你做的動作」)

| Principle (source) | How games do it | Before | Now |
|---|---|---|---|
| Arc ([MoCap Online, sword/melee guide](https://mocaponline.com/blogs/mocap-news/sword-melee-animation-guide)) | Swings travel a curved path; fastest at ~60–70 % of the arc | hand went straight from wind-up to strike | a mid key bows the path; ease accelerates into the strike |
| Wrist snap (same) | The weapon lags the hand, then snaps through at the peak | weapon turned with the hand | at the mid key the weapon has turned only ~35 % of the way, then snaps |
| Follow-through (same) | Momentum carries 30–60° past the target; heavy weapons further | stopped dead at the strike | `follow` pose past the target before recovery (cut to the far hip, chop towards the ground, sweep on round) |
| Weapon trail (same) | On at swing start, off when the follow-through slows | none | `WeaponTrail3D` ribbon from the tip, 0.38–0.6 of the clip, fades in 0.14 s |
| Hit stop (same) | 1–4 frames frozen on a hit | already (`_punch_landed`) | — |
| Two-handed weight (same) | Full trunk rotation drives the swing; off-hand stays on the weapon ([weapon systems guide](https://mocaponline.com/blogs/mocap-news/weapon-animation-systems-guide)) | rear hand on the shaft, little trunk turn | sweep and chop turn and fold the trunk |
| Idle with a weapon (same) | Weapon-specific: rested on a shoulder, leaned on, grip adjusted | broom hanging from one hand | broom shouldered on the walk; umbrella point-down like a cane |
| Long weapons' moves ([Sifu weapons guides](https://earlyguides.com/sifu/weapons)) | Brooms/staffs: reach, sweeping blows that catch several people, stagger | the "sweep" skill played the overhead chop | its own low sweep at the legs (`Fight_Sweep_Long`, animation key `sweep`) |

Built by `strike()` in `tools/art/make_fight_clips.py`; seen in `tests/capture/weapon_showcase.tscn`.
