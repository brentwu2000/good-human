class_name TerritoryPoint3D
extends Node3D
## Sprint 05 (P4-006): the Big Banyan Tree as a place in the world.
##
## It owns no rules. It reads TerritoryProgress to decide which of the landmark
## variants to show (D5-01/D5-02/D5-07), and turns two things that happen
## naturally on a walk into the first two steps of the territory loop: coming
## near the tree (discovering the place) and staying long enough to take in what
## it smells of (learning that another dog lives here).
##
## Marking, challenging, claiming and rewards are not here — a landmark should
## not be able to change a walk on its own.

signal discovered(territory: TerritoryData)
signal rival_scent_found(territory: TerritoryData)

const GROUP: StringName = &"territory_points"
## Meters. Close enough to see it is a landmark.
const NOTICE_RADIUS: float = 6.0
## Meters, and seconds spent there, before the dog reads the scents at its roots.
const SCENT_RADIUS: float = 3.0
const SCENT_SECONDS: float = 1.5

@export var territory_id: StringName = &"banyan"
@export var run_manager: RunManager
## The dog, in this walk's world.
@export var dog: Node3D

var data: TerritoryData
var landmark: Node3D

var _presentation: TerritoryPresentation3D
var _near_seconds: float = 0.0
var _shown_state: int = -1


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	data = DataRegistry.get_territory(territory_id)
	if data == null:
		push_error("TerritoryPoint3D: unknown territory %s" % territory_id)
		set_process(false)
		return
	_rebuild_landmark()


func _process(delta: float) -> void:
	if data == null or dog == null or run_manager == null or not run_manager.is_running():
		return
	var distance := _flat_distance()
	if distance > NOTICE_RADIUS:
		_near_seconds = 0.0
		return
	_notice()
	if distance > SCENT_RADIUS:
		_near_seconds = 0.0
		return
	_near_seconds += delta
	if _near_seconds >= SCENT_SECONDS:
		_read_scents()


## Current persistent state of this place.
func state() -> TerritoryProgress.State:
	return Game.territory_progress.state_of(territory_id)


## Rebuilds the landmark when the place has moved on (also used after marking).
func refresh() -> void:
	if int(state()) != _shown_state:
		_rebuild_landmark()


func play_recognize() -> void:
	if _presentation != null:
		_presentation.play_recognize()


func play_mark() -> void:
	if _presentation != null:
		_presentation.play_mark()


func play_reward_reveal() -> void:
	if _presentation != null:
		_presentation.play_reward_reveal()


# --- The first two steps of the loop ------------------------------------------

## Coming near it at all: this is a place, and now the dog knows it.
func _notice() -> void:
	if not Game.territory_progress.advance_to(territory_id, TerritoryProgress.State.DISCOVERED):
		return
	Game.territory_progress.note_event(territory_id, data.discovered_text)
	play_recognize()
	refresh()
	discovered.emit(data)


## Standing at the roots long enough to take in what it smells of. Another dog
## lives here — that is learned, not announced by a UI.
func _read_scents() -> void:
	_near_seconds = 0.0
	if data.resident_spot.is_empty() or state() != TerritoryProgress.State.DISCOVERED:
		return
	if not Game.territory_progress.advance_to(territory_id, TerritoryProgress.State.CONTESTED):
		return
	Game.territory_progress.note_event(territory_id, data.rival_scent_text)
	play_recognize()
	refresh()
	rival_scent_found.emit(data)


func _rebuild_landmark() -> void:
	if landmark != null:
		landmark.queue_free()
	_shown_state = int(state())
	landmark = BanyanLandmark3D.build(_shown_state as BanyanLandmark3D.TerritoryState)
	add_child(landmark)
	_presentation = landmark.get_node_or_null("TerritoryPresentation") as TerritoryPresentation3D


func _flat_distance() -> float:
	var delta := dog.global_position - global_position
	delta.y = 0.0
	return delta.length()
