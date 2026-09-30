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
	# The park grandma (the old master's slot) brings her own model.
	check(OLD_MASTER.display_name == "老奶奶" and OLD_MASTER.skeletal_model != null, "the old master is the park grandma, with her own model")
	var grandma := _puppet(OLD_MASTER)
	var gv := grandma._body as P04HumanVisual
	check(gv != null and gv.model.scene_file_path.ends_with("ai_grandma/grandma.glb"), "and the fight uses it (%s)" % (gv.model.scene_file_path if gv else "none"))
	check(gv != null and gv.player.has_animation("Idle_Relaxed") and gv.player.has_animation("Jab"), "with her relaxed idle and the combat clips")
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
	check(visual.player.current_animation.ends_with("Idle_Relaxed"), "and the relaxed ambient clip plays on it (%s)" % visual.player.current_animation)
	# Outside a fight nobody stands in a guard: the relaxed clips, not the boxer's Idle.
	var plain_visual := plain._body as P04HumanVisual
	plain.set_ambient(false)
	await get_tree().process_frame
	check(plain_visual.player.current_animation == "relaxed/Idle_Relaxed", "the shared human stands relaxed (%s)" % plain_visual.player.current_animation)
	plain.set_ambient(true)
	await get_tree().process_frame
	check(plain_visual.player.current_animation == "relaxed/Walk_Relaxed", "and walks relaxed (%s)" % plain_visual.player.current_animation)
	check(plain_visual.player.has_animation("Jab") and plain_visual.player.has_animation("Idle"), "the combat clips are still there")
	var sk := plain_visual.skeleton
	var hand := sk.find_bone("hand_l")
	var shoulder := sk.find_bone("upperarm_l")
	plain_visual.player.seek(0.5, true)
	var hand_y := (sk.get_bone_global_pose(hand).origin).y
	var shoulder_y := (sk.get_bone_global_pose(shoulder).origin).y
	check(hand_y < shoulder_y - 0.4, "hands hang well below the shoulders (%.2f m below)" % (shoulder_y - hand_y))
	finish()


func _puppet(data: FighterData) -> FighterPuppet3D:
	var puppet := FighterPuppet3D.new()
	add_child(puppet)
	puppet.apply(data)
	return puppet
