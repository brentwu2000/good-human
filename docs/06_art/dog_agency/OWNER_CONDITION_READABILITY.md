# D4-13 — Owner Condition Readability v0.1

Status: REVIEW

Visual board: `assets/_source/design/dog_agency/owner_condition_readability_01.svg`

## Decision

The owner's condition is read first through full-body behavior, then through timing and sound, and only last through prototype HP UI. HEALTHY, HURT, CRITICAL and DOWN must remain distinguishable at the 405×720 window override without numbers, color grading or a persistent bar.

The states describe presentation bands. Combat simulation remains authoritative for health and outcomes.

## Presentation bands

| State | Suggested health band | Primary silhouette | Motion rhythm | Face / breath | Camera relationship |
|---|---:|---|---|---|---|
| HEALTHY | > 67% | vertical spine, even stance, hands ready but ordinary | clean recoveries, steady weight transfer | alert head, quiet breath | ACTIVE framing breathes normally |
| HURT | 35–67% | guarded ribs, one shoulder lower, stance narrows between actions | recovery gains a small extra settle; occasional weight check | mouth opens on exhale; brief wince after unblocked hit | no automatic crisis push |
| CRITICAL | 1–34% | asymmetric crouch, unstable rear foot, protective near hand | visible hesitation and two-part recovery; never constant shaking | heavier breath, head dips then reacquires opponent | existing CRISIS framing protects full body |
| DOWN | 0% | body reaches ground with bent, non-rigid limbs | one fall, then restrained breath/settle only | face remains visible where camera side permits | CRISIS/RESOLUTION holds while dog can approach |

The 34% boundary matches the current combat-camera crisis threshold. The 67% HURT boundary is an art tuning target and must not drive combat AI or damage.

## Silhouette construction

### HEALTHY

- Head sits over the pelvis; both feet support weight.
- Hands read as improvised guard, not trained boxing form.
- Outfit modules retain their normal hang and do not inflate the torso.
- Idle variation is small enough that the first hit reaction remains clear.

### HURT

- Torso bends 6–10 degrees toward the guarded side.
- Near hand covers the struck region between actions; far hand remains available.
- One knee softens, but both heels continue to find the ground.
- Do not loop a clutching animation through an attack; condition pose yields to mechanically honest windup/contact poses.

### CRITICAL

- Torso angle increases to roughly 12–18 degrees with uneven shoulders.
- Rear foot adjusts twice during recovery: catch, then settle.
- Head drops below the HEALTHY eye line, then looks back toward the opponent.
- A short knee buckle may follow a heavy hit, but the character cannot resemble DOWN until health reaches zero.
- Avoid red aura, flashing outline, skull icon or screen-edge blood treatment.

### DOWN

- Fall direction follows the last impact when space permits.
- Final pose occupies a broad, low footprint and preserves the face/profile.
- Arms and knees form an uneven human collapse; avoid a rigid plank rotation.
- The leash anchor lowers with the owner hand. The leash relaxes on the ground rather than pointing like a laser.
- The dog retains a clear approach lane to the owner's head/shoulder side.

## Transition rules

- Condition is evaluated between actions. Never snap the base pose in the middle of windup, contact, block or dodge.
- After hitstop, play contact recoil → balance catch → current condition recovery.
- Moving from HURT back to HEALTHY is allowed only if gameplay actually restores health; do not visually recover because time passed.
- CRITICAL is persistent until health leaves its band or DOWN occurs. Use irregular breath timing, not continuous tremble.
- DOWN overrides every other pose and remains in world for the resolution beat.

## Readability stack

1. spine and shoulder angle;
2. distance and symmetry between feet;
3. recovery timing after an action;
4. head height and reacquisition of the opponent;
5. restrained breath/vocal layer;
6. optional small UI fallback during prototype review.

Color is not in the primary stack. Different skin tones, hair, tops, bottoms and accessories must produce the same condition read.

## Modular compatibility

- Backpack, messenger bag and tote follow the torso with delayed secondary motion but cannot hide the guarding hand.
- Cardigan, hoodie and work jacket preserve the shoulder slope; do not use cloth bulk to fake condition.
- Glasses may skew slightly after a heavy hit but cannot disappear or become a universal CRITICAL cue.
- Hair motion settles later on heavier impacts but never reveals hidden strength.
- Body scale and stoop modify the neutral baseline; condition offsets are additive and should be clamped to avoid extreme caricature.

## HP UI relationship

The current five-block HP label may remain during prototype tuning, but the target presentation is:

- owner body language carries the condition;
- no numeric health appears;
- if a fallback remains for review, keep it small, low-contrast and outside the face/impact line;
- CRITICAL cannot be communicated only by recoloring the HP label;
- opponent condition uses the same behavioral grammar, without making appearance reveal combat power.

## Mobile acceptance

Review four static silhouettes at 100%, 56% and the final 405×720 window size, then in motion:

- HEALTHY and HURT differ before color or UI is visible;
- HURT and CRITICAL differ by foot stability and recovery rhythm, not merely a deeper torso bend;
- CRITICAL never reads as already defeated;
- DOWN is readable from either side orbit and leaves room for the dog to approach;
- all four states keep feet/ground contact visible in D4-11 combat framing;
- a player can correctly order the four states after a two-second, UI-free clip.

## Runtime handoff

Presentation can read `CombatCoordinator3D.owner_condition()` and map it to these bands without changing simulation. `FighterPuppet3D` needs condition-aware neutral/recovery offsets layered around existing windup, strike, hurt, block, dodge and down calls. D4-17 should capture each state from left orbit, right orbit and the final mobile window size.
