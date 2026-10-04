class_name AdoptionMatch
extends RefCounted
## Sprint 06 (S06-05): how the visiting humans come to feel about the dog.
## Every behaviour the dog shows a person moves their hidden interest, and
## they answer with a reaction — never a number or a compatibility % (D6-05).
## The player can try to win someone over but cannot guarantee it: what
## reaches a person depends on who they are, the dog's own nature, a little
## chance, and doing the same trick again counts for less.

const Behavior := DogTraitData.Behavior
const Reaction := HumanBackgroundData.Reaction

## Interest at which someone is ready to take the dog home.
const ADOPT_THRESHOLD: float = 0.6
## Each repeat of the same behaviour to the same person counts this much less.
const REPEAT_FACTOR: float = 0.6
## A behaviour lands a little differently every time.
const NOISE: float = 0.1
## First impression from what the dog is like (its personality tags).
const FIRST_IMPRESSION: float = 0.5

var dog: DogCandidate
var humans: Array[HumanCandidate] = []
## Hidden interest per human, same order as `humans`.
var interest: Array[float] = []

var _rng: RandomNumberGenerator
var _repeats: Dictionary[String, int] = {}


func _init(adopting_dog: DogCandidate, visitors: Array[HumanCandidate], rng: RandomNumberGenerator) -> void:
	dog = adopting_dog
	humans = visitors
	_rng = rng
	for human in humans:
		interest.append(first_impression(human))


## What a person makes of the dog before it does anything.
func first_impression(human: HumanCandidate) -> float:
	var bg := human.background()
	var fondness := 0.0
	if bg != null:
		for tag in dog.personality_tags:
			fondness += bg.likes_dog_tags.get(tag, 0.0)
	return fondness * FIRST_IMPRESSION


## How much more (or less) this dog does `behavior`, from its traits.
func dog_affinity(behavior: int) -> float:
	var sum := 0.0
	for id in dog.all_trait_ids():
		var t := DataRegistry.get_dog_trait(id)
		if t != null:
			sum += t.behavior_affinity.get(behavior, 0.0)
	return clampf(sum, -0.5, 1.0)


## The dog does `behavior` towards human `index`. Returns how they react.
func perform(behavior: int, index: int) -> Reaction:
	var human := humans[index]
	var key := "%d|%d" % [index, behavior]
	var repeats: int = _repeats.get(key, 0)
	_repeats[key] = repeats + 1
	var lean := human.preference(behavior)
	# The dog's nature makes a behaviour land harder whichever way it goes.
	var effect := lean * (1.0 + dog_affinity(behavior)) * pow(REPEAT_FACTOR, repeats)
	effect += _rng.randf_range(-NOISE, NOISE)
	interest[index] += effect
	return reaction_for(behavior, effect, interest[index])


## What shows on their face and body. Startled is reserved for loud or
## sudden things going wrong; affection needs real warmth built up.
static func reaction_for(behavior: int, effect: float, total: float) -> Reaction:
	if effect <= -0.35 and behavior in [Behavior.BARK, Behavior.APPROACH, Behavior.STARE]:
		return Reaction.STARTLED
	if effect <= -0.12:
		return Reaction.CAUTIOUS
	if effect < 0.12:
		return Reaction.INDIFFERENT
	if total >= ADOPT_THRESHOLD and effect >= 0.25:
		return Reaction.AFFECTIONATE
	if behavior in [Behavior.WAG, Behavior.FETCH, Behavior.STARE, Behavior.IGNORE]:
		return Reaction.AMUSED
	return Reaction.INTERESTED


## Who takes the dog home. Anyone ready may be the one (weighted by how much
## they care), so even a clear favourite is not a certainty. If nobody is
## ready, the one who cared most comes back for it anyway.
func decide() -> int:
	var ready: Array[int] = []
	var total := 0.0
	for i in humans.size():
		if interest[i] >= ADOPT_THRESHOLD:
			ready.append(i)
			total += interest[i]
	if ready.is_empty():
		var best := 0
		for i in humans.size():
			if interest[i] > interest[best]:
				best = i
		return best
	var roll := _rng.randf() * total
	for i in ready:
		roll -= interest[i]
		if roll <= 0.0:
			return i
	return ready[-1]
