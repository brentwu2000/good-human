extends "res://tests/test_case.gd"
## P2-001/002 event + tracker, P2-008 anti-farming, P2-009 summary,
## P2-010/011 conversion, P2-012 persistence, P2-013 resolver, P2-014 perks.

const TEST_SAVE: String = "user://tests/training_core_save.json"
const DRAGGED: TrainingEventData = preload("res://data/training/events/run_dragged.tres")
const PROVOKE: TrainingEventData = preload("res://data/training/events/courage_provoke.tres")
const LONG_WALK: TrainingEventData = preload("res://data/training/events/endure_long_walk.tres")
const PLAYER: FighterData = preload("res://data/combat/fighters/player_human.tres")

var balance: TrainingBalance


func _ready() -> void:
	balance = DataRegistry.training
	_test_data()
	_test_cooldown_and_diminishing()
	_test_unique_and_cap()
	_test_conversion()
	_test_resolver_and_perks()
	_test_traits_and_stats()
	_test_persistence_through_game()
	await _test_run_manager_records()
	finish()


func _test_data() -> void:
	check(balance != null, "training balance loaded")
	check_eq(balance.extract_conversion, 1.0, "extraction converts 100%")
	check_eq(balance.defeat_conversion, 0.5, "defeat converts 50%")
	check(balance.perks.size() >= 8, "at least 8 prototype perks")
	var hidden := balance.perks.filter(func(p: PerkData) -> bool: return p.hidden)
	check(hidden.size() >= 2, "hidden mixed perks")
	var tags: Dictionary = {}
	for file in ResourceLoader.list_directory("res://data/training/events"):
		var data := load("res://data/training/events/" + file) as TrainingEventData
		check(data != null and not data.experience_text.is_empty(), "%s describes an experience" % file)
		check(not data.experience_text.contains("+") and not data.experience_text.contains(data.tag_name(data.tag)), "%s does not show raw tags" % file)
		tags[data.tag] = true
	check_eq(tags.size(), 5, "events cover all five tags")


func _test_cooldown_and_diminishing() -> void:
	var tracker := TrainingTracker.new(balance)
	check_eq(tracker.record(TrainingEvent.new(DRAGGED, &"", 0.0)), 1.0, "first drag counts fully")
	check_eq(tracker.record(TrainingEvent.new(DRAGGED, &"", DRAGGED.cooldown - 1.0)), 0.0, "cooldown blocks repeat")
	var second := tracker.record(TrainingEvent.new(DRAGGED, &"", DRAGGED.cooldown + 1.0))
	check(is_equal_approx(second, balance.repeat_diminishing), "repeat diminishes (%.2f)" % second)
	var third := tracker.record(TrainingEvent.new(DRAGGED, &"", DRAGGED.cooldown * 3.0))
	check(third < second, "keeps diminishing")
	check_eq(tracker.events.size(), 3, "accepted events kept")


func _test_unique_and_cap() -> void:
	var tracker := TrainingTracker.new(balance)
	check(tracker.record(TrainingEvent.new(PROVOKE, &"pair_a", 1.0)) > 0.0, "provoke pair a")
	check_eq(tracker.record(TrainingEvent.new(PROVOKE, &"pair_a", 50.0)), 0.0, "same pair only once")
	check(tracker.record(TrainingEvent.new(PROVOKE, &"pair_b", 51.0)) > 0.0, "another pair counts")
	for i in 100:
		tracker.record(TrainingEvent.new(LONG_WALK, StringName("walk_%d" % i), float(i)))
	check_eq(tracker.total(TrainingEventData.Tag.ENDURE), balance.tag_run_cap, "per-run tag cap")


func _test_conversion() -> void:
	var tracker := TrainingTracker.new(balance)
	tracker.record(TrainingEvent.new(DRAGGED))
	tracker.record(TrainingEvent.new(PROVOKE, &"x", 0.0, "", {"name": "老爺爺"}, 2.0))
	var extracted := RunTrainingSummary.from_tracker(tracker, RunResult.Outcome.EXTRACTED)
	check_eq(extracted.converted[TrainingEventData.Tag.RUN], 1.0, "extraction keeps all RUN")
	check_eq(extracted.converted[TrainingEventData.Tag.COURAGE], 2.0, "context scale applied")
	check(not extracted.is_partial(), "extraction not partial")
	var defeated := RunTrainingSummary.from_tracker(tracker, RunResult.Outcome.DEFEATED)
	check_eq(defeated.converted[TrainingEventData.Tag.COURAGE], 1.0, "defeat keeps half")
	check(defeated.is_partial(), "defeat is partial")
	var lines := extracted.experiences()
	check_eq(lines.size(), 2, "two experiences")
	check(String(lines[1]["text"]).contains("老爺爺"), "experience names the opponent")


