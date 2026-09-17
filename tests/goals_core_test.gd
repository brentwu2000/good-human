extends "res://tests/test_case.gd"
## P2G-001..008, 018: desire data, tracker, primary/context selection,
## emergent triggers, persistent threads, completion/failure, chaining, save.

var catalog: GoalCatalog
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	catalog = DataRegistry.goals
	rng.seed = 5
	_test_catalog()
	_test_strange_scent_chain_across_walks()
	_test_rival_fork_and_rematch()
	_test_emergent_limit_and_squirrel_fork()
	_test_old_master_growth_context()
	_test_ignored_and_discovery_gating()
	_test_repetition_penalty()
	_test_save_roundtrip()
	finish()


func _tracker(progress: GoalProgress) -> DesireTracker:
	var tracker := DesireTracker.new(progress, catalog.desires)
	tracker.undiscovered = {&"dogs": 3, &"places": 3}
	return tracker


func _test_catalog() -> void:
	var ids: Dictionary[StringName, bool] = {}
	var categories: Dictionary = {}
	for desire in catalog.desires:
		check(not desire.dog_text.is_empty(), "%s speaks as the dog" % desire.id)
		check(desire.completion != null, "%s can be resolved" % desire.id)
		ids[desire.id] = true
		categories[desire.category] = true
	check(catalog.desires.size() >= 5, "5+ desire templates")
	check(categories.size() >= 5, "varied desire kinds")
	for desire in catalog.desires:
		for next in desire.next_on_complete + desire.next_on_fail:
			check(ids.has(next), "%s -> %s exists" % [desire.id, next])
	var emergent := catalog.desires.filter(func(d: DesireData) -> bool: return d.layer == DesireData.Layer.EMERGENT)
	check(emergent.size() >= 2, "2+ emergent triggers")


func _test_strange_scent_chain_across_walks() -> void:
	var progress := GoalProgress.new()
	var tracker := _tracker(progress)
	var started: Array[StringName] = []
	tracker.desire_started.connect(func(d: DesireData, reason: StringName) -> void: started.append(StringName("%s:%s" % [d.id, reason])))

	var primary := tracker.begin_walk(rng)
	check_eq(primary.id, &"desire_strange_scent", "fresh dog: strange scent calls")
	tracker.handle_event(&"cue_sniffed", &"scent_alley")
	check(tracker.is_active(&"desire_strange_scent"), "wrong cue does nothing")
	tracker.handle_event(&"cue_sniffed", &"scent_park")
	check_eq(progress.state_of(&"desire_strange_scent"), GoalProgress.State.COMPLETED, "scent followed")
	check(progress.has_flag(&"found_half_ball"), "clue remembered")
	check(started.has(&"desire_whose_ball:follow_up"), "clue leads to a follow-up right away")
	tracker.end_walk()
	check_eq(progress.state_of(&"desire_whose_ball"), GoalProgress.State.DORMANT, "unresolved thread sleeps between walks")

	primary = tracker.begin_walk(rng)
	check_eq(primary.id, &"desire_whose_ball", "next walk returns to the unresolved thread")
	tracker.handle_event(&"cue_sniffed", &"scent_alley")
	check(progress.has_flag(&"rival_revealed") and tracker.is_active(&"desire_find_rival"), "scent trail reveals a rival")
	tracker.handle_event(&"pair_met", &"enc_jogger", true)
	check(tracker.is_active(&"desire_find_rival"), "other dogs are not the rival")
	tracker.handle_event(&"pair_met", &"enc_rival", true)
	check(tracker.is_active(&"desire_rival_duel"), "meeting the rival wants a duel")
	tracker.end_walk()
	check_eq(progress.walks, 2, "walks counted")


func _test_rival_fork_and_rematch() -> void:
	var progress := GoalProgress.new()
	progress.states[&"desire_rival_duel"] = GoalProgress.State.DORMANT
	progress.set_flag(&"rival_revealed")
	var tracker := _tracker(progress)
	check_eq(tracker.begin_walk(rng).id, &"desire_rival_duel", "duel thread resumes")
	tracker.handle_event(&"fight_lost", &"enc_rival")
	check_eq(progress.state_of(&"desire_rival_duel"), GoalProgress.State.FAILED, "losing fails the duel")
	check(tracker.is_active(&"desire_rival_rematch"), "failure forks into a rematch")
	tracker.end_walk()
	check_eq(tracker.begin_walk(rng).id, &"desire_rival_rematch", "rematch carries to the next walk")
	tracker.handle_event(&"fight_won", &"enc_rival")
	check(progress.has_flag(&"rival_beaten") and progress.state_of(&"desire_rival_rematch") == GoalProgress.State.COMPLETED, "rematch won")
	tracker.end_walk()

	var winner := GoalProgress.new()
	winner.states[&"desire_rival_duel"] = GoalProgress.State.DORMANT
	var t2 := _tracker(winner)
	t2.begin_walk(rng)
	t2.handle_event(&"fight_won", &"enc_rival")
	check(winner.has_flag(&"rival_beaten") and winner.state_of(&"desire_rival_rematch") == GoalProgress.State.INACTIVE, "winning first time needs no rematch")


