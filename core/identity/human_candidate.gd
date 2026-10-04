class_name HumanCandidate
extends RefCounted
## Sprint 06 (S06-04, SPRINT06_IDENTITY_SCHEMA): one person who visits the
## shelter, and later the player's human. Plain data, serialisable into the
## save. Looks and combat stats are rolled separately: how someone dresses
## never says how they fight (Sprint 06 hard rule).

const STAT_NAMES: Array[StringName] = [&"strength", &"endurance", &"agility", &"will"]
## The template every generated human fights with (skills, combat art).
const TEMPLATE_PATH: String = "res://data/combat/fighters/player_human.tres"

var id: StringName
var appearance_seed: int = 0
var background_id: StringName
var personality_tags: Array[StringName] = []
## DogTraitData.Behavior -> weight (their background's, with their own lean).
var preference_weights: Dictionary[int, float] = {}
var hidden_tendencies: Array[StringName] = []
## Same as background_id for now: whose reaction lines they use.
var reaction_set: StringName
## Hidden combat stats (4..7 each, the same spread for everyone).
var stats: Dictionary[StringName, int] = {}
var shirt_color: Color = Color.WHITE
var pants_color: Color = Color.BLACK
var hair_style: int = 0
var top_style: int = 0
var accessory_style: int = 0


func background() -> HumanBackgroundData:
	return DataRegistry.get_human_background(background_id)


func preference(behavior: int) -> float:
	return preference_weights.get(behavior, 0.0)


## The person as a fighter, under the name the dog's family gave them.
func to_fighter_data(display_name: String) -> FighterData:
	var fighter := (load(TEMPLATE_PATH) as FighterData).duplicate(true) as FighterData
	fighter.id = &"player_human"
	fighter.display_name = display_name
	fighter.stats.strength = stats.get(&"strength", 5)
	fighter.stats.endurance = stats.get(&"endurance", 5)
	fighter.stats.agility = stats.get(&"agility", 5)
	fighter.stats.will = stats.get(&"will", 5)
	fighter.shirt_color = shirt_color
	fighter.pants_color = pants_color
	fighter.hair_style = hair_style
	fighter.top_style = top_style
	fighter.accessory_style = accessory_style
	return fighter


func serialize() -> Dictionary:
	var prefs: Dictionary = {}
	for key in preference_weights:
		prefs[str(key)] = preference_weights[key]
	var stat_values: Dictionary = {}
	for key in stats:
		stat_values[String(key)] = stats[key]
	return {
		"id": String(id),
		"appearance_seed": appearance_seed,
		"background_id": String(background_id),
		"personality_tags": DogCandidate._strings(personality_tags),
		"preference_weights": prefs,
		"hidden_tendencies": DogCandidate._strings(hidden_tendencies),
		"reaction_set": String(reaction_set),
		"stats": stat_values,
		"shirt_color": shirt_color.to_html(false),
		"pants_color": pants_color.to_html(false),
		"hair_style": hair_style,
		"top_style": top_style,
		"accessory_style": accessory_style,
	}


## Rebuilds a human from save data, dropping anything that does not fit.
static func deserialize(data: Variant) -> HumanCandidate:
	if not data is Dictionary or str(data.get("background_id", "")).is_empty():
		return null
	var human := HumanCandidate.new()
	human.id = StringName(str(data.get("id", "")))
	human.appearance_seed = int(data.get("appearance_seed", 0))
	human.background_id = StringName(str(data["background_id"]))
	human.personality_tags = DogCandidate._names(data.get("personality_tags"))
	human.hidden_tendencies = DogCandidate._names(data.get("hidden_tendencies"))
	human.reaction_set = StringName(str(data.get("reaction_set", data["background_id"])))
	var prefs: Variant = data.get("preference_weights")
	if prefs is Dictionary:
		for key: Variant in prefs:
			var behavior := int(str(key))
			if behavior >= 0 and behavior < DogTraitData.Behavior.size():
				human.preference_weights[behavior] = clampf(float(prefs[key]), -1.5, 1.5)
	var raw_stats: Variant = data.get("stats")
	for stat in STAT_NAMES:
		var value: int = 5
		if raw_stats is Dictionary and raw_stats.has(String(stat)):
			value = int(raw_stats[String(stat)])
		human.stats[stat] = clampi(value, 1, 99)
	human.shirt_color = Color.from_string(str(data.get("shirt_color", "")), Color.WHITE)
	human.pants_color = Color.from_string(str(data.get("pants_color", "")), Color.BLACK)
	human.hair_style = clampi(int(data.get("hair_style", 0)), 0, 4)
	human.top_style = clampi(int(data.get("top_style", 0)), 0, 4)
	human.accessory_style = clampi(int(data.get("accessory_style", 0)), 0, 4)
	return human
