#!/usr/bin/env bash
# Texturing v5 smoke test: stages A-C on the grandma; checks reports exist,
# the region map covers every face, and the source file is unchanged.
set -eu
cd "$(dirname "$0")/../.."
B="${BLENDER:-/c/Program Files/Blender Foundation/Blender 5.2/blender.exe}"
SRC=art_pipeline/assets/source/grandma.glb
[ -f "$SRC" ] || cp assets/characters/human/models/ai_grandma/grandma.glb "$SRC"
before=$(sha256sum "$SRC" | cut -d' ' -f1)
OUT=art_pipeline/assets/work/smoke; mkdir -p "$OUT"
"$B" -b --factory-startup --python art_pipeline/scripts/inspect_asset.py -- --input "$SRC" --output "$OUT/inspection.json" --size 128 >/dev/null 2>&1
"$B" -b --factory-startup --python art_pipeline/scripts/segment_regions.py -- --config art_pipeline/config/characters/grandma.json --work "$OUT/B.blend" --report "$OUT" --size 128 >/dev/null 2>&1
"$B" -b --factory-startup --python art_pipeline/scripts/assign_materials.py -- --config art_pipeline/config/characters/grandma.json --regions "$OUT/B.blend" --work "$OUT/C.blend" --report "$OUT" --size 128 >/dev/null 2>&1
python - "$OUT" <<'PY'
import json, sys
o = sys.argv[1]
ins = json.load(open(f"{o}/inspection.json"))
assert ins["meshes"] and all("uv" in m for m in ins["meshes"]), "inspection incomplete"
rm = json.load(open(f"{o}/region_map.json"))
for name, obj in rm["objects"].items():
    counted = sum(r["faces"] for r in obj["regions"].values()) + len(obj["needs_review"])
    assert counted == obj["faces"], f"{name}: {counted} of {obj['faces']} faces accounted for"
assert rm["status"].startswith(("NEEDS_REVIEW", "CANDIDATE")), rm["status"]
mt = json.load(open(f"{o}/materials.json"))
assert all(k.startswith("M_") for k in mt["materials"]), "material names"
print("SMOKE_PASS", rm["status"], rm["needs_review_faces"], "review faces")
PY
after=$(sha256sum "$SRC" | cut -d' ' -f1)
[ "$before" = "$after" ] && echo "SOURCE_UNCHANGED" || { echo "SOURCE_CHANGED"; exit 1; }
