class_name SearchPoint3D
extends Interactable3D
## 3D sniff spot. Same rules as SearchPoint: knows only its LootTable;
## RunManager owns RNG, inventory and searched state; loot is rolled at run
## start so the scent can hint its rarity; a full bag leaves loot waiting.

@export var search_id: StringName
@export var display_label: String = "搜索點"
@export var loot_table: LootTableData
@export var search_duration: float = 1.0
@export var one_time: bool = true
## Walking further than this (m) from the point cancels the search.
@export var cancel_distance: float = 2.2
@export var color: Color = Color(0.45, 0.55, 0.45)

var _run: RunManager
var _searching: bool = false
var _progress: float = 0.0
var _pending_loot: ItemStack
var _has_rolled: bool = false
var _time: float = 0.0

var _visual: Node3D
var _name_label: Label3D
var _scent: Label3D
var _popup: Label3D
var _popup_left: float = 0.0


func _enter_tree() -> void:
	add_to_group(SearchPoint.GROUP)


func _ready() -> void:
	prompt = "👃 聞聞看"
	_visual = SearchProp3D.build(search_id, color)
	add_child(_visual)
	_name_label = Greybox.label(display_label, 1.15, 30)
	add_child(_name_label)
	_scent = Greybox.label("", 1.6, 34)
	add_child(_scent)
	_popup = Greybox.label("", 2.1, 40)
	add_child(_popup)
	add_interaction_area(0.9)
	if search_id.is_empty():
		push_error("SearchPoint3D %s has no search_id" % get_path())


## Called by RunManager at run start, in a stable order, with the run RNG.
func prepare(run: RunManager) -> void:
	_run = run
	cancel_search()
	_pending_loot = loot_table.roll(run.run_rng) if loot_table != null else null
	_has_rolled = true
	_visual.scale = Vector3.ONE
	Greybox.set_faded(_visual, false)
	_update_scent()


func get_scent_rarity() -> int:
	return -1 if _pending_loot == null else _pending_loot.item.rarity


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


func is_searching() -> bool:
	return _searching


func cancel_search() -> void:
	_searching = false
	if _visual != null:
		_visual.rotation = Vector3.ZERO


func _process(delta: float) -> void:
	_time += delta
	_popup_left -= delta
	if _popup_left <= 0.0:
		_popup.text = ""
	if _scent.visible:
		_scent.position.y = 1.6 + sin(_time * 2.0) * 0.08
	if not _searching:
		return
	if not is_instance_valid(_run) or not _run.is_running():
		cancel_search()
		return
	var dog := _run.dog_actor as Node3D
	if dog != null and dog.global_position.distance_to(global_position) > cancel_distance:
		cancel_search()
		_show_popup("走掉了…", Color(0.8, 0.8, 0.8))
		return
	_progress += delta
	_visual.rotation.z = sin(_time * 40.0) * 0.08
	_name_label.text = "%s %s" % [display_label, "●".repeat(int(_progress / search_duration * 5.0))]
	if _progress >= search_duration:
		_finish_search()


func _finish_search() -> void:
	cancel_search()
	_name_label.text = display_label
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
		_show_popup(("✨ " if before.item.rarity == ItemData.Rarity.RARE else "") + before.item.display_name, before.item.get_rarity_color())
	else:
		_show_popup("背包滿了！", Color(1.0, 0.45, 0.4))
	if one_time and _run.is_searched(search_id):
		Greybox.set_faded(_visual, true, 0.45)
	_update_scent()


func _update_scent() -> void:
	var searched := _run != null and one_time and _run.is_searched(search_id)
	var rarity := get_scent_rarity()
	_scent.visible = not searched and _has_rolled
	match rarity:
		ItemData.Rarity.RARE:
			_scent.text = "✨〰〰〰"
		ItemData.Rarity.UNCOMMON:
			_scent.text = "〰〰"
		_:
			_scent.text = "〰"
	_scent.modulate = ItemData.rarity_color(rarity) if rarity >= 0 else Color(0.92, 0.92, 0.92)


func _show_popup(text: String, popup_color: Color) -> void:
	_popup.text = text
	_popup.modulate = popup_color
	_popup_left = 1.4
