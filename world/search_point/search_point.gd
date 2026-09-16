class_name SearchPoint
extends Interactable
## Sniff spot. Knows only its LootTable; RunManager owns RNG, inventory and
## searched state. Loot is rolled when the run starts (from the run seed) so the
## point can hint its scent strength. If the bag is full, loot waits here.

const GROUP: StringName = &"search_points"

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
var _time: float = 0.0

@onready var _visual: Control = %Visual
@onready var _name_label: Label = %NameLabel
@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _scent: Label = %Scent
@onready var _popup: Label = %Popup


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	if prompt == "互動":
		prompt = "👃 聞聞看"
	_name_label.text = display_label
	_progress_bar.max_value = search_duration
	_progress_bar.hide()
	_popup.hide()
	_visual.pivot_offset = _visual.size / 2.0
	_update_scent()
	if search_id.is_empty():
		push_error("SearchPoint %s has no search_id" % get_path())


## Called by RunManager at run start, in a stable order, with the run RNG.
func prepare(run: RunManager) -> void:
	_run = run
	cancel_search()
	_pending_loot = loot_table.roll(run.run_rng) if loot_table != null else null
	_has_rolled = true
	_visual.modulate = Color.WHITE
	_update_scent()


## Rarity of the loot waiting here, or -1 when there is nothing.
func get_scent_rarity() -> int:
	if _pending_loot == null:
		return -1
	return _pending_loot.item.rarity


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
	if is_node_ready():
		_progress_bar.hide()
		_visual.rotation = 0.0


func _process(delta: float) -> void:
	_time += delta
	_animate_scent()
	if not _searching:
		return
	if not is_instance_valid(_run) or not _run.is_running():
		cancel_search()
		return
	if is_instance_valid(_run.dog) and _run.dog.global_position.distance_to(global_position) > cancel_distance:
		cancel_search()
		_show_popup("走掉了…", Color(0.8, 0.8, 0.8))
		return
	_progress += delta
	_progress_bar.value = _progress
	_visual.rotation = sin(_time * 40.0) * 0.12
	if _progress >= search_duration:
		_finish_search()


func _finish_search() -> void:
	cancel_search()
	if not _has_rolled:
		_pending_loot = loot_table.roll(_run.run_rng) if loot_table != null else null
		_has_rolled = true
	var before := _pending_loot
	_pending_loot = _run.resolve_search(self, _pending_loot)
	if _pending_loot == null:
		_has_rolled = false

	if before == null:
		_show_popup("空的…", Color(0.75, 0.75, 0.75))
	elif _pending_loot == null or _pending_loot.quantity < before.quantity:
		var got := before.quantity - (0 if _pending_loot == null else _pending_loot.quantity)
		var text := before.item.display_name + (" x%d" % got if got > 1 else "")
		_show_popup(("✨ " if before.item.rarity == ItemData.Rarity.RARE else "") + text, before.item.get_rarity_color())
	else:
		_show_popup("背包滿了！", Color(1.0, 0.45, 0.4))

	if _run.is_searched(search_id) and one_time:
		_visual.modulate = Color(0.4, 0.4, 0.4)
	_update_scent()


func _update_scent() -> void:
	if not is_node_ready():
		return
	var searched := _run != null and one_time and _run.is_searched(search_id)
	var rarity := get_scent_rarity()
	_scent.visible = not searched and _has_rolled
	match rarity:
		ItemData.Rarity.RARE:
			_scent.text = "✨ 〰〰〰"
			_scent.add_theme_font_size_override("font_size", 34)
		ItemData.Rarity.UNCOMMON:
			_scent.text = "〰〰"
			_scent.add_theme_font_size_override("font_size", 28)
		_:
			_scent.text = "〰"
			_scent.add_theme_font_size_override("font_size", 22)
	_scent.modulate = ItemData.rarity_color(rarity) if rarity >= 0 else Color(0.92, 0.92, 0.92)


func _animate_scent() -> void:
	if not _scent.visible:
		return
	var strength := 0.25 + 0.2 * (get_scent_rarity() + 1)
	_scent.self_modulate.a = clampf(strength + sin(_time * 3.0) * 0.25, 0.1, 1.0)
	_scent.position.y = -96.0 + sin(_time * 2.0) * 6.0


func _show_popup(text: String, color: Color) -> void:
	_popup.text = text
	_popup.modulate = color
	_popup.position = Vector2(-150, -110)
	_popup.self_modulate.a = 1.0
	_popup.show()
	var tween := create_tween()
	tween.tween_property(_popup, "position:y", -190.0, 1.2).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_popup, "self_modulate:a", 0.0, 1.2).set_delay(0.5)
	tween.tween_callback(_popup.hide)
