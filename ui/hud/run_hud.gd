extends CanvasLayer
## In-run HUD: timer, bag button, toasts, context interact button, inventory panel.
## Reads RunManager / DogController; never changes run rules itself.

const TOAST_SECONDS: float = 2.4
const DEBUG_TAPS: int = 5
const DEBUG_TAP_WINDOW: float = 2.0
const HINT_SECONDS: float = 12.0
const HINT_MOVE_DISTANCE: float = 250.0
const EXPERIENCE_SECONDS: float = 2.2

@export var run_manager: RunManager
## Optional; enables the combat debug buttons.
@export var combat_coordinator: Node
@export var owner_behavior: OwnerBehavior
@export var goal_director: GoalDirector
## Optional DogAgency (3D walk).
@export var dog_agency: Node
## Optional TemptationDirector (Sprint 05): reasons to stay out.
@export var temptation_director: TemptationDirector

var _toast_queue: Array[Dictionary] = []
var _toast_time_left: float = 0.0
var _debug_taps: Array[float] = []
var _hint_time_left: float = HINT_SECONDS
## Vector2 or Vector3 depending on the world.
var _dog_start: Variant
var _experience_queue: Array[String] = []
var _experience_tween: Tween

@onready var _time_label: Label = %TimeLabel
@onready var _bag_button: Button = %BagButton
@onready var _toast_label: Label = %ToastLabel
@onready var _touch_controls: Control = %TouchControls
@onready var _inventory_panel: InventoryPanel = %InventoryPanel
@onready var _interact_button: TouchActionButton = _touch_controls.get_node("%InteractButton")
@onready var _debug_panel: DebugPanel = get_node_or_null("%DebugPanel")
@onready var _hint_label: Label = %HintLabel
@onready var _experience_fx: PanelContainer = %ExperienceFX
@onready var _experience_label: Label = %ExperienceLabel
@onready var _risk_label: Label = %RiskLabel


func _ready() -> void:
	_inventory_panel.hide()
	_inventory_panel.closed.connect(_on_inventory_closed)
	_bag_button.pressed.connect(toggle_inventory)
	_toast_label.hide()
	_experience_fx.hide()
	_risk_label.hide()
	if _debug_panel != null:
		_debug_panel.run_manager = run_manager
		_debug_panel.combat_coordinator = combat_coordinator
		_debug_panel.owner_behavior = owner_behavior
		_debug_panel.goal_director = goal_director
		_debug_panel.dog_agency = dog_agency
		_time_label.gui_input.connect(_on_time_label_input)
	_hint_label.text = controls_hint()

	run_manager.run_started.connect(_on_run_started)
	run_manager.loot_gained.connect(_on_loot_gained)
	run_manager.loot_blocked.connect(_on_loot_blocked)
	run_manager.search_empty.connect(_on_search_empty)
	run_manager.extraction_unlocked.connect(_on_extraction_unlocked)
	run_manager.value_changed.connect(_on_value_changed)
	if temptation_director != null:
		temptation_director.offered.connect(_on_temptation_offered)
	if run_manager.training != null:
		run_manager.training.event_recorded.connect(_on_training_event_recorded)
	if run_manager.dog_actor != null:
		run_manager.dog_actor.connect(&"focus_changed", _on_focus_changed)
	_on_focus_changed(null)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory()
	_update_time()
	_update_toast(delta)
	_update_hint(delta)


func toggle_inventory() -> void:
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


## Pixels in 2D, meters in 3D.
func _hint_move_distance() -> float:
	return HINT_MOVE_DISTANCE if run_manager.dog_actor is Node2D else HINT_MOVE_DISTANCE / 80.0


func _update_hint(delta: float) -> void:
	if not _hint_label.visible:
		return
	_hint_time_left -= delta
	var moved: bool = run_manager.dog_actor != null and _dog_start != null and run_manager.dog_actor.global_position.distance_to(_dog_start) > _hint_move_distance()
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


func _on_inventory_closed() -> void:
	_touch_controls.show()


