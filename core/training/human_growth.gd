class_name HumanGrowth
extends RefCounted
## Persistent growth of the one human (saved under SaveManager.data["human"]).

## Tag name -> accumulated growth.
var growth: Dictionary = {}
var perks: Array[StringName] = []
var defeats: int = 0


func _init() -> void:
	clear()


func clear() -> void:
	growth.clear()
	for tag_name: String in TrainingEventData.Tag.keys():
		growth[tag_name] = 0.0
	perks.clear()
	defeats = 0


func get_growth(tag: TrainingEventData.Tag) -> float:
	return float(growth.get(TrainingEventData.tag_name(tag), 0.0))


func has_perk(id: StringName) -> bool:
	return perks.has(id)


func serialize() -> Dictionary:
	var perk_names: Array[String] = []
	for id in perks:
		perk_names.append(String(id))
	return {"growth": growth.duplicate(), "perks": perk_names, "defeats": defeats}


## Tolerates missing or malformed data (old saves have an empty "human").
func deserialize(data: Dictionary) -> void:
	clear()
	var raw_growth: Variant = data.get("growth")
	if raw_growth is Dictionary:
		for tag_name: String in growth.keys():
			var value: Variant = raw_growth.get(tag_name)
			if value is float or value is int:
				growth[tag_name] = maxf(float(value), 0.0)
	var raw_perks: Variant = data.get("perks")
	if raw_perks is Array:
		for id: Variant in raw_perks:
			if id is String and not perks.has(StringName(id)):
				perks.append(StringName(id))
	var raw_defeats: Variant = data.get("defeats")
	if raw_defeats is float or raw_defeats is int:
		defeats = maxi(int(raw_defeats), 0)
