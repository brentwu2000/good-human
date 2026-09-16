extends Node
## High-level scene flow: Boot → Home → RunMap → RunResult → Home.
## Holds no run state; RunManager owns that inside the run scene.

const BOOT_SCENE: String = "res://scenes/boot.tscn"
const HOME_SCENE: String = "res://scenes/home.tscn"
const RUN_MAP_SCENE: String = "res://world/run_map/run_map_01.tscn"


func goto_home() -> void:
	_change_scene(HOME_SCENE)


func start_run() -> void:
	_change_scene(RUN_MAP_SCENE)


func can_start_run() -> bool:
	return ResourceLoader.exists(RUN_MAP_SCENE)


func _change_scene(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_error("Game: scene not found: %s" % path)
		return
	get_tree().change_scene_to_file.call_deferred(path)
