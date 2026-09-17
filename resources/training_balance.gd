class_name TrainingBalance
extends Resource
## Every tunable Sprint 03 training/growth number in one place.

@export_group("Conversion")
## Share of run TrainingTags that become permanent growth.
@export_range(0.0, 1.0) var extract_conversion: float = 1.0
@export_range(0.0, 1.0) var defeat_conversion: float = 0.5
## Other failures (debug fail).
@export_range(0.0, 1.0) var failed_conversion: float = 0.5

@export_group("Anti-farming")
## Max amount per tag in one run.
@export var tag_run_cap: float = 8.0
## Each repeat of the same event+key in a run is multiplied by this again.
@export_range(0.0, 1.0) var repeat_diminishing: float = 0.7
## Contributions below this are dropped.
@export var min_contribution: float = 0.05

@export_group("Growth to combat stats")
## Stat points per growth point (floored).
@export var run_to_agility: float = 0.25
@export var run_to_endurance: float = 0.1
@export var strain_to_strength: float = 0.25
@export var courage_to_will: float = 0.25
@export var endure_to_endurance: float = 0.2
@export var endure_to_will: float = 0.1

@export_group("Visible behaviour")
## Growth in the matching tag at which a trait reaches its trained value.
@export var trait_full_growth: float = 4.0
## Progress granted by the perk that completes a trait.
@export_range(0.0, 1.0) var perk_trait_progress: float = 1.0
## Seconds of being dragged fast before the owner stumbles (RUN).
@export var stumble_after_untrained: float = 3.0
@export var stumble_after_trained: float = 12.0
## Exertion gained per second while dragged fast (ENDURE).
@export var exertion_gain_untrained: float = 0.1
@export var exertion_gain_trained: float = 0.03
## Seconds catching breath when exhausted (ENDURE).
@export var recovery_untrained: float = 1.2
@export var recovery_trained: float = 0.4
## Seconds the owner hangs back near an unfamiliar pair (COURAGE).
@export var hesitation_untrained: float = 0.6
@export var hesitation_trained: float = 0.0
## Follow speed multiplier with a heavy bag (STRAIN).
@export var heavy_bag_speed_untrained: float = 0.85
@export var heavy_bag_speed_trained: float = 1.0
## Bag slots used to count as heavy.
@export var heavy_bag_slots: int = 6

@export_group("Content")
@export var perks: Array[PerkData] = []
