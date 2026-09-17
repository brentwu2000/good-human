extends CanvasLayer
## In-run HUD: timer, bag button, toasts, context interact button, inventory panel.
## Reads RunManager / DogController; never changes run rules itself.

const TOAST_SECONDS: float = 2.4
const DEBUG_TAPS: int = 5
const DEBUG_TAP_WINDOW: float = 2.0
const HINT_SECONDS: float = 12.0
const HINT_MOVE_DISTANCE: float = 250.0

@export var run_manager: RunManager
## Optional; enables the encounter debug buttons.
@export var encounter_controller: EncounterController

var _toast_queue: Array[Dictionary] = []
var _toast_time_left: float = 0.0
var _debug_taps: Array[float] = []
var _hint_time_left: float = HINT_SECONDS
var _dog_start: Vector2

@onready var _time_label: Label = %TimeLabel
@onready var _bag_button: Button = %BagButton
@onready var _toast_label: Label = %ToastLabel
@onready var _touch_controls: Control = %TouchControls
@onready var _inventory_panel: InventoryPanel = %InventoryPanel
@onready var _interact_button: TouchActionButton = _touch_controls.get_node("%InteractButton")
@onready var _debug_panel: DebugPanel = get_node_or_null("%DebugPanel")
@onready var _hint_label: Label = %HintLabel


func _ready() -> void:
	_inventory_panel.hide()
	_inventory_panel.closed.connect(_on_inventory_closed)
	_bag_button.pressed.connect(toggle_inventory)
	_toast_label.hide()
	if _debug_panel != null:
		_debug_panel.run_manager = run_manager
		_debug_panel.encounter_controller = encounter_controller
		_time_label.gui_input.connect(_on_time_label_input)
	_hint_label.text = controls_hint()

	run_manager.run_started.connect(_on_run_started)
	run_manager.loot_gained.connect(_on_loot_gained)
	run_manager.loot_blocked.connect(_on_loot_blocked)
	run_manager.search_empty.connect(_on_search_empty)
	run_manager.extraction_unlocked.connect(_on_extraction_unlocked)
	run_manager.encounter_state_changed.connect(_on_encounter_state_changed)
	if run_manager.dog != null:
		run_manager.dog.focus_changed.connect(_on_focus_changed)
	_on_focus_changed(null)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory()
	_update_time()
	_update_toast(delta)
	_update_hint(delta)


func toggle_inventory() -> void:
	# No bag shuffling (e.g. into dog safe slots) during an encounter.
	if run_manager.encounter_active and not _inventory_panel.visible:
		return
	if _inventory_panel.visible:
		_inventory_panel.close()
	else:
		_touch_controls.hide()
		_inventory_panel.open()


func show_toast(message: String, color: Color = Color.WHITE, big: bool = false) -> void:
	_toast_queue.append({"text": message, "color": color, "big": big})


## Controls text shown in the first seconds of a walk.
static func controls_hint() -> String:
	# Not is_touchscreen_available(): mouse-to-touch emulation makes it true on desktop.
	if OS.has_feature("mobile"):
		return "左下拖曳移動 · 右下按鈕聞聞看 · 🎒 看背包"
	return "WASD 移動 · E 聞聞看／互動 · Tab 背包\n（也可以用滑鼠拖曳左下搖桿）"


func _update_hint(delta: float) -> void:
	if not _hint_label.visible:
		return
	_hint_time_left -= delta
	var moved := run_manager.dog != null and run_manager.dog.global_position.distance_to(_dog_start) > HINT_MOVE_DISTANCE
	if _hint_time_left <= 0.0 or moved:
		_hint_label.hide()


func _on_time_label_input(event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	if press == null or not press.pressed or press.button_index != MOUSE_BUTTON_LEFT:
		return
	var now := Time.get_ticks_msec() / 1000.0
	_debug_taps.append(now)
	while not _debug_taps.is_empty() and now - _debug_taps[0] > DEBUG_TAP_WINDOW:
		_debug_taps.pop_front()
	if _debug_taps.size() >= DEBUG_TAPS:
		_debug_taps.clear()
		_debug_panel.toggle()


func _on_encounter_state_changed(active: bool) -> void:
	if active:
		if _inventory_panel.visible:
			_inventory_panel.close()
		_touch_controls.hide()
		_hint_label.hide()
	else:
		_touch_controls.show()
	_bag_button.disabled = active


func _on_inventory_closed() -> void:
	_touch_controls.show()


func _on_run_started(_run_seed: int) -> void:
	_inventory_panel.setup(run_manager.human_run_inventory, run_manager.dog_safe_inventory)
	if run_manager.dog != null:
		_dog_start = run_manager.dog.global_position
	for inventory in [run_manager.human_run_inventory, run_manager.dog_safe_inventory]:
		if not inventory.changed.is_connected(_update_bag_button):
			inventory.changed.connect(_update_bag_button)
	_update_bag_button()


func _on_loot_gained(item: ItemData, quantity: int) -> void:
	var text := "獲得 %s%s（$%d）" % [item.display_name, " x%d" % quantity if quantity > 1 else "", item.value * quantity]
	if item.rarity == ItemData.Rarity.RARE:
		text = "✨ 稀有！" + text
	show_toast(text, item.get_rarity_color(), item.rarity == ItemData.Rarity.RARE)


func _on_loot_blocked(item: ItemData, _quantity: int) -> void:
	show_toast("背包滿了！%s 還留在原地（可以丟掉東西再來）" % item.display_name, Color(1.0, 0.55, 0.5))


func _on_search_empty(_point: SearchPoint) -> void:
	show_toast("什麼都沒聞到……", Color(0.75, 0.75, 0.75))


func _on_extraction_unlocked(point: ExtractionPoint) -> void:
	show_toast(point.unlock_message, Color(0.6, 1.0, 0.6), true)


func _on_focus_changed(target: Interactable) -> void:
	if target == null:
		_interact_button.text = "互動"
		_interact_button.disabled = true
	else:
		_interact_button.text = target.get_prompt(run_manager)
		_interact_button.disabled = false


func _update_bag_button() -> void:
	var bag := run_manager.human_run_inventory
	var value := bag.total_value() + run_manager.dog_safe_inventory.total_value()
	_bag_button.text = "🎒 %d/%d  $%d" % [bag.used_slot_count(), bag.capacity, value]


func _update_time() -> void:
	var seconds := int(run_manager.elapsed_time)
	_time_label.text = "%02d:%02d" % [seconds / 60, seconds % 60]


func _update_toast(delta: float) -> void:
	if _toast_time_left > 0.0:
		_toast_time_left -= delta
		if _toast_time_left <= 0.0:
			_toast_label.hide()
		return
	if _toast_queue.is_empty():
		return
	var toast: Dictionary = _toast_queue.pop_front()
	_toast_label.text = toast["text"]
	_toast_label.modulate = toast["color"]
	_toast_label.add_theme_font_size_override("font_size", 36 if toast["big"] else 28)
	_toast_label.show()
	_toast_time_left = TOAST_SECONDS + (1.0 if toast["big"] else 0.0)
	if toast["big"]:
		_toast_label.pivot_offset = _toast_label.size / 2.0
		_toast_label.scale = Vector2(1.25, 1.25)
		create_tween().tween_property(_toast_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
