class_name HumanModular3D
extends RefCounted
## Modular visual layer for the 3D owner and opponent humans.
## Appearance values are authored independently from combat stats.

const INK := Color("#273438")
const CREAM := Color("#f0e3c5")
const TEAL := Color("#3b8f86")


static func build(data: FighterData) -> Node3D:
	var root := Greybox.human(data.shirt_color, data.pants_color, data.hair_color, data.skin_color)
	root.name = "ModularHuman"
	_add_face(root, data)
	_add_hair(root, data)
	_add_top(root, data)
	_add_bottom(root, data)
	_add_accessory(root, data)
	_add_shoes(root, data)
	return root


static func _add_face(root: Node3D, data: FighterData) -> void:
	root.add_child(Greybox.sphere(0.030, INK, Vector3(-0.070, 1.65, -0.176)))
	root.add_child(Greybox.sphere(0.030, INK, Vector3(0.070, 1.65, -0.176)))
	root.add_child(Greybox.sphere(0.042, data.skin_color.darkened(0.08), Vector3(0, 1.59, -0.192)))


static func _add_hair(root: Node3D, data: FighterData) -> void:
	match data.hair_style:
		1: # Bob: strong side masses, soft everyday silhouette.
			root.add_child(Greybox.capsule(0.090, 0.35, data.hair_color, Vector3(-0.17, 1.58, 0.03), Vector3(0, 0, 0.08)))
			root.add_child(Greybox.capsule(0.090, 0.35, data.hair_color, Vector3(0.17, 1.58, 0.03), Vector3(0, 0, -0.08)))
		2: # Curly: clustered volumes remain readable from behind.
			for offset in [Vector3(-0.14, 1.74, 0), Vector3(0.14, 1.74, 0), Vector3(-0.12, 1.88, 0.02), Vector3(0.12, 1.88, 0.02)]:
				root.add_child(Greybox.sphere(0.12, data.hair_color, offset))
		3: # Cap.
			root.add_child(Greybox.cylinder(0.205, 0.10, data.shirt_color.darkened(0.08), Vector3(0, 1.82, -0.01)))
			root.add_child(Greybox.box(Vector3(0.30, 0.035, 0.16), data.shirt_color, Vector3(0, 1.79, -0.19)))
		4: # Bun; color stays data-driven, not age/power driven.
			root.add_child(Greybox.sphere(0.125, data.hair_color, Vector3(0, 1.91, 0.10)))
			root.add_child(Greybox.sphere(0.075, data.hair_color.darkened(0.10), Vector3(0, 2.02, 0.13)))


static func _add_top(root: Node3D, data: FighterData) -> void:
	var dark := data.shirt_color.darkened(0.18)
	match data.top_style:
		0: # Overshirt with contrasting undershirt and open seam.
			root.add_child(Greybox.box(Vector3(0.18, 0.42, 0.055), CREAM, Vector3(0, 1.10, -0.255)))
			root.add_child(Greybox.box(Vector3(0.028, 0.46, 0.060), dark, Vector3(0, 1.10, -0.285)))
		1: # Hoodie.
			root.add_child(Greybox.sphere(0.24, dark, Vector3(0, 1.39, 0.10)))
			root.add_child(Greybox.capsule(0.018, 0.23, CREAM, Vector3(-0.055, 1.31, -0.255)))
			root.add_child(Greybox.capsule(0.018, 0.23, CREAM, Vector3(0.055, 1.31, -0.255)))
		2: # Work jacket with harmless reflective tab.
			root.add_child(Greybox.box(Vector3(0.42, 0.055, 0.06), CREAM, Vector3(0, 1.16, -0.25)))
			root.add_child(Greybox.box(Vector3(0.10, 0.13, 0.065), dark, Vector3(0.13, 1.27, -0.26)))
		3: # Plain tee.
			root.add_child(Greybox.box(Vector3(0.38, 0.055, 0.06), data.shirt_color.lightened(0.16), Vector3(0, 1.32, -0.25)))
		4: # Cardigan: soft silhouette deliberately decoupled from strength.
			root.add_child(Greybox.box(Vector3(0.16, 0.46, 0.06), CREAM.darkened(0.08), Vector3(0, 1.08, -0.255)))
			for y in [0.96, 1.08, 1.20]:
				root.add_child(Greybox.sphere(0.022, dark, Vector3(0, y, -0.30)))


static func _add_bottom(root: Node3D, data: FighterData) -> void:
	match data.bottom_style:
		1: # Cuffed trousers.
			root.add_child(Greybox.box(Vector3(0.17, 0.10, 0.18), data.pants_color.lightened(0.16), Vector3(-0.10, 0.18, -0.01)))
			root.add_child(Greybox.box(Vector3(0.17, 0.10, 0.18), data.pants_color.lightened(0.16), Vector3(0.10, 0.18, -0.01)))
		2: # Wide relaxed trousers.
			root.add_child(Greybox.box(Vector3(0.23, 0.46, 0.20), data.pants_color, Vector3(-0.11, 0.43, 0)))
			root.add_child(Greybox.box(Vector3(0.23, 0.46, 0.20), data.pants_color, Vector3(0.11, 0.43, 0)))


static func _add_accessory(root: Node3D, data: FighterData) -> void:
	match data.accessory_style:
		1: # Glasses.
			for x in [-0.075, 0.075]:
				root.add_child(Greybox.box(Vector3(0.105, 0.072, 0.018), INK, Vector3(x, 1.66, -0.198)))
			root.add_child(Greybox.box(Vector3(0.045, 0.018, 0.018), INK, Vector3(0, 1.66, -0.202)))
		2: # Messenger bag.
			root.add_child(Greybox.box(Vector3(0.38, 0.34, 0.15), data.hair_color.darkened(0.15), Vector3(0.24, 0.91, 0.20)))
			root.add_child(Greybox.box(Vector3(0.035, 0.88, 0.035), CREAM.darkened(0.30), Vector3(0, 1.18, -0.02), Vector3(0, 0, -0.42)))
		3: # Tote bag.
			root.add_child(Greybox.box(Vector3(0.36, 0.40, 0.12), data.shirt_color.lightened(0.20), Vector3(0.40, 0.72, 0.05)))
			root.add_child(Greybox.capsule(0.025, 0.48, INK, Vector3(0.34, 1.05, 0.04), Vector3(0, 0, -0.30)))
		4: # Backpack with teal tag.
			root.add_child(Greybox.box(Vector3(0.39, 0.48, 0.18), data.hair_color.darkened(0.28), Vector3(0, 1.10, 0.26)))
			root.add_child(Greybox.box(Vector3(0.12, 0.06, 0.03), TEAL, Vector3(0, 1.08, 0.37)))


static func _add_shoes(root: Node3D, data: FighterData) -> void:
	var shoe_color := data.shoe_color
	root.add_child(Greybox.box(Vector3(0.17, 0.085, 0.30), shoe_color, Vector3(-0.10, 0.065, -0.08)))
	root.add_child(Greybox.box(Vector3(0.17, 0.085, 0.30), shoe_color, Vector3(0.10, 0.065, -0.08)))
	root.add_child(Greybox.box(Vector3(0.17, 0.025, 0.31), CREAM, Vector3(-0.10, 0.025, -0.08)))
	root.add_child(Greybox.box(Vector3(0.17, 0.025, 0.31), CREAM, Vector3(0.10, 0.025, -0.08)))
