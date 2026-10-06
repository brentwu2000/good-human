class_name SfxSynth
extends RefCounted
## P03-E09: placeholder sounds made in code, until real audio exists. Each is
## a short 16-bit mono clip built once from noise and tones and cached. They
## are deliberately plain — thumps, rustles, a bark-shaped yelp — so the fight
## has weight and the world has a floor, not to be final sound design.

const RATE: int = 22050

static var _cache: Dictionary = {}


static func get_sound(sound: StringName) -> AudioStreamWAV:
	if not _cache.has(sound):
		_cache[sound] = _build(sound)
	return _cache[sound]


static func _build(sound: StringName) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(sound)
	var samples := PackedFloat32Array()
	var loop := false
	match sound:
		&"impact_light":
			samples = _mix([_thump(0.14, 130.0, 22.0, 0.9), _noise_burst(rng, 0.08, 45.0, 0.5, 0.35)])
		&"impact_heavy":
			samples = _mix([_thump(0.32, 72.0, 11.0, 1.0), _noise_burst(rng, 0.16, 26.0, 0.35, 0.5)])
		&"block":
			samples = _mix([_thump(0.16, 170.0, 26.0, 0.7), _noise_burst(rng, 0.06, 60.0, 0.15, 0.3)])
		&"whoosh":
			samples = _whoosh(rng, 0.24)
		&"bark":
			samples = _bark(rng)
		&"growl":
			samples = _growl(rng, 0.9)
		&"leash":
			samples = _mix([_ring(0.12, 3100.0, 40.0, 0.35), _ring(0.12, 4300.0, 55.0, 0.25, 0.03), _ring(0.1, 2600.0, 50.0, 0.2, 0.06)])
		&"step":
			samples = _noise_burst(rng, 0.05, 90.0, 0.08, 0.35)
		&"birds":
			samples = _birds(rng, 0.9)
		&"pulse":
			samples = _heartbeat(1.0)
			loop = true
		&"ambience":
			samples = _ambience(rng, 4.0)
			loop = true
		_:
			samples = _thump(0.1, 200.0, 30.0, 0.5)
	return _to_wav(samples, loop)


# --- Building blocks ------------------------------------------------------------

## A low sine dropping in pitch and dying away: the body of a blow.
static func _thump(seconds: float, freq: float, decay: float, gain: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(seconds * RATE))
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var f := freq * (1.0 + 1.5 * exp(-t * 40.0))
		phase += TAU * f / RATE
		out[i] = sin(phase) * exp(-t * decay) * gain
	return out


## Noise with a fast attack and exponential decay; `smooth` 0..1 dulls it.
static func _noise_burst(rng: RandomNumberGenerator, seconds: float, decay: float, gain: float, smooth: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(seconds * RATE))
	var last := 0.0
	for i in out.size():
		var t := float(i) / RATE
		last = lerpf(rng.randf_range(-1.0, 1.0), last, smooth)
		out[i] = last * exp(-t * decay) * gain * minf(t * 800.0, 1.0)
	return out


static func _ring(seconds: float, freq: float, decay: float, gain: float, delay: float = 0.0) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int((seconds + delay) * RATE))
	for i in out.size():
		var t := float(i) / RATE - delay
		if t >= 0.0:
			out[i] = sin(TAU * freq * t) * exp(-t * decay) * gain
	return out


## Air moving: smoothed noise swelling and falling away.
static func _whoosh(rng: RandomNumberGenerator, seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(seconds * RATE))
	var last := 0.0
	for i in out.size():
		var p := float(i) / out.size()
		last = lerpf(rng.randf_range(-1.0, 1.0), last, 0.85)
		out[i] = last * sin(PI * p) * 0.55
	return out


## Two short voiced yelps, falling in pitch: "wuf-wuf".
static func _bark(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(0.32 * RATE))
	for start: float in [0.0, 0.15]:
		var phase := 0.0
		for i in int(0.12 * RATE):
			var t := float(i) / RATE
			var at := int(start * RATE) + i
			if at >= out.size():
				break
			var f := lerpf(520.0, 330.0, t / 0.12)
			phase += TAU * f / RATE
			var voice := sin(phase) * 0.6 + sin(phase * 2.0) * 0.25 + sin(phase * 3.0) * 0.1
			var env := minf(t * 300.0, 1.0) * exp(-t * 18.0)
			out[at] += (voice + rng.randf_range(-0.3, 0.3)) * env * 0.7
	return out


## A low rumble with a rough tremble.
static func _growl(rng: RandomNumberGenerator, seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(seconds * RATE))
	var phase := 0.0
	var last := 0.0
	for i in out.size():
		var t := float(i) / RATE
		phase += TAU * (95.0 + 10.0 * sin(t * 7.0)) / RATE
		last = lerpf(rng.randf_range(-1.0, 1.0), last, 0.9)
		var tremble := 0.6 + 0.4 * sin(TAU * 24.0 * t)
		var env := minf(t * 8.0, 1.0) * minf((seconds - t) * 6.0, 1.0)
		out[i] = (sin(phase) * 0.5 + last * 0.5) * tremble * env * 0.6
	return out


## Wings: bursts of fluttering noise.
static func _birds(rng: RandomNumberGenerator, seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(seconds * RATE))
	for i in out.size():
		var t := float(i) / RATE
		var flutter := maxf(sin(TAU * 18.0 * t + rng.randf() * 0.4), 0.0)
		out[i] = rng.randf_range(-1.0, 1.0) * flutter * exp(-t * 3.0) * 0.35
	return out


## A restrained heartbeat: lub-dub, then quiet. Loops.
static func _heartbeat(seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(seconds * RATE))
	for beat: Array in [[0.0, 0.9], [0.22, 0.6]]:
		var thump := _thump(0.18, 52.0, 16.0, float(beat[1]))
		var at := int(float(beat[0]) * RATE)
		for i in thump.size():
			if at + i < out.size():
				out[at + i] += thump[i]
	return out


## A quiet street: a low hum of distant traffic and the odd chirp. Loops.
static func _ambience(rng: RandomNumberGenerator, seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(seconds * RATE))
	var last := 0.0
	for i in out.size():
		var t := float(i) / RATE
		last = lerpf(rng.randf_range(-1.0, 1.0), last, 0.985)
		out[i] = last * 0.9 + sin(TAU * 60.0 * t) * 0.02
	for chirp in 3:
		var at := rng.randf_range(0.2, seconds - 0.4)
		var bird := _ring(0.08, rng.randf_range(2600.0, 3600.0), 35.0, 0.12)
		for i in bird.size():
			var j := int(at * RATE) + i
			if j < out.size():
				out[j] += bird[i]
	# Fade the ends together so the loop does not click.
	var fade := int(0.05 * RATE)
	for i in fade:
		var w := float(i) / fade
		out[i] *= w
		out[out.size() - 1 - i] *= w
	return out


static func _mix(parts: Array) -> PackedFloat32Array:
	var length := 0
	for part: PackedFloat32Array in parts:
		length = maxi(length, part.size())
	var out := PackedFloat32Array()
	out.resize(length)
	for part: PackedFloat32Array in parts:
		for i in part.size():
			out[i] += part[i]
	return out


static func _to_wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	return wav
