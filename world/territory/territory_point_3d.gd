class_name TerritoryPoint3D
extends Interactable3D
## Sprint 05 (P4-006): the Big Banyan Tree as a place in the world.
##
## It owns no rules. It reads TerritoryProgress to decide which of the landmark
## variants to show (D5-01/D5-02/D5-07), and turns two things that happen
## naturally on a walk into the first two steps of the territory loop: coming
## near the tree (discovering the place) and staying long enough to take in what
## it smells of (learning that another dog lives here).
##
## Marking it (P4-007) is the dog's own move: it costs nothing, risks nothing
## and grants nothing by itself. It only makes this walk count for the place,
## so the claim is still settled by getting home (P4-009/P4-010).
##
## Claim progress and rewards are not decided here.

signal discovered(territory: TerritoryData)
signal rival_scent_found(territory: TerritoryData)
signal marked(territory: TerritoryData)
## S05-05: the dog read whose scent is on the roots on this walk. `text` is
## what it makes of it, in its own words.
signal scents_read(territory: TerritoryData, text: String)
## S05-11: the place's one ownership reward was found at the roots.
signal reward_found(territory: TerritoryData, item: ItemData)

const GROUP: StringName = &"territory_points"
## Meters. Close enough to see it is a landmark.
const NOTICE_RADIUS: float = 6.0
## Meters, and seconds spent there, before the dog reads the scents at its roots.
const SCENT_RADIUS: float = 3.0
const SCENT_SECONDS: float = 1.5

## OpponentPair3D.GROUP, by value (see _alert_resident).
const RESIDENT_GROUP: StringName = &"opponent_pairs_3d"
## Meters: how close the dog has to be to leave its own mark.
const MARK_RADIUS: float = 2.2
## S05-04: the place calling the dog back, in scent rather than a map icon.
## Amber wisps drift up out of the canopy, high enough to be seen over the
## rooftops from the far side of the walk.
const CALL_WISPS: int = 7
const CALL_LOW: float = 6.0
const CALL_HIGH: float = 18.0
const CALL_RISE_SECONDS: float = 4.5
const CALL_COLOR := Color("#efb448")

@export var territory_id: StringName = &"banyan"
@export var run_manager: RunManager
## The dog, in this walk's world.
@export var dog: Node3D

var data: TerritoryData
var landmark: Node3D
## Set when the dog marks the place on this walk; the claim is settled on the
## way home, not here.
var marked_this_walk: bool = false
## S05-05: the roots have been read on this walk (once per walk).
var scents_read_this_walk: bool = false

var _presentation: TerritoryPresentation3D
var _near_seconds: float = 0.0
var _shown_state: int = -1
var _calling: bool = false
var _call: Node3D
var _call_time: float = 0.0


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	data = DataRegistry.get_territory(territory_id)
	if data == null:
		push_error("TerritoryPoint3D: unknown territory %s" % territory_id)
		set_process(false)
		return
	prompt = "💧 做記號"
	add_interaction_area(MARK_RADIUS)
	_rebuild_landmark()
	if run_manager != null:
		run_manager.run_started.connect(func(_s: int) -> void:
			marked_this_walk = false
			scents_read_this_walk = false
			set_calling(false))


# --- Marking (P4-007) ---------------------------------------------------------

## Only somewhere the dog has understood, once per walk, and never again once
## the place is already its own.
func can_interact(context: Object) -> bool:
	var run := context as RunManager
	if not enabled or run == null or not run.is_running() or data == null:
		return false
	return not marked_this_walk and state() >= TerritoryProgress.State.CONTESTED and not Game.territory_progress.is_owned(territory_id)


func get_prompt(_context: Object) -> String:
	return prompt


## Leaving the dog's own scent next to the resident's. It changes nothing on
## its own — it makes this walk one that counts for the place.
func interact(context: Object) -> void:
	if not can_interact(context):
		return
	marked_this_walk = true
	var run := context as RunManager
	run.record_territory_mark(territory_id)
	Game.territory_progress.note_event(territory_id, data.marked_text)
	play_recognize()
	play_mark()
	_alert_resident()
	marked.emit(data)


## S05-06: if the dog that lives here is about, it sees the mark and reacts.
## Returns the pair that did, or null.
## Untyped on purpose: naming OpponentPair3D here closes a script dependency
## cycle that made Godot crash on exit now and then.
func _alert_resident() -> Node:
	for pair in get_tree().get_nodes_in_group(RESIDENT_GROUP):
		if pair.get(&"spot_id") == data.resident_spot:
			pair.call(&"react_to_mark", dog.global_position if dog != null else global_position)
			return pair if pair.get(&"riled_this_walk") else null
	return null


