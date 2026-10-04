extends "res://tests/test_case.gd"
## Sprint 06 through the real scenes: the shelter, the adoption room, naming,
## and the pair carried into Home and the walk.

const TEST_SAVE: String = "user://tests/identity_world_save.json"

var _tree: SceneTree


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_tree = get_tree()
	Game.use_classic_pair_when_missing = false
	DirAccess.make_dir_recursive_absolute(TEST_SAVE.get_base_dir())
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(TEST_SAVE)
	SaveManager.save_path = TEST_SAVE
	await _test_shelter()
	await _test_adoption()
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(TEST_SAVE)
	finish()


func _test_shelter() -> void:
	var placeholder := Node.new()
	_tree.root.add_child(placeholder)
	_tree.current_scene = placeholder
	_tree.change_scene_to_file(Game.SHELTER_SCENE)
	await _wait_for_scene(Game.SHELTER_SCENE)
	var shelter := _tree.current_scene as ShelterScene
	check_eq(shelter.dogs.size(), ShelterScene.DOG_COUNT, "S06-02: dogs are waiting at the shelter")
	var shown := shelter._pivots.filter(func(p: Node3D) -> bool: return p.is_inside_tree() and p.get_node_or_null("Model") != null)
	check_eq(shown.size(), ShelterScene.DOG_COUNT, "each in its pen, as its breed")
	var card := shelter.find_child("DogTraits", true, false) as Label
	var first := shelter.selected
	var dog := shelter.dogs[first]
	for id in dog.visible_trait_ids:
		check(card.text.contains(DataRegistry.get_dog_trait(id).text), "the card says what can be seen (%s)" % id)
	for id in dog.hidden_trait_ids:
		check(not card.text.contains(DataRegistry.get_dog_trait(id).text), "but not what cannot (%s)" % id)
	check(card.text.contains("看不出來"), "and that there is more to find out")
	var digits := RegEx.create_from_string("[0-9%]")
	check(digits.search(card.text) == null, "never a number")
	Input.action_press(&"move_right")
	await _tree.process_frame
	Input.action_release(&"move_right")
	shelter.select(first + 1)
	check_eq(shelter.selected, (first + 1) % ShelterScene.DOG_COUNT, "the player can look along the pens")
	var picked := shelter.dogs[shelter.selected]
	shelter.choose()
	check(Game.chosen_dog == picked, "choosing hands that dog on to the adoption")


