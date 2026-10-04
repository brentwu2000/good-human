class_name DogTraitData
extends Resource
## Sprint 06 (S06-01): something a dog is like. Said in experiential words
## (「很愛聞東西」), never as a number. A trait can be visible at the shelter or
## hidden until the dog shows it.

## Contextual things a dog can do when a human visits (S06-05).
enum Behavior { WAG, SIT, APPROACH, BARK, FETCH, LICK_HAND, LIE_DOWN, STARE, IGNORE }

@export var id: StringName
## How a shelter worker or the player would say it.
@export var text: String
## Personality tags it gives the dog (for matching with humans).
@export var tags: Array[StringName] = []
## Behavior -> how much more (or less) this dog does it, -1..1. Shapes how a
## behavior lands with a visiting human (S06-05).
@export var behavior_affinity: Dictionary[Behavior, float] = {}
## Dog stat -> bias added to its rolled value ("nose", "energy", "voice").
## The partially visible talent: a visible trait hints at it, a hidden one
## does not.
@export var stat_bias: Dictionary[StringName, float] = {}
