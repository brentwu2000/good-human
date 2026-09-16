class_name LootEntry
extends Resource

@export var item: ItemData
@export_range(0, 1000) var weight: int = 1
@export_range(1, 99) var min_quantity: int = 1
@export_range(1, 99) var max_quantity: int = 1
