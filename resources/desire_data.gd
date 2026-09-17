class_name DesireData
extends Resource
## Something the dog wants. Optional, expressed from the dog's point of view,
## caused by the world, and able to lead to the next desire. Not a quest.

enum Category { SCENT, CHASE, RIVAL, BRING_HOME, DISCOVERY, THREAT }
## PRIMARY: offered at walk start. EMERGENT: triggered during a walk.
## THREAD: continues a chain and persists across walks until resolved.
enum Layer { PRIMARY, EMERGENT, THREAD }

@export var id: StringName
@export var category: Category = Category.SCENT
@export var layer: Layer = Layer.PRIMARY
## What the dog is thinking.
@export_multiline var dog_text: String
## Where it seems to come from (short, optional).
@export var world_hint: String
## World cue id to highlight while active (ScentCue / pair encounter id).
@export var hint_target: StringName
@export var priority: int = 10
## Survives the end of a walk while unresolved.
@export var persistent: bool = false

@export_group("Rules")
## EMERGENT: event that makes the dog want this.
@export var trigger: DesireCondition
@export var completion: DesireCondition
## Optional; failing can branch instead of ending the chain.
@export var failure: DesireCondition
## Progress flags required before this desire can be picked or triggered.
@export var requires_flags: Array[StringName] = []
## Not offered once any of these flags are set.
@export var blocked_by_flags: Array[StringName] = []
## Human growth needed (unlocked perks).
@export var min_human_perks: int = 0
## Can be wanted again after completion (e.g. meeting new dogs).
@export var repeatable: bool = false
## Only offered while this collection category still has undiscovered entries.
@export var needs_undiscovered: StringName

@export_group("Outcome")
@export var next_on_complete: Array[StringName] = []
@export var next_on_fail: Array[StringName] = []
## Flags set on completion (unlock content, remember events).
@export var sets_flags: Array[StringName] = []
@export var fail_sets_flags: Array[StringName] = []
## Optional loot granted by RunManager on completion.
@export var reward_table: LootTableData
## Dog's thought when it is done.
@export var complete_text: String
@export var fail_text: String