func _on_run_started(_run_seed: int) -> void:
	_inventory_panel.setup(run_manager.human_run_inventory, run_manager.dog_safe_inventory)
	if run_manager.dog_actor != null:
		_dog_start = run_manager.dog_actor.global_position
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


func _on_search_empty(_point: Node) -> void:
	show_toast("什麼都沒聞到……", Color(0.75, 0.75, 0.75))


func _on_extraction_unlocked(point: Node) -> void:
	show_toast(point.unlock_message, Color(0.6, 1.0, 0.6), true)
	# The risk tag has something new to say now. It states the consequence and
	# never tells the player to leave (D5-05), so there is no second nudge here.
	_update_risk_badge(run_manager.run_value())


## P4-003: the world is still offering something. Said in the dog's voice, with
## no prompt and no timer — the player can simply go home instead.
func _on_temptation_offered(temptation: TemptationData) -> void:
	show_toast(temptation.dog_text, Color(1.0, 0.92, 0.66), true)
	if not temptation.world_hint.is_empty():
		show_toast("（%s）" % temptation.world_hint, Color(0.85, 0.82, 0.72))


func _on_value_changed(value: RunValue) -> void:
	_update_risk_badge(value)


## D5-05 selected presentation: one quiet consequence line, never a danger bar.
func _update_risk_badge(value: RunValue) -> void:
	var balance := DataRegistry.balance
	var text := ""
	var color := Color(0.88, 0.86, 0.78)
	if value.unbanked_value > 0 and run_manager.is_past_first_extraction():
		text = "回家就安全 · 主人還帶著 $%d" % value.unbanked_value
		color = Color(0.72, 0.95, 0.72)
	elif value.unbanked_value >= balance.risk_notable_value:
		text = "主人帶著 $%d · 倒下會失去" % value.unbanked_value
	if value.is_bag_full():
		text = "主人的袋子裝滿了" if text.is_empty() else text + " · 袋子已滿"
	if value.unbanked_value >= balance.risk_heavy_value:
		color = Color(1.0, 0.82, 0.55)
	_risk_label.text = text
	_risk_label.modulate = color
	_risk_label.visible = not text.is_empty()


func _on_training_event_recorded(event: TrainingEvent) -> void:
	var memory := event.experience_text()
	if memory.is_empty():
		return
	_experience_queue.append(memory)
	if not _experience_fx.visible:
		_play_next_experience()


func _play_next_experience() -> void:
	if _experience_queue.is_empty():
		_experience_fx.hide()
		return
	_experience_label.text = "主人記住了：\n%s" % _experience_queue.pop_front()
	# Autowrapped text can grow the card; shrink it back to its content.
	_experience_fx.size.y = 0.0
	_experience_fx.show()
	_experience_fx.modulate = Color(1, 1, 1, 0)
	_experience_fx.position.y += 14.0
	if _experience_tween != null:
		_experience_tween.kill()
	_experience_tween = create_tween()
	_experience_tween.set_parallel(true)
	_experience_tween.tween_property(_experience_fx, "modulate", Color.WHITE, 0.22)
	_experience_tween.tween_property(_experience_fx, "position:y", _experience_fx.position.y - 14.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_experience_tween.set_parallel(false)
	_experience_tween.tween_interval(EXPERIENCE_SECONDS)
	_experience_tween.tween_property(_experience_fx, "modulate", Color(1, 1, 1, 0), 0.28)
	_experience_tween.tween_callback(_play_next_experience)


## `target` is an Interactable or Interactable3D (or null).
func _on_focus_changed(target: Node) -> void:
	if target == null:
		_interact_button.text = "互動"
		_interact_button.disabled = true
	else:
		_interact_button.text = target.get_prompt(run_manager)
		_interact_button.disabled = false


## The headline number is what the owner is carrying, because that is what a
## defeat would take. Whatever the dog is carrying is shown as already safe.
func _update_bag_button() -> void:
	var value := run_manager.run_value()
	var text := "🎒 %d/%d  $%d" % [value.unbanked_slots, value.unbanked_capacity, value.unbanked_value]
	if value.safe_value > 0:
		text += "  🔒$%d" % value.safe_value
	_bag_button.text = text


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
