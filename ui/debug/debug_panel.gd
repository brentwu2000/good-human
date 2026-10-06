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
	_bind(%CombatLogButton, _toggle_combat_log)
	_update_combat_log_button()
	# D4/P02-011: tuning the owner's condition and comparing the two combat
	# cameras. Built here so they sit with the other combat buttons.
	_add_button("主人重傷（25%）", func() -> void: _with_combat(func(c: Node) -> void:
		if c.has_method(&"debug_set_owner_condition"):
			c.debug_set_owner_condition(0.25)))
	# P-05: a weapon lying beside the dog, without waiting on a search roll.
	for id: StringName in [&"umbrella", &"broom", &"old_dumbbell"]:
		var weapon := DataRegistry.get_weapon(id)
		_add_button("地上放%s" % weapon.display_name, func() -> void: _debug_drop_weapon(weapon))
	# S05-04: see the banyan call without waiting for the temptation roll.
	_add_button("大榕樹在叫（誘惑）", _debug_banyan_call)
	var camera_button := _add_button("", Callable())
	camera_button.pressed.connect(func() -> void:
		CameraRig3D.combat_pov = not CameraRig3D.combat_pov
		_update_camera_button(camera_button))
	_update_camera_button(camera_button)
	# Style Bible v1: the shared soft-toon material on every character.
	var toon_button := _add_button("", Callable())
	toon_button.pressed.connect(func() -> void:
		SoftToon.set_enabled(get_tree(), not SoftToon.enabled)
		_update_toon_button(toon_button))
	_update_toon_button(toon_button)
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
		if combat_coordinator != null and combat_coordinator.has_method(&"debug_text"):
			_info_label.text += "\n" + combat_coordinator.debug_text()
		var instinct := get_tree().get_first_node_in_group(DogInstinct.GROUP) as DogInstinct
		if instinct != null:
			_info_label.text += "  " + instinct.debug_text()


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


func _debug_banyan_call() -> void:
	var director := run_manager.owner.get_node_or_null("TemptationDirector") as TemptationDirector if run_manager.owner != null else null
	if director == null:
		return
	Game.territory_progress.advance_to(&"banyan", TerritoryProgress.State.DISCOVERED)
	for template in director.catalog:
		if template.needs == TemptationData.Needs.TERRITORY:
			director.offer(template, run_manager.elapsed_time)
			return


func _with_combat(action: Callable) -> void:
	if combat_coordinator != null:
		action.call(combat_coordinator)


## P03-E10 / P04-11: fight text (log, health bars, the dog's outcome toasts)
## is off in normal play; this puts it back for debugging without changing
## anything the fight does.
func _toggle_combat_log() -> void:
	FighterPuppet3D.show_combat_text = not FighterPuppet3D.show_combat_text
	_update_combat_log_button()


func _update_combat_log_button() -> void:
	var button := get_node_or_null("%CombatLogButton") as Button
	if button != null:
		button.text = "戰鬥文字/血條：開" if FighterPuppet3D.show_combat_text else "戰鬥文字/血條：關"


## A button in the same grid and style as the combat log toggle.
func _debug_drop_weapon(weapon: WeaponData) -> void:
	var dog := run_manager.dog_actor as Node3D
	if dog == null or not run_manager.is_running():
		return
	run_manager.weapon_found.emit(ItemStack.new(weapon.item, 1), dog.global_position + Vector3(0.6, 0, -1.4))


func _add_button(text: String, action: Callable) -> Button:
	var template := %CombatLogButton as Button
	# No DUPLICATE_SIGNALS: the copy must not also toggle the combat log.
	var button := template.duplicate(0) as Button
	button.unique_name_in_owner = false
	button.text = text
	template.get_parent().add_child(button)
	if action.is_valid():
		button.pressed.connect(action)
	return button


func _update_toon_button(button: Button) -> void:
	# Materials switch now; the Style v1 proportions follow on the next walk.
	button.text = "角色風格：卡通" if SoftToon.enabled else "角色風格：標準"


func _update_camera_button(button: Button) -> void:
	button.text = "戰鬥鏡頭：狗眼" if CameraRig3D.combat_pov else "戰鬥鏡頭：越肩"


func _bind(button: Button, action: Callable) -> void:
	button.pressed.connect(action)
