extends SceneTree
## Retarget check (Claude, 2026-10-17): in Fight_Stance, the world direction each bone points
## (to its chain child) on every human vs the P-04 owner. ~0 deg = the clip reads the same.
##   godot --headless --path <project> --script res://tools/art/check_retarget.gd

const MODELS := ["office_worker/office_worker", "delivery_rider/delivery_rider", "retired_fisher/retired_fisher",
	"market_auntie/market_auntie", "ai_grandma/grandma", "gym_coach/gym_coach"]
const BONES := ["pelvis", "spine_01", "spine_02", "spine_03", "clavicle_l", "upperarm_l", "lowerarm_l", "hand_l", "upperarm_r", "lowerarm_r", "neck_01"]


func _initialize() -> void:
	_run.call_deferred()


func _dirs(visual: P04HumanVisual) -> Dictionary:
	visual.pose_clip(visual.fight_clip("Fight_Stance"), 0.3)
	var sk := visual.skeleton
	var out := {}
	for b in BONES:
		var i := sk.find_bone(b)
		var child := -1
		for c in sk.get_bone_children(i):
			var cn := sk.get_bone_name(c)
			if (b.ends_with("_l") or b.ends_with("_r")) or not (cn.ends_with("_l") or cn.ends_with("_r")):
				child = c
				break
		if child < 0:
			continue
		var a := sk.global_transform * sk.get_bone_global_pose(i).origin
		var c3 := sk.global_transform * sk.get_bone_global_pose(child).origin
		out[b] = (c3 - a).normalized()
	return out


func _run() -> void:
	var ref := P04HumanVisual.new(load("res://assets/characters/human/models/p04_owner/p04_owner_refined.glb") as PackedScene)
	get_root().add_child(ref)
	for i in 10:
		await process_frame
	var want := _dirs(ref)
	for i in 3:
		await process_frame
	want = _dirs(ref)
	for m in MODELS:
		var v := P04HumanVisual.new(load("res://assets/characters/human/models/%s.glb" % m) as PackedScene)
		get_root().add_child(v)
		for i in 10:
			await process_frame
		var got := _dirs(v)
		var line := "RT %-15s" % m.get_file()
		for b in BONES:
			if want.has(b) and got.has(b):
				line += " %s:%3.0f" % [b.replace("upperarm", "ua").replace("lowerarm", "la").replace("clavicle", "cl"), rad_to_deg((want[b] as Vector3).angle_to(got[b]))]
		print(line)
		v.queue_free()
	quit()
