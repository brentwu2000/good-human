class_name ClinicWindow
extends RefCounted
## Sprint 06 (owner direction 2026-10-05): the opening happens at one place —
## the pen by the front window of a small animal hospital. Choosing the dog
## looks in at it from the street (ShelterScene); then the player IS the pup
## inside, looking out (AdoptionScene). Both build the same place from here.
## Placeholder geometry until Codex's D6-01/D6-03 art.

## The glass is at z = WINDOW_Z; the pen is inside (+z), the street outside.
const WINDOW_Z: float = -1.3
## The pen: x and z limits; the glass is just beyond PEN_MIN.y.
const PEN_MIN := Vector2(-1.25, WINDOW_Z + 0.18)
const PEN_MAX := Vector2(1.25, 0.25)
## A low sill, so a pup at the glass can be seen from the pavement and can
## see out over it.
const SILL: float = 0.12
const PUPPY_SCALE: float = 0.62


## The clinic behind the pen: floor, back wall, the counter, the pen itself.
## `back_fence` off when the view is from inside the pen (AdoptionScene): the
## rail behind the pup would cut across the view.
static func build_inside(parent: Node3D, back_fence: bool = true) -> void:
	parent.add_child(Greybox.box(Vector3(8, 0.04, 3.4), Color(0.76, 0.78, 0.77), Vector3(0, -0.02, 0.4)))
	for x in range(-4, 5):
		parent.add_child(Greybox.box(Vector3(0.012, 0.045, 3.4), Color(0.74, 0.77, 0.76), Vector3(x * 0.8, -0.015, 0.4)))
	parent.add_child(Greybox.box(Vector3(8, 3.0, 0.1), Color(0.95, 0.96, 0.95), Vector3(0, 1.5, 2.1)))
	parent.add_child(Greybox.box(Vector3(8, 1.0, 0.02), Color(0.72, 0.86, 0.82), Vector3(0, 0.5, 2.04)))
	for x in [-4.0, 4.0]:
		parent.add_child(Greybox.box(Vector3(0.1, 3.0, 3.4), Color(0.93, 0.94, 0.93), Vector3(x, 1.5, 0.4)))
	parent.add_child(Greybox.box(Vector3(8, 0.1, 3.4), Color(0.97, 0.97, 0.96), Vector3(0, 2.95, 0.4)))
	# The front counter, a notice board, a chair for whoever is waiting.
	parent.add_child(Greybox.box(Vector3(1.8, 1.05, 0.6), Color(0.86, 0.8, 0.7), Vector3(-2.5, 0.525, 1.4)))
	parent.add_child(Greybox.box(Vector3(1.9, 0.05, 0.7), Color(0.95, 0.94, 0.9), Vector3(-2.5, 1.07, 1.4)))
	parent.add_child(Greybox.box(Vector3(0.7, 0.9, 0.02), Color(0.86, 0.74, 0.55), Vector3(0.4, 1.7, 2.03)))
	parent.add_child(Greybox.box(Vector3(0.24, 0.3, 0.01), Color(0.98, 0.96, 0.9), Vector3(0.28, 1.78, 2.015)))
	parent.add_child(Greybox.box(Vector3(0.22, 0.18, 0.01), Color(0.95, 0.85, 0.85), Vector3(0.55, 1.55, 2.015)))
	parent.add_child(Greybox.box(Vector3(0.45, 0.06, 0.45), Color(0.4, 0.55, 0.62), Vector3(2.0, 0.45, 1.6)))
	parent.add_child(Greybox.box(Vector3(0.45, 0.5, 0.06), Color(0.4, 0.55, 0.62), Vector3(2.0, 0.7, 1.82)))
	# The pen: a low white fence on the inside, a blanket on the floor.
	var pen := Color(0.92, 0.92, 0.9)
	if back_fence:
		for x in [-1.35, -0.45, 0.45, 1.35]:
			parent.add_child(Greybox.cylinder(0.015, 0.45, pen, Vector3(x, 0.225, PEN_MAX.y + 0.08)))
		parent.add_child(Greybox.box(Vector3(2.7, 0.025, 0.025), pen, Vector3(0, 0.44, PEN_MAX.y + 0.08)))
	for z in [-0.9, -0.3]:
		for x in [-1.35, 1.35]:
			parent.add_child(Greybox.cylinder(0.015, 0.45, pen, Vector3(x, 0.225, z)))
	parent.add_child(Greybox.box(Vector3(2.6, 0.02, 1.5), Color(0.78, 0.86, 0.92), Vector3(0, 0.01, -0.5)))
	# A chewed ball and a bowl: the pups live here for now.
	parent.add_child(Greybox.cylinder(0.08, 0.05, Color(0.7, 0.72, 0.75), Vector3(1.0, 0.04, 0.05)))
	parent.add_child(Greybox.sphere(0.05, Color(0.9, 0.55, 0.3), Vector3(-0.9, 0.06, 0.1)))


