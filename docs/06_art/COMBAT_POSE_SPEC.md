# GOOD HUMAN! — Combat Pose Spec v0.1

Status: `REVIEW`  
Visual reference: `assets/characters/human/concepts/owner_combat_pose_study_01.png`

## Intent

The player's owner fights like an ordinary person under pressure, not a trained martial artist. Silhouettes must remain readable and mechanically honest, while clothing and body type continue to conceal true combat power.

## Pose Mapping

| Pose | Runtime use | Existing `FighterPuppet` call |
|---|---|---|
| Neutral | Default combat loop and recovery | `_reset_pose()` |
| Punch | Full-extension strike key | `play_strike()` with `animation_key = "punch"` |
| Kick | Impact key with planted support foot | `play_strike()` with `animation_key = "kick"` |
| Block | Active guard silhouette | `set_guard(true)` / `animation_key = "block"` |
| Dodge | Backward evasion key | `play_evade()` / `animation_key = "dodge"` |
| Hit reaction | Unblocked damage response | `play_hurt(false)` |
| Defeat | Persistent down state | `play_down()` / `set_beaten(true)` |

## Production Rules

- Preserve glasses, backpack, hair, beard, outfit colors, cuffed jeans, and shoe design in every frame.
- Author upright frames at approximately 210 px visible height in a fixed 256×240 transparent cell.
- Ground point is the midpoint between the planted feet. Do not recenter around the torso.
- The defeat cell may use 320×160 but must retain the same ground origin when placed by the puppet.
- Horizontal mirroring is allowed only after verifying backpack straps, hair part, and leading limbs remain visually acceptable.
- Do not add weapons, gloves, a uniform, aura, or effects that imply profession or power level.

## Integration Plan

1. Extract and clean seven transparent key-pose frames from the study.
2. Add optional combat art resources to the player `FighterData` only.
3. Keep current Polygon2D puppet as fallback for opponents without finished art.
4. Route existing `FighterPuppet` presentation calls to sprite poses without changing combat simulation logic.
5. Validate facing, ground stability, HP UI, hit popups, and defeat persistence in the combat arena.

## Engine Integration v1

The player owner's seven key poses are integrated through optional `FighterData.combat_sprite_frames`:

- production frames live under `assets/characters/human/sprites/owner_combat_v1/`;
- every frame uses a transparent 320×240 canvas and common ground alignment;
- `FighterPuppet` routes its existing presentation calls to neutral, punch, kick, block, dodge, hit, and down poses;
- combat simulation, damage, timing, and AI remain unchanged;
- fighters without combat sprite art continue to use the original Polygon2D puppet fallback;
- the exploration owner hides the whole combat puppet in `FOLLOW` and restores it for `COMBAT` and `DOWN`.

This is a playable key-pose integration. It remains in `REVIEW` because anticipation, impact, recovery, and transition in-betweens are not final S-level animation.
