class_name WorldWeapon3D
extends Interactable3D
## P05-10 (ADR-021, D5W-05/06): a find that can be fought with, lying where
## the dog found it. The dog cannot use it; it brings its human over, and the
## human crouches, picks it up and holds it — or, holding something already,
## swaps. Near it, a few words say how it compares with what they hold.

## How close (m) the human must be for the dog to get them to pick it up.
const OWNER_REACH: float = 3.0
## How close (m) the dog must be for the comparison to show.
const SHOW_WITHIN: float = 2.6

var stack: ItemStack
var weapon: WeaponData
var run: RunManager
var human: HumanFollower3D

var _prop: Node3D
var _label: Label3D
## P-05 greed: it suits the human; it calls from further away.
var _calling: bool = false


func setup(found: ItemStack, run_manager: RunManager, owner_actor: HumanFollower3D) -> void:
	stack = found
	weapon = DataRegistry.weapon_for_item(found.item_id)
	run = run_manager
	human = owner_actor


func _ready() -> void:
	add_to_group(&"world_weapons")
	_prop = WeaponProp3D.build(weapon)
	if _prop != null:
		# Lying on the ground, not floating.
		_prop.rotation = Vector3(0.0, 0.4, PI * 0.5)
		_prop.position = Vector3(0.25, 0.06, 0.0)
		add_child(_prop)
		WeaponProp3D.show_condition(_prop, WeaponCondition.state(weapon, WeaponCondition.left(weapon, stack)))
	_label = Greybox.label("", 1.0, 26, Color(1.0, 0.95, 0.8))
	_label.visible = false
	add_child(_label)
	add_interaction_area(1.2)


func _process(_delta: float) -> void:
	var dog := run.dog_actor as Node3D if run != null else null
	var near := dog != null and dog.global_position.distance_to(global_position) < SHOW_WITHIN
	_label.visible = near or _calling
	if near:
		_label.text = describe() + ("" if owner_near() else "\n（帶主人過來）")
	elif _calling:
		_label.text = "❗"


func set_calling(on: bool) -> void:
	_calling = on


func describe() -> String:
	var fists: Array[CombatSkillData] = human.fighter.skills if human != null and human.fighter != null else []
	return WeaponCompare.describe(weapon, stack.condition, run.equipped_weapon, fists)


func owner_near() -> bool:
	return human != null and human.is_following() and human.global_position.distance_to(global_position) <= OWNER_REACH


func can_interact(_context: Object) -> bool:
	return enabled and run != null and run.is_running() and not run.owner_busy and owner_near()


func get_prompt(_context: Object) -> String:
	if run != null and run.equipped_weapon != null:
		return "🔁 換成%s" % weapon.display_name
	return "🐾 讓主人撿起%s" % weapon.display_name


## The dog asks; the human picks it up.
func interact(_context: Object) -> void:
	if not can_interact(null):
		return
	var taken := run.take_weapon(stack)
	if not bool(taken["ok"]):
		human.say("（拿不下了……包包滿了。）", Color(1.0, 0.75, 0.6), 1.8)
		return
	human.puppet.play_pick_up(global_position)
	human.say("（撿起了%s）" % weapon.display_name, Color(1.0, 0.95, 0.8), 1.8)
	var dropped: ItemStack = taken["dropped"]
	if dropped != null:
		# Swapped: what they held is put down where this was.
		var down := WorldWeapon3D.new()
		down.setup(dropped, run, human)
		get_parent().add_child(down)
		down.global_position = global_position + Vector3(0.4, 0, 0.3)
	queue_free()
