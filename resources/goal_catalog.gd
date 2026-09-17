class_name GoalCatalog
extends Resource
## All dog desires plus what can be discovered (for collection totals).

@export var desires: Array[DesireData] = []
## Place ids that PlaceMarkers use.
@export var places: Array[StringName] = []
## Encounter ids that can be met (dogs).
@export var dogs: Array[StringName] = []