func _test_emergent_limit_and_squirrel_fork() -> void:
	var progress := GoalProgress.new()
	progress.set_flag(&"found_half_ball")
	var tracker := _tracker(progress)
	tracker.begin_walk(rng)
	tracker.handle_event(&"squirrel_spotted", &"squirrel")
	check(tracker.is_active(&"desire_chase_squirrel"), "spotting a squirrel creates a desire")
	tracker.handle_event(&"item_found", &"tennis_ball", true)
	check(tracker.is_active(&"desire_bring_ball_home"), "finding a ball: bring it home")
	tracker.handle_event(&"fight_started", &"enc_old_master")
	check(not tracker.is_active(&"desire_old_master_grudge"), "at most two emergent desires")
	tracker.handle_event(&"squirrel_escaped", &"squirrel")
	check(progress.has_flag(&"squirrel_got_away"), "escape remembered")
	tracker.handle_event(&"brought_home", &"tennis_ball")
	check_eq(progress.state_of(&"desire_bring_ball_home"), GoalProgress.State.COMPLETED, "ball brought home")
	tracker.end_walk()

	progress.last_primary = &""
	var picks: Dictionary[StringName, bool] = {}
	for i in 12:
		var primary := tracker.begin_walk(rng)
		if primary != null:
			picks[primary.id] = true
		tracker.end_walk()
	check(picks.has(&"desire_squirrel_again"), "escaped squirrel becomes a later walk's desire")


func _test_old_master_growth_context() -> void:
	var progress := GoalProgress.new()
	progress.set_flag(&"found_half_ball")
	var tracker := _tracker(progress)
	tracker.undiscovered = {}
	tracker.begin_walk(rng)
	tracker.handle_event(&"fight_started", &"enc_old_master")
	check(tracker.is_active(&"desire_old_master_grudge"), "provoking the Old Master stirs the dog")
	tracker.handle_event(&"fight_lost", &"enc_old_master")
	check(progress.has_flag(&"lost_to_old_master"), "defeat remembered")
	tracker.end_walk()

	progress.last_primary = &""
	check_eq(tracker.begin_walk(rng).id, &"desire_avoid_old_master", "untrained human: avoid him")
	tracker.handle_event(&"extracted", &"bus_stop")
	check_eq(progress.state_of(&"desire_avoid_old_master"), GoalProgress.State.COMPLETED, "got home safely")
	tracker.end_walk()

	tracker.human_perks = 2
	check_eq(tracker.begin_walk(rng).id, &"desire_rematch_old_master", "grown human: the dog wants a rematch")
	tracker.handle_event(&"fight_lost", &"enc_old_master")
	check_eq(progress.state_of(&"desire_rematch_old_master"), GoalProgress.State.FAILED, "rematch can fail")
	tracker.end_walk()


func _test_ignored_and_discovery_gating() -> void:
	var progress := GoalProgress.new()
	progress.set_flag(&"found_half_ball")
	var tracker := _tracker(progress)
	var primary := tracker.begin_walk(rng)
	check(primary != null and not primary.persistent, "a simple desire is offered")
	tracker.end_walk()
	check_eq(progress.state_of(primary.id), GoalProgress.State.INACTIVE, "ignored desires just fade")

	tracker.undiscovered = {&"dogs": 0, &"places": 0}
	progress.last_primary = &""
	var next := tracker.begin_walk(rng)
	check(next == null or next.needs_undiscovered.is_empty(), "nothing left to discover: no discovery desire")
	tracker.end_walk()


func _test_repetition_penalty() -> void:
	var progress := GoalProgress.new()
	progress.set_flag(&"found_half_ball")
	var tracker := _tracker(progress)
	var first := tracker.begin_walk(rng)
	tracker.end_walk()
	var second := tracker.begin_walk(rng)
	tracker.end_walk()
	check(first != null and second != null and first.id != second.id, "does not offer the same desire twice in a row (%s, %s)" % [first.id, second.id])


func _test_save_roundtrip() -> void:
	var progress := GoalProgress.new()
	progress.states[&"desire_whose_ball"] = GoalProgress.State.DORMANT
	progress.set_flag(&"found_half_ball")
	progress.discover(&"dogs", &"enc_rival")
	progress.completions[&"desire_strange_scent"] = 1
	progress.walks = 3
	progress.last_primary = &"desire_strange_scent"
	var copy := GoalProgress.new()
	copy.deserialize(JSON.parse_string(JSON.stringify(progress.serialize())))
	check_eq(copy.state_of(&"desire_whose_ball"), GoalProgress.State.DORMANT, "thread state saved")
	check(copy.has_flag(&"found_half_ball") and copy.is_discovered(&"dogs", &"enc_rival"), "flags and discoveries saved")
	check(copy.walks == 3 and copy.completions[&"desire_strange_scent"] == 1 and copy.last_primary == &"desire_strange_scent", "counters saved")
	var broken := GoalProgress.new()
	broken.deserialize({"states": {"x": "NOPE", "y": 3}, "flags": "bad", "discoveries": {"dogs": [1, "a"]}, "walks": -2})
	check(broken.states.is_empty() and broken.flags.is_empty() and broken.discovered_count(&"dogs") == 1 and broken.walks == 0, "malformed goal data tolerated")
