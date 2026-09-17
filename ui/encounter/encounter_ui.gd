class_name EncounterUI
extends CanvasLayer
## Encounter decision (Provoke / Leave), fight banner and fight result.
## Emits the player's choice; EncounterController applies it.

signal provoke_pressed
signal leave_pressed
signal continue_pressed

@onready var _blocker: ColorRect = %Blocker
@onready var _banner: Label = %CombatBanner
@onready var _panel: Control = %Panel
@onready var _title: Label = %TitleLabel
@onready var _body: Label = %BodyLabel
@onready var _provoke_button: Button = %ProvokeButton
@onready var _leave_button: Button = %LeaveButton
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	_provoke_button.pressed.connect(provoke_pressed.emit)
	_leave_button.pressed.connect(leave_pressed.emit)
	_continue_button.pressed.connect(continue_pressed.emit)
	close()


func show_decision(encounter: EncounterData) -> void:
	_show_panel("%s和%s" % [encounter.human.display_name, encounter.dog_name], encounter.intro_text, true)


func show_fighting() -> void:
	_blocker.hide()
	_panel.hide()
	_banner.text = "🥊 主人自己打起來了！"
	_banner.show()


func show_victory(encounter: EncounterData, reward: ItemStack) -> void:
	var lines := "%s認輸了。" % encounter.human.display_name
	if reward != null:
		lines += "\n獲得 %s%s" % [reward.item.display_name, " x%d" % reward.quantity if reward.quantity > 1 else ""]
	_show_panel("🎉 主人贏了！", lines, false, "繼續散步")


func show_defeat(encounter: EncounterData) -> void:
	_show_panel("😵 主人被打倒了…", "%s看起來一點也不累。\n背包裡的東西保不住了。" % encounter.human.display_name, false, "🏥 送醫院")


func show_aborted() -> void:
	_show_panel("😮‍💨 打不出結果", "兩個人都累了，各自牽著狗走開。", false, "繼續散步")


func close() -> void:
	_blocker.hide()
	_banner.hide()
	_panel.hide()


func is_deciding() -> bool:
	return _panel.visible and _provoke_button.visible


func _show_panel(title: String, body: String, decision: bool, continue_text: String = "") -> void:
	_banner.hide()
	_blocker.show()
	_panel.show()
	_title.text = title
	_body.text = body
	_provoke_button.visible = decision
	_leave_button.visible = decision
	_continue_button.visible = not decision
	_continue_button.text = continue_text
