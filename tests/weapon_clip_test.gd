extends "res://tests/test_case.gd"
## Owner, 2026-10-09: 「還不錯，但穿模了，需要做一下調整」. A held weapon must
## not pass through the body holding it — head, torso or legs — in any of its
## clips (guard, footwork, blows, blocks, reactions, carrying on the walk).
## The weapon is measured from its own model (`BodyContact.prop_capsules`);
## the arms hold it, so they don't count.

const PLAYER: FighterData = preload("res://data/combat/fighters/player_human.tres")
const SETS := {
	&"umbrella": ["Fight_Stance_Armed", "Fight_Step_Fwd_Armed", "Fight_Step_Back_Armed", "Fight_Circle_Armed",
		"Fight_Block_Armed", "Fight_Dodge_Armed", "Fight_HitLight_Armed", "Fight_HitHeavy_Armed",
		"Fight_Thrust", "Fight_Swing", "Carry_Idle_Armed", "Carry_Walk_Armed"],
	&"broom": ["Fight_Stance_Long", "Fight_Step_Fwd_Long", "Fight_Step_Back_Long", "Fight_Circle_Long",
		"Fight_Block_Long", "Fight_Dodge_Long", "Fight_HitLight_Long", "Fight_HitHeavy_Long",
		"Fight_Thrust_Long", "Fight_Swing_Long", "Fight_Sweep_Long", "Fight_Shove_Long", "Carry_Idle_Long", "Carry_Walk_Long"],
}
## A weapon resting against clothing is fine; this deep is through it.
const ALLOWED: float = 0.03
const BODY: Array[String] = ["torso", "head", "thigh", "shin"]


func _ready() -> void:
	var worst_all := 0.0
	for id: StringName in SETS:
		var puppet := FighterPuppet3D.new()
		add_child(puppet)
		puppet.apply(PLAYER)
		puppet.hold(DataRegistry.get_weapon(id))
		var body := puppet._body as P04HumanVisual
		await get_tree().process_frame
		for clip: String in SETS[id]:
			var name := "fight/" + clip
			check(body.player.has_animation(name), "%s: %s exists" % [id, clip])
			if not body.player.has_animation(name):
				continue
			body.pose_clip(name, 0.0)
			await get_tree().create_timer(P04HumanVisual.BLEND_SECONDS + 0.05).timeout
			var worst := 0.0
			var where := ""
			for i in 21:
				var t := i / 20.0
				body.pose_clip(name, t)
				await get_tree().process_frame
				var own := BodyContact.capsules(body.skeleton).filter(func(c: Array) -> bool: return c[3] in BODY)
				var hit := BodyContact.deepest(BodyContact.prop_capsules(puppet._prop), own)
				if hit[0] > worst:
					worst = hit[0]
					where = "%s, %s at t %.2f" % [hit[1], hit[2], t]
			worst_all = maxf(worst_all, worst)
			if worst > 0.0:
				print("  %s %s: %.3f m (%s)" % [id, clip, worst, where])
			check(worst <= ALLOWED, "%s %s: the weapon stays out of the body (%.3f m into the %s)" % [id, clip, worst, where])
		puppet.queue_free()
	print("worst %.3f m" % worst_all)
	finish()
