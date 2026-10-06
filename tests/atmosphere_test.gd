extends "res://tests/test_case.gd"
## P03-E09: the Combat Atmosphere Director on the real 3D walk. The street
## quietens as a fight builds, a heartbeat sits under the stand-off, blows
## and the dog are heard, people nearby watch, the first heavy blow puts the
## birds up. Presentation only: the fight itself is untouched.

const TEST_SAVE: String = "user://tests/atmosphere_save.json"

var _tree: SceneTree


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_tree = get_tree()
	for sound: StringName in [&"impact_light", &"impact_heavy", &"block", &"whoosh", &"bark", &"growl", &"leash", &"step", &"birds", &"pulse", &"ambience"]:
		var wav := SfxSynth.get_sound(sound)
		check(wav != null and wav.data.size() > 400, "P03-E09: a placeholder %s sound exists" % sound)
	check(SfxSynth.get_sound(&"ambience").loop_mode == AudioStreamWAV.LOOP_FORWARD and SfxSynth.get_sound(&"pulse").loop_mode == AudioStreamWAV.LOOP_FORWARD, "the street and the heartbeat loop")
	check(SfxSynth.get_sound(&"impact_heavy").data.size() > SfxSynth.get_sound(&"impact_light").data.size(), "a heavy blow sounds longer than a light one")

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
	await _frames(5)
	var map := _tree.current_scene as RunMap3D
	var atmosphere := map.atmosphere
	check(atmosphere != null, "the walk has an atmosphere director")
	await _seconds(2.0)
	var calm_street := atmosphere._ambience.volume_db
	check(atmosphere._ambience.playing and calm_street > -20.0, "walking, the street is heard (%.0f dB)" % calm_street)
	check(atmosphere._pulse.volume_db < -40.0, "and there is no heartbeat")

	# A fight builds.
	var coordinator := map.coordinator
	coordinator.time_scale = 0.0
	var pair := coordinator.get_pairs()[0]
	map.dog.global_position = pair.human_global_position() + Vector3(1.5, 0, 1.5)
	map.human.global_position = pair.human_global_position() + Vector3(1.0, 0, 0)
	# Someone standing nearby, to watch.
	var watcher: OpponentPair3D = coordinator.get_pairs()[1]
	var watcher_was := watcher.global_position
	watcher.global_position = pair.global_position + Vector3(5, 0, 0)
	coordinator.start_engagement(pair)
	await _seconds(2.0)
	check(atmosphere._ambience.volume_db < calm_street - 5.0, "as it builds the street goes quiet (%.0f dB)" % atmosphere._ambience.volume_db)
	check(atmosphere._pulse.volume_db > -20.0, "and a low heartbeat comes up under it (%.0f dB)" % atmosphere._pulse.volume_db)
	check(atmosphere._watchers.has(watcher), "someone standing nearby stops to watch")

	# Blows are heard; the first heavy one puts the birds up, once.
	var sim := coordinator.engagement.simulation
	var kick: CombatSkillData = load("res://data/combat/skills/skill_kick.tres")
	var jab: CombatSkillData = load("res://data/combat/skills/skill_jab.tres")
	var before := atmosphere._next_voice
	sim.combat_event.emit(&"strike", CombatSimulation.PLAYER, jab, 0.0)
	sim.combat_event.emit(&"hit", CombatSimulation.PLAYER, jab, 5.0)
	check(atmosphere._voices[before].stream == SfxSynth.get_sound(&"whoosh"), "a swing is heard as air")
	check(atmosphere._voices[before + 1].stream == SfxSynth.get_sound(&"impact_light"), "a jab lands as a light thump")
	check(not atmosphere._birds_flown, "a jab does not put the birds up")
	var nodes_before := map.get_child_count()
	sim.combat_event.emit(&"hit", CombatSimulation.OPPONENT, kick, 20.0)
	check(atmosphere._birds_flown, "the first heavy blow puts the birds up")
	check(map.get_child_count() > nodes_before + 5, "birds and dust are seen")
	var flown := map.get_child_count()
	sim.combat_event.emit(&"hit", CombatSimulation.OPPONENT, kick, 20.0)
	check(map.get_child_count() < flown + 6, "only once a fight")
	var at := atmosphere._next_voice
	sim.combat_event.emit(&"blocked", CombatSimulation.OPPONENT, jab, 2.0)
	check(atmosphere._voices[at].stream == SfxSynth.get_sound(&"block"), "a block is a dull thud")
	# The dog.
	at = atmosphere._next_voice
	map.get_node("DogAgency").emit_signal(&"barked", &"opening")
	check(atmosphere._voices[at].stream == SfxSynth.get_sound(&"bark"), "the dog's bark is heard")
	at = atmosphere._next_voice
	map.get_node("DogAgency").emit_signal(&"pulled", &"saved")
	check(atmosphere._voices[at].stream == SfxSynth.get_sound(&"leash"), "and the leash when it pulls")
	check_eq(sim.fighters[0].hp, sim.fighters[0].max_hp * map.run_manager.owner_condition, "presentation only: hearing the fight changes nothing in it")
	watcher.global_position = watcher_was
	finish()


func _seconds(seconds: float) -> void:
	await _tree.create_timer(seconds).timeout


func _frames(count: int) -> void:
	for i in count:
		await _tree.process_frame


func _wait_for_scene(path: String) -> void:
	for i in 600:
		await _tree.process_frame
		if _tree.current_scene != null and _tree.current_scene.scene_file_path == path:
			await _tree.process_frame
			return
	check(false, "timed out waiting for scene %s" % path)
