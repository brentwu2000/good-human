extends Node
## Minimal headless test base. Run a test scene with:
##   godot --headless --path <project> res://tests/<name>_test.tscn
## Exit code 0 = pass, 1 = fail.

var _failures: int = 0
var _checks: int = 0


func check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	check(actual == expected, "%s (expected %s, got %s)" % [message, expected, actual])


func finish() -> void:
	var name_text: String = (get_script() as Script).resource_path.get_file()
	if _checks == 0:
		_failures += 1
		push_error("FAIL: no checks ran")
	if _failures == 0:
		print("PASS %s: %d checks" % [name_text, _checks])
	else:
		print("FAILED %s: %d/%d checks failed" % [name_text, _failures, _checks])
	get_tree().quit(1 if _failures > 0 else 0)
