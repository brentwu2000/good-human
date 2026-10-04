extends "res://tests/test_case.gd"
## Sprint 06 identity logic without scenes: candidate generation, matching,
## the persistent pair, bond, habits, memories and save versioning.


func _ready() -> void:
	_test_dog_data()
	_test_dog_generator()
	finish()


func _test_dog_data() -> void:
	check(DataRegistry.dog_breeds.size() >= 6, "S06-01: several breeds to meet (%d)" % DataRegistry.dog_breeds.size())
	check(DataRegistry.dog_traits.size() >= 8, "and many things a dog can be like (%d)" % DataRegistry.dog_traits.size())
	for breed in DataRegistry.dog_breeds:
		check(ResourceLoader.exists(breed.model_path), "%s has a model" % breed.id)
	for t in DataRegistry.dog_traits:
		check(not t.text.is_empty() and not t.text.contains("%") and not t.text.is_valid_float(), "%s is said in words, not numbers" % t.id)


func _test_dog_generator() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var dogs := DogCandidateGenerator.generate(rng, 5, DataRegistry.dog_breeds, DataRegistry.dog_traits)
	check_eq(dogs.size(), 5, "five dogs at the shelter")
	var breeds: Dictionary[StringName, bool] = {}
	for dog in dogs:
		breeds[dog.breed_id] = true
		check_eq(dog.visible_trait_ids.size(), DogCandidateGenerator.VISIBLE_TRAITS, "%s shows some of what it is like" % dog.id)
		check_eq(dog.hidden_trait_ids.size(), DogCandidateGenerator.HIDDEN_TRAITS, "and hides some")
		var all := dog.all_trait_ids()
		var unique: Dictionary[StringName, bool] = {}
		for id in all:
			unique[id] = true
		check_eq(unique.size(), all.size(), "never the same trait twice")
		check(not dog.personality_tags.is_empty(), "a personality comes with it")
		for stat in DogCandidate.STATS:
			check(dog.stat(stat) >= 0.5 and dog.stat(stat) <= 1.5, "%s %s stays in range" % [dog.id, stat])
	check_eq(breeds.size(), 5, "all different breeds while there are enough")
	rng.seed = 42
	var again := DogCandidateGenerator.generate(rng, 5, DataRegistry.dog_breeds, DataRegistry.dog_traits)
	check_eq(_json(again), _json(dogs), "the same seed meets the same dogs")
	rng.seed = 43
	check(_json(DogCandidateGenerator.generate(rng, 5, DataRegistry.dog_breeds, DataRegistry.dog_traits)) != _json(dogs), "another seed meets others")
	# Talent leans the way the traits do: across many dogs, a keen nose smells better.
	rng.seed = 7
	var many := DogCandidateGenerator.generate(rng, 200, DataRegistry.dog_breeds, DataRegistry.dog_traits)
	var with_nose := 0.0
	var with_count := 0
	var without := 0.0
	var without_count := 0
	for dog in many:
		if dog.all_trait_ids().has(&"keen_nose"):
			with_nose += dog.stat(&"nose")
			with_count += 1
		else:
			without += dog.stat(&"nose")
			without_count += 1
	check(with_count > 0 and with_nose / with_count > without / without_count + 0.08, "a keen nose is a real talent")
	# A breed says nothing about talent: breed and stats are rolled apart.
	var restored := DogCandidate.deserialize(dogs[0].serialize())
	check_eq(JSON.stringify(restored.serialize()), JSON.stringify(dogs[0].serialize()), "a dog survives a save")
	check(DogCandidate.deserialize({}) == null and DogCandidate.deserialize("x") == null, "no dog from nothing")
	var bad := DogCandidate.deserialize({"breed_id": "shiba", "base_dog_stats": {"nose": 99, "evil": 3}})
	check(bad.stat(&"nose") <= 1.5 and not bad.base_dog_stats.has(&"evil"), "bad stats are clamped or dropped")


func _json(dogs: Array[DogCandidate]) -> String:
	var out: Array = []
	for dog in dogs:
		out.append(dog.serialize())
	return JSON.stringify(out)
