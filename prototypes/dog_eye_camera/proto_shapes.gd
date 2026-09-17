class_name ProtoShapes
extends RefCounted
## Primitive mesh helpers for the P-01 greybox (no final art).


static func material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	return mat


static func box(size: Vector3, color: Color, position: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material(color)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	return instance


static func cylinder(radius: float, height: float, color: Color, position: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.material = material(color)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	return instance


static func sphere(radius: float, color: Color, position: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.material = material(color)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	return instance


## Solid box with collision on the world layer.
static func solid_box(size: Vector3, color: Color, position: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = position
	body.add_child(box(size, color))
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	return body


## Standing human: legs, body, head; `scale_y` changes height.
static func human(shirt: Color, pants: Color, hair: Color, scale_y: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.add_child(box(Vector3(0.32, 0.85, 0.22), pants, Vector3(0, 0.43, 0)))
	root.add_child(box(Vector3(0.46, 0.6, 0.26), shirt, Vector3(0, 1.15, 0)))
	root.add_child(sphere(0.14, Color(0.93, 0.78, 0.64), Vector3(0, 1.6, 0)))
	root.add_child(box(Vector3(0.3, 0.08, 0.3), hair, Vector3(0, 1.72, 0)))
	root.scale = Vector3(1, scale_y, 1)
	return root


## Greybox dog: body, head, nose, ears, tail, legs. `size` 1 = medium dog.
static func dog(color: Color, size: float = 1.0) -> Node3D:
	var root := Node3D.new()
	var dark := color.darkened(0.25)
	root.add_child(box(Vector3(0.34, 0.3, 0.72), color, Vector3(0, 0.4, 0)))
	root.add_child(box(Vector3(0.28, 0.28, 0.3), color, Vector3(0, 0.62, -0.44)))
	root.add_child(box(Vector3(0.12, 0.1, 0.14), Color(0.15, 0.1, 0.08), Vector3(0, 0.56, -0.64)))
	for x in [-0.1, 0.1]:
		root.add_child(box(Vector3(0.07, 0.12, 0.05), dark, Vector3(x, 0.8, -0.4)))
	root.add_child(box(Vector3(0.06, 0.06, 0.28), dark, Vector3(0, 0.55, 0.44)))
	for x in [-0.11, 0.11]:
		for z in [-0.25, 0.25]:
			root.add_child(box(Vector3(0.08, 0.26, 0.08), dark, Vector3(x, 0.13, z)))
	root.scale = Vector3.ONE * size
	return root


static func label(text: String, height: float, font_size: int = 48, color: Color = Color.WHITE) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position.y = height
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = font_size
	l.outline_size = 12
	l.modulate = color
	l.no_depth_test = true
	# Same on-screen size at any distance (close chase cameras made it huge).
	l.fixed_size = true
	l.pixel_size = 0.001
	return l
