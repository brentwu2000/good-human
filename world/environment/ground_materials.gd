class_name GroundMaterials
extends RefCounted
## The walk's ground, as materials instead of flat colours (Claude, at the
## owner's request 2026-10-06; ART-005 is Codex's kit — collision and layout
## are untouched, only what the ground looks like). Textures are generated
## once in code and laid in world space (triplanar), so asphalt, pavers and
## grass keep the same scale on any size of box.

static var _cache: Dictionary = {}


static func asphalt() -> StandardMaterial3D:
	return _cached(&"asphalt", func() -> StandardMaterial3D:
		var m := _world_material(_noise_texture(7, 3.5, [Color(0.25, 0.26, 0.27), Color(0.29, 0.3, 0.31), Color(0.33, 0.33, 0.34)]), 1.2)
		m.roughness = 0.92
		return m)


## Square concrete pavers, 0.5 m, with grout and a little colour between them.
static func pavers() -> StandardMaterial3D:
	return _cached(&"pavers", func() -> StandardMaterial3D:
		var m := _world_material(_paver_texture(), 2.0)
		m.roughness = 0.85
		return m)


static func grass() -> StandardMaterial3D:
	return _cached(&"grass", func() -> StandardMaterial3D:
		var m := _world_material(_noise_texture(3, 0.35, [Color(0.25, 0.4, 0.2), Color(0.32, 0.5, 0.25), Color(0.4, 0.56, 0.3)]), 3.0)
		m.roughness = 0.95
		return m)


static func concrete() -> StandardMaterial3D:
	return _cached(&"concrete", func() -> StandardMaterial3D:
		var m := _world_material(_noise_texture(11, 1.4, [Color(0.6, 0.59, 0.56), Color(0.68, 0.66, 0.62), Color(0.74, 0.72, 0.68)]), 1.2)
		m.roughness = 0.8
		return m)


## Packed earth and gravel for paths through the park.
static func path() -> StandardMaterial3D:
	return _cached(&"path", func() -> StandardMaterial3D:
		var m := _world_material(_noise_texture(5, 1.1, [Color(0.5, 0.44, 0.35), Color(0.6, 0.53, 0.42), Color(0.66, 0.6, 0.5)]), 1.4)
		m.roughness = 0.95
		return m)


## Lays `material` on a Greybox box or solid box (its mesh, wherever it is).
static func apply(node: Node, material: Material) -> void:
	var mesh := node as MeshInstance3D
	if mesh == null:
		for child in node.get_children():
			if child is MeshInstance3D:
				mesh = child
				break
	if mesh != null:
		mesh.material_override = material


static func _cached(key: StringName, make: Callable) -> StandardMaterial3D:
	if not _cache.has(key):
		_cache[key] = make.call()
	return _cache[key]


static func _world_material(texture: Texture2D, metres_per_tile: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = texture
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / metres_per_tile
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


## Seamless noise through a three-colour ramp.
static func _noise_texture(seed_value: int, frequency_scale: float, colors: Array) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.02 * frequency_scale
	noise.fractal_octaves = 5
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	ramp.colors = PackedColorArray(colors)
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	texture.noise = noise
	texture.color_ramp = ramp
	texture.generate_mipmaps = true
	return texture


static func _paver_texture() -> ImageTexture:
	var size := 256
	var image := Image.create(size, size, true, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var per := 4
	var cell := size / per
	var tones: Array[Color] = []
	for i in per * per:
		tones.append(Color(0.66, 0.63, 0.58).lerp(Color(0.58, 0.55, 0.5), rng.randf()))
	var grain := FastNoiseLite.new()
	grain.seed = 3
	grain.frequency = 0.09
	for y in size:
		for x in size:
			var cx := x / cell
			var cy := y / cell
			var lx := x % cell
			var ly := y % cell
			var grout := lx < 2 or ly < 2
			var c: Color = Color(0.42, 0.4, 0.37) if grout else tones[cy * per + cx]
			var g := grain.get_noise_2d(x, y) * 0.04
			image.set_pixel(x, y, Color(c.r + g, c.g + g, c.b + g))
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)
