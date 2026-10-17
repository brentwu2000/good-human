extends SceneTree
## Where each human's elbows and hands are in the shared fight clips (Claude, 2026-10-17):
## guard (Fight_Stance) and a jab at its peak. Body frame: forward = -Z, up = +Y, metres
## relative to the head bone, scaled by the character's height.
##   godot --headless --path <project> --script res://tools/art/measure_fight_pose.gd

const MODELS := ["p04_owner/p04_owner", "office_worker/office_worker", "delivery_rider/delivery_rider",
	"retired_fisher/retired_fisher", "market_auntie/market_auntie", "ai_grandma/grandma",
	"gym_coach/gym_coach", "xiaomi/xiaomi"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for m in MODELS:
		var scene := load("res://assets/characters/human/models/%s.glb" % m) as PackedScene
		var visual := P04HumanVisual.new(scene)
		get_root().add_child(visual)
		await process_frame
		var line := "POSE %-16s" % m.get_file()
		for clip in ["Fight_Stance", "Fight_Jab"]:
			var name := visual.fight_clip(clip)
			visual.pose_clip(name, 0.0 if clip == "Fight_Stance" else 0.5)
			for i in 6:
				await process_frame
			var sk := visual.skeleton
			var head := _at(sk, "head")
			var height := head.y
			line += " | %s" % clip
			for b in ["lowerarm_l", "hand_l", "lowerarm_r", "hand_r"]:
				var p := (_at(sk, b) - head) / maxf(height, 0.5)
				line += "  %s fwd %+.2f up %+.2f" % [b.replace("lowerarm", "elbow"), -p.z, p.y]
		print(line)
		visual.queue_free()
		await process_frame
	quit()


func _at(sk: Skeleton3D, bone: String) -> Vector3:
	var i := sk.find_bone(bone)
	return sk.global_transform * sk.get_bone_global_pose(i).origin if i >= 0 else Vector3.ZERO
