#!/usr/bin/env bash
# S05-13: the P-04 baseline (collision, combat readability, dog POV) plus what
# Sprint 05 added on top of it. Run after any change that touches the walk.
# Usage: tests/run_p04_regression.sh   (GODOT=/path/to/godot_console.exe to override)
set -u
GODOT="${GODOT:-/c/Users/b/Downloads/Godot_v4.6.3-stable_win64.exe/Godot_v4.6.3-stable_win64_console.exe}"
cd "$(dirname "$0")/.."
PROJECT="$(pwd -W 2>/dev/null || pwd)"
timeout 180 "$GODOT" --headless --path "$PROJECT" --import >/dev/null 2>&1

SCENES=(
	physical_presence_test      # P04-01 / P04-08: no penetration, sliding, push-out
	combat_spacing_test         # P04-02 footwork and spacing
	combat_contact_test         # P04-03..07 phases, contact, hit reactions
	combat_motion_3d_test       # motion states read without text
	combat_feedback_test        # P04-11 no-HUD readability, owner condition
	dog_pov_presence_test       # P04-09 dog POV presence
	dog_agency_3d_test          # P04-10 bark / pull
	s05_presence_regression_test  # Sprint 05 reactions and props stay clear
)
failed=0
for name in "${SCENES[@]}"; do
	output="$(timeout 120 "$GODOT" --headless --path "$PROJECT" "res://tests/$name.tscn" 2>&1)"
	code=$?
	echo "$output" | grep -E "^(PASS|FAILED)|FAIL:|SCRIPT ERROR"
	if [ $code -ne 0 ] || echo "$output" | grep -q "SCRIPT ERROR"; then
		echo "  -> $name exited with $code"
		failed=1
	fi
done
exit $failed
