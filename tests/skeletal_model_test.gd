extends "res://tests/test_case.gd"
## FighterData.skeletal_model: a fighter can bring its own model rigged on the
## P-04 OwnerSkeleton. The shared adapter drives it with the same clips, and it
## keeps its own size (body_scale only shapes the shared P-04 human).

const OLD_MASTER: FighterData = preload("res://data/combat/fighters/oppx01_old_master.tres")
const STAND_IN: PackedScene = preload("res://assets/characters/human/models/p04_owner/p04_owner.glb")


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	if not ProjectSettings.get_setting("art/use_p04_candidate", false):
		check(true, "skeletal art is off in this project: nothing to test")
		finish()
		return
	var shared := OLD_MASTER.duplicate() as FighterData
	shared.skeletal_model = null
	shared.body_scale = Vector2(0.85, 0.88)
	var plain := _puppet(shared)
	check(plain._body is P04HumanVisual, "without a model of its own: the shared P-04 human")
	check(plain._body.scale.is_equal_approx(Vector3(0.85, 0.88, 0.85)), "shaped by body_scale")

	var own := shared.duplicate() as FighterData
	own.skeletal_model = STAND_IN
	var custom := _puppet(own)
	var visual := custom._body as P04HumanVisual
	check(visual != null, "a fighter's own model goes through the same adapter")
	check(visual.model.scene_file_path == STAND_IN.resource_path, "and it is that fighter's model (%s)" % visual.model.scene_file_path)
	check(custom._body.scale.is_equal_approx(Vector3.ONE), "at its own size, not body_scale")
	check(visual.skeleton != null and visual.player != null and visual.player.has_animation("Idle"), "rigged and animated like the shared human")
	check(visual.skeleton.find_bone("pelvis") >= 0 and visual.skeleton.find_bone("upperarm_l") >= 0, "on the OwnerSkeleton bone names the adapter maps")
	custom.set_ambient(false)
	await get_tree().process_frame
	check(visual.player.current_animation == "Idle", "and the ambient clip plays on it")
	finish()


func _puppet(data: FighterData) -> FighterPuppet3D:
	var puppet := FighterPuppet3D.new()
	add_child(puppet)
	puppet.apply(data)
	return puppet
