class_name DesireCard
extends PanelContainer
## Art-facing presentation component. Goal selection remains owned by the
## tracker; this node only translates DesireData into dog-perspective UI.

const CATEGORY_ICONS: Dictionary = {
	DesireData.Category.SCENT: preload("res://assets/ui/desires/icon_strange_scent.svg"),
	DesireData.Category.CHASE: preload("res://assets/ui/desires/icon_squirrel.svg"),
	DesireData.Category.RIVAL: preload("res://assets/ui/desires/icon_rival.svg"),
	DesireData.Category.BRING_HOME: preload("res://assets/ui/desires/icon_bring_home.svg"),
	DesireData.Category.DISCOVERY: preload("res://assets/ui/desires/icon_new_dog.svg"),
	DesireData.Category.THREAT: preload("res://assets/ui/desires/icon_old_master.svg"),
}

@onready var _icon: TextureRect = %DesireIcon
@onready var _desire_text: Label = %DesireText
@onready var _hint_text: Label = %HintText


func present(desire: DesireData) -> void:
	if desire == null:
		hide()
		return
	_icon.texture = CATEGORY_ICONS.get(desire.category, CATEGORY_ICONS[DesireData.Category.SCENT])
	_desire_text.text = desire.dog_text
	_hint_text.text = desire.world_hint
	_hint_text.visible = not desire.world_hint.is_empty()
	show()


func present_thread(desire: DesireData) -> void:
	present(desire)
	_icon.texture = preload("res://assets/ui/desires/icon_memory_thread.svg")
