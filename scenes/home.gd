extends Control
## Home (S06-11, D6-06): coming back to the pair. The dog and its human come
## first — the two of them at home, the human's name, how close they are, what
## the human has picked up, one remembered moment and what the dog still has
## on its mind. The stash and the counts are below, smaller.

@onready var _stash_label: Label = %StashLabel
@onready var _dog_bag_label: Label = %DogBagLabel
@onready var _walk_button: Button = %WalkButton
@onready var _walk_3d_button: Button = %Walk3DButton
@onready var _view_stash_button: Button = %ViewStashButton
@onready var _stash_panel: StashPanel = %StashPanel
@onready var _controls_label: Label = %ControlsLabel
@onready var _growth_label: Label = %GrowthLabel
@onready var _goals_label: Label = %GoalsLabel
@onready var _territory_label: Label = %TerritoryLabel
@onready var _new_game_button: Button = %NewGameButton
@onready var _new_game_confirm: ConfirmationDialog = %NewGameConfirm
@onready var _pair_view: SubViewportContainer = %PairView
@onready var _pair_name: Label = %PairName
@onready var _pair_label: Label = %PairLabel

var _dog_visual: Node3D


func _ready() -> void:
	_walk_button.pressed.connect(_on_walk_pressed)
	_walk_3d_button.pressed.connect(Game.start_run_3d)
	_view_stash_button.pressed.connect(func() -> void: _stash_panel.open(Game.home_stash))
	# Sprint 06: a save is one pair, so meeting a new dog means starting over.
	_new_game_button.pressed.connect(_new_game_confirm.popup_centered)
	_new_game_confirm.confirmed.connect(Game.start_new_game)
	_build_pair_view()
	_refresh()


func _refresh() -> void:
	var stash := Game.home_stash
	_stash_label.text = "倉庫 %d/%d　總價值 $%d" % [stash.used_slot_count(), stash.capacity, stash.total_value()]
	# Dog Safe Inventory is run-scoped in Sprint 01, so it is empty at Home.
	_dog_bag_label.text = "狗包 0/%d" % DataRegistry.balance.dog_safe_slots
	_walk_button.disabled = not Game.can_start_run()
	_controls_label.text = preload("res://ui/hud/run_hud.gd").controls_hint()
	_growth_label.text = growth_text()
	_goals_label.text = goals_text()
	_territory_label.text = territory_text()
	_pair_name.text = pair_name_text()
	_pair_label.text = pair_text()
	_pair_label.visible = not _pair_label.text.is_empty()
	_territory_label.visible = not _territory_label.text.is_empty()


func _process(delta: float) -> void:
	if _dog_visual != null:
		(_dog_visual.get_node("Motion") as DogModelMotion3D).update_motion(delta, 0.0, false)


static func pair_name_text() -> String:
	if not Game.has_pair():
		return ""
	var breed := DataRegistry.get_dog_breed(Game.pair_state.dog.breed_id)
	return "%s和你（%s）" % [Game.pair_state.human_custom_name, breed.display_name if breed != null else "狗狗"]


## The two of them at home: the human standing easy, the dog at their feet.
func _build_pair_view() -> void:
	var viewport := _pair_view.get_node("Viewport") as SubViewport
	var world := Node3D.new()
	viewport.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.93, 0.86, 0.74)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.95, 0.86, 0.76)
	env.environment.ambient_light_energy = 0.75
	world.add_child(env)
	var lamp := DirectionalLight3D.new()
	lamp.rotation_degrees = Vector3(-40, 30, 0)
	lamp.light_color = Color(1.0, 0.93, 0.82)
	lamp.shadow_enabled = true
	world.add_child(lamp)
	world.add_child(Greybox.box(Vector3(6, 0.05, 4), Color(0.6, 0.45, 0.32), Vector3(0, -0.025, -0.5)))
	world.add_child(Greybox.box(Vector3(6, 3, 0.1), Color(0.95, 0.9, 0.8), Vector3(0, 1.5, -1.8)))
	world.add_child(Greybox.box(Vector3(1.6, 0.45, 0.7), Color(0.42, 0.55, 0.52), Vector3(-1.6, 0.225, -1.3)))
	world.add_child(Greybox.box(Vector3(1.0, 0.03, 0.7), Color(0.85, 0.7, 0.55), Vector3(0.55, 0.015, -0.2)))
	var owner_body := FighterPuppet3D.new()
	world.add_child(owner_body)
	owner_body.apply(Game.owner_fighter())
	owner_body.position = Vector3(-0.35, 0, -0.5)
	owner_body.rotation.y = PI - 0.25
	owner_body.set_ambient(false)
	_dog_visual = DogVisual3D.build(Game.pair_state.dog if Game.has_pair() else null)
	_dog_visual.position = Vector3(0.55, 0, -0.1)
	_dog_visual.rotation.y = PI + 0.35
	world.add_child(_dog_visual)
	var camera := Camera3D.new()
	camera.fov = 45.0
	world.add_child(camera)
	camera.look_at_from_position(Vector3(0.1, 1.15, 2.1), Vector3(0.1, 0.9, -0.4))


