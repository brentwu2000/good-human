extends Node
## High-level flow: Boot → Home → RunMap → RunResult → Home, plus the persistent
## Home Stash. Holds no in-run state; RunManager owns that inside the run scene.

const BOOT_SCENE: String = "res://scenes/boot.tscn"
const HOME_SCENE: String = "res://scenes/home.tscn"
const RUN_MAP_SCENE: String = "res://world/run_map/run_map_01.tscn"
const RUN_RESULT_SCENE: String = "res://ui/run_result/run_result.tscn"

var home_stash: Inventory
## The one human's persistent growth.
var human_growth: HumanGrowth = HumanGrowth.new()
var last_run_result: RunResult


func _ready() -> void:
	home_stash = Inventory.new(DataRegistry.balance.home_stash_slots)


## Rebuilds persistent state from SaveManager.data (call after load_game()).
func load_profile() -> void:
	home_stash.deserialize(SaveManager.data["stash"], DataRegistry.get_item)
	var human: Dictionary = SaveManager.data["human"]
	human_growth.deserialize(human.get("growth_data", {}))


func goto_home() -> void:
	_change_scene(HOME_SCENE)


func start_run() -> void:
	_change_scene(RUN_MAP_SCENE)


func can_start_run() -> bool:
	return ResourceLoader.exists(RUN_MAP_SCENE)


## Applies a finished run to the persistent profile, saves, then shows the result.
func finish_run(result: RunResult, show_result: bool = true) -> void:
	for stack in result.to_stash:
		var left := home_stash.add_item(stack.item, stack.quantity)
		if left > 0:
			result.stash_overflow.append(ItemStack.new(stack.item, left))

	var stats: Dictionary = SaveManager.data["statistics"]
	stats["runs"] = int(stats["runs"]) + 1
	if result.is_success():
		stats["successful_extractions"] = int(stats["successful_extractions"]) + 1
	if result.training != null:
		GrowthResolver.apply(human_growth, result.training, result.outcome == RunResult.Outcome.DEFEATED, DataRegistry.training)
	SaveManager.data["stash"] = home_stash.serialize()
	SaveManager.data["human"]["growth_data"] = human_growth.serialize()
	SaveManager.save_game()

	last_run_result = result
	if show_result:
		_change_scene(RUN_RESULT_SCENE)


func _change_scene(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_error("Game: scene not found: %s" % path)
		return
	get_tree().change_scene_to_file.call_deferred(path)
