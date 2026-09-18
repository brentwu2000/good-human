class_name ExtractionVisual3D
extends RefCounted

const INK := Color("#29383b")
const CREAM := Color("#efe3c8")
const LOCKED := Color("#7f8986")
const TEAL := Color("#3b9b82")

static func build(extraction_id: StringName) -> Node3D:
	var root := Node3D.new()
	root.name = "ExtractionVisual"
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var corner := Node3D.new()
		corner.rotation.y = angle
		corner.add_child(Greybox.box(Vector3(0.62, 0.025, 0.08), LOCKED, Vector3(1.05, 0.025, 0)))
		corner.add_child(Greybox.box(Vector3(0.08, 0.025, 0.62), LOCKED, Vector3(1.32, 0.025, 0.27)))
		root.add_child(corner)
	var beacon := Greybox.cylinder(0.065, 2.25, LOCKED, Vector3(0, 1.125, 0))
	beacon.name = "Beacon"
	root.add_child(beacon)
	root.add_child(Greybox.box(Vector3(0.62, 0.56, 0.08), INK, Vector3(0, 2.10, 0)))
	root.add_child(Greybox.sphere(0.105, CREAM, Vector3(0, 2.12, -0.075)))
	for x in [-0.12, -0.04, 0.04, 0.12]:
		root.add_child(Greybox.sphere(0.040, CREAM, Vector3(x, 2.25 + absf(x) * 0.25, -0.075)))
	var tag_color := TEAL if String(extraction_id).contains("bus") else CREAM
	root.add_child(Greybox.box(Vector3(0.44, 0.055, 0.14), tag_color, Vector3(0, 1.70, -0.08)))
	return root