## The shop front: a low sill, a big pane of glass, frames, the clinic's name.
static func build_front(parent: Node3D) -> void:
	var wall := Color(0.9, 0.9, 0.88)
	var frame := Color(0.32, 0.34, 0.36)
	parent.add_child(Greybox.box(Vector3(8, SILL, 0.12), wall, Vector3(0, SILL * 0.5, WINDOW_Z)))
	parent.add_child(Greybox.box(Vector3(8, 0.5, 0.12), wall, Vector3(0, 2.65, WINDOW_Z)))
	for x in [-3.0, -0.95, 0.95, 2.75, 3.85]:
		parent.add_child(Greybox.box(Vector3(0.07, 2.4, 0.1), frame, Vector3(x, 1.2, WINDOW_Z)))
	parent.add_child(Greybox.box(Vector3(8, 0.06, 0.1), frame, Vector3(0, 2.4, WINDOW_Z)))
	parent.add_child(Greybox.box(Vector3(8, 0.04, 0.1), frame, Vector3(0, SILL, WINDOW_Z)))
	var glass := MeshInstance3D.new()
	var pane := BoxMesh.new()
	pane.size = Vector3(8, 2.4 - SILL, 0.02)
	glass.mesh = pane
	var glass_mat := StandardMaterial3D.new()
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.albedo_color = Color(0.82, 0.92, 0.95, 0.16)
	glass_mat.metallic = 0.2
	glass_mat.roughness = 0.05
	glass.material_override = glass_mat
	glass.position = Vector3(0, (2.4 + SILL) * 0.5, WINDOW_Z)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(glass)
	# Light on the glass, so it reads as a pane between the pups and the street.
	var shine := StandardMaterial3D.new()
	shine.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shine.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shine.albedo_color = Color(1, 1, 1, 0.18)
	for streak: Array in [[-0.55, 1.5, 0.09], [-0.38, 1.6, 0.04], [0.45, 1.1, 0.07], [1.9, 1.4, 0.06]]:
		var bar := MeshInstance3D.new()
		var quad := BoxMesh.new()
		quad.size = Vector3(float(streak[2]), 1.6, 0.005)
		bar.mesh = quad
		bar.material_override = shine
		bar.position = Vector3(float(streak[0]), float(streak[1]), WINDOW_Z + 0.02)
		bar.rotation.z = 0.5
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(bar)
	# The clinic's name on the glass: right way round from the street,
	# backwards from inside.
	var sign := Greybox.label("毛毛動物醫院", 0.0, 64, Color(0.2, 0.45, 0.42, 0.85), 30.0)
	sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sign.pixel_size = 0.0022
	sign.position = Vector3(0.0, 2.15, WINDOW_Z - 0.02)
	sign.rotation.y = PI
	parent.add_child(sign)
	# A paper taped to the glass, written by hand for the street.
	var paper := Greybox.box(Vector3(0.3, 0.2, 0.004), Color(0.99, 0.97, 0.9), Vector3(-0.42, 0.9, WINDOW_Z - 0.014))
	paper.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(paper)
	var note := Label3D.new()
	note.text = "等一個家\n歡迎進來看看"
	note.font_size = 48
	note.outline_size = 0
	note.modulate = Color(0.75, 0.3, 0.25)
	note.pixel_size = 0.0011
	note.position = Vector3(-0.42, 0.9, WINDOW_Z - 0.018)
	note.rotation.y = PI
	parent.add_child(note)
	# Nose prints low on the glass, where the pups press against it.
	var smudge := StandardMaterial3D.new()
	smudge.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smudge.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smudge.albedo_color = Color(0.85, 0.88, 0.9, 0.22)
	for at: Vector2 in [Vector2(-0.35, 0.24), Vector2(-0.28, 0.27), Vector2(0.2, 0.22), Vector2(0.62, 0.3), Vector2(0.68, 0.26), Vector2(-1.05, 0.21)]:
		var print_mark := MeshInstance3D.new()
		var dot := SphereMesh.new()
		dot.radius = 0.035
		dot.height = 0.05
		print_mark.mesh = dot
		print_mark.scale = Vector3(1.0, 0.7, 0.1)
		print_mark.material_override = smudge
		print_mark.position = Vector3(at.x, at.y, WINDOW_Z - 0.012)
		print_mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(print_mark)


