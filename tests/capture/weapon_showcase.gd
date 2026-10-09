extends Node
## Owner, 2026-10-09 (「請開起來測試給我看一下各種武器使用情境」): every way
## the owner holds and uses each weapon, one after another, named on screen,
## seen side-on in the real 3D walk. Attacks play at speed, then slowed down.
## A recording tool, not a test:
##
##   godot --path <project> --write-movie build/captures/weapon_<id>.avi \
##         --fixed-fps 30 --resolution 960x540 \
##         res://tests/capture/weapon_showcase.tscn -- <umbrella|broom>

const SLOW: float = 0.35
const STEPS := {
	&"umbrella": [
		["拿著走路（像拐杖，傘尖朝下）", "Carry_Walk_Armed", 2.6, "walk"],
		["拿著站著", "Carry_Idle_Armed", 1.6, "loop"],
		["備戰：手杖式前架，傘尖指向對方臉部", "Fight_Stance_Armed", 2.0, "loop"],
		["前進", "Fight_Step_Fwd_Armed", 1.2, "loop"],
		["後退", "Fight_Step_Back_Armed", 1.2, "loop"],
		["刺擊", "Fight_Thrust", 0.0, "attack"],
		["劈擊（轉腰帶動）", "Fight_Swing", 0.0, "attack"],
		["格擋：高位懸架", "Fight_Block_Armed", 1.6, "hold"],
		["閃避", "Fight_Dodge_Armed", 0.0, "attack"],
		["輕受擊", "Fight_HitLight_Armed", 0.0, "attack"],
		["重受擊", "Fight_HitHeavy_Armed", 0.0, "attack"],
	],
	&"broom": [
		["拿著走路（握中段，刷頭朝下）", "Carry_Walk_Long", 2.6, "walk"],
		["拿著站著", "Carry_Idle_Long", 1.6, "loop"],
		["備戰：雙手刺刀式，刷頭朝前", "Fight_Stance_Long", 2.0, "loop"],
		["前進", "Fight_Step_Fwd_Long", 1.2, "loop"],
		["後退", "Fight_Step_Back_Long", 1.2, "loop"],
		["雙手刺擊", "Fight_Thrust_Long", 0.0, "attack"],
		["舉高下劈", "Fight_Swing_Long", 0.0, "attack"],
		["近身推擊", "Fight_Shove_Long", 0.0, "attack"],
		["格擋：桿子橫舉在臉前", "Fight_Block_Long", 1.6, "hold"],
		["閃避", "Fight_Dodge_Long", 0.0, "attack"],
		["輕受擊", "Fight_HitLight_Long", 0.0, "attack"],
		["重受擊", "Fight_HitHeavy_Long", 0.0, "attack"],
	],
}
## How far apart they stand with it (the weapon's own fighting distance).
const APART := {&"umbrella": 1.25, &"broom": 1.4}

