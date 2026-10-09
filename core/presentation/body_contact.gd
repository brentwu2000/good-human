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


## A held prop as capsules along its +Y (the shaft through the fist), from
## its own meshes: cut into SLICES along the shaft, each as thick as the
## mesh there, so a broom's head is fat and its handle thin. Worked out once
## per prop (in its own frame) and placed where it is now.
const SLICES: int = 6


static func prop_capsules(prop: Node3D, at: Variant = null) -> Array:
	if prop == null:
		return []
	if not prop.has_meta("contact_slices"):
		prop.set_meta("contact_slices", _slice_prop(prop))
	var out: Array = []
	if at == null:
		at = prop.global_transform
	var place: Transform3D = at
	for slice: Array in prop.get_meta("contact_slices"):
		out.append([place * slice[0], place * slice[1], slice[2], "weapon%d" % out.size()])
	return out


static func _slice_prop(prop: Node3D) -> Array:
	var to_prop := prop.global_transform.affine_inverse()
	var points: Array[Vector3] = []
	for node in prop.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var into := to_prop * mesh_instance.global_transform
		for surface in mesh_instance.mesh.get_surface_count():
			var vertices: PackedVector3Array = mesh_instance.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for v in vertices:
				points.append(into * v)
	if points.is_empty():
		return []
	var low := INF
	var high := -INF
	for p in points:
		low = minf(low, p.y)
		high = maxf(high, p.y)
	var step := (high - low) / SLICES
	var radii: Array[float] = []
	radii.resize(SLICES)
	radii.fill(0.0)
	for p in points:
		var i := clampi(int((p.y - low) / maxf(step, 0.0001)), 0, SLICES - 1)
		radii[i] = maxf(radii[i], Vector2(p.x, p.z).length())
	var slices: Array = []
	for i in SLICES:
		slices.append([Vector3(0, low + step * i, 0), Vector3(0, low + step * (i + 1), 0), maxf(radii[i], 0.01)])
	return slices
