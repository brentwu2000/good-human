class_name RunTrainingSummary
extends RefCounted
## What a finished run taught the human: run totals, the conversion share
## for the outcome, and (after GrowthResolver) newly unlocked perks.

## Tag -> amount gathered on the run.
var raw: Dictionary[TrainingEventData.Tag, float] = {}
## Tag -> amount that becomes permanent growth.
var converted: Dictionary[TrainingEventData.Tag, float] = {}
var conversion: float = 1.0
var events: Array[TrainingEvent] = []
## Filled by GrowthResolver.
var new_perks: Array[PerkData] = []


static func from_tracker(tracker: TrainingTracker, outcome: RunResult.Outcome) -> RunTrainingSummary:
	var summary := RunTrainingSummary.new()
	var balance := tracker.balance
	match outcome:
		RunResult.Outcome.EXTRACTED:
			summary.conversion = balance.extract_conversion
		RunResult.Outcome.DEFEATED:
			summary.conversion = balance.defeat_conversion
		_:
			summary.conversion = balance.failed_conversion
	for tag in tracker.totals:
		summary.raw[tag] = tracker.totals[tag]
		summary.converted[tag] = tracker.totals[tag] * summary.conversion
	summary.events = tracker.events.duplicate()
	return summary


func is_partial() -> bool:
	return conversion < 1.0


func is_empty() -> bool:
	return events.is_empty()


## Distinct experiences in first-seen order: [{text, count}].
func experiences() -> Array[Dictionary]:
	var order: Array[String] = []
	var counts: Dictionary[String, int] = {}
	for event in events:
		var text := event.experience_text()
		if text.is_empty():
			continue
		if not counts.has(text):
			order.append(text)
			counts[text] = 0
		counts[text] += 1
	var lines: Array[Dictionary] = []
	for text in order:
		lines.append({"text": text, "count": counts[text]})
	return lines
