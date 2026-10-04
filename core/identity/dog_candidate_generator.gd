class_name DogCandidateGenerator
extends RefCounted
## Sprint 06 (S06-01): the dogs waiting at the shelter. Each is a breed (looks
## only), a couple of things you can see about it and one you cannot yet, and
## a talent that leans the way its traits do. No rarity, no tiers (ADR-020).

const VISIBLE_TRAITS: int = 2
const HIDDEN_TRAITS: int = 1
## How far a dog's raw talent varies either side of 1.0, before traits.
const STAT_SPREAD: float = 0.1


## `count` dogs from the run-independent `rng`, all different breeds while
## there are breeds enough.
static func generate(rng: RandomNumberGenerator, count: int, breeds: Array[DogBreedData], traits: Array[DogTraitData]) -> Array[DogCandidate]:
	var dogs: Array[DogCandidate] = []
	if breeds.is_empty() or traits.size() < VISIBLE_TRAITS + HIDDEN_TRAITS:
		return dogs
	var breed_order := _shuffled(breeds.size(), rng)
	for i in count:
		var dog := DogCandidate.new()
		dog.id = StringName("dog_%d" % i)
		dog.breed_id = breeds[breed_order[i % breed_order.size()]].id
		dog.appearance_seed = rng.randi()
		var picks := _shuffled(traits.size(), rng)
		for j in VISIBLE_TRAITS + HIDDEN_TRAITS:
			var picked := traits[picks[j]]
			if j < VISIBLE_TRAITS:
				dog.visible_trait_ids.append(picked.id)
			else:
				dog.hidden_trait_ids.append(picked.id)
			for tag in picked.tags:
				if not dog.personality_tags.has(tag):
					dog.personality_tags.append(tag)
		for stat in DogCandidate.STATS:
			var value := 1.0 + rng.randf_range(-STAT_SPREAD, STAT_SPREAD)
			for trait_id in dog.all_trait_ids():
				value += _trait(traits, trait_id).stat_bias.get(stat, 0.0)
			dog.base_dog_stats[stat] = clampf(value, 0.5, 1.5)
		dogs.append(dog)
	return dogs


static func _trait(traits: Array[DogTraitData], id: StringName) -> DogTraitData:
	for t in traits:
		if t.id == id:
			return t
	return null


## 0..size-1 in a run-RNG order (Fisher–Yates, deterministic per seed).
static func _shuffled(size: int, rng: RandomNumberGenerator) -> Array[int]:
	var order: Array[int] = []
	for i in size:
		order.append(i)
	for i in range(size - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := order[i]
		order[i] = order[j]
		order[j] = swap
	return order
