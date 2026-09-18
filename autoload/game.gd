extends Node
## High-level flow: Boot → Home → RunMap → RunResult → Home, plus the persistent
## Home Stash. Holds no in-run state; RunManager owns that inside the run scene.

const BOOT_SCENE: String = "res://scenes/boot.tscn"
const HOME_SCENE: String = "res://scenes/home.tscn"
const RUN_MAP_SCENE: String = "res://world/run_map/run_map_01.tscn"
## P-02 3D vertical slice (switchable top-down / dog view).
const RUN_MAP_3D_SCENE: String = "res://world/run_map_3d/run_map_3d_01.tscn"
const RUN_RESULT_SCENE: String = "res://ui/run_result/run_result.tscn"

var home_stash: Inventory
## The one human's persistent growth.
var human_growth: HumanGrowth = HumanGrowth.new()
## The dog's desires, threads and discoveries.
var goal_progress: GoalProgress = GoalProgress.new()
## The places the dog keeps going back to (Sprint 05).
var territory_progress: TerritoryProgress = TerritoryProgress.new()
var last_run_result: RunResult


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


func goto_home() -> void:
	_change_scene(HOME_SCENE)


func start_run() -> void:
	_change_scene(RUN_MAP_SCENE)


func start_run_3d() -> void:
	_change_scene(RUN_MAP_3D_SCENE)


func can_start_run() -> bool:
	return ResourceLoader.exists(RUN_MAP_SCENE)


## Applies a finished run to the persistent profile, saves, then shows the result.
func finish_run(result: RunResult, show_result: bool = true) -> void:
	for stack in result.to_stash:
		var left := home_stash.add_item(stack.item, stack.quantity)
		if left > 0:
			result.stash_overflow.append(ItemStack.new(stack.item, left))

	_resolve_territories(result)

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
