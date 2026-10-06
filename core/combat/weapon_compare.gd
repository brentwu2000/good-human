class_name WeaponCompare
extends RefCounted
## P05-10 (D5W-06): a find against what the human is holding, in a few plain
## words, world-first — reach, speed, defence, impact and condition, never a
## number and never only damage.

## Reach, quickness, defence and impact of a set of skills (bare hands are the
## fighter's own skills).
static func profile(skills: Array[CombatSkillData]) -> Dictionary:
	var reach := 0.0
	var quickest := INF
	var guard := 0.0
	var impact := 0.0
	for skill in skills:
		if skill == null:
			continue
		if skill.effect == CombatSkillData.Effect.ATTACK:
			reach = maxf(reach, skill.preferred_range)
			quickest = minf(quickest, skill.windup)
			impact = maxf(impact, skill.power * (1.0 + skill.guard_break))
		elif skill.effect == CombatSkillData.Effect.BLOCK:
			guard = maxf(guard, skill.damage_reduction)
	return {"reach": reach, "speed": 1.0 / maxf(quickest, 0.05), "guard": guard, "impact": impact}


## 「雨傘（有點舊了）：比空手長・比較快・會擋」.
static func describe(found: WeaponData, condition: int, held: WeaponData, fists: Array[CombatSkillData]) -> String:
	var mine := profile(fists if held == null or held.is_unarmed() else held.moveset.skills())
	var theirs := profile(found.moveset.skills())
	var against := "空手" if held == null or held.is_unarmed() else held.display_name
	var words: Array[String] = []
	words.append(_more(theirs["reach"], mine["reach"], 0.08, "比%s長" % against, "比%s短" % against))
	words.append(_more(theirs["speed"], mine["speed"], 0.12, "比較快", "比較慢"))
	words.append(_more(theirs["impact"], mine["impact"], 0.12, "比較重", "比較輕"))
	words.append(_more(theirs["guard"], mine["guard"], 0.1, "比較會擋", "比較難擋"))
	words = words.filter(func(w: String) -> bool: return not w.is_empty())
	var state := WeaponCondition.label(WeaponCondition.state(found, condition if condition >= 0 else found.condition_max))
	return "%s（%s）：%s" % [found.display_name, state, "・".join(words) if not words.is_empty() else "差不多"]


static func _more(a: float, b: float, margin: float, more: String, less: String) -> String:
	if a > b * (1.0 + margin):
		return more
	if a < b * (1.0 - margin):
		return less
	return ""
