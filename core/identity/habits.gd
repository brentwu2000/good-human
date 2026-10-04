class_name Habits
extends RefCounted
## Sprint 06 (S06-09): counts, across walks, the moments that build each
## habit and gives the human the habit once there have been enough. Counts
## live on the pair (`habit_progress`, saved), and a habit, once formed,
## stays: it is part of who they are now.


## Moments towards `habit` already gone through.
static func progress(pair: PairState, habit: HabitData) -> int:
	return int(pair.habit_progress.get(habit.id, 0))


## Moments still needed for this human (their tendencies can shorten it).
static func needed(pair: PairState, habit: HabitData) -> int:
	var head_start := 0
	if pair.human != null:
		for tendency in pair.human.hidden_tendencies:
			head_start += habit.tendency_head_start.get(tendency, 0)
	return maxi(habit.threshold - head_start, 1)


## Counts one finished walk. Returns the habits it formed.
static func apply_walk(pair: PairState, result: RunResult, habits: Array[HabitData]) -> Array[HabitData]:
	var formed: Array[HabitData] = []
	for habit in habits:
		if pair.habit_ids.has(habit.id):
			continue
		var moments := 0
		if habit.counts_searches:
			moments += result.searches
		if result.training != null:
			for event in result.training.events:
				if event.data != null and habit.trigger_event_ids.has(event.data.id):
					moments += 1
		if moments <= 0:
			continue
		pair.habit_progress[habit.id] = progress(pair, habit) + moments
		if progress(pair, habit) >= needed(pair, habit):
			pair.habit_ids.append(habit.id)
			formed.append(habit)
	return formed


static func has(pair: PairState, effect: StringName) -> bool:
	if pair == null:
		return false
	for id in pair.habit_ids:
		var habit := DataRegistry.get_habit(id)
		if habit != null and habit.presentation_effect == effect:
			return true
	return false
