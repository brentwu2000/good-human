"""Texturing v5, the stage-B gate: a person approves the NEEDS_REVIEW faces.

  blender -b --factory-startup --python art_pipeline/scripts/approve_regions.py -- \
      --regions art_pipeline/assets/work/grandma_B_regions.blend \
      --report art_pipeline/reports/grandma \
      --work art_pipeline/assets/work/grandma_B_approved.blend \
      --approver owner --decision accept_candidates [--override face=region ...]

`accept_candidates`: each review face takes the candidate recorded in
region_map.json (faces with no candidate stay 0 and the gate fails).
`--override 123=hair`: a person's correction for one face (repeatable).
Writes the approved checkpoint and `approval.json` (who, when, decision,
faces changed). Without an approval file the later stages refuse to run.
"""
import argparse
import datetime
import json
import os
import sys

import bpy
import numpy as np


def args():
    argv = sys.argv[sys.argv.index("--") + 1:]
    p = argparse.ArgumentParser()
    for k in ("regions", "report", "work", "approver", "decision"):
        p.add_argument("--" + k, required=True)
    p.add_argument("--override", action="append", default=[])
    return p.parse_args(argv)


def main():
    a = args()
    rm = json.load(open(os.path.join(a.report, "region_map.json"), encoding="utf-8"))
    bpy.ops.wm.open_mainfile(filepath=os.path.abspath(a.regions))
    changed, unresolved = 0, []
    overrides = {}
    for o in a.override:
        f, name = o.split("=")
        overrides[int(f)] = name
    for name, obj in rm["objects"].items():
        ob = bpy.data.objects[name]
        ids = {k: v["id"] for k, v in obj["regions"].items()}
        attr = ob.data.attributes["region_id"]
        rid = np.zeros(len(ob.data.polygons), dtype=np.int32)
        attr.data.foreach_get("value", rid)
        for item in obj["needs_review"]:
            fi = item["face"]
            target = overrides.get(fi) if name == "Character" else None
            target = target or (item["candidate"] if a.decision == "accept_candidates" else None)
            if target:
                rid[fi] = ids[target]
                changed += 1
            else:
                unresolved.append({"object": name, "face": fi})
        attr.data.foreach_set("value", rid)
        ob.data.update()
    bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(a.work))
    ok = not unresolved
    rep = {"gate": "stage_B_regions", "approver": a.approver, "decision": a.decision,
           "date": datetime.datetime.now().isoformat(timespec="seconds"),
           "faces_changed": changed, "overrides": a.override, "unresolved": unresolved,
           "status": "APPROVED" if ok else "UNRESOLVED", "checkpoint": os.path.abspath(a.work)}
    json.dump(rep, open(os.path.join(a.report, "approval.json"), "w", encoding="utf-8"), indent=1)
    print("APPROVE_OK" if ok else "APPROVE_UNRESOLVED", changed, len(unresolved))


if __name__ == "__main__":
    main()
