# Dog Agency System v0.1

## Pillars
POSITION — where the dog is matters.
TIMING — when the dog acts matters.
RELATION — leash/owner/opponent-dog relationships matter.
CHAOS — actions can create comedy and unintended outcomes.

## Bark
Not a generic +20% buff button.
Prototype Bark can create an Attention event.

Inputs/conditions may include:
- distance
- facing/relative direction
- timing window
- bark repetition/resistance

Possible outcomes:
- opponent briefly redirects attention;
- owner gains an opening;
- owner morale/stability response;
- repeated barking becomes less effective.

Keep hidden numbers debug-only.

## Leash Pull
The leash is a gameplay relationship, not decoration.

Dog movement creates tension. When threshold/timing conditions are met, a pull can influence owner movement.

Possible outcomes:
- pull owner away from incoming attack;
- reposition owner;
- initiate/assist disengagement;
- bad pull causes stumble/loss of balance.

Do not implement as a detached “Perfect Dodge” button.

## Nearby Interaction
Combat must not globally disable world Interactables.
The dog may choose to sniff/search/pick up or investigate nearby things while humans fight, subject to later balance.

## Training Integration
Dog Agency may emit semantic TrainingEvents:
- strong pull → STRAIN
- forced reposition/run → RUN
- dangerous intervention → COURAGE
- surviving bad outcome → ENDURE

## Opponent Dog
Sprint 04 only needs basic reaction hooks:
observe, bark back, approach, retreat, social/sniff.
Full relationship simulation is deferred.