func _test_adoption() -> void:
	Game.adopting_human = null
	var scene := (load(Game.ADOPTION_SCENE) as PackedScene).instantiate() as AdoptionScene
	scene.pace = 0.02
	scene.seed_value = 77
	_tree.root.add_child(scene)
	check(scene.dog == Game.chosen_dog, "S06-03: the dog chosen at the shelter is the one waiting")
	var reactions: Array[int] = []
	scene.reacted.connect(func(_i: int, r: int) -> void: reactions.append(r))
	check_eq(scene.perform(AdoptionScene.Behavior.WAG), -1, "nothing to do before anyone comes in")
	for visit in AdoptionScene.VISITORS:
		await scene.visitor_ready
		check_eq(scene.visit_index, visit, "visitor %d comes in" % (visit + 1))
		var line := scene.find_child("Line", true, false) as Label
		for k in AdoptionScene.ACTIONS_PER_VISIT:
			var r := scene.perform([AdoptionScene.Behavior.WAG, AdoptionScene.Behavior.SIT, AdoptionScene.Behavior.LICK_HAND][k])
			check(r >= 0, "they react to what the dog does")
			check(RegEx.create_from_string("[0-9%]").search(line.text) == null, "and never in numbers (%s)" % line.text)
		check_eq(scene.perform(AdoptionScene.Behavior.BARK), -1, "a visit has only so many moments")
	check_eq(reactions.size(), AdoptionScene.VISITORS * AdoptionScene.ACTIONS_PER_VISIT, "every moment got a reaction")
	var chosen: Array[HumanCandidate] = []
	scene.decided.connect(func(h: HumanCandidate) -> void: chosen.append(h))
	for i in 600:
		await _tree.process_frame
		if not chosen.is_empty():
			break
	check_eq(chosen.size(), 1, "one of them comes back for the dog")
	check(chosen.size() == 1 and scene.humans.has(chosen[0]), "someone who visited")
	# S06-06: the human is named, and from then on they are the save's pair.
	await scene.naming_ready
	check(scene.find_child("Naming", true, false).visible, "S06-06: the player names their human")
	var edit := scene.find_child("NameEdit", true, false) as LineEdit
	check(chosen[0].background().name_suggestions.has(edit.text), "starting from a name that fits them (%s)" % edit.text)
	var first_name := edit.text
	scene.next_suggestion()
	check(edit.text != first_name or chosen[0].background().name_suggestions.size() == 1, "another name can be offered")
	check(scene.summary().contains("收容所") and scene.summary().contains("回來"), "how they met is kept in words (%s)" % scene.summary())
	scene.confirm_name("  阿明  ")
	check(Game.has_pair(), "naming makes them the pair")
	check_eq(Game.pair_state.human_custom_name, "阿明", "under the name given")
	check(Game.pair_state.dog == scene.dog and Game.pair_state.human == chosen[0], "this dog and this human")
	check_eq(Game.owner_fighter().display_name, "阿明", "and the walk's fighter goes by it")
	check(not Game.pair_state.is_classic, "a pair of the player's own, not the classic one")
	SaveManager.load_game()
	var saved := PairState.deserialize(SaveManager.data.get("pair"))
	check(saved != null and saved.human_custom_name == "阿明" and saved.dog.breed_id == scene.dog.breed_id, "it is saved at once")
	await _wait_for_scene(Game.HOME_SCENE)
	check(_tree.current_scene.scene_file_path == Game.HOME_SCENE, "and the pair goes home")
	scene.queue_free()

	# S06-07: the first walk is this dog and this human.
	var pair := Game.pair_state
	_tree.current_scene.get_node("%Walk3DButton").pressed.emit()
	await _wait_for_scene(Game.RUN_MAP_3D_SCENE)
	await _tree.physics_frame
	var map := _tree.current_scene as RunMap3D
	check_eq(map.human.fighter.display_name, "阿明", "S06-07: the walk's owner is the adopted human")
	check_eq(map.human.fighter.stats.strength, pair.human.stats[&"strength"], "with their own hidden strength")
	check_eq(map.human.fighter.shirt_color.to_html(false), pair.human.shirt_color.to_html(false), "and their own clothes")
	var breed := DataRegistry.get_dog_breed(pair.dog.breed_id)
	var model := map.dog.find_child("Model", true, false)
	check(model != null and model.scene_file_path.get_file().get_basename().begins_with(breed.model_path.get_file().get_basename()), "the walk's dog is the breed chosen at the shelter (%s)" % (model.scene_file_path if model != null else "none"))
	check(is_equal_approx(map.dog.sprint_speed, 6.2 * pair.dog.stat(&"energy")), "its energy is its own (%.2f)" % map.dog.sprint_speed)
	check(is_equal_approx(Game.dog_talent(&"nose"), pair.dog.stat(&"nose")), "and so is its nose")
	# S06-09: a habit the human has picked up shows on the walk.
	var behavior := map.get_node("OwnerBehavior") as OwnerBehavior
	check(not behavior.has_habit(&"search_sigh"), "S06-09: a new human has no habits yet")
	pair.habit_ids.append(&"search_sigh")
	behavior.refresh_habits()
	var point := map.get_node("SearchPoints/trash_street_east") as SearchPoint3D
	map.dog.global_position = point.global_position + Vector3(0.6, 0.1, 0)
	map.human.global_position = point.global_position + Vector3(1.6, 0.1, 0)
	point.interact(map.run_manager)
	for i in 5:
		await _tree.physics_frame
	check(map.human.hold_time > 0.0, "used to the dog rummaging, the human just stops and waits")
	check_eq(map.human._bubble.text, DataRegistry.get_habit(&"search_sigh").walk_line, "with a sigh of their own")
	pair.habit_ids.erase(&"search_sigh")
	# Persistence: a reload brings back the same pair, not a new one.
	var before := JSON.stringify(pair.serialize())
	SaveManager.load_game()
	Game.load_profile()
	check_eq(JSON.stringify(Game.pair_state.serialize()), before, "the pair survives a reload unchanged")
	check(Game.owner_fighter().display_name == "阿明", "and is still called by name")
	# A save is one pair: meeting another dog means a new game, from the shelter.
	Game.home_stash.add_item(DataRegistry.get_item(&"umbrella"), 1)
	Game.start_new_game()
	await _wait_for_scene(Game.SHELTER_SCENE)
	check(not Game.has_pair() and Game.home_stash.is_empty(), "a new game starts with nothing and no pair")
	SaveManager.load_game()
	Game.load_profile()
	check(not Game.has_pair(), "and stays that way after a reload, until the next adoption")


func _wait_for_scene(path: String) -> void:
	for i in 300:
		await _tree.process_frame
		if _tree.current_scene != null and _tree.current_scene.scene_file_path == path:
			await _tree.process_frame
			return
	check(false, "timed out waiting for scene %s" % path)
