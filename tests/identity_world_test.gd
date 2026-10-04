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


func _wait_for_scene(path: String) -> void:
	for i in 300:
		await _tree.process_frame
		if _tree.current_scene != null and _tree.current_scene.scene_file_path == path:
			await _tree.process_frame
			return
	check(false, "timed out waiting for scene %s" % path)
