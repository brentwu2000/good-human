extends "res://tests/test_case.gd"
## P0-003: Save / Load / Default, corrupt JSON must not crash.

const TEST_DIR: String = "user://tests"
const TEST_PATH: String = "user://tests/save_test.json"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var original_path := SaveManager.save_path
	SaveManager.save_path = TEST_PATH

	_test_missing_file_gives_default()
	_test_round_trip()
	_test_corrupt_json_falls_back()
	_test_wrong_root_type_falls_back()
	_test_partial_save_is_filled_and_typed()

	_cleanup()
	SaveManager.save_path = original_path
	SaveManager.reset_to_default()
	finish()


func _test_missing_file_gives_default() -> void:
	_cleanup()
	SaveManager.load_game()
	check_eq(SaveManager.data, SaveManager.default_data(), "missing file loads default")


func _test_round_trip() -> void:
	_cleanup()
	SaveManager.reset_to_default()
	SaveManager.data["stash"] = [{"item_id": "tennis_ball", "quantity": 2}]
	SaveManager.data["statistics"]["runs"] = 3
	check(SaveManager.save_game(), "save_game returns true")
	check(FileAccess.file_exists(TEST_PATH), "save file written")
	check(not FileAccess.file_exists(TEST_PATH + ".tmp"), "temp file replaced")

	# Saving again must overwrite the existing file.
	SaveManager.data["statistics"]["successful_extractions"] = 1
	check(SaveManager.save_game(), "second save_game overwrites existing file")

	SaveManager.reset_to_default()
	SaveManager.load_game()
	check_eq(SaveManager.data["version"], SaveManager.SAVE_VERSION, "version persisted")
	check_eq(SaveManager.data["statistics"]["runs"], 3, "runs persisted")
	check(SaveManager.data["statistics"]["runs"] is int, "runs restored as int")
	check_eq(SaveManager.data["statistics"]["successful_extractions"], 1, "second save persisted")
	var stash: Array = SaveManager.data["stash"]
	check_eq(stash.size(), 1, "stash persisted")
	check_eq(stash[0]["item_id"], "tennis_ball", "stash item id persisted")


func _test_corrupt_json_falls_back() -> void:
	_cleanup()
	_write_raw("{ this is not json")
	SaveManager.load_game()
	check_eq(SaveManager.data, SaveManager.default_data(), "corrupt JSON loads default")
	check(FileAccess.file_exists(TEST_PATH + ".corrupt"), "corrupt file kept aside")
	check(not FileAccess.file_exists(TEST_PATH), "corrupt file moved away from save path")


func _test_wrong_root_type_falls_back() -> void:
	_cleanup()
	_write_raw("[1, 2, 3]")
	SaveManager.load_game()
	check_eq(SaveManager.data, SaveManager.default_data(), "non-object JSON loads default")


func _test_partial_save_is_filled_and_typed() -> void:
	_cleanup()
	_write_raw('{"version": 1, "stash": "oops", "statistics": {"runs": 2.0, "successful_extractions": -5}}')
	SaveManager.load_game()
	check_eq(SaveManager.data["stash"], [], "invalid stash replaced by default")
	check_eq(SaveManager.data["dog"], {}, "missing dog filled")
	check_eq(SaveManager.data["statistics"]["runs"], 2, "float runs converted")
	check_eq(SaveManager.data["statistics"]["successful_extractions"], 0, "negative stat clamped")


func _write_raw(text: String) -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _cleanup() -> void:
	for path: String in [TEST_PATH, TEST_PATH + ".tmp", TEST_PATH + ".corrupt"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
