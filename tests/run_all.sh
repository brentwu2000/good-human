#!/usr/bin/env bash
# Runs every tests/*_test.tscn headless. Usage: tests/run_all.sh
# Override the editor binary with GODOT=/path/to/godot_console.exe
set -u
GODOT="${GODOT:-/c/Users/b/Downloads/Godot_v4.6.3-stable_win64.exe/Godot_v4.6.3-stable_win64_console.exe}"
cd "$(dirname "$0")/.."
PROJECT="$(pwd -W 2>/dev/null || pwd)"

# Import first so class_name cache and .uid files exist on fresh clones.
timeout 180 "$GODOT" --headless --path "$PROJECT" --import >/dev/null 2>&1

failed=0
for scene in tests/*_test.tscn; do
	# A GDScript parse error leaves Godot hanging, so a timeout counts as failure.
	output="$(timeout 60 "$GODOT" --headless --path "$PROJECT" "res://$scene" 2>&1)"
	code=$?
	echo "$output" | grep -E "^(PASS|FAILED)|FAIL:|SCRIPT ERROR"
	if [ $code -ne 0 ] || echo "$output" | grep -q "SCRIPT ERROR"; then
		echo "  -> $scene exited with $code"
		failed=1
	fi
done
exit $failed
