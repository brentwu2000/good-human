extends Node
## Owns all reads/writes of the persistent save file.
## Other scripts must not use FileAccess on the save directly.

signal saved
signal loaded

## 1: Sprints 01-05. 2: Sprint 06, one dog and one human per save (`pair`).
const SAVE_VERSION: int = 2
const DEFAULT_SAVE_PATH: String = "user://save.json"

## Overridable so tests can use an isolated file.
var save_path: String = DEFAULT_SAVE_PATH
var data: Dictionary = default_data()


static func default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"stash": [],
		"dog": {},
		"human": {},
		"statistics": {
			"runs": 0,
			"successful_extractions": 0,
		},
	}


## Loads the save. Never crashes: a missing file yields defaults, and an
## unreadable/corrupt file is kept aside as `<path>.corrupt` before falling back.
func load_game() -> void:
	if not FileAccess.file_exists(save_path):
		data = default_data()
		loaded.emit()
		return

	var json := JSON.new()
	var err := json.parse(FileAccess.get_file_as_string(save_path))
	if err == OK and json.data is Dictionary:
		data = _sanitize(json.data)
	else:
		push_warning("SaveManager: save at %s is corrupt; using defaults." % save_path)
		_quarantine_corrupt_file()
		data = default_data()
	loaded.emit()


## Writes to a temp file first, then replaces the save, so a crash mid-write
## cannot destroy the previous save.
func save_game() -> bool:
	data["version"] = SAVE_VERSION
	var tmp_path := save_path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot write %s (%s)" % [tmp_path, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	var err := DirAccess.rename_absolute(tmp_path, save_path)
	if err != OK:
		push_error("SaveManager: cannot replace %s (%s)" % [save_path, error_string(err)])
		return false
	saved.emit()
	return true


func reset_to_default() -> void:
	data = default_data()


## Brings a save written by an older build up to SAVE_VERSION. Returns a new
## dictionary; `raw` is left as it was.
static func migrate(raw: Dictionary, from_version: int) -> Dictionary:
	var data := raw.duplicate(true)
	if from_version < 2:
		# v1 -> v2 (Sprint 06): a save that already walked keeps its dog and
		# owner as the classic pair instead of starting over at the shelter.
		# A v1 save that never walked has nothing to keep and opens at the
		# shelter like a new game.
		var stats: Variant = data.get("statistics")
		var runs := int(stats.get("runs", 0)) if stats is Dictionary and (stats.get("runs") is float or stats.get("runs") is int) else 0
		if not data.get("pair") is Dictionary and runs > 0:
			data["pair"] = PairState.classic().serialize()
	data["version"] = SAVE_VERSION
	return data


func _quarantine_corrupt_file() -> void:
	var corrupt_path := save_path + ".corrupt"
	if FileAccess.file_exists(corrupt_path):
		DirAccess.remove_absolute(corrupt_path)
	DirAccess.rename_absolute(save_path, corrupt_path)


## Fills missing keys from defaults and restores types lost by JSON
## (all JSON numbers parse as float), migrating older versions first.
func _sanitize(raw: Dictionary) -> Dictionary:
	var result := default_data()
	var version := int(raw.get("version", 1)) if (raw.get("version") is float or raw.get("version") is int) else 1
	if version > SAVE_VERSION:
		push_warning("SaveManager: save version %d is newer than this build (%d); reading what it can." % [version, SAVE_VERSION])
	raw = migrate(raw, version)
	if raw.get("stash") is Array:
		result["stash"] = raw["stash"]
	if raw.get("dog") is Dictionary:
		result["dog"] = raw["dog"]
	if raw.get("human") is Dictionary:
		result["human"] = raw["human"]
	# Sprint 06: the save's one pair (absent until the adoption).
	if raw.get("pair") is Dictionary:
		result["pair"] = raw["pair"]

	var raw_stats: Variant = raw.get("statistics")
	if raw_stats is Dictionary:
		var stats: Dictionary = result["statistics"]
		for key: String in stats.keys():
			var value: Variant = raw_stats.get(key)
			if value is float or value is int:
				stats[key] = maxi(int(value), 0)
	return result
