class_name HumanCandidateGenerator
extends RefCounted
## Sprint 06 (S06-04): the people who come to the shelter that day. Different
## backgrounds, each with their own lean on what reaches them, ordinary clothes
## and combat stats rolled from one shared spread — so neither their looks nor
## their background tells the player how strong they are.

const STAT_MIN: int = 4
const STAT_MAX: int = 7
## How far a person leans away from their background's preferences.
const PREFERENCE_JITTER: float = 0.25


static func generate(rng: RandomNumberGenerator, count: int, backgrounds: Array[HumanBackgroundData]) -> Array[HumanCandidate]:
	var humans: Array[HumanCandidate] = []
	if backgrounds.is_empty():
		return humans
	var order := DogCandidateGenerator._shuffled(backgrounds.size(), rng)
	for i in count:
		var bg := backgrounds[order[i % order.size()]]
		var human := HumanCandidate.new()
		human.id = StringName("human_%d" % i)
		human.background_id = bg.id
		human.reaction_set = bg.id
		human.appearance_seed = rng.randi()
		human.personality_tags = bg.personality_tags.duplicate()
		for behavior in DogTraitData.Behavior.size():
			human.preference_weights[behavior] = bg.preference_weights.get(behavior, 0.0) + rng.randf_range(-PREFERENCE_JITTER, PREFERENCE_JITTER)
		human.hidden_tendencies = bg.tendencies.duplicate()
		for stat in HumanCandidate.STAT_NAMES:
			human.stats[stat] = rng.randi_range(STAT_MIN, STAT_MAX)
		human.shirt_color = _pick(bg.shirt_colors, rng, Color(0.85, 0.45, 0.35))
		human.pants_color = _pick(bg.pants_colors, rng, Color(0.2, 0.25, 0.4))
		human.hair_style = _pick(bg.hair_styles, rng, 0)
		human.top_style = _pick(bg.top_styles, rng, 0)
		human.accessory_style = _pick(bg.accessory_styles, rng, 0)
		humans.append(human)
	return humans


static func _pick(values: Array, rng: RandomNumberGenerator, fallback: Variant) -> Variant:
	return values[rng.randi_range(0, values.size() - 1)] if not values.is_empty() else fallback
