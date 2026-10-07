extends "res://tests/test_case.gd"
## Owner, 2026-10-08: 「普通走路牽繩這段，變成稍微第三人稱視角，也看的到主人」.
## Walking on the lead, the shot shows the two of them: the dog ahead, the
## owner whole and solid beside it, neither covering the other — on a
## straight walk and round a turn.

const TEST_SAVE: String = "user://tests/walk_framing_save.json"

var _tree: SceneTree
var map: RunMap3D


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_tree = get_tree()
	# The phone's portrait screen, which is what makes room on the sides tight.
	_tree.root.size = Vector2i(405, 720)
	DirAccess.make_dir_recursive_absolute(TEST_SAVE.get_base_dir())
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(TEST_SAVE)
	SaveManager.save_path = TEST_SAVE
	var placeholder := Node.new()
	_tree.root.add_child(placeholder)
	_tree.current_scene = placeholder
	_tree.change_scene_to_file(Game.BOOT_SCENE)
	await _wait_for_scene(Game.HOME_SCENE)
	_tree.current_scene.get_node("%Walk3DButton").pressed.emit()
	await _wait_for_scene(Game.RUN_MAP_3D_SCENE)
	await _physics(5)
	map = _tree.current_scene as RunMap3D
	# The walk's opening places the pair; take over once it has.
	await _physics(60)

	# Open ground in the park, walking towards the pair.
	var pair := map.get_node("Encounters/pair_park") as OpponentPair3D
	map.dog.global_position = pair.global_position + Vector3(0, 0.1, 9.0)
	map.dog.facing = Vector3.FORWARD
	map.human.global_position = map.dog.global_position + Vector3(0.7, 0, 1.5)
	map.rig.snap_behind_dog()
	await _physics(5)
	var start := map.dog.global_position
	await _walk(&"move_up", 150, "straight")
	check(_flat(map.dog.global_position - start).length() > 3.0, "the dog walked (%.1f m)" % _flat(map.dog.global_position - start).length())
	Input.action_press(&"move_up")
	Input.action_press(&"move_right", 0.6)
	await _sample(150, "turning")
	Input.action_release(&"move_right")
	Input.action_release(&"move_up")
	finish()


func _walk(action: StringName, frames: int, label: String) -> void:
	Input.action_press(action)
	await _physics(60)
	await _sample(frames - 60, label)
	Input.action_release(action)


## Over `frames`, how often the owner is seen whole and solid, the dog is seen,
## and the owner stays off the dog on screen.
func _sample(frames: int, label: String) -> void:
	var camera := map.rig.camera
	var seen := 0
	var solid := 0
	var dog_seen := 0
	var clear := 0
	for i in frames:
		await _tree.physics_frame
		var owner := map.human.global_position
		var head := owner + Vector3(0, 1.75, 0)
		var whole := camera.is_position_in_frustum(owner + Vector3(0, 0.05, 0)) and camera.is_position_in_frustum(head)
		seen += 1 if whole else 0
		solid += 1 if not map.human.faded else 0
		dog_seen += 1 if map.rig.is_dog_visible() else 0
		var dog_screen := camera.unproject_position(map.dog.global_position + Vector3(0, 0.3, 0))
		var owner_left := camera.unproject_position(owner + Vector3(0, 0.9, 0)) - camera.unproject_position(owner + Vector3(0, 0.9, 0) + camera.global_basis.x * 0.3)
		var owner_screen := camera.unproject_position(owner + Vector3(0, 0.9, 0))
		var half_width := absf(owner_left.x)
		var feet := camera.unproject_position(owner).y
		var top := camera.unproject_position(head).y
		var covers := absf(dog_screen.x - owner_screen.x) < half_width + 12.0 and dog_screen.y > top and dog_screen.y < feet
		clear += 0 if covers else 1
	var share := func(n: int) -> float: return float(n) / frames
	check(share.call(seen) >= 0.9, "%s: the owner is in the shot, head to foot (%.0f%%)" % [label, share.call(seen) * 100.0])
	check(share.call(solid) >= 0.9, "%s: and drawn solid, not faded (%.0f%%)" % [label, share.call(solid) * 100.0])
	check(share.call(dog_seen) >= 0.98, "%s: the dog is always in the shot (%.0f%%)" % [label, share.call(dog_seen) * 100.0])
	check(share.call(clear) >= 0.9, "%s: the owner does not cover the dog (%.0f%%)" % [label, share.call(clear) * 100.0])


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0, v.z)


func _physics(frames: int) -> void:
	for i in frames:
		await _tree.physics_frame


func _wait_for_scene(path: String) -> void:
	for i in 600:
		await _tree.process_frame
		if _tree.current_scene != null and _tree.current_scene.scene_file_path == path:
			return
	push_error("timed out waiting for " + path)
