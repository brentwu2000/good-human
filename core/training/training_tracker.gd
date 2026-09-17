class_name TrainingTracker
extends RefCounted
## Run-scoped accumulation of TrainingTags (owned by RunManager). Applies the
## anti-farming rules: per-key cooldown, uniqueness, repeat diminishing and a
## per-tag run cap. Never touches permanent growth.

signal event_recorded(event: TrainingEvent)

var balance: TrainingBalance
## Tag -> accepted amount this run.
var totals: Dictionary[TrainingEventData.Tag, float] = {}
## Accepted events in order (for the summary).
var events: Array[TrainingEvent] = []

var _last_time: Dictionary[String, float] = {}
var _repeats: Dictionary[String, int] = {}


func _init(training_balance: TrainingBalance) -> void:
	balance = training_balance
	reset()


func reset() -> void:
	totals.clear()
	for tag in TrainingEventData.Tag.values():
		totals[tag] = 0.0
	events.clear()
	_last_time.clear()
	_repeats.clear()


## Returns the accepted amount (0 when rejected).
func record(event: TrainingEvent) -> float:
	var data := event.data
	var slot := "%s|%s" % [data.id, event.key]
	var repeats: int = _repeats.get(slot, 0)
	if data.unique_per_key and repeats > 0:
		return 0.0
	if data.cooldown > 0.0 and _last_time.has(slot) and event.run_time - _last_time[slot] < data.cooldown:
		return 0.0

	var amount := data.magnitude * event.scale * pow(balance.repeat_diminishing, repeats)
	amount = minf(amount, balance.tag_run_cap - totals[data.tag])
	_last_time[slot] = event.run_time
	_repeats[slot] = repeats + 1
	if amount < balance.min_contribution:
		return 0.0

	totals[data.tag] += amount
	event.accepted = amount
	events.append(event)
	event_recorded.emit(event)
	return amount


func total(tag: TrainingEventData.Tag) -> float:
	return totals.get(tag, 0.0)


## Debug only.
func debug_add_all(amount: float) -> void:
	for tag in totals:
		totals[tag] = minf(totals[tag] + amount, balance.tag_run_cap)
