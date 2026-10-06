extends Node
## High-level flow: Boot → Home → RunMap → RunResult → Home, plus the persistent
## Home Stash. Holds no in-run state; RunManager owns that inside the run scene.

const BOOT_SCENE: String = "res://scenes/boot.tscn"
const HOME_SCENE: String = "res://scenes/home.tscn"
const RUN_MAP_SCENE: String = "res://world/run_map/run_map_01.tscn"
## P-02 3D vertical slice (switchable top-down / dog view).
const RUN_MAP_3D_SCENE: String = "res://world/run_map_3d/run_map_3d_01.tscn"
const RUN_RESULT_SCENE: String = "res://ui/run_result/run_result.tscn"
## Sprint 06: a new game starts at the shelter, then the adoption.
const SHELTER_SCENE: String = "res://scenes/shelter.tscn"
const ADOPTION_SCENE: String = "res://scenes/adoption.tscn"

var home_stash: Inventory
## The one human's persistent growth.
var human_growth: HumanGrowth = HumanGrowth.new()
## The dog's desires, threads and discoveries.
var goal_progress: GoalProgress = GoalProgress.new()
## The places the dog keeps going back to (Sprint 05).
var territory_progress: TerritoryProgress = TerritoryProgress.new()
## Sprint 06: this save's one dog and one human; null until the adoption.
var pair_state: PairState
## Saves from before Sprint 06 (and tests) carry on with the classic pair
## instead of starting over at the shelter.
var use_classic_pair_when_missing: bool = false
var last_run_result: RunResult
## Sprint 06: the dog picked at the shelter, waiting to be adopted.
var chosen_dog: DogCandidate
## The other pups that share the window pen with it (they can be adopted too).
var window_litter: Array[DogCandidate] = []
## S06-03: the human who came back for it.
var adopting_human: HumanCandidate


func _ready() -> void:
	home_stash = Inventory.new(DataRegistry.balance.home_stash_slots)


## Rebuilds persistent state from SaveManager.data (call after load_game()).
func load_profile() -> void:
	home_stash.deserialize(SaveManager.data["stash"], DataRegistry.get_item)
	var human: Dictionary = SaveManager.data["human"]
	human_growth.deserialize(human.get("growth_data", {}))
	var dog: Dictionary = SaveManager.data["dog"]
	goal_progress.deserialize(dog.get("goals", {}))
	territory_progress.deserialize(dog.get("territories", {}))
	pair_state = PairState.deserialize(SaveManager.data.get("pair"))
	if pair_state == null and use_classic_pair_when_missing:
		# Tests and review captures walk with the classic pair. Old saves get
		# it through SaveManager's v1 -> v2 migration instead.
		pair_state = PairState.classic()
		SaveManager.data["pair"] = pair_state.serialize()


func has_pair() -> bool:
	return pair_state != null


## The human the walk uses: this save's own, or the classic owner.
func owner_fighter() -> FighterData:
	return pair_state.owner_fighter() if pair_state != null else load(HumanCandidate.TEMPLATE_PATH) as FighterData


## S06-07: the dog's talent for `stat` ("nose", "energy", "voice"), 1.0
## without a pair. Rolled at the shelter, leaning the way its traits do.
func dog_talent(stat: StringName) -> float:
	return pair_state.dog.stat(stat) if pair_state != null and pair_state.dog != null else 1.0


## Sprint 06: everything this save had is gone and the shelter is next. A
## save never holds a second pair (ADR-019), so this is the only way to meet
## another dog.
func start_new_game() -> void:
	SaveManager.reset_to_default()
	SaveManager.save_game()
	home_stash.clear()
	human_growth.clear()
	goal_progress.clear()
	territory_progress.clear()
	pair_state = null
	chosen_dog = null
	adopting_human = null
	last_run_result = null
	_change_scene(SHELTER_SCENE)


## Where a profile starts: Home with its pair, or the shelter for a new one.
func goto_start() -> void:
	if has_pair():
		goto_home()
	else:
		_change_scene(SHELTER_SCENE)


## S06-02: the player picked their dog; next comes the adoption.
func choose_dog(dog: DogCandidate, litter: Array = []) -> void:
	chosen_dog = dog
	window_litter.assign(litter)
	if ResourceLoader.exists(ADOPTION_SCENE):
		_change_scene(ADOPTION_SCENE)


## S06-06: a human chose the dog and has been given their name. From here
## on this is the save's pair (ADR-019: one human, one relationship).
func adopt(dog: DogCandidate, human: HumanCandidate, human_name: String = "", summary: String = "") -> void:
	adopting_human = human
	pair_state = PairState.adopted(dog, human, human_name, summary)
	_collect_memory(Memories.remember(pair_state, &"met", &"shelter", 0))
	SaveManager.data["dog"]["goals"] = goal_progress.serialize()
	chosen_dog = null
	save_pair()
	goto_home()


