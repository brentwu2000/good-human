extends "res://tests/test_case.gd"
## Sprint 06 identity logic without scenes: candidate generation, matching,
## the persistent pair, bond, habits, memories and save versioning.


func _ready() -> void:
	_test_dog_data()
	_test_dog_generator()
	_test_human_generator()
	_test_adoption_match()
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


func _test_human_generator() -> void:
	check(DataRegistry.human_backgrounds.size() >= 5, "S06-04: many kinds of ordinary people (%d)" % DataRegistry.human_backgrounds.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var humans := HumanCandidateGenerator.generate(rng, 3, DataRegistry.human_backgrounds)
	check_eq(humans.size(), 3, "three people visit")
	var bgs: Dictionary[StringName, bool] = {}
	for human in humans:
		bgs[human.background_id] = true
		check(human.background() != null, "%s has a background" % human.id)
		check_eq(human.preference_weights.size(), DogTraitData.Behavior.size(), "and a lean on every dog behavior")
		for stat in HumanCandidate.STAT_NAMES:
			var v: int = human.stats[stat]
			check(v >= HumanCandidateGenerator.STAT_MIN and v <= HumanCandidateGenerator.STAT_MAX, "%s %s in the shared spread" % [human.id, stat])
	check_eq(bgs.size(), 3, "three different people")
	# Appearance is not a strength rating: no background is stronger on average.
	rng.seed = 5
	var many := HumanCandidateGenerator.generate(rng, 600, DataRegistry.human_backgrounds)
	var totals: Dictionary[StringName, Array] = {}
	for human in many:
		var sum := 0
		for stat in HumanCandidate.STAT_NAMES:
			sum += human.stats[stat]
		if not totals.has(human.background_id):
			totals[human.background_id] = [0, 0]
		totals[human.background_id][0] += sum
		totals[human.background_id][1] += 1
	var means: Array[float] = []
	for id in totals:
		means.append(float(totals[id][0]) / totals[id][1])
	check(means.max() - means.min() < 1.0, "no kind of person is reliably stronger (%.2f..%.2f)" % [means.min(), means.max()])
	# Same clothes, different strength: within one background the stats vary.
	var spread: Dictionary[int, bool] = {}
	for human in many:
		if human.background_id == many[0].background_id:
			spread[human.stats[&"strength"]] = true
	check(spread.size() >= 3, "people who look alike are not alike in a fight")
	var fighter := humans[0].to_fighter_data("阿明")
	check_eq(fighter.display_name, "阿明", "the human goes by the name they were given")
	check_eq(fighter.stats.strength, humans[0].stats[&"strength"], "with their own hidden strength")
	check_eq(fighter.shirt_color.to_html(false), humans[0].shirt_color.to_html(false), "and their own clothes")
	check(not fighter.skills.is_empty(), "and the shared way of fighting")
	var template := load(HumanCandidate.TEMPLATE_PATH) as FighterData
	check(template.display_name == "主人" and template.stats.strength == 6, "the template is not changed by it")
	var restored := HumanCandidate.deserialize(humans[0].serialize())
	check_eq(JSON.stringify(restored.serialize()), JSON.stringify(humans[0].serialize()), "a human survives a save")
	check(HumanCandidate.deserialize({}) == null, "no human from nothing")


func _test_adoption_match() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var dog := DogCandidateGenerator.generate(rng, 1, DataRegistry.dog_breeds, DataRegistry.dog_traits)[0]
	var nurse := _human_of(&"night_nurse", rng)
	var student := _human_of(&"student", rng)
	var adoption := AdoptionMatch.new(dog, [nurse, student], rng)
	var before := adoption.interest[0]
	var reaction := adoption.perform(AdoptionMatch.Behavior.LICK_HAND, 0)
	check(adoption.interest[0] > before, "S06-05: a behaviour someone likes draws them in")
	check(reaction in [AdoptionMatch.Reaction.INTERESTED, AdoptionMatch.Reaction.AFFECTIONATE], "and they show it (%s)" % AdoptionMatch.Reaction.keys()[reaction])
	before = adoption.interest[0]
	reaction = adoption.perform(AdoptionMatch.Behavior.BARK, 0)
	check(adoption.interest[0] < before, "barking at a tired nurse pushes her away")
	check(reaction in [AdoptionMatch.Reaction.STARTLED, AdoptionMatch.Reaction.CAUTIOUS], "and she shows that too (%s)" % AdoptionMatch.Reaction.keys()[reaction])
	# The same trick again counts for less.
	var gains: Array[float] = []
	for i in 3:
		var was := adoption.interest[1]
		adoption.perform(AdoptionMatch.Behavior.FETCH, 1)
		gains.append(adoption.interest[1] - was)
	check(gains[0] > gains[2], "doing the same thing again counts for less (%.2f > %.2f)" % [gains[0], gains[2]])
	# What the player does decides who it is far more often than chance —
	# but the player only ever sees reactions.
	var won := 0
	var trials := 200
	for t in trials:
		rng.seed = 1000 + t
		var visitors: Array[HumanCandidate] = HumanCandidateGenerator.generate(rng, 3, DataRegistry.human_backgrounds)
		var m := AdoptionMatch.new(dog, visitors, rng)
		var target := t % 3
		# Courting: the two things the target likes best, a couple of times.
		var ranked: Array[int] = []
		for b in AdoptionMatch.Behavior.size():
			ranked.append(b)
		var person := visitors[target]
		ranked.sort_custom(func(a: int, b: int) -> bool: return person.preference(a) > person.preference(b))
		for k in 4:
			m.perform(ranked[k % 2], target)
		if m.decide() == target:
			won += 1
	check(won > trials * 0.6, "courting someone usually wins them (%d/%d)" % [won, trials])
	# Two people ready: either may be the one.
	var picks: Dictionary[int, int] = {}
	for t in 200:
		rng.seed = 5000 + t
		var m := AdoptionMatch.new(dog, [nurse, student], rng)
		m.interest[0] = 1.0
		m.interest[1] = 0.8
		var who := m.decide()
		picks[who] = picks.get(who, 0) + 1
	check(picks.get(0, 0) > 0 and picks.get(1, 0) > 0, "nothing is guaranteed when two people want the dog (%s)" % picks)
	var nobody := AdoptionMatch.new(dog, [nurse, student], rng)
	nobody.interest[0] = -0.5
	nobody.interest[1] = 0.1
	check_eq(nobody.decide(), 1, "if nobody is sure, the one who cared most comes back")


func _human_of(background: StringName, rng: RandomNumberGenerator) -> HumanCandidate:
	var bg := DataRegistry.get_human_background(background)
	var only: Array[HumanBackgroundData] = [bg]
	return HumanCandidateGenerator.generate(rng, 1, only)[0]


func _json(dogs: Array[DogCandidate]) -> String:
	var out: Array = []
	for dog in dogs:
		out.append(dog.serialize())
	return JSON.stringify(out)
