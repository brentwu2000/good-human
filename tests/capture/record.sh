#!/usr/bin/env bash
# P03-E12: records every brawl capture case with Godot's Movie Maker into
# build/captures/<case>.avi (405x720 portrait, 30 fps, normal presentation).
# Usage: tests/capture/record.sh [case ...]   (no arguments: every case)
# Needs a desktop session: Movie Maker renders, so it cannot run headless.
set -u
GODOT="${GODOT:-/c/Users/b/Downloads/Godot_v4.6.3-stable_win64.exe/Godot_v4.6.3-stable_win64_console.exe}"
cd "$(dirname "$0")/../.."
PROJECT="$(pwd -W 2>/dev/null || pwd)"
CASES="${*:-snap orbit_cw orbit_ccw behind_bark leash_pull critical win loss p02_snap banyan}"
mkdir -p build/captures
failed=0
for case in $CASES; do
	out="build/captures/$case.avi"
	rm -f "$out"
	timeout 300 "$GODOT" --path "$PROJECT" --write-movie "$PROJECT/$out" --fixed-fps 30 \
		--resolution 405x720 res://tests/capture/brawl_capture.tscn -- "$case" >/dev/null 2>&1
	if [ -s "$out" ]; then
		echo "recorded $out ($(du -h "$out" | cut -f1))"
	else
		echo "FAILED $case"
		failed=1
	fi
done
exit $failed
