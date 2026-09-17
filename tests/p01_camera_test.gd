extends "res://tests/test_case.gd"
## P-01 prototype smoke test: the greybox loads, every camera variant keeps
## the dog in view, C switches context (explore/sprint/sniff/combat) without
## changing gameplay, collision pulls the camera in, and the seamless fight
## proxy starts and disengages while the dog stays controllable.

const SCENE: PackedScene = preload("res://prototypes/dog_eye_camera/p01_camera.tscn")

var world: P01World


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	world = SCENE.instantiate() as P01World
	add_child(world)
	await _physics(5)
	check(world.dog != null and world.owner_actor != null and world.opponent != null and world.squirrel != null, "greybox actors spawned")

	await _test_variants_keep_dog_visible()
	await _test_hybrid_contexts()
	await _test_collision()
	await _test_fight_and_disengage()
	await _test_squirrel()
	await _test_background_life()
	finish()


func _test_variants_keep_dog_visible() -> void:
	for variant in [ProtoCameraRig.Variant.A_TOP_DOWN, ProtoCameraRig.Variant.B_DOG_CHASE, ProtoCameraRig.Variant.C_HYBRID]:
		world.reset_scene()
		world.set_variant(variant)
		await _hold(&"move_up", 60)
		await _physics(20)
		check(world.rig.is_dog_visible(), "variant %d: dog visible after walking" % variant)
		check(world.dog.global_position.z < world.DOG_START.z - 2.0, "variant %d: dog walked forward" % variant)
		check(world.rig.is_owner_visible(), "variant %d: owner visible while following" % variant)
	world.set_variant(ProtoCameraRig.Variant.A_TOP_DOWN)
	check(world.rig.current["distance"] > 10.0 and world.rig.current["pitch"] < -40.0, "A is high and far")
	world.set_variant(ProtoCameraRig.Variant.B_DOG_CHASE)
	check(world.rig.global_position.y - world.dog.global_position.y < 2.0, "B stays near dog height")
	# Owner right behind the dog, between it and the chase camera.
	world.reset_scene()
	world.dog.facing = Vector3.FORWARD
	world.owner_actor.global_position = world.dog.global_position + Vector3(0, 0, 1.5)
	world.rig.yaw = 0.0
	world.rig.snap()
	check(world.owner_actor.faded, "owner blocking the chase camera fades out")
	world.set_variant(ProtoCameraRig.Variant.A_TOP_DOWN)
	check(not world.owner_actor.faded, "top-down view needs no fade")


func _test_hybrid_contexts() -> void:
	world.reset_scene()
	world.set_variant(ProtoCameraRig.Variant.C_HYBRID)
	await _physics(3)
	check_eq(world.rig.context, &"EXPLORE", "C: explore at rest")
	Input.action_press(&"sprint")
	await _hold(&"move_up", 40)
	check_eq(world.rig.context, &"SPRINT", "C: sprint context while running")
	Input.action_release(&"sprint")
	await _physics(30)

	world.reset_scene()
	world.dog.global_position = world.search_spot.global_position + Vector3(0.6, 0, 0)
	await _physics(2)
	world.interact()
	await _physics(2)
	check(world.search_spot.searching and world.rig.context == &"SNIFF", "C: sniff context while searching")
	await _physics(90)
	check(world.search_spot.found and not world.dog.sniffing, "search finishes and frees the dog")
	check_eq(world.rig.context, &"EXPLORE", "C: back to explore")


func _test_collision() -> void:
	world.reset_scene()
	world.set_variant(ProtoCameraRig.Variant.C_HYBRID)
	# Back the dog up against the houses: the boom would go inside a wall.
	world.dog.global_position = Vector3(-8, 0.2, 4.6)
	world.dog.facing = Vector3.FORWARD
	world.rig.yaw = 0.0
	world.rig.tuning["distance"] = 6.0
	world.rig.snap()
	await _physics(2)
	check(world.rig.collided, "camera boom hits the house")
	check(world.rig.global_position.z < 5.5 - world.rig.collision_margin * 0.5, "camera pulled in front of the wall")
	check(world.rig.is_dog_visible(), "dog still visible after collision")
	world.rig.tuning["distance"] = 0.0


func _test_fight_and_disengage() -> void:
	world.reset_scene()
	world.set_variant(ProtoCameraRig.Variant.C_HYBRID)
	var opponent := world.opponent
	world.dog.global_position = opponent.human_position() + Vector3(-1.0, 0.2, 0.5)
	world.owner_actor.global_position = opponent.human_position() + Vector3(-2.2, 0.2, 1.2)
	await _physics(3)
	world.interact()
	await _physics(3)
	check_eq(opponent.state, ProtoOpponent.State.COMBAT, "provoking starts the fight in place")
	check_eq(world.rig.context, &"COMBAT_READABILITY", "C: combat framing")
	check_eq(world.owner_actor.state, ProtoOwner.State.COMBAT, "owner fights")
	var dog_start := world.dog.global_position
	await _hold(&"move_left", 20)
	check(world.dog.global_position.distance_to(dog_start) > 0.5, "dog stays controllable during the fight")
	check(world.rig.is_dog_visible(), "dog visible in combat framing")
	world.dog.global_position = world.owner_actor.global_position + Vector3(0, 0.2, ProtoOpponent.DISENGAGE_DISTANCE + 2.0)
	await _physics(3)
	check(opponent.state == ProtoOpponent.State.RETURNING and world.owner_actor.state == ProtoOwner.State.FOLLOW, "running away disengages")


func _test_squirrel() -> void:
	world.reset_scene()
	var squirrel := world.squirrel
	world.dog.global_position = squirrel.global_position + Vector3(0, 0.2, 2.0)
	for i in int(ProtoSquirrel.CHASE_SECONDS * 60) + 30:
		world.dog.global_position = squirrel.global_position + Vector3(0, 0.2, 1.5)
		await get_tree().physics_frame
	check_eq(squirrel.state, ProtoSquirrel.State.TREED, "chased squirrel goes up a tree")


func _test_background_life() -> void:
	var dogs := world.life.filter(func(n: ProtoNpc) -> bool: return n.has_dog)
	check(world.life.size() >= 10 and dogs.size() >= 6, "street and park have people and dogs (%d people, %d dogs)" % [world.life.size(), dogs.size()])
	var walker := world.life[0]
	var start := walker.global_position
	await _physics(60)
	check(walker.global_position.distance_to(start) > 0.3, "walkers stroll their routes")
	world.dog.global_position = walker.global_position + Vector3(1.0, 0.2, 0)
	await _physics(3)
	check(walker.is_noticing(), "people and their dogs notice the player's dog")


func _hold(action: StringName, frames: int) -> void:
	Input.action_press(action)
	await _physics(frames)
	Input.action_release(action)


func _physics(frames: int) -> void:
	for i in frames:
		await get_tree().physics_frame
