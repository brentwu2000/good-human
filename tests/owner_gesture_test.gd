extends "res://tests/test_case.gd"
## Owner, 2026-10-09: Mesh2Motion's people clips on the owner — a fist-pump
## for a win, bending to pick something up, standing hurt when hurt, a wave
## setting off — each over the whole body, then back to the ordinary idle,
## and never holding them in place once they start to walk.

const PLAYER: FighterData = preload("res://data/combat/fighters/player_human.tres")


func _ready() -> void:
	var puppet := FighterPuppet3D.new()
	add_child(puppet)
	puppet.apply(PLAYER)
	var body := puppet._body as P04HumanVisual
	await get_tree().process_frame
	for clip in ["M2M_Victory", "M2M_PickUp", "M2M_Idle_Hurt", "M2M_Greeting", "M2M_Nod", "M2M_Cheer", "M2M_Tired"]:
		check(not body.m2m_clip(clip).is_empty(), "the owner has %s" % clip)
	# A win: the fist-pump, then back to standing.
	puppet.set_ambient(false)
	puppet.play_victory()
	check(String(body.player.current_animation).ends_with("M2M_Victory"), "a win is a fist-pump (%s)" % body.player.current_animation)
	puppet.set_ambient(false)
	check(String(body.player.current_animation).ends_with("M2M_Victory"), "standing still doesn't cut it short")
	puppet._gesture_left = 0.0
	puppet.set_ambient(false)
	check(not String(body.player.current_animation).contains("M2M_"), "then they stand as usual (%s)" % body.player.current_animation)
	# Picking up: bending for it; walking off ends it.
	puppet.play_pick_up(puppet.global_position + Vector3(0, 0, -0.5))
	check(String(body.player.current_animation).ends_with("M2M_PickUp"), "picking something up bends for it")
	puppet.set_ambient(true)
	check(not String(body.player.current_animation).contains("M2M_PickUp"), "and moving off ends it at once")
	# Hurt, standing still, they stand hurt; well, they don't.
	puppet.set_hp_ratio(0.2)
	puppet._ambient_clip = ""
	puppet.set_ambient(false)
	check(String(body.player.current_animation).ends_with("M2M_Idle_Hurt"), "hurt, they stand hurt (%s)" % body.player.current_animation)
	puppet.set_hp_ratio(1.0)
	puppet.set_ambient(false)
	check(not String(body.player.current_animation).contains("Hurt"), "healthy, they don't")
	puppet.queue_free()
	finish()
