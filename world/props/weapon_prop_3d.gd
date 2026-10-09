class_name WeaponProp3D
extends RefCounted
## P-05: what a held weapon looks like until Codex's D5W-01 silhouettes
## arrive. Built along +Y from the grip outwards; held, it sits on `grip()`,
## the shaft running through the closed fist the way the fight clips close it.

## Where a hand holds a shaft, in its hand bone's frame: written by
## tools/art/make_fight_clips.py from the fingers curled round one.
const GRIP_JSON := "res://assets/characters/human/animations/p04_fight_grip.json"
static var _grips: Dictionary = {}


## The transform (hand bone frame) that puts a prop's +Y along the shaft
## through hand `side`'s fist ("l" or "r"), its origin in the middle of it.
static func grip(side: String) -> Transform3D:
	if _grips.is_empty():
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(GRIP_JSON))
		if data is Dictionary:
			_grips = data
	var hand: Dictionary = _grips.get(side, {})
	if hand.is_empty():
		return Transform3D.IDENTITY
	var y := _vector(hand["axis"]).normalized()
	var z := _vector(hand["normal"])
	z = (z - y * z.dot(y)).normalized()
	return Transform3D(Basis(y.cross(z), y, z), _vector(hand["centre"]))


## How far along the shaft from the fist a prop sits in the hand: a long
## thing (the broom) is held near the end of its handle, so it sits forward.
static func shift(archetype: WeaponData.Archetype) -> float:
	if archetype != WeaponData.Archetype.LONG_OBJECT:
		return 0.0
	if _grips.is_empty():
		grip("l")
	return float(_grips.get("long_shift", 0.0))


static func _vector(values: Array) -> Vector3:
	return Vector3(values[0], values[1], values[2])


## How far along +Y from the grip the drawn weapon ends (its striking tip).
const TIP := {
	WeaponData.Archetype.UMBRELLA: 0.6,
	WeaponData.Archetype.LONG_OBJECT: 0.79,
	WeaponData.Archetype.HEAVY_BLUNT: 0.12,
}


## P05-09 (placeholder for D5W-07): WORN sags a little and dulls; CRITICAL
## is visibly bent and dark. Applied to the prop's own pose and colours.
static func show_condition(prop: Node3D, condition: WeaponCondition.State) -> void:
	var bend := 0.0
	var dull := 0.0
	match condition:
		WeaponCondition.State.WORN:
			bend = 0.08
			dull = 0.25
		WeaponCondition.State.CRITICAL:
			bend = 0.28
			dull = 0.5
	prop.rotation.z = bend
	prop.set_meta("condition", condition)
	# Placeholder pieces carry an override; a modelled prop carries its own
	# surface materials. Either way each gets its own copy before it dulls.
	for node in prop.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		for surface in mesh.get_surface_override_material_count() if mesh.material_override == null else 1:
			var current: Material = mesh.material_override if mesh.material_override != null else mesh.get_active_material(surface)
			var material := current as StandardMaterial3D
			if material == null:
				continue
			var key := "base_color_%d" % surface
			if not mesh.has_meta(key):
				material = material.duplicate() as StandardMaterial3D
				if mesh.material_override != null:
					mesh.material_override = material
				else:
					mesh.set_surface_override_material(surface, material)
				mesh.set_meta(key, material.albedo_color)
			material.albedo_color = (mesh.get_meta(key) as Color).darkened(dull)


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


## A bamboo broom, held halfway up the handle like a stick (P05-08: so the
## drawn head is where the thrust's reach says it is): handle behind the fist,
## the rest and the bundled head out in front.
static func _broom(root: Node3D) -> void:
	root.add_child(Greybox.cylinder(0.014, 1.15, Color(0.72, 0.6, 0.38), Vector3(0, -0.12, 0)))
	var head := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.03
	cone.bottom_radius = 0.13
	cone.height = 0.38
	head.mesh = cone
	head.material_override = Greybox.material(Color(0.62, 0.55, 0.32))
	head.position = Vector3(0, 0.6, 0)
	root.add_child(head)


## A closed folding umbrella (P05-08: sized so the drawn tip is where the
## poke's reach says it is): a J handle in the fist, the shaft, the furled
## canopy (widest near the handle end) and the metal tip.
static func _umbrella(root: Node3D) -> void:
	var canopy := Color(0.16, 0.2, 0.32)
	root.add_child(Greybox.box(Vector3(0.03, 0.1, 0.03), Color(0.35, 0.22, 0.12), Vector3(0, -0.02, 0)))
	root.add_child(Greybox.box(Vector3(0.03, 0.03, 0.08), Color(0.35, 0.22, 0.12), Vector3(0, -0.07, 0.03)))
	root.add_child(Greybox.cylinder(0.009, 0.56, Color(0.25, 0.25, 0.27), Vector3(0, 0.28, 0)))
	var furl := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.012
	cone.bottom_radius = 0.05
	cone.height = 0.38
	furl.mesh = cone
	furl.material_override = Greybox.material(canopy)
	furl.position = Vector3(0, 0.33, 0)
	root.add_child(furl)
	root.add_child(Greybox.cylinder(0.006, 0.06, Color(0.75, 0.75, 0.78), Vector3(0, 0.57, 0)))
