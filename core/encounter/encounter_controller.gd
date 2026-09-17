class_name EncounterController
extends Node
## Scene-scoped encounter flow for one run:
## World trigger → Provoke/Leave → CombatArena → explicit result → run handling.
## Combat rules live in CombatSimulation; run rules (loot, defeat) in RunManager.

signal encounter_started(point: EncounterPoint)
signal encounter_ended(point: EncounterPoint, result: CombatSimulation.Result)

const ARENA_SCENE: PackedScene = preload("res://world/encounter/combat_arena.tscn")

@export var run_manager: RunManager
@export var human: HumanFollower
@export var ui: EncounterUI
## Arena is added here (y-sorted with the actors).
@export var world: Node2D
@export var player_fighter: FighterData
## Ordinary pairs shuffled over spots without a fixed encounter each run.
@export var ordinary_pool: Array[EncounterData] = []
@export var combat_time_scale: float = 1.0

var current_point: EncounterPoint
var arena: CombatArena
var last_result: CombatSimulation.Result = CombatSimulation.Result.NONE

var _points: Array[EncounterPoint] = []


func _ready() -> void:
	run_manager.run_started.connect(_on_run_started)
	ui.provoke_pressed.connect(provoke)
	ui.leave_pressed.connect(leave)
	ui.continue_pressed.connect(_on_continue)


func is_active() -> bool:
	return current_point != null


func get_points() -> Array[EncounterPoint]:
	return _points


# --- Run setup ----------------------------------------------------------------

func _on_run_started(_seed: int) -> void:
	_cleanup_arena()
	current_point = null
	ui.close()
	_points.clear()
	for node in get_tree().get_nodes_in_group(EncounterPoint.GROUP):
		var point := node as EncounterPoint
		if point != null and (owner == null or owner.is_ancestor_of(point)):
			_points.append(point)
	_points.sort_custom(func(a: EncounterPoint, b: EncounterPoint) -> bool: return String(a.spot_id) < String(b.spot_id))

	# Runs after loot rolls, so adding encounters does not change loot seeds.
	var pool := ordinary_pool.duplicate()
	for i in range(pool.size() - 1, 0, -1):
		var j := run_manager.run_rng.randi_range(0, i)
		var swap: EncounterData = pool[i]
		pool[i] = pool[j]
		pool[j] = swap
	for point in _points:
		var data := point.fixed_encounter
		if data == null and not pool.is_empty():
			data = pool.pop_back()
		point.setup(data)
		point.dog = run_manager.dog
		if not point.triggered.is_connected(_on_point_triggered):
			point.triggered.connect(_on_point_triggered)


# --- Flow -----------------------------------------------------------------------

func _on_point_triggered(point: EncounterPoint) -> void:
	if is_active() or not run_manager.is_running() or not point.is_available():
		return
	current_point = point
	last_result = CombatSimulation.Result.NONE
	run_manager.set_encounter_active(true)
	var dog := run_manager.dog
	if dog != null:
		dog.input_enabled = false
		dog.velocity = Vector2.ZERO
	human.say("欸…有人擋路", Color(1.0, 0.9, 0.6))
	ui.show_decision(point.encounter)
	encounter_started.emit(point)


func leave() -> void:
	if not is_active() or arena != null:
		return
	human.say("我們走別條路吧", Color(0.85, 0.85, 0.85))
	_end(CombatSimulation.Result.NONE)


func provoke() -> void:
	if not is_active() or arena != null:
		return
	var encounter := current_point.encounter
	var sim := CombatSimulation.new(player_fighter, encounter.human, run_manager.run_rng.randi())
	arena = ARENA_SCENE.instantiate() as CombatArena
	arena.time_scale = combat_time_scale
	arena.position = current_point.global_position
	world.add_child(arena)
	arena.start(sim, encounter)
	arena.finished.connect(_on_combat_finished)

	current_point.set_pair_visible(false)
	human.hide()
	human.set_physics_process(false)
	if run_manager.dog != null:
		run_manager.dog.global_position = arena.player_dog_global_position()
		_frame_camera(arena.global_position - run_manager.dog.global_position)
	ui.show_fighting()


func _on_combat_finished(result: CombatSimulation.Result) -> void:
	last_result = result
	var encounter := current_point.encounter
	match result:
		CombatSimulation.Result.VICTORY:
			current_point.set_defeated()
			ui.show_victory(encounter, run_manager.grant_reward(encounter.reward_table))
		CombatSimulation.Result.DEFEAT:
			ui.show_defeat(encounter)
		_:
			ui.show_aborted()


func _on_continue() -> void:
	if not is_active():
		return
	if last_result == CombatSimulation.Result.DEFEAT:
		var defeated_by := current_point.encounter.human.display_name
		_end(last_result)
		run_manager.defeat_run(defeated_by)
		return
	if last_result == CombatSimulation.Result.VICTORY:
		human.say("贏了！好狗狗有幫我加油吧？", Color(0.6, 1.0, 0.6), 2.0)
	_end(last_result)


func _end(result: CombatSimulation.Result) -> void:
	var point := current_point
	_cleanup_arena()
	point.set_pair_visible(true)
	human.show()
	human.set_physics_process(true)
	if run_manager.dog != null:
		human.global_position = run_manager.dog.global_position + Vector2(-60, 60)
		run_manager.dog.input_enabled = true
		_frame_camera(Vector2.ZERO)
	ui.close()
	current_point = null
	run_manager.set_encounter_active(false)
	encounter_ended.emit(point, result)


## Centres the dog's camera on the fight so both pairs are in frame.
func _frame_camera(offset: Vector2) -> void:
	var camera := run_manager.dog.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.offset = offset


func _cleanup_arena() -> void:
	if arena != null:
		arena.queue_free()
		arena = null


# --- Debug (Debug Panel / tests only) -----------------------------------------

func debug_force_result(result: CombatSimulation.Result) -> void:
	if arena != null and arena.simulation != null:
		arena.simulation.force_result(result)


## Walks the dog next to the nearest pair that can still be fought.
func debug_goto_next_encounter() -> void:
	var dog := run_manager.dog
	if dog == null or is_active():
		return
	var best: EncounterPoint = null
	for point in _points:
		if point.is_available() and (best == null or dog.global_position.distance_to(point.global_position) < dog.global_position.distance_to(best.global_position)):
			best = point
	if best != null:
		dog.global_position = best.global_position + Vector2(-best.trigger_radius * 0.6, 0)
		human.global_position = dog.global_position + Vector2(-60, 60)
