class_name WeaponProp3D
extends RefCounted
## P-05: what a held weapon looks like until Codex's D5W-01 silhouettes
## arrive. Built along +Y from the grip (the fist) outwards, so attached to a
## hand bone it points the way the forearm does: forward on a poke, up in a
## guard.

## A placeholder for `weapon`, or null for bare hands.
static func build(weapon: WeaponData) -> Node3D:
	if weapon == null or weapon.is_unarmed():
		return null
	if weapon.world_prefab != null:
		return weapon.world_prefab.instantiate() as Node3D
	var root := Node3D.new()
	root.name = "WeaponProp"
	match weapon.archetype:
		WeaponData.Archetype.UMBRELLA:
			_umbrella(root)
		WeaponData.Archetype.LONG_OBJECT:
			_broom(root)
		WeaponData.Archetype.HEAVY_BLUNT:
			_dumbbell(root)
		_:
			root.add_child(Greybox.cylinder(0.02, 1.0, Color(0.5, 0.45, 0.4), Vector3(0, 0.45, 0)))
	return root


## An old dumbbell: a short bar across the fist, a plate at each end.
static func _dumbbell(root: Node3D) -> void:
	var iron := Color(0.22, 0.22, 0.24)
	root.add_child(Greybox.cylinder(0.016, 0.3, Color(0.55, 0.55, 0.57), Vector3(0, 0.04, 0), Vector3(0, 0, PI * 0.5)))
	for x in [-0.13, 0.13]:
		root.add_child(Greybox.cylinder(0.08, 0.05, iron, Vector3(x, 0.04, 0), Vector3(0, 0, PI * 0.5)))


## A bamboo broom: a long handle and the bundled head out past the end.
static func _broom(root: Node3D) -> void:
	root.add_child(Greybox.cylinder(0.014, 1.25, Color(0.72, 0.6, 0.38), Vector3(0, 0.45, 0)))
	var head := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.03
	cone.bottom_radius = 0.13
	cone.height = 0.38
	head.mesh = cone
	head.material_override = Greybox.material(Color(0.62, 0.55, 0.32))
	head.position = Vector3(0, 1.24, 0)
	root.add_child(head)


## A closed umbrella: a J handle in the fist, the shaft, the furled canopy
## (widest near the handle end) and the metal tip.
static func _umbrella(root: Node3D) -> void:
	var canopy := Color(0.16, 0.2, 0.32)
	root.add_child(Greybox.box(Vector3(0.03, 0.1, 0.03), Color(0.35, 0.22, 0.12), Vector3(0, -0.02, 0)))
	root.add_child(Greybox.box(Vector3(0.03, 0.03, 0.08), Color(0.35, 0.22, 0.12), Vector3(0, -0.07, 0.03)))
	root.add_child(Greybox.cylinder(0.009, 0.82, Color(0.25, 0.25, 0.27), Vector3(0, 0.4, 0)))
	var furl := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.012
	cone.bottom_radius = 0.055
	cone.height = 0.56
	furl.mesh = cone
	furl.material_override = Greybox.material(canopy)
	furl.position = Vector3(0, 0.46, 0)
	root.add_child(furl)
	root.add_child(Greybox.cylinder(0.006, 0.07, Color(0.75, 0.75, 0.78), Vector3(0, 0.84, 0)))
