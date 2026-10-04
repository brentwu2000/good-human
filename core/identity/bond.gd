class_name Bond
extends RefCounted
## Sprint 06 (S06-08): how close the dog and its human have become. Three
## quiet numbers kept on the pair — familiarity (time together), trust (the
## dog getting them home, the dog helping in a fight) and shared (things
## gone through together) — that the player never sees. What they see is the
## human: how they greet the dog, whether they stop to pet it first, a line at
## Home. Never a bar to fill (Identity Systems: behaviour over a grind bar).

const FAMILIARITY: StringName = &"familiarity"
const TRUST: StringName = &"trust"
const SHARED: StringName = &"shared"
const MAX_VALUE: float = 100.0
## A walk adds at most this much trust and this much shared, so the bond is
## built over many walks rather than one lucky one.
const TRUST_PER_WALK: float = 3.0
const SHARED_PER_WALK: float = 3.0
## Long enough to count as a real walk together.
const LONG_WALK_SECONDS: float = 90.0
## Training events where the dog looked after its human in a fight.
const DOG_HELPED: Array[StringName] = [&"agency_pull_save", &"agency_pull_escape", &"agency_bark_distract"]
## Total bond at which each stage begins (stage 0 starts at 0).
const STAGES: Array[float] = [0.0, 5.0, 12.0, 25.0]

const GREETINGS: Array[String] = [
	"好，出去散步吧。",
	"走吧，今天要去哪？",
	"走吧，夥伴。",
	"嘿，我的好狗狗。今天也拜託你了。",
]
const HOME_WORDS: Array[String] = [
	"還在互相認識。",
	"開始習慣彼此了。",
	"出門前，會先看你一眼。",
	"已經離不開你了。",
]


static func value(pair: PairState, key: StringName) -> float:
	return pair.bond.get(key, 0.0)


static func total(pair: PairState) -> float:
	return value(pair, FAMILIARITY) + value(pair, TRUST) + value(pair, SHARED)


static func stage(pair: PairState) -> int:
	var at := 0
	var sum := total(pair)
	for i in STAGES.size():
		if sum >= STAGES[i]:
			at = i
	return at


## Applies one finished walk. Returns true if it brought the pair closer by
## a whole stage (worth a word on the result screen).
static func apply_walk(pair: PairState, result: RunResult) -> bool:
	var before := stage(pair)
	var familiarity := 1.0 + (1.0 if result.elapsed_time >= LONG_WALK_SECONDS else 0.0)
	var trust := 2.0 if result.is_success() else 0.0
	var shared := float(result.fights_won + result.fights_lost) + 2.0 * result.territories_claimed.size()
	if result.training != null:
		for event in result.training.events:
			if event.data != null and DOG_HELPED.has(event.data.id):
				trust += 1.0
		shared += result.training.new_perks.size()
	_add(pair, FAMILIARITY, familiarity)
	_add(pair, TRUST, minf(trust, TRUST_PER_WALK))
	_add(pair, SHARED, minf(shared, SHARED_PER_WALK))
	return stage(pair) > before


static func greeting(pair: PairState) -> String:
	return GREETINGS[stage(pair)]


static func home_words(pair: PairState) -> String:
	return HOME_WORDS[stage(pair)]


## Close enough that the human stops to pet the dog before setting off.
static func pets_before_walk(pair: PairState) -> bool:
	return stage(pair) >= 2


static func _add(pair: PairState, key: StringName, amount: float) -> void:
	pair.bond[key] = clampf(value(pair, key) + amount, 0.0, MAX_VALUE)
