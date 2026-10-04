class_name PairState
extends RefCounted
## Sprint 06 (S06-07, ADR-019): the one dog and the one human of this save.
## Saved under SaveManager.data["pair"]. There is never a roster: a save has
## exactly one pair, or none yet (a new game, still at the shelter).

## The pair a save had before Sprint 06: the shiba and the original owner.
## Old saves and tests keep it, so nothing earlier is lost.
const CLASSIC_BREED: StringName = &"shiba"
const CLASSIC_NAME: String = "主人"

var dog: DogCandidate
var human: HumanCandidate
## What the dog's family calls their human (given at the adoption).
var human_custom_name: String = ""
## True for the pre-Sprint 06 pair: the owner is `player_human.tres` itself.
var is_classic: bool = false
## Bond (S06-08): trust, familiarity, shared — never shown as a bar.
var bond: Dictionary[StringName, float] = {}
## Habits the human has picked up (S06-09).
var habit_ids: Array[StringName] = []
## Meaningful moments (S06-10), oldest first.
var memories: Array[Dictionary] = []
## How they met, in words (S06-06).
var adoption_summary: String = ""

var _fighter: FighterData


static func classic() -> PairState:
	var pair := PairState.new()
	pair.is_classic = true
	pair.dog = DogCandidate.new()
	pair.dog.id = &"classic_dog"
	pair.dog.breed_id = CLASSIC_BREED
	for stat in DogCandidate.STATS:
		pair.dog.base_dog_stats[stat] = 1.0
	pair.human_custom_name = CLASSIC_NAME
	return pair


static func adopted(adopted_dog: DogCandidate, adopter: HumanCandidate, name: String, summary: String) -> PairState:
	var pair := PairState.new()
	pair.dog = adopted_dog
	pair.human = adopter
	pair.human_custom_name = name.strip_edges() if not name.strip_edges().is_empty() else CLASSIC_NAME
	pair.adoption_summary = summary
	return pair


## The human as the walk's fighter, built once per load.
func owner_fighter() -> FighterData:
	if _fighter == null:
		if is_classic or human == null:
			_fighter = load(HumanCandidate.TEMPLATE_PATH) as FighterData
		else:
			_fighter = human.to_fighter_data(human_custom_name)
	return _fighter


func serialize() -> Dictionary:
	var bond_values: Dictionary = {}
	for key in bond:
		bond_values[String(key)] = bond[key]
	return {
		"dog": dog.serialize() if dog != null else {},
		"human": human.serialize() if human != null else {},
		"human_custom_name": human_custom_name,
		"is_classic": is_classic,
		"bond": bond_values,
		"habit_ids": DogCandidate._strings(habit_ids),
		"memories": memories.duplicate(true),
		"adoption_summary": adoption_summary,
	}


## Null when there is no usable pair in `data` (the save has not adopted yet).
static func deserialize(data: Variant) -> PairState:
	if not data is Dictionary:
		return null
	var pair := PairState.new()
	pair.is_classic = bool(data.get("is_classic", false))
	pair.dog = DogCandidate.deserialize(data.get("dog"))
	pair.human = HumanCandidate.deserialize(data.get("human"))
	if pair.dog == null or (pair.human == null and not pair.is_classic):
		return null
	pair.human_custom_name = str(data.get("human_custom_name", CLASSIC_NAME))
	pair.adoption_summary = str(data.get("adoption_summary", ""))
	var raw_bond: Variant = data.get("bond")
	if raw_bond is Dictionary:
		for key: Variant in raw_bond:
			pair.bond[StringName(str(key))] = clampf(float(raw_bond[key]), 0.0, 100.0)
	pair.habit_ids = DogCandidate._names(data.get("habit_ids"))
	var raw_memories: Variant = data.get("memories")
	if raw_memories is Array:
		for memory: Variant in raw_memories:
			if memory is Dictionary and memory.has("id"):
				pair.memories.append(memory)
	return pair
