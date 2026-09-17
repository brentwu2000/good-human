extends Control
## Shows Game.last_run_result: outcome, walk time, seed, items.

@onready var _title_label: Label = %TitleLabel
@onready var _summary_label: Label = %SummaryLabel
@onready var _items_label: Label = %ItemsLabel
@onready var _training_card: PanelContainer = %TrainingCard
@onready var _training_label: Label = %TrainingLabel
@onready var _perk_card: PanelContainer = %PerkCard
@onready var _perk_label: Label = %PerkLabel
@onready var _loot_label: Label = %LootLabel
@onready var _home_button: Button = %HomeButton


func _ready() -> void:
	_home_button.pressed.connect(Game.goto_home)
	show_result(Game.last_run_result)


func show_result(result: RunResult) -> void:
	if result == null:
		_title_label.text = "沒有散步紀錄"
		_summary_label.text = ""
		_items_label.text = ""
		_training_card.visible = false
		_perk_card.visible = false
		_loot_label.text = "還沒有帶東西回家。"
		return

	var seconds := int(result.elapsed_time)
	_summary_label.text = "散步時間 %02d:%02d\nSeed %d" % [seconds / 60, seconds % 60, result.run_seed]
	match result.outcome:
		RunResult.Outcome.EXTRACTED:
			_title_label.text = "🏠 平安回家！"
		RunResult.Outcome.DEFEATED:
			_title_label.text = "🏥 主人被送去醫院了……"
			_summary_label.text = "被%s打倒了，休息一下就會好。\n狗狗安全口袋裡的東西保住了。\n%s" % [result.defeated_by, _summary_label.text]
		_:
			_title_label.text = "😵 散步失敗……"

	var training: Array[String] = _experience_lines(result.training)
	_training_card.visible = not training.is_empty()
	_training_label.text = "\n".join(training)
	var perks: Array[String] = _perk_lines(result.training)
	_perk_card.visible = not perks.is_empty()
	_perk_label.text = "\n\n".join(perks)

	var loot: Array[String] = []
	loot.append("帶回來  $%d" % _value_of(result.to_stash))
	loot.append_array(_describe(result.to_stash))
	if not result.lost.is_empty():
		loot.append("\n遺失  $%d" % _value_of(result.lost))
		loot.append_array(_describe(result.lost))
	if not result.stash_overflow.is_empty():
		loot.append("\n倉庫放不下（已遺失）")
		loot.append_array(_describe(result.stash_overflow))
	loot.append("\n家中收藏總值  $%d" % Game.home_stash.total_value())
	_loot_label.text = "\n".join(loot)

	# Retain the aggregate text for compatibility; the visible UI uses cards.
	var legacy_lines: Array[String] = training_lines(result.training)
	legacy_lines.append_array(loot)
	_items_label.text = "\n".join(legacy_lines)


static func _experience_lines(summary: RunTrainingSummary) -> Array[String]:
	var lines: Array[String] = []
	if summary == null or summary.is_empty():
		return lines
	for experience in summary.experiences():
		var count: int = experience["count"]
		lines.append("• %s%s" % [experience["text"], "  ×%d" % count if count >= 2 else ""])
	if summary.is_partial():
		lines.append("\n即使跌倒了，主人還是記住了一部分。")
	return lines


static func _perk_lines(summary: RunTrainingSummary) -> Array[String]:
	var lines: Array[String] = []
	if summary == null:
		return lines
	for perk in summary.new_perks:
		lines.append("%s\n%s" % [perk.display_name, perk.description])
	return lines


## Experiences and changes in words; never raw TrainingTags.
static func training_lines(summary: RunTrainingSummary) -> Array[String]:
	var lines: Array[String] = []
	if summary == null or summary.is_empty():
		return lines
	lines.append("今天的散步，主人…")
	for experience in summary.experiences():
		var count: int = experience["count"]
		lines.append("  ・%s%s" % [experience["text"], "（好幾次）" if count >= 3 else ""])
	if summary.is_partial():
		lines.append("  （被打倒了，只記住了一半）")
	for perk in summary.new_perks:
		lines.append("✨ 主人好像變了：「%s」
    %s" % [perk.display_name, perk.description])
	lines.append("")
	return lines


func _describe(stacks: Array[ItemStack]) -> Array[String]:
	var lines: Array[String] = []
	if stacks.is_empty():
		lines.append("  （沒有）")
	for stack in stacks:
		var mark := "✨" if stack.item.rarity == ItemData.Rarity.RARE else ""
		lines.append("  %s%s x%d  $%d" % [mark, stack.item.display_name, stack.quantity, stack.item.value * stack.quantity])
	return lines


func _value_of(stacks: Array[ItemStack]) -> int:
	var total := 0
	for stack in stacks:
		total += stack.item.value * stack.quantity
	return total