var _tree: SceneTree
var _caption: Label
var _owner: FighterPuppet3D
var _other: FighterPuppet3D


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_tree = get_tree()
	var args := OS.get_cmdline_user_args()
	var id := StringName(args[0]) if not args.is_empty() else &"umbrella"
	SaveManager.save_path = "user://captures/showcase_save.json"
	DirAccess.make_dir_recursive_absolute("user://captures")
	if FileAccess.file_exists(SaveManager.save_path):
		DirAccess.remove_absolute(SaveManager.save_path)
	Game.use_classic_pair_when_missing = true
	FighterPuppet3D.show_combat_text = false
	var placeholder := Node.new()
	_tree.root.add_child(placeholder)
	_tree.current_scene = placeholder
	_tree.change_scene_to_file(Game.BOOT_SCENE)
	await _wait_for_scene(Game.HOME_SCENE)
	_tree.current_scene.get_node("%Walk3DButton").pressed.emit()
	await _wait_for_scene(Game.RUN_MAP_3D_SCENE)
	var map := _tree.current_scene as RunMap3D
	await _frames(30)
	# Nothing else moves them: the owner stops following the dog.
	map.human.set_physics_process(false)
	map.human.say("", Color.WHITE, 0.0)
	for layer in map.find_children("*", "CanvasLayer", true, false):
		(layer as CanvasLayer).visible = false
	var pair := map.get_node("Encounters/pair_park") as OpponentPair3D
	_owner = map.human.puppet
	_other = pair.human_puppet
	_owner.hold(DataRegistry.get_weapon(id))
	# Open ground beside the park pair; the dog sits out of the way behind.
	var spot := pair.global_position + Vector3(0, 0, 5.0)
	map.human.global_position = spot
	_other.global_position = spot + Vector3(APART[id], 0, 0)
	map.dog.global_position = spot + Vector3(-1.4, 0.1, 0.9)
	_face(_owner, _other.global_position)
	_face(_other, _owner.global_position)
	var middle := spot + Vector3(APART[id] * 0.5, 0, 0)
	var camera := Camera3D.new()
	map.add_child(camera)
	# From the owner's lead-hand side, a little in front of them.
	camera.global_position = middle + Vector3(-0.35, 1.15, -3.1)
	camera.look_at(middle + Vector3(-0.2, 0.95, 0), Vector3.UP)
	camera.fov = 50.0
	camera.make_current()
	_caption = _make_caption()
	(_other._body as P04HumanVisual).play_clip("fight/Fight_Stance")
	var visual := _owner._body as P04HumanVisual
	var title := "雨傘" if id == &"umbrella" else "掃把"
	for step: Array in STEPS[id]:
		var clip := "fight/%s" % step[1]
		if not visual.player.has_animation(clip):
			push_error("weapon_showcase: missing %s" % clip)
			continue
		var length := visual.player.get_animation(clip).length
		match step[3]:
			"walk":
				_caption.text = "%s｜%s" % [title, step[0]]
				map.human.global_position = spot + Vector3(-1.6, 0, 0)
				await _play(visual, clip, length, step[2], 1.0, Vector3(1.6 / step[2], 0, 0), map.human)
				map.human.global_position = spot
			"loop", "hold":
				_caption.text = "%s｜%s" % [title, step[0]]
				await _play(visual, clip, length, step[2], 1.0 if step[3] == "loop" else 0.0, Vector3.ZERO, null)
			"attack":
				_caption.text = "%s｜%s" % [title, step[0]]
				await _play(visual, clip, length, length, 1.0, Vector3.ZERO, null)
				await _play(visual, "fight/" + ("Fight_Stance_Armed" if id == &"umbrella" else "Fight_Stance_Long"), 1.0, 0.4, 1.0, Vector3.ZERO, null)
				_caption.text = "%s｜%s（慢動作）" % [title, step[0]]
				await _play(visual, clip, length, length / SLOW, SLOW, Vector3.ZERO, null)
		await _play(visual, "fight/" + ("Fight_Stance_Armed" if id == &"umbrella" else "Fight_Stance_Long"), 1.0, 0.5, 1.0, Vector3.ZERO, null)
	_tree.quit()


## Poses `clip` for `seconds` at `speed` (0: held at its middle), moving
## `mover` by `velocity`.
func _play(visual: P04HumanVisual, clip: String, length: float, seconds: float, speed: float, velocity: Vector3, mover: Node3D) -> void:
	var elapsed := 0.0
	var frames := maxi(1, int(seconds * 30.0))
	for i in frames:
		var t := 0.5 if speed == 0.0 else fmod(elapsed * speed, length) / length
		visual.pose_clip(clip, t)
		if mover != null:
			mover.global_position += velocity / 30.0
		await _tree.process_frame
		elapsed += 1.0 / 30.0


func _face(puppet: FighterPuppet3D, point: Vector3) -> void:
	var d := point - puppet.global_position
	puppet.rotation.y = atan2(-d.x, -d.z)


func _make_caption() -> Label:
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 10)
	label.position = Vector2(24, 18)
	label.size = Vector2(672, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	layer.add_child(label)
	return label


func _frames(n: int) -> void:
	for i in n:
		await _tree.process_frame


func _wait_for_scene(path: String) -> void:
	for i in 600:
		await _tree.process_frame
		if _tree.current_scene != null and _tree.current_scene.scene_file_path == path:
			await _tree.process_frame
			return
