class_name HumanFollower
extends CharacterBody2D
## The owner, walked by the dog on a leash. FOLLOW: walks after the dog.
## COMBAT: stands and fights where the fight started; its position is driven
## by the active Engagement (the dog stays free). DOWN: knocked out.

enum State { FOLLOW, COMBAT, DOWN }

@export var dog: Node2D
## Combat stats, skills and placeholder look of the player's human.
@export var fighter: FighterData
## Owner starts walking when the leash is longer than this.
@export var slack_length: float = 90.0
## Leash never stretches beyond this while following.
@export var max_length: float = 170.0
@export var walk_speed: float = 230.0
## Snap behind the dog only when this far (stuck on a corner). Larger than the
## combat disengage distance so running after the dog stays visible.
@export var catch_up_distance: float = 700.0

var state: State = State.FOLLOW

var _bubble_tween: Tween

@onready var puppet: FighterPuppet = %Puppet
@onready var _leash: Line2D = $Leash
@onready var _bubble: Label = %Bubble


func _ready() -> void:
	_bubble.hide()
	# Leash is drawn in world space, not relative to the owner.
	_leash.top_level = true
	if fighter != null:
		puppet.apply(fighter)


func _physics_process(_delta: float) -> void:
	if dog == null:
		return
	if state == State.FOLLOW:
		_follow()
	_update_leash()


func _follow() -> void:
	var to_dog := dog.global_position - global_position
	var distance := to_dog.length()
	if distance > slack_length:
		# Walk faster the tighter the leash gets.
		var pull := inverse_lerp(slack_length, max_length, distance)
		velocity = to_dog.normalized() * walk_speed * clampf(0.5 + pull, 0.5, 1.6)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, walk_speed * 0.25)
	move_and_slide()

	# Hard leash: never let the owner fall far behind (e.g. stuck on a corner).
	distance = global_position.distance_to(dog.global_position)
	if distance > catch_up_distance:
		global_position = dog.global_position - (dog.global_position - global_position).normalized() * max_length

	if absf(velocity.x) > 5.0:
		puppet.set_facing(velocity.x)


func is_following() -> bool:
	return state == State.FOLLOW


## Called by CombatCoordinator.
func set_state(value: State) -> void:
	state = value
	velocity = Vector2.ZERO
	if value == State.FOLLOW:
		puppet.revive()
		puppet.show_hp(false)


func say(text: String, color: Color = Color.WHITE, seconds: float = 1.6) -> void:
	if _bubble_tween != null:
		_bubble_tween.kill()
	_bubble.text = text
	_bubble.modulate = color
	_bubble.self_modulate.a = 1.0
	_bubble.show()
	_bubble_tween = create_tween()
	_bubble_tween.tween_interval(seconds)
	_bubble_tween.tween_property(_bubble, "self_modulate:a", 0.0, 0.3)
	_bubble_tween.tween_callback(_bubble.hide)


func _update_leash() -> void:
	var hand := global_position + Vector2(14.0 * puppet.facing, -30.0)
	var collar := dog.global_position
	# During a fight the leash is dropped: it trails loosely instead of pulling.
	var reach := max_length if state == State.FOLLOW else maxf(hand.distance_to(collar), max_length)
	var sag := clampf(1.0 - hand.distance_to(collar) / reach, 0.0, 1.0) * 40.0
	if state != State.FOLLOW:
		sag = 30.0
	var middle := (hand + collar) / 2.0 + Vector2(0, sag)
	_leash.points = PackedVector2Array([hand, (hand + middle) / 2.0 + Vector2(0, sag * 0.3), middle, (middle + collar) / 2.0 + Vector2(0, sag * 0.3), collar])
	_leash.default_color = Color(0.85, 0.2, 0.2) if sag < 4.0 else Color(0.7, 0.3, 0.25)