func _process(delta: float) -> void:
	if _calling:
		_animate_call(delta)
	if data == null or dog == null or run_manager == null or not run_manager.is_running():
		return
	var distance := _flat_distance()
	if _calling and distance <= NOTICE_RADIUS:
		# The dog came: the place has said what it had to say.
		set_calling(false)
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


# --- Calling the dog back (S05-04) ---------------------------------------------

## The place as a reason to stay out (the Banyan temptation). Presentation only.
func set_calling(value: bool) -> void:
	_calling = value
	if value and _call == null:
		_call = _build_call()
		add_child(_call)
	if _call != null:
		_call.visible = value
	_call_time = 0.0


func is_calling() -> bool:
	return _calling


## True when the place is still worth coming back to on this walk: known, not
## yet the dog's own, and not marked today.
func is_worth_returning() -> bool:
	var current := state()
	return data != null and current >= TerritoryProgress.State.DISCOVERED 		and current < TerritoryProgress.State.OWNED and not marked_this_walk


func _build_call() -> Node3D:
	var root := Node3D.new()
	root.name = "ScentCall"
	for i in CALL_WISPS:
		var mesh := SphereMesh.new()
		mesh.radius = 0.55
		mesh.height = 1.1
		mesh.radial_segments = 10
		mesh.rings = 6
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(CALL_COLOR, 0.0)
		var wisp := MeshInstance3D.new()
		wisp.mesh = mesh
		wisp.material_override = mat
		wisp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(wisp)
	return root


## Each wisp rises on its own offset, curling round the trunk and thinning out
## as it climbs, so it reads as a smell on the air rather than a beacon.
func _animate_call(delta: float) -> void:
	_call_time += delta
	var count := _call.get_child_count()
	for i in count:
		var wisp := _call.get_child(i) as MeshInstance3D
		var t := fposmod(_call_time / CALL_RISE_SECONDS + float(i) / count, 1.0)
		var angle := t * TAU * 1.2 + float(i) * 2.1
		var drift := lerpf(0.8, 2.6, t)
		wisp.position = Vector3(cos(angle) * drift, lerpf(CALL_LOW, CALL_HIGH, t), sin(angle) * drift)
		wisp.scale = Vector3.ONE * lerpf(0.7, 1.8, t)
		var mat := wisp.material_override as StandardMaterial3D
		mat.albedo_color.a = 0.55 * sin(t * PI)


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
## lives here — that is learned, not announced by a UI. On later walks the
## same moment tells the dog how the place stands between them (S05-05).
func _read_scents() -> void:
	_near_seconds = 0.0
	if scents_read_this_walk or data.resident_spot.is_empty():
		return
	scents_read_this_walk = true
	if dog.has_method(&"play_sniff"):
		dog.call(&"play_sniff")
	if state() == TerritoryProgress.State.DISCOVERED:
		if not Game.territory_progress.advance_to(territory_id, TerritoryProgress.State.CONTESTED):
			return
		Game.territory_progress.note_event(territory_id, data.rival_scent_text)
		if not data.contested_flag.is_empty():
			Game.goal_progress.set_flag(data.contested_flag)
		play_recognize()
		refresh()
		rival_scent_found.emit(data)
		return
	var text := scent_text()
	if not text.is_empty():
		scents_read.emit(data, text)
	_find_reward()


## S05-11: the first walk the place is the dog's own, the roots give up
## something the resident left behind. Once ever; a full bag keeps it waiting
## for a later walk rather than losing it.
func _find_reward() -> void:
	if data.reward_table == null or not Game.territory_progress.is_owned(territory_id) 			or Game.territory_progress.is_reward_given(territory_id):
		return
	var stack := run_manager.grant_reward(data.reward_table)
	if stack == null or run_manager.human_run_inventory.count_item(stack.item.id) <= 0:
		return
	Game.territory_progress.mark_reward_given(territory_id)
	Game.territory_progress.note_event(territory_id, data.reward_found_text)
	play_reward_reveal()
	reward_found.emit(data, stack.item)


## 0..1: how much of what is on the roots is the dog's own. Grows only with
## walks that came home after marking, never with time.
func own_scent_share() -> float:
	if Game.territory_progress.is_owned(territory_id):
		return 1.0
	return clampf(float(Game.territory_progress.claim_progress(territory_id)) / maxf(data.claim_target, 1), 0.0, 1.0)


## What the roots say about whose place this is, in the dog's words.
func scent_text() -> String:
	match state():
		TerritoryProgress.State.CONTESTED:
			return data.rival_only_text
		TerritoryProgress.State.CLAIMING:
			return data.mixed_scent_text
		TerritoryProgress.State.OWNED:
			return data.own_scent_text
	return ""


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