## S06-12: each kind of moment the pair has lived is a collection entry
## ("events"). The human is never one: there is no owner roster.
func _collect_memory(memory: Dictionary) -> void:
	if not memory.is_empty():
		goal_progress.discover(&"events", StringName(str(memory["kind"])))


func save_pair() -> void:
	if pair_state != null:
		SaveManager.data["pair"] = pair_state.serialize()
		SaveManager.save_game()


func goto_home() -> void:
	_change_scene(HOME_SCENE)


func start_run() -> void:
	_change_scene(RUN_MAP_SCENE)


func start_run_3d() -> void:
	_change_scene(RUN_MAP_3D_SCENE)


# --- P-05: taking a banked weapon out again -----------------------------------

## The stash slot of the weapon the human takes on the next walk, or -1 for
## bare hands. Chosen at Home; once taken out it is exposed again.
var carry_out_slot: int = -1


## Stash slots holding something to fight with.
func carry_out_choices() -> Array[int]:
	var slots: Array[int] = []
	for i in home_stash.capacity:
		var stack := home_stash.stack_at(i)
		if stack != null and DataRegistry.weapon_for_item(stack.item_id) != null:
			slots.append(i)
	return slots


## Bare hands → each banked weapon in turn → bare hands.
func next_carry_out() -> void:
	var choices := carry_out_choices()
	var at := choices.find(carry_out_slot)
	carry_out_slot = -1 if at + 1 >= choices.size() else choices[at + 1]


## What the human will carry, or null.
func carry_out_stack() -> ItemStack:
	if carry_out_slot < 0 or not carry_out_choices().has(carry_out_slot):
		return null
	return home_stash.stack_at(carry_out_slot)


## The walk begins: the chosen weapon leaves the stash and goes in the human's
## hand — in their bag, exposed, like anything found on the way. Saved at
## once, so quitting mid-walk cannot keep it safe at home as well.
func hand_out_carried(run: RunManager) -> void:
	var stack := carry_out_stack()
	carry_out_slot = -1
	if stack == null:
		return
	home_stash.take_stack(home_stash.slots.find(stack))
	if not bool(run.take_weapon(stack)["ok"]):
		home_stash.add_stack(stack)
		return
	SaveManager.data["stash"] = home_stash.serialize()
	SaveManager.save_game()


func can_start_run() -> bool:
	return ResourceLoader.exists(RUN_MAP_SCENE)


## Applies a finished run to the persistent profile, saves, then shows the result.
func finish_run(result: RunResult, show_result: bool = true) -> void:
	var stash_before := home_stash.total_value()
	for stack in result.to_stash:
		var left := home_stash.add_stack(stack)
		if left > 0:
			result.stash_overflow.append(ItemStack.new(stack.item, left))
	result.banked_value_delta = home_stash.total_value() - stash_before

	_resolve_territories(result)
	if pair_state != null:
		result.bond_closer = Bond.apply_walk(pair_state, result)
		for habit in Habits.apply_walk(pair_state, result, DataRegistry.habits):
			result.habits_formed.append(habit.id)
		for memory in Memories.apply_walk(pair_state, result, int(SaveManager.data["statistics"]["runs"]) + 1):
			_collect_memory(memory)

	var stats: Dictionary = SaveManager.data["statistics"]
	stats["runs"] = int(stats["runs"]) + 1
	if result.is_success():
		stats["successful_extractions"] = int(stats["successful_extractions"]) + 1
	if result.training != null:
		GrowthResolver.apply(human_growth, result.training, result.outcome == RunResult.Outcome.DEFEATED, DataRegistry.training)
	SaveManager.data["stash"] = home_stash.serialize()
	SaveManager.data["human"]["growth_data"] = human_growth.serialize()
	SaveManager.data["dog"]["goals"] = goal_progress.serialize()
	SaveManager.data["dog"]["territories"] = territory_progress.serialize()
	if pair_state != null:
		SaveManager.data["pair"] = pair_state.serialize()
	SaveManager.save_game()

	last_run_result = result
	if show_result:
		_change_scene(RUN_RESULT_SCENE)


## Sprint 05 P4-009/P4-010: a place the dog marked moves forward only when the
## walk got home. A walk that ended badly loses nothing it had already earned —
## territory never decays (ADR-012), it just does not advance today.
func _resolve_territories(result: RunResult) -> void:
	if not result.is_success():
		return
	for id in result.marked_territories:
		var data := DataRegistry.get_territory(id)
		if data == null:
			continue
		var completed := territory_progress.add_claim(id, data.claim_target)
		result.territory_claims[id] = territory_progress.claim_progress(id)
		if not completed:
			territory_progress.note_event(id, data.marked_text)
			continue
		result.territories_claimed.append(id)
		territory_progress.note_event(id, data.claimed_text)
		if not data.owned_flag.is_empty():
			goal_progress.set_flag(data.owned_flag)


func _change_scene(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_error("Game: scene not found: %s" % path)
		return
	get_tree().change_scene_to_file.call_deferred(path)
