class_name DebugPanel
extends Control
## All debug actions in one place. Removed from non-debug builds.
## Hidden by default (blind QA): open with F1, or tap the run timer 5 times quickly.

@export var run_manager: RunManager
## CombatCoordinator or CombatCoordinator3D.
var combat_coordinator: Node
var owner_behavior: OwnerBehavior
var goal_director: GoalDirector
## Optional DogAgency (3D walk).
var dog_agency: Node

@onready var _info_label: Label = %InfoLabel
@onready var _body: Control = %Body


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	_body.hide()
	_bind(%AddMinuteButton, func() -> void: run_manager.debug_add_time(60.0))
	_bind(%SetTimeButton, func() -> void: run_manager.debug_skip_to_next_unlock(10.0))
	_bind(%UnlockButton, func() -> void: run_manager.debug_unlock_all_extractions())
	_bind(%GiveBallButton, func() -> void: run_manager.debug_give_item(&"tennis_ball"))
	_bind(%GiveMysteryButton, func() -> void: run_manager.debug_give_item(&"mysterious_item"))
	_bind(%GiveGlovesButton, func() -> void: run_manager.debug_give_item(&"boxing_gloves"))
	_bind(%ClearBagButton, func() -> void: run_manager.human_run_inventory.clear())
	_bind(%ExtractButton, func() -> void: run_manager.extract(&"debug"))
	_bind(%FailButton, func() -> void: run_manager.fail_run())
	_bind(%NextEncounterButton, func() -> void: _with_combat(func(c: Node) -> void: c.debug_goto_next_pair()))
	_bind(%WinFightButton, func() -> void: _with_combat(func(c: Node) -> void: c.debug_force_result(CombatSimulation.Result.VICTORY)))
	_bind(%TrainAllButton, func() -> void: run_manager.training.debug_add_all(3.0))
	_bind(%GrowFullButton, func() -> void: _set_growth(DataRegistry.training.trait_full_growth))
	_bind(%ResetGrowthButton, func() -> void: _set_growth(0.0))
	_bind(%CompleteDesireButton, func() -> void: _with_goals(func(g: GoalDirector) -> void: g.debug_complete_first()))
	_bind(%ResetGoalsButton, func() -> void: _with_goals(func(g: GoalDirector) -> void: g.debug_reset_goals()))
	_bind(%LoseFightButton, func() -> void: _with_combat(func(c: Node) -> void: c.debug_force_result(CombatSimulation.Result.DEFEAT)))


func _process(_delta: float) -> void:
	if run_manager == null:
		return
	if Input.is_action_just_pressed("debug_panel"):
		toggle()
	if _body.visible:
		var seconds := int(run_manager.elapsed_time)
		_info_label.text = "Run %02d:%02d   Seed %d\n%s\n%s" % [seconds / 60, seconds % 60, run_manager.run_seed, _training_text(), _goals_text()]
		if dog_agency != null:
			_info_label.text += "\n" + dog_agency.debug_text()


func toggle() -> void:
	_body.visible = not _body.visible


## Raw numbers are debug-only (players never see tags).
func _training_text() -> String:
	var parts: Array[String] = []
	for tag in run_manager.training.totals:
		parts.append("%s %.1f/%.1f" % [TrainingEventData.tag_name(tag), run_manager.training.totals[tag], Game.human_growth.get_growth(tag)])
	return "  ".join(parts)


## Sets every tag's permanent growth, re-resolves perks and saves.
func _set_growth(value: float) -> void:
	var growth := Game.human_growth
	var defeats := growth.defeats
	growth.clear()
	# Full growth also counts as having survived hard defeats (unlocks every perk).
	growth.defeats = maxi(defeats, 2) if value > 0.0 else 0
	for tag_name: String in growth.growth.keys():
		growth.growth[tag_name] = value
	GrowthResolver.apply(growth, RunTrainingSummary.new(), false, DataRegistry.training)
	SaveManager.data["human"]["growth_data"] = growth.serialize()
	SaveManager.save_game()
	if owner_behavior != null:
		owner_behavior.refresh_traits()


func _goals_text() -> String:
	if goal_director == null:
		return ""
	var ids: Array[String] = []
	for desire in goal_director.active_desires():
		ids.append(String(desire.id))
	var flags: Array[String] = []
	for flag in Game.goal_progress.flags:
		flags.append(String(flag))
	return "Goals: %s  Flags: %s" % [", ".join(ids), ", ".join(flags)]


func _with_goals(action: Callable) -> void:
	if goal_director != null:
		action.call(goal_director)


func _with_combat(action: Callable) -> void:
	if combat_coordinator != null:
		action.call(combat_coordinator)


func _bind(button: Button, action: Callable) -> void:
	button.pressed.connect(action)
