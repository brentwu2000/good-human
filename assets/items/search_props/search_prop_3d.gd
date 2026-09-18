class_name SearchProp3D
extends RefCounted
## Distinct world silhouettes for searchable locations in the 3D run.

const INK := Color("#29383b")
const CREAM := Color("#efe3c8")
const TEAL := Color("#3b8f86")
const CORAL := Color("#d97058")
const WOOD := Color("#956244")
const LEAF := Color("#5a8956")


static func build(search_id: StringName, accent: Color) -> Node3D:
	var id := String(search_id)
	if "mailbox" in id:
		return _mailbox(accent)
	if "bush" in id:
		return _bush()
	if "bench" in id:
		return _bench_cache()
	if "gym" in id:
		return _gym_bag(accent)
	return _trash_bag(accent)


static func _trash_bag(accent: Color) -> Node3D:
	var root := Node3D.new()
	root.add_child(Greybox.sphere(0.31, INK.lightened(0.10), Vector3(0, 0.28, 0)))
	root.add_child(Greybox.cone(0.03, 0.11, 0.18, INK, Vector3(0, 0.61, 0)))
	root.add_child(Greybox.box(Vector3(0.20, 0.035, 0.035), accent, Vector3(0, 0.52, -0.26), Vector3(0, 0, -0.10)))
	return root


static func _mailbox(accent: Color) -> Node3D:
	var root := Node3D.new()
	root.add_child(Greybox.cylinder(0.075, 0.78, INK, Vector3(0, 0.39, 0)))
	root.add_child(Greybox.box(Vector3(0.52, 0.46, 0.38), accent, Vector3(0, 0.92, 0)))
	root.add_child(Greybox.cylinder(0.19, 0.52, accent.lightened(0.08), Vector3(0, 1.15, 0), Vector3(0, 0, PI * 0.5)))
	root.add_child(Greybox.box(Vector3(0.30, 0.055, 0.03), CREAM, Vector3(0, 0.98, -0.205)))
	root.add_child(Greybox.box(Vector3(0.06, 0.43, 0.06), CORAL, Vector3(0.34, 1.08, 0)))
	root.add_child(Greybox.box(Vector3(0.24, 0.13, 0.055), CORAL, Vector3(0.43, 1.26, 0)))
	return root


static func _bush() -> Node3D:
	var root := Node3D.new()
	root.add_child(Greybox.sphere(0.58, LEAF, Vector3(-0.28, 0.50, 0)))
	root.add_child(Greybox.sphere(0.64, LEAF.lightened(0.10), Vector3(0.28, 0.55, 0)))
	root.add_child(Greybox.sphere(0.42, LEAF.darkened(0.10), Vector3(0, 0.88, 0.02)))
	root.add_child(Greybox.box(Vector3(0.23, 0.025, 0.18), CREAM, Vector3(0.18, 0.15, -0.50), Vector3(0.05, 0.2, 0.12)))
	return root


static func _bench_cache() -> Node3D:
	var root := Node3D.new()
	root.add_child(Greybox.box(Vector3(1.65, 0.12, 0.52), WOOD, Vector3(0, 0.52, 0)))
	root.add_child(Greybox.box(Vector3(1.65, 0.60, 0.10), WOOD.lightened(0.08), Vector3(0, 0.82, 0.23)))
	for x in [-0.58, 0.58]:
		root.add_child(Greybox.box(Vector3(0.09, 0.52, 0.09), INK, Vector3(x, 0.25, 0)))
	root.add_child(Greybox.box(Vector3(0.34, 0.12, 0.24), CORAL, Vector3(0.36, 0.65, -0.10), Vector3(0.04, -0.15, 0.08)))
	return root


static func _gym_bag(accent: Color) -> Node3D:
	var root := Node3D.new()
	root.add_child(Greybox.box(Vector3(0.70, 0.38, 0.38), accent.darkened(0.12), Vector3(0, 0.22, 0)))
	root.add_child(Greybox.capsule(0.035, 0.75, CREAM.darkened(0.25), Vector3(0, 0.58, 0), Vector3(0, 0, PI * 0.5)))
	root.add_child(Greybox.box(Vector3(0.28, 0.20, 0.025), TEAL, Vector3(0, 0.23, -0.205)))
	root.add_child(Greybox.cylinder(0.08, 0.60, CORAL, Vector3(0.52, 0.10, 0), Vector3(0, 0, PI * 0.5)))
	return root
