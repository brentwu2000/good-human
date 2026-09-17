class_name GrowthResolver
extends RefCounted
## Turns a RunTrainingSummary into persistent HumanGrowth, unlocks perks and
## derives what growth changes: combat stats and visible behaviour traits.


## Applies converted training, records a defeat, fills summary.new_perks.
static func apply(growth: HumanGrowth, summary: RunTrainingSummary, defeated: bool, balance: TrainingBalance) -> void:
	for tag in summary.converted:
		var name := TrainingEventData.tag_name(tag)
		growth.growth[name] = float(growth.growth.get(name, 0.0)) + summary.converted[tag]
	if defeated:
		growth.defeats += 1
	summary.new_perks.clear()
	for perk in balance.perks:
		if perk != null and not growth.has_perk(perk.id) and perk.is_met(growth.growth, growth.defeats):
			growth.perks.append(perk.id)
			summary.new_perks.append(perk)


static func owned_perks(growth: HumanGrowth, balance: TrainingBalance) -> Array[PerkData]:
	var owned: Array[PerkData] = []
	for perk in balance.perks:
		if perk != null and growth.has_perk(perk.id):
			owned.append(perk)
	return owned


## Base fighter with growth stat bonuses (a copy; the base resource is untouched).
static func apply_to_fighter(base: FighterData, growth: HumanGrowth, balance: TrainingBalance) -> FighterData:
	var fighter := base.duplicate() as FighterData
	var stats := base.stats.duplicate() as CombatStats
	var run := growth.get_growth(TrainingEventData.Tag.RUN)
	var strain := growth.get_growth(TrainingEventData.Tag.STRAIN)
	var courage := growth.get_growth(TrainingEventData.Tag.COURAGE)
	var endure := growth.get_growth(TrainingEventData.Tag.ENDURE)
	stats.agility += int(run * balance.run_to_agility)
	stats.endurance += int(run * balance.run_to_endurance + endure * balance.endure_to_endurance)
	stats.strength += int(strain * balance.strain_to_strength)
	stats.will += int(courage * balance.courage_to_will + endure * balance.endure_to_will)
	for perk in owned_perks(growth, balance):
		stats.strength += perk.bonus_strength
		stats.endurance += perk.bonus_endurance
		stats.agility += perk.bonus_agility
		stats.will += perk.bonus_will
	fighter.stats = stats
	return fighter


## 0 = untrained, 1 = fully trained, for one behaviour trait.
static func trait_progress(growth: HumanGrowth, balance: TrainingBalance, trait_key: StringName) -> float:
	var progress := 0.0
	match trait_key:
		&"stumble":
			progress = growth.get_growth(TrainingEventData.Tag.RUN) / balance.trait_full_growth
		&"exertion", &"recovery":
			progress = growth.get_growth(TrainingEventData.Tag.ENDURE) / balance.trait_full_growth
		&"hesitation":
			progress = growth.get_growth(TrainingEventData.Tag.COURAGE) / balance.trait_full_growth
		&"heavy_bag":
			progress = growth.get_growth(TrainingEventData.Tag.STRAIN) / balance.trait_full_growth
		&"greeting":
			progress = growth.get_growth(TrainingEventData.Tag.SOCIAL) / balance.trait_full_growth
	for perk in owned_perks(growth, balance):
		if perk.trait_key == trait_key:
			progress = maxf(progress, balance.perk_trait_progress)
	return clampf(progress, 0.0, 1.0)


static func traits(growth: HumanGrowth, balance: TrainingBalance) -> HumanTraits:
	var t := HumanTraits.new()
	t.stumble_after = lerpf(balance.stumble_after_untrained, balance.stumble_after_trained, trait_progress(growth, balance, &"stumble"))
	t.exertion_gain = lerpf(balance.exertion_gain_untrained, balance.exertion_gain_trained, trait_progress(growth, balance, &"exertion"))
	t.recovery_time = lerpf(balance.recovery_untrained, balance.recovery_trained, trait_progress(growth, balance, &"recovery"))
	t.hesitation_time = lerpf(balance.hesitation_untrained, balance.hesitation_trained, trait_progress(growth, balance, &"hesitation"))
	t.heavy_bag_speed = lerpf(balance.heavy_bag_speed_untrained, balance.heavy_bag_speed_trained, trait_progress(growth, balance, &"heavy_bag"))
	t.greets = trait_progress(growth, balance, &"greeting") >= 1.0
	return t
