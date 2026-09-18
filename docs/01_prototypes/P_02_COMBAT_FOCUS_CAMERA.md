# P-02 COMBAT FOCUS CAMERA
Goal: test whether combat feels stronger when the dog remains freely controlled but the camera continuously prioritizes the owner.

## Core
FollowAnchor = PlayerDog
FocusAnchor = PlayerHuman
Optional SecondaryFocus = threatening opponent.

Combat remains in Run World. No BattleScene, teleport, modal combat UI or loss of dog control.

## Emotional Curve
TENSION → SNAP → CHAOS → CRISIS → RESOLUTION → RELEASE

TENSION: humans react/approach, leash tightens.
SNAP: 0.5–1.0s smooth camera push-in + owner focus + subtle audio duck; never cutscene.
CHAOS: dog moves/circles/interacts while humans fight.
CRISIS: owner condition becomes readable; camera may tighten modestly.
RESOLUTION: win recovery/acknowledgement or owner falls while dog remains active briefly.
RELEASE: camera pulls back, leash relaxes, ambience returns.

## Camera
Use soft screen-space focus/dead-zone, not rigid centering, to avoid sickness.
Dog should remain lower foreground/edge where practical; owner primary; opponent near owner; leash visible when useful.
Test dog circling, behind-opponent position, nearby interactable detour, Bark, Pull, critical owner, win, loss, disengage.

Failure: excessive spinning, constrained movement, lost opponent, occlusion, nausea, or cinematic feeling detached from dog.
