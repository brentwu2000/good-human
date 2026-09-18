class_name BanyanLandmark3D
extends RefCounted
## Big Banyan Tree landmark and territory-state visual baseline.
## Territory is expressed through scent traces and repeated presence, not flags.

enum TerritoryState { UNKNOWN, DISCOVERED, CONTESTED, CLAIMING, OWNED }

const BARK := Color("#75513d")
const BARK_LIGHT := Color("#966b4e")
const LEAF := Color("#47754e")
const LEAF_LIGHT := Color("#65935d")
const SCENT_NEUTRAL := Color("#a28ba8")
const SCENT_RIVAL := Color("#d06b55")
const SCENT_PLAYER := Color("#37968b")
const STONE := Color("#8f9187")


static func build(state: TerritoryState = TerritoryState.DISCOVERED) -> Node3D:
	var root := Node3D.new()
	root.name = "BigBanyanLandmark"
	root.add_to_group(&"territory_landmark")
	_build_trunks(root)
	_build_roots(root)
	_build_canopy(root)
	_build_hanging_roots(root)
	_build_scent_knots(root, state)
	return root


static func _build_trunks(root: Node3D) -> void:
	for data: Array in [
		[Vector3(-0.34, 2.05, 0.05), Vector3(0.10, 0.0, -0.08), 0.42, 4.10],
		[Vector3(0.28, 1.95, 0.02), Vector3(-0.08, 0.0, 0.10), 0.38, 3.90],
		[Vector3(0.02, 1.75, 0.30), Vector3(0.14, 0.0, 0.03), 0.30, 3.50],
	]:
		var trunk := Greybox.capsule(data[2], data[3], BARK, data[0], data[1])
		root.add_child(trunk)
	# A pale bark scar gives the landmark a memorable face from the main path.
	root.add_child(Greybox.box(Vector3(0.22, 0.62, 0.06), BARK_LIGHT, Vector3(0.05, 1.40, -0.48), Vector3(0.0, 0.0, -0.10)))


static func _build_roots(root: Node3D) -> void:
	for i in 8:
		var angle := TAU * i / 8.0 + 0.18
		var length := 1.45 + 0.25 * (i % 3)
		var position := Vector3(sin(angle), 0.16, cos(angle)) * length * 0.48
		var buttress := Greybox.box(Vector3(0.28, 0.34, length), BARK.darkened(0.06), position, Vector3(0.10, angle, 0.0))
		root.add_child(buttress)


static func _build_canopy(root: Node3D) -> void:
	for data: Array in [
		[Vector3(-1.45, 4.15, 0.10), 1.75, LEAF],
		[Vector3(1.35, 4.25, 0.20), 1.65, LEAF_LIGHT],
		[Vector3(0.00, 4.80, 0.00), 1.85, LEAF],
		[Vector3(-0.20, 4.20, -1.30), 1.45, LEAF_LIGHT.darkened(0.04)],
		[Vector3(0.35, 4.05, 1.35), 1.55, LEAF.darkened(0.08)],
	]:
		root.add_child(Greybox.sphere(data[1], data[2], data[0]))


static func _build_hanging_roots(root: Node3D) -> void:
	for data: Array in [
		[Vector3(-1.30, 2.55, -0.35), 2.35],
		[Vector3(1.15, 2.65, 0.50), 2.15],
		[Vector3(-0.65, 2.85, 1.05), 1.85],
		[Vector3(0.85, 2.75, -0.95), 2.05],
	]:
		root.add_child(Greybox.cylinder(0.035, data[1], BARK_LIGHT.darkened(0.12), data[0]))


static func _build_scent_knots(root: Node3D, state: TerritoryState) -> void:
	var colors: Array[Color] = []
	match state:
		TerritoryState.UNKNOWN:
			colors = []
		TerritoryState.DISCOVERED:
			colors = [SCENT_NEUTRAL]
		TerritoryState.CONTESTED:
			colors = [SCENT_RIVAL, SCENT_PLAYER, SCENT_RIVAL]
		TerritoryState.CLAIMING:
			colors = [SCENT_PLAYER, SCENT_RIVAL, SCENT_PLAYER, SCENT_PLAYER]
		TerritoryState.OWNED:
			colors = [SCENT_PLAYER, SCENT_PLAYER, SCENT_PLAYER, SCENT_PLAYER]
	for i in colors.size():
		var angle := -1.0 + i * 0.62
		var anchor := Vector3(sin(angle) * 1.15, 0.10, -0.72 + cos(angle) * 0.35)
		root.add_child(Greybox.sphere(0.105, colors[i], anchor))
		root.add_child(Greybox.capsule(0.025, 0.42, colors[i].lightened(0.10), anchor + Vector3(0.10, 0.12, 0), Vector3(0, 0, PI * 0.5)))
	# Small ordinary stones keep the scent language grounded in the place.
	for i in 5:
		var angle := TAU * i / 5.0
		root.add_child(Greybox.sphere(0.13, STONE, Vector3(sin(angle) * 1.38, 0.08, cos(angle) * 1.38)))
