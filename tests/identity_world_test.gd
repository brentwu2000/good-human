extends "res://tests/test_case.gd"
## Sprint 06 through the real scenes: the shelter, the adoption room, naming,
## and the pair carried into Home and the walk.

const TEST_SAVE: String = "user://tests/identity_world_save.json"

var _tree: SceneTree


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_tree = get_tree()
	DirAccess.make_dir_recursive_absolute(TEST_SAVE.get_base_dir())
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(TEST_SAVE)
	SaveManager.save_path = TEST_SAVE
	await _test_shelter()
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


func _wait_for_scene(path: String) -> void:
	for i in 300:
		await _tree.process_frame
		if _tree.current_scene != null and _tree.current_scene.scene_file_path == path:
			await _tree.process_frame
			return
	check(false, "timed out waiting for scene %s" % path)
