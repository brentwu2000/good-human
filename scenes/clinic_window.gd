class_name ClinicWindow
extends RefCounted
## Sprint 06 (owner direction 2026-10-05): the opening happens at one place —
## the pen by the front window of a small animal hospital. Choosing the dog
## looks in at it from the street (ShelterScene); then the player IS the pup
## inside, looking out (AdoptionScene). Both build the same place from here.
## Modelled pieces (D6-01/D6-03, Claude at the owner's request, built by
## `tools/art/build_clinic_window.py` in these very coordinates); the glass,
## its shine, the painted name, the paper and the nose prints stay in code.

## The glass is at z = WINDOW_Z; the pen is inside (+z), the street outside.
const WINDOW_Z: float = -1.3
## The pen: x and z limits; the glass is just beyond PEN_MIN.y.
const PEN_MIN := Vector2(-1.25, WINDOW_Z + 0.18)
const PEN_MAX := Vector2(1.25, 0.25)
## A low sill, so a pup at the glass can be seen from the pavement and can
## see out over it.
const SILL: float = 0.12
const PUPPY_SCALE: float = 0.62
const INSIDE := preload("res://assets/environment/clinic/clinic_inside.glb")
const PEN := preload("res://assets/environment/clinic/clinic_pen.glb")
const PEN_BACK := preload("res://assets/environment/clinic/clinic_pen_back.glb")
const FRONT := preload("res://assets/environment/clinic/clinic_front.glb")
const STREET := preload("res://assets/environment/clinic/clinic_street.glb")


## The clinic behind the pen: floor, back wall, the counter, the pen itself.
## `back_fence` off when the view is from inside the pen (AdoptionScene): the
## rail behind the pup would cut across the view.
static func build_inside(parent: Node3D, back_fence: bool = true) -> void:
	parent.add_child(INSIDE.instantiate())
	parent.add_child(PEN.instantiate())
	if back_fence:
		parent.add_child(PEN_BACK.instantiate())


## The shop front: a low sill, a big pane of glass, frames, the clinic's name.
static func build_front(parent: Node3D) -> void:
	parent.add_child(FRONT.instantiate())
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
	parent.add_child(STREET.instantiate())


## Daylight from the street side and an even indoor fill.
static func build_light(parent: Node3D) -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.74, 0.84, 0.92)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.86, 0.9, 0.92)
	env.environment.ambient_light_energy = 0.55
	# Filmic, so pale floors and fleece keep their colour instead of burning out.
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment.tonemap_exposure = 1.0
	parent.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 150, 0)
	sun.light_energy = 0.95
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
