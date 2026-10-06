class_name EnvironmentKit3D
extends RefCounted
## GOOD HUMAN! neighbourhood starter kit.
## Code-native low-poly assets keep the prototype light and editable while
## giving the dog-height camera a coherent, warm urban identity.

const INK := Color("#29383b")
const CREAM := Color("#f2e5c7")
const TEAL := Color("#2f817b")
const CORAL := Color("#d86f58")
const WOOD := Color("#9a6445")
const LEAF := Color("#568657")
const LEAF_LIGHT := Color("#72a366")
const CONCRETE := Color("#b9afa1")
const GLASS := Color("#9cc7cf")

## Modelled pieces (Claude, at the owner's request 2026-10-06;
## tools/art/build_walk_kit.py). The kit's bodies — collision, the camera's
## fade group — are unchanged; only what is drawn is swapped. Off: the
## greybox shapes, as before.
static var use_models: bool = true
const MODELS := {
	&"tree_trunk": preload("res://assets/environment/walk_kit/tree_trunk.glb"),
	&"tree_canopy": preload("res://assets/environment/walk_kit/tree_canopy.glb"),
	&"bush": preload("res://assets/environment/walk_kit/bush.glb"),
	&"park_bench": preload("res://assets/environment/walk_kit/park_bench.glb"),
	&"lamp": preload("res://assets/environment/walk_kit/lamp.glb"),
	&"bin": preload("res://assets/environment/walk_kit/bin.glb"),
	&"gate_pillar": preload("res://assets/environment/walk_kit/gate_pillar.glb"),
	&"gate_lintel": preload("res://assets/environment/walk_kit/gate_lintel.glb"),
	&"bus_stop": preload("res://assets/environment/walk_kit/bus_stop.glb"),
	&"shop_a": preload("res://assets/environment/walk_kit/shop_a.glb"),
	&"shop_b": preload("res://assets/environment/walk_kit/shop_b.glb"),
	&"block_a": preload("res://assets/environment/walk_kit/block_a.glb"),
	&"block_b": preload("res://assets/environment/walk_kit/block_b.glb"),
}


## Hides the greybox drawn under `node` and puts the model there instead.
static func _dress(node: Node3D, model: StringName, offset: Vector3 = Vector3.ZERO, scale_factor: float = 1.0) -> void:
	if not use_models:
		return
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).visible = false
	var dressed := (MODELS[model] as PackedScene).instantiate() as Node3D
	dressed.position = offset
	dressed.scale = Vector3.ONE * scale_factor
	node.add_child(dressed)


## Buildings are solid volumes, not see-through occluders: one between the
## camera and the dog pulls the camera in (and only fades once pulling in would
## bring it closer than the rig allows). Fading them instead would let the
## camera settle inside the building and watch the dog through the wall.
static func building(size: Vector3, color: Color, position: Vector3, variant: int = 0) -> Node3D:
	var root := Node3D.new()
	var body := Greybox.solid_box(size, color, position)
	root.add_child(body)
	var front_z := -size.z * 0.5 - 0.035
	var rows := maxi(1, int(size.y / 1.65))
	var columns := maxi(2, int(size.x / 2.1))
	for row in rows:
		for column in columns:
			var x := -size.x * 0.5 + (column + 0.5) * size.x / columns
			var y := -size.y * 0.5 + 1.15 + row * 1.55
			var window_color := GLASS.darkened(0.08 * ((row + column + variant) % 3))
			body.add_child(Greybox.box(Vector3(0.86, 0.82, 0.07), INK, Vector3(x, y, front_z)))
			body.add_child(Greybox.box(Vector3(0.68, 0.64, 0.085), window_color, Vector3(x, y, front_z - 0.012)))
			body.add_child(Greybox.box(Vector3(0.035, 0.64, 0.10), CREAM.darkened(0.12), Vector3(x, y, front_z - 0.03)))
	var door_x := -size.x * 0.28 if variant % 2 == 0 else size.x * 0.28
	body.add_child(Greybox.box(Vector3(0.82, 1.55, 0.10), INK, Vector3(door_x, -size.y * 0.5 + 0.80, front_z - 0.02)))
	body.add_child(Greybox.box(Vector3(0.60, 1.35, 0.12), TEAL if variant % 2 == 0 else CORAL, Vector3(door_x, -size.y * 0.5 + 0.78, front_z - 0.05)))
	body.add_child(Greybox.sphere(0.055, CREAM, Vector3(door_x + 0.20, -size.y * 0.5 + 0.76, front_z - 0.13)))
	var trim := CORAL if variant % 2 == 0 else TEAL
	body.add_child(Greybox.box(Vector3(size.x + 0.10, 0.16, 0.14), trim, Vector3(0, size.y * 0.5 - 0.20, front_z - 0.04)))
	body.add_child(Greybox.box(Vector3(size.x * 0.58, 0.12, 0.52), trim.darkened(0.08), Vector3(0, -size.y * 0.5 + 1.72, front_z - 0.22), Vector3(-0.12, 0, 0)))
	var kind := "block" if size.z >= 8.0 else "shop"
	_dress(body, StringName("%s_%s" % [kind, "a" if variant % 2 == 0 else "b"]))
	return root


