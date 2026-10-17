class_name BunnyRobot3D
extends RefCounted
## Xiaomi toy proxy (docs/04_systems/XIAOMI_TOY_PROXY.md): placeholder body of
## the bunny toy robot that fights for her. Round, pink and cream, rabbit ears,
## spring arms with big boxing-glove fists, wheels for feet — a toy, never a
## weapon (sheet: assets/characters/human/concepts/xiaomi_bunny_robot_visual_target_01.png).
##
## Built on the greybox human's joints (Hips, Torso, Head, ArmL/R, LegL/R) at
## human size, so every greybox action FighterPuppet3D plays — wind-ups,
## strikes, blocks, hit reactions, the fall — moves it; FighterData.body_scale
## then shrinks it to toy size. Final art replaces this through the art pipeline.

const PINK := Color(0.96, 0.46, 0.63)
const DEEP_PINK := Color(0.88, 0.24, 0.47)
const CREAM := Color(0.98, 0.94, 0.88)
const GOLD := Color(0.95, 0.74, 0.32)
const INK := Color(0.16, 0.13, 0.16)


static func build(_data: FighterData) -> Node3D:
	var root := Node3D.new()
	root.name = "BunnyRobot"
	var hip := Greybox.HIP_HEIGHT
	var shoulder := Greybox.SHOULDER_HEIGHT
	var neck := Greybox.NECK_HEIGHT

	# Stubby legs on toy wheels.
	for side in [-1.0, 1.0]:
		var leg := _joint(root, "Leg" + ("L" if side < 0.0 else "R"), Vector3(0.15 * side, hip, 0))
		leg.add_child(Greybox.capsule(0.15, 0.55, CREAM, Vector3(0, 0.40 - hip, 0)))
		leg.add_child(Greybox.cylinder(0.14, 0.12, PINK, Vector3(0, 0.12 - hip, 0), Vector3(0, 0, PI * 0.5)))
		leg.add_child(Greybox.cylinder(0.06, 0.13, GOLD, Vector3(0, 0.12 - hip, 0), Vector3(0, 0, PI * 0.5)))

	var hips := _joint(root, "Hips", Vector3(0, hip, 0))
	var torso := _joint(hips, "Torso", Vector3.ZERO)
	# Round belly with a pink band and a heart panel on the chest.
	torso.add_child(Greybox.sphere(0.40, CREAM, Vector3(0, 1.02 - hip, 0)))
	torso.add_child(Greybox.cylinder(0.405, 0.10, PINK, Vector3(0, 0.86 - hip, 0)))
	torso.add_child(Greybox.sphere(0.13, DEEP_PINK, Vector3(-0.06, 1.10 - hip, -0.33)))
	torso.add_child(Greybox.sphere(0.13, DEEP_PINK, Vector3(0.06, 1.10 - hip, -0.33)))
	torso.add_child(Greybox.box(Vector3(0.14, 0.14, 0.10), DEEP_PINK, Vector3(0, 1.03 - hip, -0.34), Vector3(0, 0, PI * 0.25)))
	torso.add_child(Greybox.sphere(0.05, GOLD, Vector3(0, 1.08 - hip, -0.42)))
	# Backpack port at the back (modules plug in here later).
	torso.add_child(Greybox.box(Vector3(0.26, 0.22, 0.08), PINK, Vector3(0, 1.06 - hip, 0.38)))

	# Spring arms ending in big boxing-glove fists.
	for side in [-1.0, 1.0]:
		var arm := _joint(torso, "Arm" + ("L" if side < 0.0 else "R"), Vector3(0.42 * side, shoulder - hip - 0.18, 0))
		arm.add_child(Greybox.sphere(0.12, PINK, Vector3(0, 0, 0)))
		for i in 5:
			var y := -0.10 - i * 0.075
			arm.add_child(Greybox.cylinder(0.065, 0.035, PINK if i % 2 == 0 else CREAM, Vector3(0, y, 0)))
		arm.add_child(Greybox.sphere(0.17, PINK, Vector3(0, -0.56, 0)))
		arm.add_child(Greybox.sphere(0.08, CREAM, Vector3(0.10 * side, -0.52, -0.06)))

	# Big head: rabbit ears, black eyes with a shine, rosy cheeks.
	var head := _joint(torso, "Head", Vector3(0, neck - hip, 0))
	head.add_child(Greybox.sphere(0.33, CREAM, Vector3(0, 1.66 - neck, 0)))
	for side in [-1.0, 1.0]:
		head.add_child(Greybox.capsule(0.09, 0.50, CREAM, Vector3(0.15 * side, 2.08 - neck, 0.02), Vector3(0, 0, -0.18 * side)))
		head.add_child(Greybox.capsule(0.05, 0.36, PINK, Vector3(0.155 * side, 2.08 - neck, -0.05), Vector3(0, 0, -0.18 * side)))
		head.add_child(Greybox.sphere(0.065, INK, Vector3(0.12 * side, 1.70 - neck, -0.28)))
		head.add_child(Greybox.sphere(0.022, Color.WHITE, Vector3(0.10 * side, 1.73 - neck, -0.33)))
		head.add_child(Greybox.sphere(0.06, PINK.lightened(0.15), Vector3(0.20 * side, 1.58 - neck, -0.24)))
	head.add_child(Greybox.sphere(0.035, DEEP_PINK, Vector3(0, 1.60 - neck, -0.32)))
	# Every piece already hangs on its joint.
	root.set_meta("skeletal_art", false)
	return root


static func _joint(parent: Node3D, joint_name: String, at: Vector3) -> Node3D:
	var joint := Node3D.new()
	joint.name = joint_name
	joint.position = at
	parent.add_child(joint)
	return joint