func _test_resolver_and_perks() -> void:
	var growth := HumanGrowth.new()
	var tracker := TrainingTracker.new(balance)
	for i in 12:
		tracker.record(TrainingEvent.new(DRAGGED, StringName("k%d" % i), float(i * 20)))
	var summary := RunTrainingSummary.from_tracker(tracker, RunResult.Outcome.EXTRACTED)
	GrowthResolver.apply(growth, summary, false, balance)
	check(growth.get_growth(TrainingEventData.Tag.RUN) >= 6.0, "RUN growth accumulated")
	check(growth.has_perk(&"perk_forced_jogging"), "被迫晨跑 unlocked")
	check(summary.new_perks.any(func(p: PerkData) -> bool: return p.id == &"perk_forced_jogging"), "summary lists new perk")
	GrowthResolver.apply(growth, summary, false, balance)
	check(summary.new_perks.is_empty(), "perk not unlocked twice")

	var survivor := HumanGrowth.new()
	survivor.growth["ENDURE"] = 6.0
	GrowthResolver.apply(survivor, RunTrainingSummary.new(), false, balance)
	check(not survivor.has_perk(&"perk_survived_today"), "今天也活下來了 needs a hard defeat")
	GrowthResolver.apply(survivor, RunTrainingSummary.new(), true, balance)
	check(survivor.has_perk(&"perk_survived_today") and survivor.defeats == 1, "unlocked after surviving a defeat")


func _test_traits_and_stats() -> void:
	var untrained := GrowthResolver.traits(HumanGrowth.new(), balance)
	var trained_growth := HumanGrowth.new()
	for tag_name: String in trained_growth.growth.keys():
		trained_growth.growth[tag_name] = balance.trait_full_growth
	var trained := GrowthResolver.traits(trained_growth, balance)
	check(trained.stumble_after > untrained.stumble_after, "RUN: stumbles later")
	check(trained.exertion_gain < untrained.exertion_gain and trained.recovery_time < untrained.recovery_time, "ENDURE: tires slower, recovers faster")
	check(trained.hesitation_time < untrained.hesitation_time, "COURAGE: less hesitation")
	check(trained.heavy_bag_speed > untrained.heavy_bag_speed, "STRAIN: heavy bag slows less")
	check(trained.greets and not untrained.greets, "SOCIAL: greets people")

	var perk_only := HumanGrowth.new()
	perk_only.perks.append(&"perk_seen_it_all")
	check_eq(GrowthResolver.traits(perk_only, balance).hesitation_time, balance.hesitation_trained, "perk completes its trait")

	var fighter := GrowthResolver.apply_to_fighter(PLAYER, trained_growth, balance)
	check(fighter.stats.agility > PLAYER.stats.agility and fighter.stats.strength > PLAYER.stats.strength and fighter.stats.will > PLAYER.stats.will, "growth raises combat stats")
	check(fighter != PLAYER and PLAYER.stats.agility == (load(PLAYER.resource_path) as FighterData).stats.agility, "base fighter untouched")
	check_eq(fighter.body_scale, PLAYER.body_scale, "growth never changes appearance")


func _test_persistence_through_game() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_SAVE.get_base_dir())
	var original_path := SaveManager.save_path
	var original_data := SaveManager.data.duplicate(true)
	var original_growth := Game.human_growth.serialize()
	var original_stash := Game.home_stash.serialize()
	SaveManager.save_path = TEST_SAVE
	SaveManager.reset_to_default()
	Game.human_growth.clear()

	var tracker := TrainingTracker.new(balance)
	tracker.record(TrainingEvent.new(DRAGGED))
	var result := RunResult.new()
	result.outcome = RunResult.Outcome.DEFEATED
	result.training = RunTrainingSummary.from_tracker(tracker, result.outcome)
	Game.finish_run(result, false)
	check_eq(Game.human_growth.get_growth(TrainingEventData.Tag.RUN), 0.5, "defeat stored half the growth")

	Game.human_growth.clear()
	SaveManager.load_game()
	Game.load_profile()
	check_eq(Game.human_growth.get_growth(TrainingEventData.Tag.RUN), 0.5, "growth survives save/load")
	check_eq(Game.human_growth.defeats, 1, "defeat count saved")

	var old := HumanGrowth.new()
	old.deserialize({"growth": "broken", "perks": [1, "perk_less_shy"], "defeats": -3})
	check(old.get_growth(TrainingEventData.Tag.RUN) == 0.0 and old.perks == [&"perk_less_shy"] and old.defeats == 0, "malformed growth data tolerated")

	DirAccess.remove_absolute(TEST_SAVE)
	SaveManager.save_path = original_path
	SaveManager.data = original_data
	Game.human_growth.deserialize(original_growth)
	Game.home_stash.deserialize(original_stash, DataRegistry.get_item)


func _test_run_manager_records() -> void:
	var run := RunManager.new()
	run.auto_start = false
	run.report_to_game = false
	add_child(run)
	check_eq(run.record_training(DRAGGED), 0.0, "nothing recorded before the run")
	run.start_run(11)
	check_eq(run.record_training(DRAGGED), 1.0, "recorded during the run")
	var ended: Array[RunResult] = []
	run.run_ended.connect(func(r: RunResult) -> void: ended.append(r))
	run.defeat_run("測試")
	check(ended[0].training != null and ended[0].training.converted[TrainingEventData.Tag.RUN] == 0.5, "defeat result carries partial training")
	run.start_run(12)
	check_eq(run.training.total(TrainingEventData.Tag.RUN), 0.0, "new run starts untrained")
	run.queue_free()
	await get_tree().process_frame
