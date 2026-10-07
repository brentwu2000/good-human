class_name BodyContact
extends RefCounted
## Two posed people as capsules (head, torso, arms, legs), and how deep one
## is inside the other. Fighting games stop a blow where it meets the body;
## the clips are authored at full extension, so the fight uses this to hold a
## strike at the moment it touches (`FighterPuppet3D._stop_at_body`), and
## `fight_body_contact_test` uses it to check nobody passes through anybody.

## [from bone, to bone, radius m, part]. The head is a sphere above its bone.
const CAPSULES: Array = [
	["pelvis", "neck_01", 0.12, "torso"],
	["head", "head", 0.1, "head"],
	["upperarm_l", "lowerarm_l", 0.05, "arm"],
	["lowerarm_l", "hand_l", 0.04, "forearm"],
	["upperarm_r", "lowerarm_r", 0.05, "arm"],
	["lowerarm_r", "hand_r", 0.04, "forearm"],
	["thigh_l", "calf_l", 0.07, "thigh"],
	["calf_l", "foot_l", 0.05, "shin"],
	["thigh_r", "calf_r", 0.07, "thigh"],
	["calf_r", "foot_r", 0.05, "shin"],
]
const HEAD_LIFT: float = 0.09


## [[from, to, radius, part], ...] in world space for `skeleton`'s pose now.
static func capsules(skeleton: Skeleton3D) -> Array:
	var out: Array = []
	if skeleton == null:
		return out
	var world := skeleton.global_transform
	for c: Array in CAPSULES:
		var from := skeleton.find_bone(c[0])
		var to := skeleton.find_bone(c[1])
		if from < 0 or to < 0:
			continue
		var pose := skeleton.get_bone_global_pose(from)
		var p0 := world * pose.origin
		var p1 := world * skeleton.get_bone_global_pose(to).origin
		if c[3] == "head":
			p0 += (world.basis * pose.basis.y).normalized() * HEAD_LIFT
			p1 = p0
		out.append([p0, p1, c[2], c[3]])
	return out


## [depth m, part of a, part of b] of the deepest overlap (depth 0: apart),
## with every capsule `pad` m thicker (a gap to keep).
static func deepest(a: Array, b: Array, pad: float = 0.0) -> Array:
	var best := [0.0, "", ""]
	for x: Array in a:
		for y: Array in b:
			var points := Geometry3D.get_closest_points_between_segments(x[0], x[1], y[0], y[1])
			var depth: float = x[2] + y[2] + 2.0 * pad - (points[0] as Vector3).distance_to(points[1])
			if depth > best[0]:
				best = [depth, x[3], y[3]]
	return best
