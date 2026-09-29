extends Node3D
## Art review visualizer for D5-02/D5-03 scent ownership states.
const SCENT := preload("res://assets/environment/territory/models/banyan_01/banyan_scent_states.glb")
const STATES := ["UNKNOWN", "DISCOVERED", "CONTESTED", "CLAIMING", "OWNED"]
var model: Node3D
var state := "UNKNOWN"
var reward_elapsed := -1.0

func _ready() -> void:
	model = SCENT.instantiate()
	add_child(model)
	set_state(state)

func set_state(next_state: String) -> void:
	state = next_state if next_state in STATES else "UNKNOWN"
	reward_elapsed = -1.0
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var visible := false
		if node.name.begins_with("Scent_" + state + "_"):
			visible = state != "UNKNOWN"
		elif node.name.begins_with("Reward_"):
			visible = state == "OWNED"
		node.visible = visible
		if visible and node.name.begins_with("Scent_"):
			node.material_override = _marker_material(Color("44e6d4") if state in ["CLAIMING", "OWNED"] else (Color("ff7b70") if state == "CONTESTED" else Color("b995ff")))
			node.scale = Vector3.ONE * 1.8

func _marker_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.2
	material.roughness = 0.25
	return material

func play_recognize() -> void:
	# Amber recognition is a timing cue layered over the discovered state.
	set_state("DISCOVERED")
	for node in model.find_children("*", "MeshInstance3D", true, false):
		if node.name.begins_with("Scent_DISCOVERED_"):
			node.scale = Vector3.ONE * 1.35
	await get_tree().create_timer(0.22).timeout
	for node in model.find_children("*", "MeshInstance3D", true, false):
		if node.name.begins_with("Scent_DISCOVERED_"):
			node.scale = Vector3.ONE

func play_mark() -> void:
	set_state("CLAIMING")
	await get_tree().create_timer(1.15).timeout
	set_state("OWNED")

func play_reward_reveal() -> void:
	set_state("OWNED")
	reward_elapsed = 0.0

func _process(delta: float) -> void:
	if reward_elapsed < 0.0:
		return
	reward_elapsed += delta
	for i in range(9):
		var leaf := model.get_node_or_null("Reward_Leaf_%02d" % i)
		if leaf:
			var lift := minf(reward_elapsed / 0.7, 1.0)
			leaf.position.y = 0.14 + sin((reward_elapsed * 5.0) + i * 0.7) * 0.035 + lift * 0.16
			leaf.rotation.y += delta * (1.2 + i * 0.05)
