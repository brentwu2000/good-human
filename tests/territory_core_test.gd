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
