extends "res://tests/test_case.gd"
## Sprint 05 P4-006 through the real 3D walk: the Big Banyan Tree is a place the
## dog finds and then learns belongs to another dog, and the landmark shows it.

const TEST_SAVE: String = "user://tests/territory_world_save.json"

var _tree: SceneTree


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_tree = get_tree()
	DirAccess.make_dir_recursive_absolute(TEST_SAVE.get_base_dir())
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(TEST_SAVE)
	SaveManager.save_path = TEST_SAVE

	var placeholder := Node.new()
	_tree.root.add_child(placeholder)
	_tree.current_scene = placeholder
	_tree.change_scene_to_file(Game.BOOT_SCENE)
	await _wait_for_scene(Game.HOME_SCENE)
	_tree.current_scene.get_node("%Walk3DButton").pressed.emit()
	await _wait_for_scene(Game.RUN_MAP_3D_SCENE)
	await _physics(5)

	var map := _tree.current_scene as RunMap3D
	var run := map.run_manager
	var dog := map.dog
	var banyan := map.get_node("BanyanTerritory") as TerritoryPoint3D
	var progress := Game.territory_progress
	var found: Array[TerritoryData] = []
	var smelled: Array[TerritoryData] = []
	banyan.discovered.connect(func(t: TerritoryData) -> void: found.append(t))
	banyan.rival_scent_found.connect(func(t: TerritoryData) -> void: smelled.append(t))

	check(banyan != null and banyan.data != null, "the banyan is in the park as a place")
	check(banyan.is_in_group(TerritoryPoint3D.GROUP), "and can be found by group")
	check_eq(progress.state_of(&"banyan"), TerritoryProgress.State.UNKNOWN, "a new dog has never been there")
	check(banyan.landmark != null, "the landmark is built from Codex's kit")
	var knots_unknown := _scent_knots(banyan)

	# Walking past at a distance changes nothing.
	await _put_dog(dog, banyan.global_position + Vector3(20, 0, 0))
	check(found.is_empty(), "the far side of the park is not a discovery")

	# Coming up to the tree: this is a place.
	await _put_dog(dog, banyan.global_position + Vector3(5, 0, 0))
	check_eq(found.size(), 1, "coming near the banyan finds it")
	check_eq(progress.state_of(&"banyan"), TerritoryProgress.State.DISCOVERED, "the dog knows the place now")
	var knots_discovered := _scent_knots(banyan)
	check(knots_discovered > knots_unknown, "a found place shows a scent trace (%d -> %d)" % [knots_unknown, knots_discovered])

	# Passing by is not the same as reading it: the dog has to stay a moment.
	check(smelled.is_empty(), "arriving is not yet understanding whose place it is")
	await _put_dog(dog, banyan.global_position + Vector3(1.5, 0, 0))
	await _physics(int(TerritoryPoint3D.SCENT_SECONDS * 70.0))
	check_eq(smelled.size(), 1, "standing at the roots reads the scents")
	check_eq(progress.state_of(&"banyan"), TerritoryProgress.State.CONTESTED, "another dog lives here")
	check(progress.last_event(&"banyan").contains("別的狗"), "and the place remembers that in the dog's words")
	check(_scent_knots(banyan) > knots_discovered, "the roots now show two dogs' traces")

	# It never runs backwards or fires twice, however long the dog hangs around.
	await _physics(int(TerritoryPoint3D.SCENT_SECONDS * 140.0))
	check_eq(found.size(), 1, "the place is only discovered once")
	check_eq(smelled.size(), 1, "and only understood once")
	check_eq(progress.state_of(&"banyan"), TerritoryProgress.State.CONTESTED, "state holds")

	# P4-007: marking is the dog's own move, and only where it understands.
	var marks: Array[TerritoryData] = []
	banyan.marked.connect(func(t: TerritoryData) -> void: marks.append(t))
	check(banyan.can_interact(run), "a place the dog understands can be marked")
	var temptations := map.get_node("TemptationDirector") as TemptationDirector
	check(temptations._world_offers(TemptationData.Needs.TERRITORY, run.run_value()), "S05-03: an unmarked place the dog knows is a reason to stay")
	check(banyan.get_prompt(run).contains("做記號"), "and says so in the dog's terms")
	# S05-04: as a temptation, the place itself calls — in scent, not an icon.
	var banyan_offer: TemptationData = null
	for template in temptations.catalog:
		if template.needs == TemptationData.Needs.TERRITORY:
			banyan_offer = template
	await _put_dog(dog, banyan.global_position + Vector3(20, 0, 0))
	temptations.offer(banyan_offer, run.elapsed_time)
	check(banyan.is_calling() and temptations.calling_point == banyan, "S05-04: the banyan temptation makes the tree call")
	var wisp := banyan.get_node("ScentCall").get_child(0) as Node3D
	await _physics(20)
	check(wisp.position.y >= TerritoryPoint3D.CALL_LOW and (wisp.material_override as StandardMaterial3D).albedo_color.a > 0.0, "scent drifts up out of the canopy (%.1f m)" % wisp.position.y)
	await _put_dog(dog, banyan.global_position + Vector3(1.5, 0, 0))
	check(not banyan.is_calling(), "and stops once the dog has come")
	banyan.interact(run)
	check_eq(marks.size(), 1, "the dog marks it")
	check(banyan._alert_resident() == null, "nobody lives there yet to see it")
	check(banyan.marked_this_walk, "this walk now counts for the place")
	check(progress.last_event(&"banyan").contains("我的味道"), "the place remembers being marked")
	check_eq(progress.claim_progress(&"banyan"), 0, "marking alone earns nothing — getting home does")
	check(not banyan.can_interact(run), "and it cannot be marked twice on one walk")
	check(not temptations._world_offers(TemptationData.Needs.TERRITORY, run.run_value()), "once marked today, it no longer tempts")

	# P4-008: the resident lives here, but only once the dog has met him, and
	# he is never in two places at once.
	var resident: OpponentPair3D = null
	var alley: OpponentPair3D = null
	for pair in map.coordinator.get_pairs():
		if pair.spot_id == &"banyan_resident":
			resident = pair
		elif pair.spot_id == &"pair_rival":
			alley = pair
	check(resident != null and alley != null, "the rival has a home and a first meeting place")
	check(not resident.is_present(), "he is not at the tree before the dog has met him")
	Game.goal_progress.set_flag(&"rival_revealed")
	check(alley.is_present() and not resident.is_present(), "revealed: he is in the alley, not at the tree")
	Game.goal_progress.set_flag(&"rival_beaten")
	check(resident.is_present(), "settled: he has gone home to his tree")
	check(not alley.is_present(), "and is no longer loitering in the alley")
	check_eq(resident.encounter, alley.encounter, "it is the same dog and the same person")
	check_eq(DataRegistry.get_territory(&"banyan").resident_spot, resident.spot_id, "the territory knows who lives there")

	check(run.marked_territories.has(&"banyan"), "the walk is carrying the mark")

	# The landmark shows what the dog remembers, walk after walk.
	run.start_run(1234)
	await _physics(5)
	check_eq(progress.state_of(&"banyan"), TerritoryProgress.State.CONTESTED, "a new walk does not reset the place")
	check(not banyan.marked_this_walk, "but a new walk has to be earned again")
	check(run.marked_territories.is_empty(), "and starts with nothing marked")

	# S05-05: on a later walk the roots say whose place it is, once per walk.
	var readings: Array[String] = []
	banyan.scents_read.connect(func(_t: TerritoryData, text: String) -> void: readings.append(text))
	check(not banyan.scents_read_this_walk, "a new walk has not read the roots yet")
	await _put_dog(dog, banyan.global_position + Vector3(1.5, 0, 0))
	await _physics(int(TerritoryPoint3D.SCENT_SECONDS * 70.0))
	check_eq(readings.size(), 1, "S05-05: standing at the roots reads them again on a new walk")
	check_eq(readings[0] if readings.size() > 0 else "", banyan.data.rival_only_text, "only the resident's scent before any claim")
	check_eq(banyan.own_scent_share(), 0.0, "none of it is the dog's yet")
	await _physics(int(TerritoryPoint3D.SCENT_SECONDS * 140.0))
	check_eq(readings.size(), 1, "and only once per walk")
	var real_state: TerritoryProgress.State = progress.states[&"banyan"]
	progress.states[&"banyan"] = TerritoryProgress.State.CLAIMING
	progress.claims[&"banyan"] = 1
	check_eq(banyan.scent_text(), banyan.data.mixed_scent_text, "claiming: the two scents are mixed")
	check(absf(banyan.own_scent_share() - 1.0 / 3.0) < 0.01, "a third of it is the dog's after one walk home")
	progress.states[&"banyan"] = TerritoryProgress.State.OWNED
	check_eq(banyan.scent_text(), banyan.data.own_scent_text, "owned: it is mostly the dog's own")
	progress.states[&"banyan"] = real_state
	progress.claims.erase(&"banyan")
	# This test's listener plus the walk's, which says it in the dog's voice.
	check_eq(banyan.scents_read.get_connections().size(), 2, "the walk says it in the dog's voice")

	# P4-010: mark it again, then actually walk home. The scene changes, so this
	# is the last thing the walk does.
	check(resident.is_present() and not resident.riled_this_walk, "the resident is home and calm")
	banyan.interact(run)
	check(run.marked_territories.has(&"banyan"), "marked again on the new walk")
	check(resident.riled_this_walk, "S05-06: the resident sees the mark and reacts")
	check(not map.coordinator.is_fighting() and resident.is_idle(), "a reaction, not a fight: provoking is still the dog's choice")

	# S05-07: the same pair remembers the dog, walk after walk.
	check(not resident.recognised_this_walk, "never fought: nothing to recognise")
	var stats_before := resident.encounter.human.stats.attack(DataRegistry.balance)
	progress.record_rival_fight(resident.encounter.id, true)
	await _put_dog(dog, resident.human_global_position() + Vector3(2.0, 0, 0))
	await _physics(3)
	check(resident.recognised_this_walk, "after a fight, the rival recognises the dog")
	check(resident._dog_lunge.dot(dog.global_position - resident._dog.global_position) < 0.0, "beaten last time, their dog backs off")
	check_eq(resident.encounter.human.stats.attack(DataRegistry.balance), stats_before, "memory only: the rival is no stronger or weaker")
	progress.rivals.clear()
	Game.goal_progress.set_flag(&"banyan_owned")
	check(not resident.is_present(), "once the place is the dog's, the resident no longer hangs about there")
	Game.goal_progress.flags.erase(&"banyan_owned")
	check(resident.is_present(), "(restored)")
	run.debug_unlock_all_extractions()
	await _physics(2)
	run.extract(&"bus_stop")
	await _wait_for_scene(Game.RUN_RESULT_SCENE)
	var result := Game.last_run_result
	check(result != null and result.marked_territories.has(&"banyan"), "the result carries what the dog marked")
	check_eq(result.territory_claims.get(&"banyan", 0), 1, "getting home turned the mark into progress")
	check_eq(progress.state_of(&"banyan"), TerritoryProgress.State.CLAIMING, "the dog is working on the place")
	check(not progress.is_owned(&"banyan"), "one walk home is not ownership")
	finish()


## Number of scent traces on the landmark: the state's world read (D5-07).
## Codex's scent set shows its `Scent_<STATE>_*` pieces; the greybox fallback
## uses small spheres.
func _scent_knots(point: TerritoryPoint3D) -> int:
	var count := 0
	for node in point.landmark.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.name.begins_with("Scent_") and mesh.is_visible_in_tree():
			count += 1
		elif mesh.get_parent() == point.landmark and mesh.mesh is SphereMesh and (mesh.mesh as SphereMesh).radius < 0.12:
			count += 1
	return count


func _put_dog(dog: Node3D, to: Vector3) -> void:
	dog.global_position = Vector3(to.x, 0.1, to.z)
	dog.velocity = Vector3.ZERO
	await _physics(4)


func _physics(frames: int) -> void:
	for i in frames:
		await _tree.physics_frame


func _wait_for_scene(path: String) -> void:
	for i in 300:
		await _tree.process_frame
		if _tree.current_scene != null and _tree.current_scene.scene_file_path == path:
			await _tree.process_frame
			return
	check(false, "timed out waiting for scene %s" % path)
