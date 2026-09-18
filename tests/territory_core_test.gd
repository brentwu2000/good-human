extends "res://tests/test_case.gd"
## Sprint 05 P4-005: the places the dog keeps going back to. Pure state and
## data; `territory_world_test` covers the banyan in the real 3D walk.

const BANYAN: StringName = &"banyan"


func _ready() -> void:
	_test_data()
	_test_states_only_move_forward()
	_test_claim_needs_walks_that_came_home()
	_test_round_trip()
	_test_bad_save_data()
	_test_claim_resolution()
	finish()


func _test_data() -> void:
	var data := DataRegistry.get_territory(BANYAN)
	check(data != null, "the banyan is authored data, not code")
	check_eq(data.display_name, "大榕樹", "it has a name")
	check_eq(data.claim_target, 3, "three relevant extractions, as the sprint asks")
	check(not data.resident_spot.is_empty(), "another dog lives there")
	check(not data.owned_flag.is_empty(), "owning it sets a flag other content can read")
	for text in [data.discovered_text, data.rival_scent_text, data.marked_text, data.claimed_text]:
		check(not text.is_empty(), "the dog has words for each step")
	check_eq(DataRegistry.get_all_territories().size(), 1, "exactly one territory this sprint")


func _test_states_only_move_forward() -> void:
	var progress := TerritoryProgress.new()
	check_eq(progress.state_of(BANYAN), TerritoryProgress.State.UNKNOWN, "somewhere never visited")
	check(progress.advance_to(BANYAN, TerritoryProgress.State.DISCOVERED), "finding it moves it on")
	check(progress.advance_to(BANYAN, TerritoryProgress.State.CONTESTED), "smelling the resident moves it on")
	check(not progress.advance_to(BANYAN, TerritoryProgress.State.DISCOVERED), "a walk cannot make the dog forget a place")
	check_eq(progress.state_of(BANYAN), TerritoryProgress.State.CONTESTED, "it stays where it got to")
	progress.note_event(BANYAN, "這裡有別的狗的味道。")
	check(progress.last_event(BANYAN).contains("別的狗"), "the place remembers the last thing that happened")


func _test_claim_needs_walks_that_came_home() -> void:
	var progress := TerritoryProgress.new()
	progress.advance_to(BANYAN, TerritoryProgress.State.CONTESTED)
	check(not progress.add_claim(BANYAN, 3), "one good walk is not enough")
	check_eq(progress.state_of(BANYAN), TerritoryProgress.State.CLAIMING, "but the dog is working on it")
	check_eq(progress.claim_progress(BANYAN), 1, "progress counted")
	check(not progress.add_claim(BANYAN, 3), "two is not enough either")
	check(progress.add_claim(BANYAN, 3), "the third one finishes it")
	check(progress.is_owned(BANYAN), "the place is the dog's now")
	check(not progress.add_claim(BANYAN, 3), "and cannot be claimed again")
	check_eq(progress.claim_progress(BANYAN), 3, "progress does not run past the target")


func _test_round_trip() -> void:
	var progress := TerritoryProgress.new()
	progress.advance_to(BANYAN, TerritoryProgress.State.CLAIMING)
	progress.add_claim(BANYAN, 3)
	progress.note_event(BANYAN, "這裡也有我的味道了。")
	var restored := TerritoryProgress.new()
	restored.deserialize(progress.serialize())
	check_eq(restored.state_of(BANYAN), progress.state_of(BANYAN), "state survives a save")
	check_eq(restored.claim_progress(BANYAN), progress.claim_progress(BANYAN), "claim progress survives a save")
	check_eq(restored.last_event(BANYAN), progress.last_event(BANYAN), "the last event survives a save")


## A hand-edited or older save must not crash or invent ownership.
func _test_bad_save_data() -> void:
	var progress := TerritoryProgress.new()
	progress.deserialize({})
	check_eq(progress.state_of(BANYAN), TerritoryProgress.State.UNKNOWN, "an empty save owns nothing")
	progress.deserialize({"states": {"banyan": 99}, "claims": {"banyan": -5}, "last_events": "nonsense"})
	check_eq(progress.state_of(BANYAN), TerritoryProgress.State.UNKNOWN, "an impossible state is ignored")
	check_eq(progress.claim_progress(BANYAN), 0, "negative progress is ignored")
	progress.deserialize({"states": {"banyan": 4}})
	check(progress.is_owned(BANYAN), "a real saved state is restored")


