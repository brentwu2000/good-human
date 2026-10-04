extends Control
## Home placeholder: owner, stash/dog bag counts, start a walk.

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


func _ready() -> void:
	_walk_button.pressed.connect(_on_walk_pressed)
	_walk_3d_button.pressed.connect(Game.start_run_3d)
	_view_stash_button.pressed.connect(func() -> void: _stash_panel.open(Game.home_stash))
	# Sprint 06: a save is one pair, so meeting a new dog means starting over.
	_new_game_button.pressed.connect(_new_game_confirm.popup_centered)
	_new_game_confirm.confirmed.connect(Game.start_new_game)
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
	_growth_label.text = pair_text() + "
" + _growth_label.text
	_territory_label.visible = not _territory_label.text.is_empty()


## S06-08: the pair first — who the human is to this dog, in words.
static func pair_text() -> String:
	if not Game.has_pair():
		return ""
	return "你和%s：%s" % [Game.pair_state.human_custom_name, Bond.home_words(Game.pair_state)]


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
	return "
".join(lines)


static func _count_text(found: int, total: int) -> String:
	return "%d/%d" % [found, total]


func _on_walk_pressed() -> void:
	Game.start_run()
