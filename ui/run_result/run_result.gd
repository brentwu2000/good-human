extends Control
## Shows Game.last_run_result: outcome, walk time, seed, items.

@onready var _title_label: Label = %TitleLabel
@onready var _summary_label: Label = %SummaryLabel
@onready var _items_label: Label = %ItemsLabel
@onready var _home_button: Button = %HomeButton


func _ready() -> void:
	_home_button.pressed.connect(Game.goto_home)
	show_result(Game.last_run_result)


func show_result(result: RunResult) -> void:
	if result == null:
		_title_label.text = "沒有散步紀錄"
		_summary_label.text = ""
		_items_label.text = ""
		return

	_title_label.text = "🏠 平安回家！" if result.is_success() else "😵 散步失敗……"
	var seconds := int(result.elapsed_time)
	_summary_label.text = "散步時間 %02d:%02d\nSeed %d" % [seconds / 60, seconds % 60, result.run_seed]

	var lines: Array[String] = []
	lines.append("帶回來的東西：")
	lines.append_array(_describe(result.to_stash))
	if not result.lost.is_empty():
		lines.append("\n遺失的東西：")
		lines.append_array(_describe(result.lost))
	if not result.stash_overflow.is_empty():
		lines.append("\n倉庫放不下（已遺失）：")
		lines.append_array(_describe(result.stash_overflow))
	_items_label.text = "\n".join(lines)


func _describe(stacks: Array[ItemStack]) -> Array[String]:
	var lines: Array[String] = []
	if stacks.is_empty():
		lines.append("  （沒有）")
	for stack in stacks:
		lines.append("  %s x%d" % [stack.item.display_name, stack.quantity])
	return lines
