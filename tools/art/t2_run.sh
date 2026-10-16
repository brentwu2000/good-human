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

[ -f "$W/hi.blend" ] || "$BL" -b --factory-startup --python tools/art/t2_prep.py -- "$CFGW" "$WW" 2>&1 | grep -E "^T2_|Error" | grep -v -E "GPUShader|gpu module" || true
[ -f "$W/hi.glb" ] || { echo "prep failed" >&2; exit 1; }
if [ ! -f "$W/colours.npz" ]; then
  BACK=$(get back); ARGS=(front="$(get front)"); [ -n "$BACK" ] && ARGS+=(back="$BACK")
  PYTHONIOENCODING=utf-8 PYTHONUNBUFFERED=1 "$T2PY" tools/art/t2_texture.py "$WW/hi.glb" "$WW/colours.npz" "${ARGS[@]}" > "$W/texture.log" 2>&1
  grep "\[t2\]" "$W/texture.log"
fi
"$BL" -b "$WW/hi.blend" --python tools/art/t2_bake.py -- "$CFGW" "$WW/colours.npz" "$WW" 2>&1 | grep -E "^T2_|Error" | grep -v -E "GPUShader|gpu module" || true
"$BL" -b --factory-startup --python tools/art/t2_finish.py -- "$CFGW" "$WW" "$OUT" 2>&1 | grep -E "^T2_|Error" | grep -v -E "GPUShader|gpu module" || true
[ -f "$OUT" ] && echo "T2_DONE $ID -> $OUT"