## P4-009/P4-010: a marked place moves forward only when the walk got home, and
## a bad walk never loses what the dog already earned.
func _test_claim_resolution() -> void:
	var original_path := SaveManager.save_path
	var original_data: Dictionary = SaveManager.data.duplicate(true)
	var original_goals := Game.goal_progress.serialize()
	var original_territories := Game.territory_progress.serialize()
	SaveManager.save_path = "user://tests/territory_claim_save.json"
	DirAccess.make_dir_recursive_absolute(SaveManager.save_path.get_base_dir())
	Game.territory_progress.clear()
	Game.goal_progress.clear()
	var data := DataRegistry.get_territory(BANYAN)

	# Marked, but the walk ended badly: nothing gained, nothing lost.
	Game.territory_progress.advance_to(BANYAN, TerritoryProgress.State.CONTESTED)
	Game.finish_run(_walk(RunResult.Outcome.DEFEATED, [BANYAN]), false)
	check_eq(Game.territory_progress.claim_progress(BANYAN), 0, "a walk that did not get home earns no claim")
	check_eq(Game.territory_progress.state_of(BANYAN), TerritoryProgress.State.CONTESTED, "and takes nothing away")

	# Got home without marking: the place is not advanced by simply extracting.
	Game.finish_run(_walk(RunResult.Outcome.EXTRACTED, []), false)
	check_eq(Game.territory_progress.claim_progress(BANYAN), 0, "getting home alone does not claim a place")

	# Marked and got home: this one counts.
	var first := _walk(RunResult.Outcome.EXTRACTED, [BANYAN])
	Game.finish_run(first, false)
	check_eq(Game.territory_progress.claim_progress(BANYAN), 1, "marked and got home: one step")
	check_eq(first.territory_claims.get(BANYAN, 0), 1, "the result reports the progress")
	check(first.territories_claimed.is_empty(), "but the place is not the dog's yet")
	check_eq(Game.territory_progress.state_of(BANYAN), TerritoryProgress.State.CLAIMING, "the dog is working on it")

	# A defeat in between keeps what was earned.
	Game.finish_run(_walk(RunResult.Outcome.DEFEATED, [BANYAN]), false)
	check_eq(Game.territory_progress.claim_progress(BANYAN), 1, "a bad walk never takes progress back")

	Game.finish_run(_walk(RunResult.Outcome.EXTRACTED, [BANYAN]), false)
	var third := _walk(RunResult.Outcome.EXTRACTED, [BANYAN])
	Game.finish_run(third, false)
	check(Game.territory_progress.is_owned(BANYAN), "the third walk home makes it the dog's place")
	check(third.territories_claimed.has(BANYAN), "the result says so, once")
	check(Game.goal_progress.flags.has(data.owned_flag), "owning it sets the flag other content reads")
	check(Game.territory_progress.last_event(BANYAN).contains("我的地方"), "and the place remembers it in the dog's words")

	# It cannot be claimed again.
	var extra := _walk(RunResult.Outcome.EXTRACTED, [BANYAN])
	Game.finish_run(extra, false)
	check(extra.territories_claimed.is_empty(), "an owned place is not claimed a second time")
	check_eq(Game.territory_progress.claim_progress(BANYAN), data.claim_target, "and progress does not keep counting")

	if FileAccess.file_exists(SaveManager.save_path):
		DirAccess.remove_absolute(SaveManager.save_path)
	SaveManager.save_path = original_path
	SaveManager.data = original_data
	Game.goal_progress.deserialize(original_goals)
	Game.territory_progress.deserialize(original_territories)


func _walk(outcome: RunResult.Outcome, marked: Array[StringName]) -> RunResult:
	var result := RunResult.new()
	result.outcome = outcome
	result.marked_territories = marked
	return result
