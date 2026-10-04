class_name MemoryKindData
extends Resource
## Sprint 06 (S06-10, SPRINT06_IDENTITY_SCHEMA MemoryData): a kind of moment
## worth remembering. Only meaningful ones: meeting, the first walk home, the
## first time the human went down, beating someone who mattered, a place
## becoming theirs, the human changing. Each is remembered once.
##
## Text placeholders: {name} the human's given name, {who} the other pair's
## human, {dog} their dog, {place} a place, {what} an item, a perk or a habit.

enum Category { MEETING, WALK, FIGHT, PLACE, GROWTH, FIND }

@export var id: StringName
@export var category: Category = Category.WALK
## 1 small .. 3 big. Home shows the most recent of the biggest.
@export_range(1, 3) var importance: int = 1
## How it is remembered (Home, 📷).
@export var text: String
## What the human says when something on a walk brings it back (empty = it
## is not recalled on walks).
@export var recall_line: String
