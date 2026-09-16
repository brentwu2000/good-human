class_name SearchPoint
extends Interactable
## Sniff spot. Knows only its LootTable; RunManager owns RNG, inventory and
## searched state. If the bag is full, the rolled loot waits here (no re-roll).

@export var search_id: StringName
@export var display_label: String = "搜索點"
@export var loot_table: LootTableData
@export_range(0.1, 10.0) var search_duration: float = 1.5
@export var one_time: bool = true
## Walking further than this from the point cancels the search.
@export var cancel_distance: float = 140.0

var _run: RunManager
var _searching: bool = false
var _progress: float = 0.0
var _pending_loot: ItemStack
var _has_rolled: bool = false

@onready var _visual: CanvasItem = %Visual
@onready var _name_label: Label = %NameLabel
@onready var _progress_bar: ProgressBar = %ProgressBar


func _ready() -> void:
	if prompt == "互動":
		prompt = "👃 聞聞看"
	_name_label.text = display_label
	_progress_bar.max_value = search_duration
	_progress_bar.hide()
	if search_id.is_empty():
		push_error("SearchPoint %s has no search_id" % get_path())


func can_interact(context: Object) -> bool:
	var run := context as RunManager
	if not enabled or _searching or run == null or not run.is_running():
		return false
	return not (one_time and run.is_searched(search_id))


func interact(context: Object) -> void:
	if not can_interact(context):
		return
	_run = context as RunManager
	_searching = true
	_progress = 0.0
	_progress_bar.value = 0.0
	_progress_bar.show()


func is_searching() -> bool:
	return _searching


func cancel_search() -> void:
	_searching = false
	_progress_bar.hide()


func _process(delta: float) -> void:
	if not _searching:
		return
	if not is_instance_valid(_run) or not _run.is_running():
		cancel_search()
		return
	if is_instance_valid(_run.dog) and _run.dog.global_position.distance_to(global_position) > cancel_distance:
		cancel_search()
		return
	_progress += delta
	_progress_bar.value = _progress
	if _progress >= search_duration:
		_finish_search()


func _finish_search() -> void:
	cancel_search()
	if not _has_rolled:
		_pending_loot = loot_table.roll(_run.run_rng) if loot_table != null else null
		_has_rolled = true
	_pending_loot = _run.resolve_search(self, _pending_loot)
	if _pending_loot == null:
		_has_rolled = false
	if _run.is_searched(search_id) and one_time:
		_visual.modulate = Color(0.45, 0.45, 0.45)
