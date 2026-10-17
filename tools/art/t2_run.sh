#!/usr/bin/env bash
# Trellis2 texture pass for one character (Claude, 2026-10-17). See docs/06_art/TRELLIS2_TEXTURE_PASS_2026-10-17.md.
#   bash tools/art/t2_run.sh tools/art/t2_configs/<id>.json [out.glb]
# Work files: build/t2/<id>/ (gitignored). The Trellis2 colours (colours.npz) are reused when
# present; delete it to regenerate. Needs the Modly Trellis2 extension in C:/Users/b/tools/modly.
set -euo pipefail
CFG="$1"
ID=$(python -c "import json,sys;print(json.load(open(sys.argv[1],encoding='utf-8'))['id'])" "$CFG")
OUT="${2:-$(python -c "import json,sys;print(json.load(open(sys.argv[1],encoding='utf-8'))['out'])" "$CFG")}"
CFGW=$(cd "$(dirname "$CFG")" && pwd -W)/$(basename "$CFG")
W="build/t2/$ID"; mkdir -p "$W"; WW=$(cd "$W" && pwd -W)
BL="/c/Program Files/Blender Foundation/Blender 5.2/blender.exe"
T2PY="${T2PY:-/c/Users/b/tools/modly/data/extensions/trellis2/venv/Scripts/python.exe}"
get() { python -c "import json,sys;print(json.load(open(sys.argv[1],encoding='utf-8')).get(sys.argv[2],''))" "$CFG" "$1"; }

# "src": "git:<rev>:<path>" = that file at that revision (the version before a pass overwrote it).
SRC=$(get src)
if [[ "$SRC" == git:* ]]; then
  REV=${SRC#git:}; REV=${REV%%:*}; P=${SRC#git:*:}
  [ -f "$W/src.glb" ] || git show "$REV:$P" > "$W/src.glb"
fi
[ -f "$W/hi.blend" ] || "$BL" -b --factory-startup --python tools/art/t2_prep.py -- "$CFGW" "$WW" 2>&1 | grep -E "^T2_|Error" | grep -v -E "GPUShader|gpu module" || true
[ -f "$W/hi.glb" ] || { echo "prep failed" >&2; exit 1; }
# Colour sets: one front/back run, or the config's "runs" (dogs: + a side run).
RUNS=$(python -c "
import json,sys
c=json.load(open(sys.argv[1],encoding='utf-8'))
runs=c.get('runs') or [{'name':'','front':c['front'],'back':c.get('back',''),'facing':'front'}]
for r in runs: print('|'.join([r['name'],r['front'],r.get('back',''),r.get('facing','front')]))" "$CFG")
SETS=""
while IFS='|' read -r NAME FRONT BACK FACING; do
  NPZ="colours${NAME:+_$NAME}.npz"
  if [ ! -f "$W/$NPZ" ]; then
    ARGS=(front="$FRONT"); [ -n "$BACK" ] && ARGS+=(back="$BACK")
    PYTHONIOENCODING=utf-8 PYTHONUNBUFFERED=1 "$T2PY" tools/art/t2_texture.py "$WW/hi.glb" "$WW/$NPZ" "${ARGS[@]}" --facing "$FACING" > "$W/texture${NAME:+_$NAME}.log" 2>&1
    grep "\[t2\]" "$W/texture${NAME:+_$NAME}.log"
  fi
  SETS="${SETS:+$SETS,}$WW/$NPZ@$FACING"
done <<< "$RUNS"
"$BL" -b "$WW/hi.blend" --python tools/art/t2_bake.py -- "$CFGW" "$SETS" "$WW" 2>&1 | grep -E "^T2_|Error" | grep -v -E "GPUShader|gpu module" || true
"$BL" -b --factory-startup --python tools/art/t2_finish.py -- "$CFGW" "$WW" "$OUT" 2>&1 | grep -E "^T2_|Error" | grep -v -E "GPUShader|gpu module" || true
# Arm joints refit onto the character's own arms (gym coach; LESSONS 6.30).
if [ "$(get refit_arms)" = "True" ] && [ -f "$OUT" ]; then
  "$BL" -b --factory-startup --python tools/art/refit_arms.py -- "$OUT" "$OUT" 2>&1 | grep -E "^REFIT|Error" | grep -v -E "GPUShader|gpu module" || true
fi
[ -f "$OUT" ] && echo "T2_DONE $ID -> $OUT"
