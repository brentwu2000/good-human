# Training System v0.1
## Tags
RUN: sprint/chase/forced movement → AGI/END.
STRAIN: leash resistance/physical effort → STR.
COURAGE: approach/remain near danger → WIL.
SOCIAL: meaningful dog/human interaction → SOC.
ENDURE: sustained exertion/setbacks → END/WIL.
## Pipeline
World Event → TrainingEvent → run-scoped TrainingTracker → RunTrainingSummary → GrowthResolver.
Interactables must not directly mutate permanent stats.
TrainingEvent supports event_id, tag, magnitude, source, context, run time, optional cooldown/uniqueness key.
Use simple anti-farming: cooldown, diminishing contribution, cap, or meaningful-duration threshold.
Player UI describes experiences; raw counters are Debug-only.
