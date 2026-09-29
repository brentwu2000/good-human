# Sprint 06 Identity Data
DogCandidate: id, breed_archetype, appearance_seed, personality_tags, visible_trait_ids, hidden_trait_ids, base_dog_stats.
HumanCandidate: id, appearance_seed, background_id, personality_tags, preference_weights, hidden_tendencies, reaction_set.
PairState: dog_id, human_id, human_custom_name, bond_state, habit_ids, memory_ids, adoption_summary.
HabitData: id, trigger_tags, threshold, presentation_effect, optional_gameplay_hook.
MemoryData: id, category, run_index, participants, place_id, event_id, presentation_key, importance.
All pools data-driven and save-versioned.
