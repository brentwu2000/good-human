extends CanvasLayer
## In-run HUD: timer, bag button, toasts, context interact button, inventory panel.
## Reads RunManager / DogController; never changes run rules itself.

const TOAST_SECONDS: float = 2.4

@export var run_manager: RunManager

var _toast_queue: Array[String] = []
var _toast_time_left: float = 0.0

@onready var _time_label: Label = %TimeLabel
@onready var _bag_button: Button = %BagButton
@onready var _toast_label: Label = %ToastLabel
@onready var _touch_controls: Control = %TouchControls
@onready var _inventory_panel: InventoryPanel = %InventoryPanel
@onready var _interact_button: TouchActionButton = _touch_controls.get_node("%InteractButton")
@onready var _debug_panel: DebugPanel = get_node_or_null("%DebugPanel")


func _ready() -> void:
	_inventory_panel.hide()
	_inventory_panel.closed.connect(_on_inventory_closed)
	_bag_button.pressed.connect(toggle_inventory)
	_toast_label.hide()
	if _debug_panel != null:
		_debug_panel.run_manager = run_manager

	run_manager.run_started.connect(_on_run_started)
	run_manager.loot_gained.connect(_on_loot_gained)
	run_manager.loot_blocked.connect(_on_loot_blocked)
	run_manager.search_empty.connect(_on_search_empty)
	run_manager.extraction_unlocked.connect(_on_extraction_unlocked)
	if run_manager.dog != null:
		run_manager.dog.focus_changed.connect(_on_focus_changed)
	_on_focus_changed(null)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory()
	_update_time()
	_update_toast(delta)


func toggle_inventory() -> void:
	if _inventory_panel.visible:
		_inventory_panel.close()
	else:
		_touch_controls.hide()
		_inventory_panel.open()


func show_toast(message: String) -> void:
	_toast_queue.append(message)


func _on_inventory_closed() -> void:
	_touch_controls.show()


func _on_run_started(_run_seed: int) -> void:
	_inventory_panel.setup(run_manager.human_run_inventory, run_manager.dog_safe_inventory)
	run_manager.human_run_inventory.changed.connect(_update_bag_button)
	_update_bag_button()


func _on_loot_gained(item: ItemData, quantity: int) -> void:
	show_toast("獲得 %s%s" % [item.display_name, " x%d" % quantity if quantity > 1 else ""])


func _on_loot_blocked(item: ItemData, _quantity: int) -> void:
	show_toast("背包滿了！%s 還留在原地" % item.display_name)


func _on_search_empty(_point: SearchPoint) -> void:
	show_toast("什麼都沒聞到……")


func _on_extraction_unlocked(point: ExtractionPoint) -> void:
	show_toast(point.unlock_message)


func _on_focus_changed(target: Interactable) -> void:
	if target == null:
		_interact_button.text = "互動"
		_interact_button.disabled = true
	else:
		_interact_button.text = target.get_prompt(run_manager)
		_interact_button.disabled = false


func _update_bag_button() -> void:
	var bag := run_manager.human_run_inventory
	_bag_button.text = "🎒 %d/%d" % [bag.used_slot_count(), bag.capacity]


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
	_toast_label.text = _toast_queue.pop_front()
	_toast_label.show()
	_toast_time_left = TOAST_SECONDS