## S06-08: the pair first — who the human is to this dog, in words.
static func pair_text() -> String:
	if not Game.has_pair():
		return ""
	var lines: Array[String] = [Bond.home_words(Game.pair_state)]
	# S06-09: what they have started doing because of the dog.
	for id in Game.pair_state.habit_ids:
		var habit := DataRegistry.get_habit(id)
		if habit != null:
			lines.append("・%s" % habit.home_text)
	# S06-10: one photo, the moment that matters most lately.
	var photo := Memories.featured(Game.pair_state)
	if not photo.is_empty():
		lines.append("📷 %s" % photo["text"])
	return "\n".join(lines)


## The owner's unlocked changes, in words.
static func growth_text() -> String:
	var perks := GrowthResolver.owned_perks(Game.human_growth, DataRegistry.training)
	if perks.is_empty():
		return "主人還是那個普通的主人。"
	var names: Array[String] = []
	for perk in perks:
		names.append("「%s」" % perk.display_name)
	return "主人的變化：" + "、".join(names)


## Unresolved dog threads (why go out again) and how much has been discovered.
static func goals_text() -> String:
	var progress := Game.goal_progress
	var catalog := DataRegistry.goals
	var lines: Array[String] = []
	var threads: Array[String] = []
	for desire in catalog.desires:
		if progress.state_of(desire.id) == GoalProgress.State.DORMANT:
			threads.append("・" + desire.dog_text)
	if not threads.is_empty():
		lines.append("狗狗還掛念著：")
		lines.append_array(threads)
	lines.append("發現　狗 %s・地點 %s・東西 %s" % [
		_count_text(progress.discovered_count(&"dogs"), catalog.dogs.size()),
		_count_text(progress.discovered_count(&"places"), catalog.places.size()),
		_count_text(progress.discovered_count(&"items"), DataRegistry.get_all_item_ids().size()),
	])
	# S06-12: the kinds of moments the two have lived through.
	if Game.has_pair():
		lines.append("一起經歷過的事 %s" % _count_text(progress.discovered_count(&"events"), DataRegistry.memory_kinds.size()))
	return "\n".join(lines)


## S05-08: the places the dog keeps going back to, as it remembers them —
## what the roots smelled of, the last thing that happened there and how it
## went with the dog that lives there. Never a progress bar (ADR-012).
static func territory_text() -> String:
	var progress := Game.territory_progress
	var lines: Array[String] = []
	for data in DataRegistry.get_all_territories():
		var state := progress.state_of(data.id)
		if state == TerritoryProgress.State.UNKNOWN:
			continue
		lines.append("🌳 %s" % data.display_name)
		var feeling := ""
		match state:
			TerritoryProgress.State.DISCOVERED:
				feeling = data.discovered_text
			TerritoryProgress.State.CONTESTED:
				feeling = data.rival_only_text
			TerritoryProgress.State.CLAIMING:
				feeling = data.mixed_scent_text
			TerritoryProgress.State.OWNED:
				feeling = data.own_scent_text
		if not feeling.is_empty():
			lines.append("「%s」" % feeling)
		var last := progress.last_event(data.id)
		if not last.is_empty() and last != feeling:
			lines.append("最近：「%s」" % last)
		if not data.resident_encounter_id.is_empty():
			match progress.last_rival_outcome(data.resident_encounter_id):
				TerritoryProgress.RivalOutcome.DOG_WON:
					lines.append("上次和%s打，我們贏了。" % data.resident_name)
				TerritoryProgress.RivalOutcome.DOG_LOST:
					lines.append("上次輸給了%s。" % data.resident_name)
	return "\n".join(lines)


static func _count_text(found: int, total: int) -> String:
	return "%d/%d" % [found, total]


func _on_walk_pressed() -> void:
	Game.start_run()
