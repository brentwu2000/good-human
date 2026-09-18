class_name CombatMotion3D
extends RefCounted
## P-03 (P03-E01): what a fighter's body is doing right now, as a state the
## world can show — not a damage number with a text label.
##
## Read from the simulation every frame; the simulation still owns every rule.
## The point of this existing at all is the P-03 exit gate: with the combat text
## hidden, the fight must still be readable. A state nobody can see on screen is
## a state that does not count.

enum State {
	IDLE_COMBAT,  ## squared up, breathing, waiting
	APPROACH,     ## closing the gap
	CIRCLE,       ## in range, working for an angle
	WINDUP,       ## committing to an attack — the dog's cue to intervene
	ATTACK,       ## the strike itself
	BLOCK,
	DODGE,
	HIT_REACT,
	STAGGER,
	DOWN,
	RECOVER,      ## the beat after an action, open and off balance
}

## Reaction states hold for their own moment before the simulation takes over
## the body again, so a hit reads as a hit rather than a flicker.
const REACT_SECONDS: float = 0.28
const STAGGER_SECONDS: float = 0.45

var state: State = State.IDLE_COMBAT
## How far the fighter is from wanting to close the distance, 0..1, for the
## puppet to lean into.
var intent: float = 0.0

var _react_left: float = 0.0
var _reacting: State = State.IDLE_COMBAT


## A hit landed on this fighter: hold the reaction briefly.
func react(staggered: bool) -> void:
	_reacting = State.STAGGER if staggered else State.HIT_REACT
	_react_left = STAGGER_SECONDS if staggered else REACT_SECONDS


## Recomputes the state from the simulation. `closing` is true when this fighter
## still needs to cover ground before it can attack.
func update(delta: float, fighter: CombatFighter, closing: bool, defeated: bool) -> void:
	if defeated:
		state = State.DOWN
		_react_left = 0.0
		return
	if _react_left > 0.0:
		_react_left -= delta
		state = _reacting
		return
	if fighter.is_guarding():
		state = State.BLOCK
	elif fighter.is_evading():
		state = State.DODGE
	elif fighter.phase == CombatFighter.Phase.WINDUP:
		state = State.WINDUP
	elif fighter.phase == CombatFighter.Phase.ACTIVE:
		state = State.ATTACK
	elif fighter.phase == CombatFighter.Phase.RECOVERY:
		state = State.RECOVER
	elif closing:
		state = State.APPROACH
	else:
		state = State.CIRCLE
	intent = 1.0 if state == State.APPROACH else 0.0


## True while the body is doing something the fight should not interrupt.
func is_committed() -> bool:
	return state in [State.WINDUP, State.ATTACK, State.HIT_REACT, State.STAGGER, State.DOWN]
