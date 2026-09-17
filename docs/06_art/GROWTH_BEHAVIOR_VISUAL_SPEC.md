# GOOD HUMAN! — Growth Behavior Visual Spec v0.1

Status: `REVIEW`  
Visual reference: `assets/characters/human/concepts/owner_growth_behavior_study_01.png`

## Principle

Human growth is shown through changed behavior, not a stronger-looking body or upgraded costume. The owner keeps the same silhouette, clothes, backpack, face, and apparent combat power. Animation changes timing, balance, recovery, gaze, and willingness to hold position.

## Observable Effect 1 — Leash Response

Before growth:

- torso lags behind the dog's pull;
- arms and shoulders tense against the leash;
- recovery step crosses awkwardly;
- backpack swings late and exaggerates lost balance.

After growth:

- owner anticipates forward movement;
- stride lands under the center of mass;
- shoulders stay relaxed;
- backpack overlap is controlled;
- this should read as cooperation with the dog, not increased combat strength.

Runtime direction: use the before response when leash tension rises sharply; reduce its frequency and duration as the relevant growth effect improves.

## Observable Effect 2 — Exertion Recovery

Before growth:

- hands on knees and head below shoulders;
- deeper torso movement and longer recovery hold;
- delayed return to the normal idle pose.

After growth:

- remains mostly upright;
- short controlled breathing cycle;
- adjusts backpack strap and returns to idle quickly.

Runtime direction: preserve the same exertion trigger while shortening the recovery animation and replacing the exhausted key pose at higher growth.

## Observable Effect 3 — Threat Hesitation

Before growth:

- weight moves onto the rear foot;
- shoulders close and hands rise defensively;
- gaze flicks toward the danger while feet begin to retreat.

After growth:

- feet remain planted;
- shoulders open slightly;
- hands stay cautious rather than combative;
- gaze holds on the threat without becoming a heroic pose.

Runtime direction: use the before pose as a brief approach hesitation near dangerous encounters; growth reduces the pause and transitions through the after pose into normal movement.

## Production Requirements

- Match the current 224×240 owner exploration cell and approximately 210 px visible height.
- Keep a common foot-ground origin so growth variants do not pop vertically.
- Do not encode raw training tags in the sprite.
- Do not add muscles, glow, badges, equipment upgrades, speed lines, or power-up color changes.
- Validate at 100%, 50%, and 33% of the 720×1280 reference viewport.

## Next Integration Step

## Engine Integration v1

- Six transparent 224×240 frames live under `assets/characters/human/sprites/owner_growth_v1/`.
- `HumanFollower` exposes `play_growth_behavior(effect, improved, seconds)` as a presentation-only hook.
- `OwnerBehavior` calls the hook for its existing stumble, exhaustion, and encounter-hesitation events.
- Before/after selection uses the midpoint between the existing untrained and fully trained trait values.
- The existing `hold_time`, trigger frequency, training values, and GrowthResolver logic remain authoritative and unchanged.
- A behavior pose temporarily takes priority over Idle/Walk, then restores the appropriate locomotion animation.

The three effects are playable key-pose integrations and are in `REVIEW`. Additional anticipation and recovery frames remain a polish task.
