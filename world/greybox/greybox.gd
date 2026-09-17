class_name Greybox
extends RefCounted
## Primitive meshes for the 3D greybox world (placeholder until 3D art).
## Every mesh gets its own material so it can be faded individually.

const WORLD_LAYER: int = 1
const ACTOR_LAYER: int = 1 << 1
const INTERACTABLE_LAYER: int = 1 << 2
## Occluders the camera fades when they hide the dog (foliage, props).
const FADE_GROUP: StringName = &"fade_occluder"


static func material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mat.metallic = 0.0
	return mat


static func box(size: Vector3, color: Color, position: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _instance(mesh, color, position)


static func cylinder(radius: float, height: float, color: Color, position: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	return _instance(mesh, color, position)


static func sphere(radius: float, color: Color, position: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return _instance(mesh, color, position)


## Static box on the world layer, optionally in a fade group.
static func solid_box(size: Vector3, color: Color, position: Vector3, fade_group: StringName = &"") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	body.position = position
	body.add_child(box(size, color))
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	if not fade_group.is_empty():
		body.add_to_group(fade_group)
	return body


## Tree with a trunk that blocks movement and a canopy that fades.
static func tree(position: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = position
	root.add_child(solid_box(Vector3(0.5, 3.0, 0.5), Color(0.4, 0.28, 0.18), Vector3(0, 1.5, 0), FADE_GROUP))
	var canopy := StaticBody3D.new()
	canopy.collision_layer = WORLD_LAYER
	canopy.collision_mask = 0
	canopy.position = Vector3(0, 3.8, 0)
	canopy.add_child(sphere(2.0, Color(0.25, 0.45, 0.22)))
	var shape := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = 2.0
	shape.shape = sphere_shape
	canopy.add_child(shape)
	canopy.add_to_group(FADE_GROUP)
	root.add_child(canopy)
	return root


static func human(shirt: Color, pants: Color, hair: Color, skin: Color = Color(0.93, 0.78, 0.64)) -> Node3D:
	var root := Node3D.new()
	root.add_child(capsule(0.11, 0.66, pants, Vector3(-0.10, 0.38, 0)))
	root.add_child(capsule(0.11, 0.66, pants, Vector3(0.10, 0.38, 0)))
	root.add_child(capsule(0.27, 0.58, shirt, Vector3(0, 1.12, 0)))
	root.add_child(capsule(0.07, 0.54, skin, Vector3(-0.34, 1.12, 0), Vector3(0, 0, -0.16)))
	root.add_child(capsule(0.07, 0.54, skin, Vector3(0.34, 1.12, 0), Vector3(0, 0, 0.16)))
	root.add_child(sphere(0.19, skin, Vector3(0, 1.62, 0)))
	root.add_child(sphere(0.20, hair, Vector3(0, 1.72, 0.025)))
	root.add_child(box(Vector3(0.34, 0.42, 0.14), hair.darkened(0.35), Vector3(0, 1.12, 0.24)))
	return root


## Dog facing -Z. `size` 1 = medium dog.
static func dog(color: Color, size: float = 1.0) -> Node3D:
	var root := Node3D.new()
	var dark := color.darkened(0.25)
	root.add_child(capsule(0.20, 0.72, color, Vector3(0, 0.42, 0), Vector3(PI / 2.0, 0, 0)))
	root.add_child(sphere(0.23, color, Vector3(0, 0.61, -0.43)))
	root.add_child(capsule(0.075, 0.16, Color(0.15, 0.1, 0.08), Vector3(0, 0.57, -0.64), Vector3(PI / 2.0, 0, 0)))
	root.add_child(cone(0.02, 0.10, 0.22, dark, Vector3(-0.15, 0.79, -0.43), Vector3(0.12, 0, 0.18)))
	root.add_child(cone(0.02, 0.10, 0.22, dark, Vector3(0.15, 0.79, -0.43), Vector3(-0.12, 0, -0.18)))
	root.add_child(sphere(0.032, Color(0.04, 0.03, 0.02), Vector3(-0.09, 0.68, -0.60)))
	root.add_child(sphere(0.032, Color(0.04, 0.03, 0.02), Vector3(0.09, 0.68, -0.60)))
	root.add_child(box(Vector3(0.44, 0.045, 0.07), Color(0.12, 0.55, 0.48), Vector3(0, 0.54, -0.02)))
	for x in [-0.11, 0.11]:
		for z in [-0.25, 0.25]:
			root.add_child(capsule(0.045, 0.24, dark, Vector3(x, 0.15, z)))
	root.add_child(capsule(0.035, 0.30, dark, Vector3(0, 0.58, 0.42), Vector3(PI / 2.0, 0, 0.28)))
	root.scale = Vector3.ONE * size
	return root


static func capsule(radius: float, height: float, color: Color, position: Vector3, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 3
	return _instance(mesh, color, position, rotation)


static func cone(top_radius: float, bottom_radius: float, height: float, color: Color, position: Vector3, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 8
	return _instance(mesh, color, position, rotation)


## World-space text that keeps the same size on screen and hides when far
## away (so distant names don't pile up on the horizon in the dog view).
static func label(text: String, height: float, font_size: int = 40, color: Color = Color.WHITE, max_distance: float = 16.0) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position.y = height
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = font_size
	l.outline_size = 12
	l.modulate = color
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.0007
	l.visibility_range_end = max_distance
	return l


## Makes every mesh under `node` see-through (or solid again).
static func set_faded(node: Node, faded: bool, alpha: float = 0.25) -> void:
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mat := (child as MeshInstance3D).get_surface_override_material(0) as StandardMaterial3D
		if mat == null:
			continue
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if faded else BaseMaterial3D.TRANSPARENCY_DISABLED
		mat.albedo_color.a = alpha if faded else 1.0


static func _instance(mesh: PrimitiveMesh, color: Color, position: Vector3, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.set_surface_override_material(0, material(color))
	instance.position = position
	instance.rotation = rotation
	return instance