## Outside: pavement, kerb, road, the shops across the street, a tree, a scooter.
static func build_street(parent: Node3D) -> void:
	parent.add_child(Greybox.box(Vector3(20, 0.08, 2.6), Color(0.72, 0.7, 0.66), Vector3(0, -0.04, -2.65)))
	parent.add_child(Greybox.box(Vector3(20, 0.12, 0.2), Color(0.6, 0.6, 0.58), Vector3(0, 0.0, -4.0)))
	parent.add_child(Greybox.box(Vector3(20, 0.04, 6), Color(0.33, 0.34, 0.36), Vector3(0, -0.06, -7.0)))
	for x in range(-9, 10, 3):
		parent.add_child(Greybox.box(Vector3(1.2, 0.01, 0.15), Color(0.9, 0.88, 0.8), Vector3(x, -0.03, -7.0)))
	var shop_colors := [Color(0.85, 0.72, 0.6), Color(0.7, 0.78, 0.82), Color(0.88, 0.84, 0.7), Color(0.76, 0.7, 0.78)]
	for i in 6:
		var x := -10.0 + i * 4.0
		parent.add_child(Greybox.box(Vector3(3.8, 4.5, 1.0), shop_colors[i % shop_colors.size()], Vector3(x, 2.25, -11.0)))
		parent.add_child(Greybox.box(Vector3(2.6, 1.6, 0.05), Color(0.45, 0.55, 0.6), Vector3(x, 1.2, -10.48)))
		parent.add_child(Greybox.box(Vector3(3.0, 0.12, 0.9), Color(0.8, 0.35, 0.3) if i % 2 == 0 else Color(0.3, 0.55, 0.5), Vector3(x, 2.3, -10.1)))
	parent.add_child(Greybox.cylinder(0.12, 2.4, Color(0.45, 0.35, 0.25), Vector3(-4.5, 1.2, -3.7)))
	parent.add_child(Greybox.sphere(1.1, Color(0.35, 0.55, 0.32), Vector3(-4.5, 2.9, -3.7)))
	parent.add_child(Greybox.box(Vector3(0.5, 0.7, 1.4), Color(0.85, 0.85, 0.82), Vector3(5.5, 0.4, -3.5)))


## Daylight from the street side and an even indoor fill.
static func build_light(parent: Node3D) -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.74, 0.84, 0.92)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.86, 0.9, 0.92)
	env.environment.ambient_light_energy = 0.8
	parent.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 150, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	parent.add_child(sun)


## A soft ring at a pup's feet: the player's own, or the one being looked at.
static func ring(pup: Node3D) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.26
	disc.bottom_radius = 0.26
	disc.height = 0.005
	mesh.mesh = disc
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.albedo_color = Color(1.0, 0.92, 0.6, 0.35)
	mesh.material_override = glow
	mesh.position.y = 0.03
	mesh.scale = Vector3.ONE / pup.scale.x
	mesh.name = "Ring"
	pup.add_child(mesh)
	return mesh
