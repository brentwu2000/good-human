class_name DogFirstPersonView3D
extends Node3D
## Storyboard 06/10: what the dog sees of itself. A muzzle at the bottom of the
## frame and the tips of both ears at the top — enough to know whose eyes these
## are, and enough for a hand to have somewhere to land, without covering the
## fight (DOG_POV_COMBAT_CAMERA: "optional lower-frame muzzle/ears... only if
## they improve identity without obscuring combat").
##
## It hangs off the camera, so it never needs to chase anything.

## How far the head dips under a hand, and for how long.
const PET_DIP: float = 0.055
const PET_SECONDS: float = 0.5

var _muzzle: Node3D
var _tween: Tween
var _ears: Array[Node3D] = []
var _ear_rest: Array[Transform3D] = []
var _instinct_tween: Tween


func _ready() -> void:
	name = "DogFirstPersonView"
	var fur := DogController3D.FUR_COLOR
	_muzzle = Node3D.new()
	add_child(_muzzle)
	# Low and centred: the bottom edge of the frame, as in the storyboard.
	_muzzle.position = Vector3(0, -0.16, -0.30)
	_muzzle.add_child(Greybox.capsule(0.052, 0.17, fur, Vector3(0, 0, -0.045), Vector3(PI * 0.5, 0, 0)))
	_muzzle.add_child(Greybox.sphere(0.028, fur.darkened(0.55), Vector3(0, 0.012, -0.125)))
	# Ear tips at the upper corners, just inside the frame.
	for side in [-1.0, 1.0]:
		var ear := Greybox.box(Vector3(0.05, 0.10, 0.03), fur.darkened(0.12), Vector3(0.115 * side, 0.115, -0.30), Vector3(-0.25, 0, 0.35 * side))
		add_child(ear)
		_ears.append(ear)
		_ear_rest.append(ear.transform)


## D4/P02-009, from inside the dog's head: THREAT pricks the ears up and
## forward and lifts the muzzle in a snarl; WORRY lays the ears back and down
## and lowers the muzzle. CALM puts everything back.
func set_instinct(instinct: int) -> void:
	if _muzzle == null:
		return
	if _instinct_tween != null:
		_instinct_tween.kill()
	_instinct_tween = create_tween().set_parallel()
	var lift := 0.0
	var ear_up := 0.0
	var ear_turn := 0.0
	match instinct:
		DogInstinct.Instinct.THREAT:
			lift = 0.14
			ear_up = 0.025
			ear_turn = -0.45
		DogInstinct.Instinct.WORRY:
			lift = -0.1
			ear_up = -0.035
			ear_turn = 0.5
	_instinct_tween.tween_property(_muzzle, "rotation:x", lift, 0.15).set_trans(Tween.TRANS_SINE)
	for i in _ears.size():
		var rest := _ear_rest[i]
		_instinct_tween.tween_property(_ears[i], "position:y", rest.origin.y + ear_up, 0.15)
		_instinct_tween.tween_property(_ears[i], "rotation:x", rest.basis.get_euler().x + ear_turn, 0.15)


## A hand has landed: the head dips under it and comes back up.
func play_petted() -> void:
	if _muzzle == null:
		return
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position:y", -PET_DIP, PET_SECONDS * 0.4).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "position:y", 0.0, PET_SECONDS * 0.6).set_trans(Tween.TRANS_SINE)
