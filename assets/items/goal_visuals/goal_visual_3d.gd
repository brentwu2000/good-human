class_name GoalVisual3D
extends RefCounted

const SCENT := Color("#c58ad8")
const SCENT_LIGHT := Color("#e2b6eb")
const SQUIRREL := Color("#a8663f")
const SQUIRREL_LIGHT := Color("#d49a65")
const INK := Color("#2b2928")

static func scent() -> Node3D:
	var root := Node3D.new()
	root.name = "ScentWisps"
	for i in 3:
		var wisp := Node3D.new()
		wisp.name = "Wisp_%d" % i
		wisp.position = Vector3((i - 1) * 0.22, 0.26 + i * 0.16, 0)
		wisp.add_child(Greybox.sphere(0.075 - i * 0.008, SCENT_LIGHT if i == 1 else SCENT))
		wisp.add_child(Greybox.capsule(0.022, 0.30, SCENT, Vector3(0.11, 0.03, 0), Vector3(0, 0, PI * 0.5)))
		root.add_child(wisp)
	root.add_child(Greybox.box(Vector3(0.42, 0.018, 0.12), SCENT.darkened(0.20), Vector3(0, 0.035, 0)))
	return root

static func squirrel() -> Node3D:
	var root := Node3D.new()
	root.name = "SquirrelVisual"
	root.add_child(Greybox.capsule(0.115, 0.34, SQUIRREL, Vector3(0, 0.20, 0), Vector3(PI * 0.5, 0, 0)))
	root.add_child(Greybox.sphere(0.135, SQUIRREL_LIGHT, Vector3(0, 0.34, -0.20)))
	root.add_child(Greybox.cone(0.015, 0.065, 0.15, SQUIRREL, Vector3(-0.07, 0.49, -0.18), Vector3(0.08, 0, 0.15)))
	root.add_child(Greybox.cone(0.015, 0.065, 0.15, SQUIRREL, Vector3(0.07, 0.49, -0.18), Vector3(-0.08, 0, -0.15)))
	root.add_child(Greybox.sphere(0.022, INK, Vector3(-0.05, 0.38, -0.31)))
	root.add_child(Greybox.sphere(0.022, INK, Vector3(0.05, 0.38, -0.31)))
	for x in [-0.07, 0.07]:
		root.add_child(Greybox.capsule(0.025, 0.16, SQUIRREL.darkened(0.16), Vector3(x, 0.07, -0.10)))
	root.add_child(Greybox.sphere(0.17, SQUIRREL, Vector3(0, 0.32, 0.27)))
	root.add_child(Greybox.sphere(0.19, SQUIRREL_LIGHT, Vector3(0.02, 0.53, 0.31)))
	root.add_child(Greybox.sphere(0.14, SQUIRREL, Vector3(0.01, 0.72, 0.22)))
	return root