static func tree(position: Vector3, scale_factor: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.position = position
	var trunk := Greybox.solid_box(Vector3(0.48, 2.8, 0.48) * scale_factor, WOOD, Vector3(0, 1.4 * scale_factor, 0), Greybox.FADE_GROUP)
	root.add_child(trunk)
	var canopy := StaticBody3D.new()
	canopy.collision_layer = Greybox.WORLD_LAYER
	canopy.collision_mask = 0
	canopy.position = Vector3(0, 3.35 * scale_factor, 0)
	canopy.add_to_group(Greybox.FADE_GROUP)
	for data: Array in [
		[Vector3(-0.62, 0.0, 0.05), 1.22, LEAF],
		[Vector3(0.58, 0.08, 0.12), 1.18, LEAF_LIGHT],
		[Vector3(0.0, 0.62, -0.08), 1.30, LEAF],
		[Vector3(0.05, -0.18, -0.72), 1.02, LEAF.darkened(0.08)],
	]:
		canopy.add_child(Greybox.sphere(data[1] * scale_factor, data[2], data[0] * scale_factor))
	var shape := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = 1.65 * scale_factor
	shape.shape = sphere_shape
	canopy.add_child(shape)
	root.add_child(canopy)
	# Trunk and canopy each under their own body, so each fades on its own.
	_dress(trunk, &"tree_trunk", Vector3(0, -1.4 * scale_factor, 0), scale_factor)
	_dress(canopy, &"tree_canopy", Vector3(0, -3.35 * scale_factor, 0), scale_factor)
	return root


static func bush(position: Vector3, scale_factor: float = 1.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = position
	body.collision_layer = Greybox.WORLD_LAYER
	body.collision_mask = 0
	body.add_to_group(Greybox.FADE_GROUP)
	body.add_child(Greybox.sphere(0.62 * scale_factor, LEAF, Vector3(-0.42, 0.58, 0)))
	body.add_child(Greybox.sphere(0.70 * scale_factor, LEAF_LIGHT, Vector3(0.20, 0.66, -0.08)))
	body.add_child(Greybox.sphere(0.55 * scale_factor, LEAF.darkened(0.08), Vector3(0.62, 0.50, 0.12)))
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(1.65, 1.05, 1.20) * scale_factor
	shape.position.y = 0.52 * scale_factor
	shape.shape = box_shape
	body.add_child(shape)
	_dress(body, &"bush", Vector3.ZERO, scale_factor)
	return body


static func bench(position: Vector3, rotation_y: float = 0.0) -> StaticBody3D:
	var body := Greybox.solid_box(Vector3(2.2, 0.12, 0.62), WOOD, position + Vector3(0, 0.58, 0), Greybox.FADE_GROUP)
	body.rotation.y = rotation_y
	body.add_child(Greybox.box(Vector3(2.2, 0.72, 0.12), WOOD.lightened(0.06), Vector3(0, 0.34, 0.25), Vector3(-0.10, 0, 0)))
	for x in [-0.82, 0.82]:
		body.add_child(Greybox.box(Vector3(0.10, 0.62, 0.10), INK, Vector3(x, -0.28, 0)))
		body.add_child(Greybox.box(Vector3(0.10, 0.62, 0.10), INK, Vector3(x, -0.28, 0.22)))
	_dress(body, &"park_bench", Vector3(0, -0.58, 0))
	return body


static func park_gate(position: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = position
	for x in [-3.2, 3.2]:
		root.add_child(Greybox.solid_box(Vector3(0.52, 2.65, 0.52), CONCRETE, Vector3(x, 1.325, 0), Greybox.FADE_GROUP))
		root.add_child(Greybox.box(Vector3(0.66, 0.14, 0.66), CREAM, Vector3(x, 2.68, 0)))
	root.add_child(Greybox.box(Vector3(7.0, 0.32, 0.34), TEAL, Vector3(0, 2.88, 0)))
	root.add_child(Greybox.box(Vector3(2.9, 0.82, 0.18), CREAM, Vector3(0, 2.90, -0.20)))
	root.add_child(Greybox.box(Vector3(2.5, 0.48, 0.20), CORAL, Vector3(0, 2.90, -0.31)))
	if use_models:
		for child in root.get_children():
			if child is StaticBody3D:
				_dress(child, &"gate_pillar", Vector3(0, -1.325, 0))
			elif child is MeshInstance3D:
				child.visible = false
		root.add_child((MODELS[&"gate_lintel"] as PackedScene).instantiate())
	return root


static func lamp(position: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = position
	root.add_child(Greybox.cylinder(0.055, 2.9, INK, Vector3(0, 1.45, 0)))
	root.add_child(Greybox.box(Vector3(0.58, 0.07, 0.07), INK, Vector3(0.23, 2.78, 0)))
	root.add_child(Greybox.box(Vector3(0.36, 0.16, 0.28), CREAM, Vector3(0.47, 2.67, 0)))
	_dress(root, &"lamp")
	return root


static func bin(position: Vector3, color: Color = TEAL) -> StaticBody3D:
	var body := Greybox.solid_box(Vector3(0.60, 0.88, 0.55), color, position + Vector3(0, 0.44, 0), Greybox.FADE_GROUP)
	body.add_child(Greybox.box(Vector3(0.68, 0.10, 0.62), INK, Vector3(0, 0.48, 0)))
	body.add_child(Greybox.box(Vector3(0.34, 0.09, 0.08), CREAM, Vector3(0, 0.14, -0.32)))
	_dress(body, &"bin", Vector3(0, -0.44, 0))
	return body


static func bus_stop(position: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = position
	for x in [-1.35, 1.35]:
		root.add_child(Greybox.solid_box(Vector3(0.09, 2.4, 0.09), INK, Vector3(x, 1.2, 0), Greybox.FADE_GROUP))
	root.add_child(Greybox.box(Vector3(3.0, 0.14, 1.45), TEAL, Vector3(0, 2.42, 0.12)))
	root.add_child(Greybox.box(Vector3(2.70, 1.75, 0.055), GLASS, Vector3(0, 1.28, 0.62)))
	root.add_child(Greybox.box(Vector3(2.74, 0.08, 0.08), INK, Vector3(0, 0.42, 0.62)))
	root.add_child(Greybox.box(Vector3(2.74, 0.08, 0.08), INK, Vector3(0, 2.14, 0.62)))
	root.add_child(bench(Vector3(0, 0, 0.24)))
	root.add_child(Greybox.box(Vector3(0.62, 0.82, 0.08), CORAL, Vector3(-0.90, 1.58, 0.56)))
	_dress(root, &"bus_stop")
	return root
