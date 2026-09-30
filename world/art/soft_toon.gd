class_name SoftToon
extends RefCounted
## Style Bible v1 (AI 3D pipeline v5): one shared soft-toon material for every
## character — people and dogs — so they read as one world. Off by default
## (project setting `art/soft_toon`); the debug panel flips it live.
##
## Each surface's own material is kept and read for its colour, texture,
## vertex colour and normal map; the toon material is set as a surface
## override, so turning it off restores the original exactly.

const SHADER := preload("res://assets/shaders/soft_toon.gdshader")
const GROUP: StringName = &"soft_toon_characters"

static var enabled: bool = ProjectSettings.get_setting("art/soft_toon", false)
static var _cache: Dictionary = {}


## The Style Bible v1 version of a model (bigger head, hands, feet; same
## skeleton and clips), when the style is on and one exists. Chosen when a
## character is built: switching live changes materials, proportions follow
## on the next walk.
static func pick(default: PackedScene, stylized_path: String) -> PackedScene:
	if enabled and ResourceLoader.exists(stylized_path):
		return load(stylized_path) as PackedScene
	return default


## Marks `root` as a character and applies the current setting to it.
static func register(root: Node) -> void:
	root.add_to_group(GROUP)
	if enabled:
		apply(root)


static func set_enabled(tree: SceneTree, value: bool) -> void:
	enabled = value
	for node in tree.get_nodes_in_group(GROUP):
		if value:
			apply(node)
		else:
			restore(node)


static func apply(root: Node) -> void:
	for node in _meshes(root):
		var mi := node as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var base := mi.get_active_material(s)
			if base is ShaderMaterial and (base as ShaderMaterial).shader == SHADER:
				continue
			# Remember what the surface had (an outfit colour, say) for restore().
			mi.set_meta(_meta_key(s), mi.get_surface_override_material(s))
			mi.set_surface_override_material(s, toon_for(base))


static func restore(root: Node) -> void:
	for node in _meshes(root):
		var mi := node as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var over := mi.get_surface_override_material(s)
			if over is ShaderMaterial and (over as ShaderMaterial).shader == SHADER:
				var before: Material = mi.get_meta(_meta_key(s), null)
				mi.set_surface_override_material(s, before)
				mi.remove_meta(_meta_key(s))


## The toon version of a material, shared between everything that uses it.
static func toon_for(source: Material) -> ShaderMaterial:
	if source != null and _cache.has(source):
		return _cache[source]
	var m := ShaderMaterial.new()
	m.shader = SHADER
	var src := source as BaseMaterial3D
	if src != null:
		m.set_shader_parameter("albedo_color", src.albedo_color)
		m.set_shader_parameter("use_vertex_color", src.vertex_color_use_as_albedo)
		if src.albedo_texture != null:
			m.set_shader_parameter("albedo_tex", src.albedo_texture)
			m.set_shader_parameter("use_albedo_tex", true)
		if src.normal_enabled and src.normal_texture != null:
			m.set_shader_parameter("normal_tex", src.normal_texture)
			m.set_shader_parameter("use_normal", true)
	if source != null:
		_cache[source] = m
	return m


static func _meta_key(surface: int) -> StringName:
	return StringName("soft_toon_before_%d" % surface)


static func _meshes(root: Node) -> Array[Node]:
	var out: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		out.append(root)
	return out.filter(func(n: Node) -> bool: return (n as MeshInstance3D).mesh != null)
