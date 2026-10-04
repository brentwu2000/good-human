class_name DogCandidate
extends RefCounted
## Sprint 06 (S06-01, SPRINT06_IDENTITY_SCHEMA): one dog at the shelter, and
## later the player's dog. Plain data, serialisable into the save.

const STATS: Array[StringName] = [&"nose", &"energy", &"voice"]

var id: StringName
var breed_id: StringName
## Drives looks that are not the breed (collar colour).
var appearance_seed: int = 0
var personality_tags: Array[StringName] = []
var visible_trait_ids: Array[StringName] = []
var hidden_trait_ids: Array[StringName] = []
## Stat -> multiplier around 1.0 ("nose", "energy", "voice").
var base_dog_stats: Dictionary[StringName, float] = {}


func all_trait_ids() -> Array[StringName]:
	var ids: Array[StringName] = visible_trait_ids.duplicate()
	ids.append_array(hidden_trait_ids)
	return ids


func stat(name: StringName) -> float:
	return base_dog_stats.get(name, 1.0)


## A colour from the appearance seed, for the collar.
func collar_color() -> Color:
	var hue := float(absi(appearance_seed) % 360) / 360.0
	return Color.from_hsv(hue, 0.55, 0.85)


func serialize() -> Dictionary:
	var stats: Dictionary = {}
	for key in base_dog_stats:
		stats[String(key)] = base_dog_stats[key]
	return {
		"id": String(id),
		"breed_id": String(breed_id),
		"appearance_seed": appearance_seed,
		"personality_tags": _strings(personality_tags),
		"visible_trait_ids": _strings(visible_trait_ids),
		"hidden_trait_ids": _strings(hidden_trait_ids),
		"base_dog_stats": stats,
	}


## Rebuilds a candidate from save data. Unknown values are dropped rather
## than trusted; returns null if there is no dog to speak of.
static func deserialize(data: Variant) -> DogCandidate:
	if not data is Dictionary or str(data.get("breed_id", "")).is_empty():
		return null
	var dog := DogCandidate.new()
	dog.id = StringName(str(data.get("id", "")))
	dog.breed_id = StringName(str(data["breed_id"]))
	dog.appearance_seed = int(data.get("appearance_seed", 0))
	dog.personality_tags = _names(data.get("personality_tags"))
	dog.visible_trait_ids = _names(data.get("visible_trait_ids"))
	dog.hidden_trait_ids = _names(data.get("hidden_trait_ids"))
	var stats: Variant = data.get("base_dog_stats")
	if stats is Dictionary:
		for key: Variant in stats:
			if StringName(str(key)) in STATS:
				dog.base_dog_stats[StringName(str(key))] = clampf(float(stats[key]), 0.5, 1.5)
	return dog


static func _strings(values: Array[StringName]) -> Array:
	var out: Array = []
	for value in values:
		out.append(String(value))
	return out


static func _names(raw: Variant) -> Array[StringName]:
	var out: Array[StringName] = []
	if raw is Array:
		for value: Variant in raw:
			out.append(StringName(str(value)))
	return out
