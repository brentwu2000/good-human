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
	# Owner direction: looked at from the street, the pups run about the pen.
	var before: Array[Vector3] = []
	for p in shelter._pivots:
		before.append(p.position)
	for i in 180:
		await _tree.process_frame
	var moved := 0
	for i in shelter._pivots.size():
		if shelter._pivots[i].position.distance_to(before[i]) > 0.05:
			moved += 1
	check(moved > 0, "the pups run about the window pen (%d moved)" % moved)
	for p in shelter._pivots:
		check(p.position.z >= ShelterScene.PEN_MIN.y - 0.001 and p.position.z <= ShelterScene.PEN_MAX.y + 0.001, "and stay in the pen")
	var at := shelter.selected
	shelter.select_step(1)
	check(shelter._pivots[shelter.selected].position.x <= shelter._pivots[at].position.x, "▶ watches the next pup to the right as seen from the street")
	shelter.select(first + 1)
	check_eq(shelter.selected, (first + 1) % ShelterScene.DOG_COUNT, "the player can look from pup to pup")
	var picked := shelter.dogs[shelter.selected]
	shelter.choose()
	check(Game.chosen_dog == picked, "choosing hands that dog on to the adoption")


func _test_adoption() -> void:
	Game.adopting_human = null
	# Owner direction: the pups run about the pen, the player's own included.
	# (At normal pace, in its own room, so nobody stops while it runs about.)
	var pen := (load(Game.ADOPTION_SCENE) as PackedScene).instantiate() as AdoptionScene
	pen.seed_value = 78
	_tree.root.add_child(pen)
	var start := pen.pup.position
	Input.action_press(&"move_left")
	for i in 10:
		await _tree.process_frame
	Input.action_release(&"move_left")
	check(pen.pup.position.x < start.x - 0.05, "the player's pup runs where it is told")
	var tapped := Vector3(0.9, 0, -0.9)
	var was := pen.pup.position.distance_to(tapped)
	pen._pup_target = tapped
	for i in 120:
		await _tree.process_frame
	check(pen.pup.position.distance_to(tapped) < was * 0.5, "or towards wherever the floor was tapped (%s)" % pen.pup.position)
	pen._pup_target = Vector3(9, 0, 9)
	for i in 30:
		await _tree.process_frame
	check(pen.pup.position.x <= AdoptionScene.PEN_MAX.x + 0.001 and pen.pup.position.z <= AdoptionScene.PEN_MAX.y + 0.001, "but never out of the pen")
	pen._pup_target = null
	var front := Vector3(AdoptionScene.STOP.x, 0, AdoptionScene.PEN_MIN.y)
	check(pen.seen_weight(front) > 0.99 and pen.seen_weight(Vector3(1.2, 0, AdoptionScene.PEN_MAX.y)) < 0.6, "a pup at the glass in front of them is seen better than one at the back")
	var litter_before: Array[Vector3] = []
	for other in pen._litter_pups:
		litter_before.append(other.position)
	for i in 240:
		await _tree.process_frame
	var moved := 0
	for k in pen._litter_pups.size():
		if pen._litter_pups[k].position.distance_to(litter_before[k]) > 0.05:
			moved += 1
	check(moved > 0, "the littermates wander about on their own (%d moved)" % moved)
	for k in pen._litter_pups.size():
		check(pen._litter_pups[k].position.distance_to(pen.pup.position) >= AdoptionScene.PUP_SPACING - 0.02, "pups go round each other, not through")
	pen.queue_free()
	var scene := (load(Game.ADOPTION_SCENE) as PackedScene).instantiate() as AdoptionScene
	scene.pace = 0.02
	scene.seed_value = 77
	_tree.root.add_child(scene)
	check(scene.dog == Game.chosen_dog, "S06-03: the dog chosen at the shelter is the one waiting")
	check_eq(scene.litter.size(), ShelterScene.DOG_COUNT - 1, "the rest of the litter shares the window pen")
	check(not scene.litter.has(scene.dog), "(not the player's pup again)")
	var reactions: Array[int] = []
	scene.reacted.connect(func(_i: int, r: int) -> void: reactions.append(r))
	var chosen: Array[HumanCandidate] = []
	scene.decided.connect(func(h: HumanCandidate) -> void: chosen.append(h))
	var gone: Array[int] = []
	scene.pup_taken.connect(func(k: int, _h: HumanCandidate) -> void: gone.append(k))
	check_eq(scene.perform(AdoptionScene.Behavior.WAG), -1, "nothing to do before anyone stops")
	# The first one to stop falls for another pup in the pen.
	await scene.visitor_ready
	check_eq(scene.visit_index, 0, "someone stops at the window")
	var line := scene.find_child("Line", true, false) as Label
	scene.litter_matches[0].interest[0] = 5.0
	scene.adoption.interest[0] = -5.0
	for k in AdoptionScene.ACTIONS_PER_VISIT:
		var r := scene.perform([AdoptionScene.Behavior.WAG, AdoptionScene.Behavior.SIT, AdoptionScene.Behavior.LICK_HAND][k])
		check(r >= 0, "they react to what the dog does")
		check(RegEx.create_from_string("[0-9%]").search(line.text) == null, "and never in numbers (%s)" % line.text)
	check_eq(scene.perform(AdoptionScene.Behavior.BARK), -1, "a look at the window has only so many moments")
	await scene.pup_taken
	check_eq(gone, [0], "owner direction: a visitor can take another pup home instead")
	check(scene.taken[0] and scene._litter_pups[0].is_queued_for_deletion(), "and it is gone from the pen")
	check(chosen.is_empty() and not Game.has_pair(), "the player's pup waits on")
	# The next one comes in for the player's pup.
	await scene.visitor_ready
	check_eq(scene.visit_index, 1, "someone else stops")
	scene.adoption.interest[1] = 5.0
	for k in AdoptionScene.ACTIONS_PER_VISIT:
		scene.perform(AdoptionScene.Behavior.SIT)
	for i in 600:
		await _tree.process_frame
		if not chosen.is_empty():
			break
	check_eq(reactions.size(), 2 * AdoptionScene.ACTIONS_PER_VISIT, "every moment got a reaction")
	check_eq(chosen.size(), 1, "and comes in for the dog")
	check(chosen.size() == 1 and chosen[0] == scene.humans[1], "the one who stopped and cared")
	check(not scene.took_home.has(1), "(not someone who already took a pup home)")
	# S06-06: the human is named, and from then on they are the save's pair.
	await scene.naming_ready
	check(scene.find_child("Naming", true, false).visible, "S06-06: the player names their human")
	var edit := scene.find_child("NameEdit", true, false) as LineEdit
	check(chosen[0].background().name_suggestions.has(edit.text), "starting from a name that fits them (%s)" % edit.text)
	var first_name := edit.text
	scene.next_suggestion()
	check(edit.text != first_name or chosen[0].background().name_suggestions.size() == 1, "another name can be offered")
	check(scene.summary().contains("動物醫院") and scene.summary().contains("回來"), "how they met is kept in words (%s)" % scene.summary())
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
	# S06-11: Home is the two of them first.
	var home := _tree.current_scene
	check((home.get_node("%PairName") as Label).text.begins_with("阿明"), "S06-11: Home leads with the human's name")
	check((home.get_node("%PairLabel") as Label).text.contains("📷"), "and a remembered moment")
	check(home.get_node("%PairView").find_children("*", "FighterPuppet3D", true, false).size() == 1, "and the two of them at home")
	# S06-12: meeting is the first entry of what the two have lived through.
	check(Game.goal_progress.is_discovered(&"events", &"met"), "S06-12: the meeting is in the collection")
	check_eq(Game.goal_progress.discovered_count(&"humans"), 0, "but no human is ever collected (no owner roster)")
	check((home.get_node("%GoalsLabel") as Label).text.contains("一起經歷過的事 1/"), "Home counts the moments lived")
	SaveManager.load_game()
	var saved_goals := GoalProgress.new()
	saved_goals.deserialize(SaveManager.data["dog"]["goals"])
	check(saved_goals.is_discovered(&"events", &"met"), "and it is saved")
	check(home.get_node("%PairView").get_index() < home.get_node("%StashLabel").get_parent().get_parent().get_index(), "before the stash and the counts")
	scene.queue_free()

	# S06-07: the first walk is this dog and this human.
	var pair := Game.pair_state
	_tree.current_scene.get_node("%Walk3DButton").pressed.emit()
	await _wait_for_scene(Game.RUN_MAP_3D_SCENE)
	await _tree.physics_frame
	var map := _tree.current_scene as RunMap3D
	check_eq(map.human._bubble.text, str(Memories.recall_for(pair, &"shelter")["recall"]), "S06-10: the first walk remembers the shelter")
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
	point.cancel_search()
	map.human.hold_time = 0.0
	# S06-10: meeting a pair the two have history with brings it back.
	var someone: OpponentPair3D = null
	for p in map.coordinator.get_pairs():
		if p.is_present() and p.is_idle():
			someone = p
			break
	Memories.remember(pair, &"won_against", someone.encounter.id, 1, {"who": "他", "dog": "牠"})
	map.dog.global_position = someone.global_position + Vector3(1.0, 0.1, 0.5)
	map.human.global_position = someone.global_position + Vector3(2.0, 0.1, 1.0)
	for i in 4:
		await _tree.physics_frame
	check_eq(map.human._bubble.text, str(Memories.recall_for(pair, someone.encounter.id)["recall"]), "S06-10: meeting them again, the human remembers")
	pair.memories.pop_back()
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
