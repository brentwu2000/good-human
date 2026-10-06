class_name DogInstinct
extends Node
## D4/P02-009 (COMBAT_EMOTIONAL_FEEDBACK "Dog Instinct"): the dog senses danger
## to its owner and shows it through its own body — ears, head, posture and a
## growl or whine. Presentation only: it changes no rule and decides nothing.
## It also happens to be the dog's own read of the telegraph a leash pull
## answers.

enum Instinct { CALM, THREAT, WORRY }

const GROUP: StringName = &"dog_instinct"

var dog: DogController3D
var coordinator: CombatCoordinator3D
var state: Instinct = Instinct.CALM


func _enter_tree() -> void:
	add_to_group(GROUP)


func _physics_process(_delta: float) -> void:
	var sensed := sense()
	if sensed != state:
		state = sensed
		if dog != null:
			dog.set_instinct(state)


## THREAT while a heavy blow (hook or kick) is winding up at the owner; WORRY
## while the owner is in a bad way or down; otherwise CALM.
func sense() -> Instinct:
	if coordinator == null:
		return Instinct.CALM
	if not coordinator.is_fighting():
		return Instinct.WORRY if coordinator.is_owner_down() else Instinct.CALM
	var them := coordinator.engagement.simulation.fighters[CombatSimulation.OPPONENT]
	if them.is_winding_up_attack() and them.action.is_heavy():
		return Instinct.THREAT
	var condition := coordinator.owner_condition()
	if condition >= 0.0 and condition <= FighterPuppet3D.CRITICAL_AT:
		return Instinct.WORRY
	return Instinct.CALM


## Debug overlay line.
func debug_text() -> String:
	return "Instinct: %s" % Instinct.keys()[state]
