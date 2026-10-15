"""Market auntie r3 (Claude, 2026-10-15): free the arms from the body below the
armpit, so a raised arm (guard, jab) no longer drags strips of blouse and skirt.

  blender -b --factory-startup --python tools/art/auntie_r3_arms.py -- <in.blend> <out.blend>

The generated mesh is one surface: the hanging arm and the torso side share faces
from the armpit down to the wrist. Each vertex is arm or body by its dominant bone;
faces joining the two below the armpit are removed. Both openings are closed
(arm inner side, body side) with UVs copied from the same vertex's existing
corners, so the fill shows the neighbouring colour. Above the armpit the shoulder
stays one surface. Each side is checked: closed boundary loops counted before/after.
"""
import json
import os
import sys

import bmesh
import bpy
import numpy as np

src, out = sys.argv[sys.argv.index("--") + 1:][:2]
bpy.ops.wm.open_mainfile(filepath=os.path.abspath(src))
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
body = bpy.data.objects["Character"]
aw, bw_ = arm.matrix_world, body.matrix_world
FAM = ("upperarm", "lowerarm", "hand", "thumb", "index", "middle", "ring", "pinky")
ARMPIT_DROP = 0.075   # below the shoulder joint (m) where arm and body part
report = {}

bm = bmesh.new()
bm.from_mesh(body.data)
deform = bm.verts.layers.deform.verify()
uvl = bm.loops.layers.uv.active
gname = {g.index: g.name for g in body.vertex_groups}


def side_of(v):
    w = v[deform]
    if not w:
        return None
    g = max(w.items(), key=lambda kv: kv[1])[0]
    n = gname[g]
    if n.split("_")[0] in FAM:
        return n[-1]
    return "b"


# The glTF mesh is split at every UV seam (thousands of open edges): weld first so
# a cut opening is one loop. UVs and colours are per corner and survive the weld.
n_before = len(bm.verts)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
report["welded_vertices"] = n_before - len(bm.verts)
tag = {v: side_of(v) for v in bm.verts}
was_open = {e for e in bm.edges if e.is_boundary}
boundary_before = len(was_open)
dead = []
for s in "lr":
    pit = (aw @ arm.data.bones[f"upperarm_{s}"].head_local).z - ARMPIT_DROP
    n = 0
    for f in bm.faces:
        sides = {tag[v] for v in f.verts}
        if s in sides and "b" in sides and max((bw_ @ v.co).z for v in f.verts) < pit:
            dead.append(f)
            n += 1
    report[s] = {"armpit_z": round(pit, 3), "bridge_faces": n}
# Past the wrist plane the hand is new geometry (auntie_r3_hands): any old arm
# surface still there is a mitten/garment leftover (thin flaps around the wrist).
# The new hand faces are told apart by their bones: they carry finger/hand weights.
leftover = 0
for s in "lr":
    wrist = aw @ arm.data.bones[f"hand_{s}"].head_local
    axis = (wrist - aw @ arm.data.bones[f"lowerarm_{s}"].head_local).normalized()
    for f in bm.faces:
        if any(tag[v] != s for v in f.verts):
            continue
        if any(gname[g].split("_")[0] in FAM[2:] for v in f.verts for g in v[deform].keys()):
            continue   # the new hand
        c = bw_ @ f.calc_center_median()
        if (c - wrist).dot(axis) > 0.005:
            dead.append(f)
            leftover += 1
report["wrist_leftover_faces"] = leftover
dead = list(set(dead))
# Below the armpit each side keeps only its own bones: torso vertices drop their
# arm weights (they stretched into strips toward a raised arm), arm vertices drop
# torso weights. Above the armpit the shoulder blend stays.
cleaned = {"body": 0, "arm": 0}
for v in bm.verts:
    t = tag[v]
    w = v[deform]
    if not w or t is None:
        continue
    z = (bw_ @ v.co).z
    for s in "lr":
        pit = report[s]["armpit_z"]
        if z >= pit:
            continue
        mine = [g for g in w.keys() if gname[g].split("_")[0] in FAM and gname[g].endswith("_" + s)]
        if t == "b" and mine:
            moved = sum(w[g] for g in mine)
            for g in mine:
                del w[g]
            if w:
                k = 1.0 / max(sum(w.values()), 1e-6)
                for g in list(w.keys()):
                    w[g] *= k
            cleaned["body"] += 1
        elif t == s:
            other = [g for g in w.keys() if g not in mine]
            if other:
                for g in other:
                    del w[g]
                k = 1.0 / max(sum(w.values()), 1e-6)
                for g in list(w.keys()):
                    w[g] *= k
                cleaned["arm"] += 1
report["weights_cleaned"] = cleaned
bmesh.ops.delete(bm, geom=dead, context="FACES_ONLY")
bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
opened = [e for e in bm.edges if e.is_boundary and e not in was_open]
# Close each new opening separately: arm-side edges with arm-side edges, body with body.
groups = {"l": [], "r": [], "b": []}
for e in opened:
    t = {tag.get(v) for v in e.verts}
    key = "b" if t == {"b"} else ("l" if "l" in t else ("r" if "r" in t else None))
    if key:
        groups[key].append(e)
filled = 0
for key, edges in groups.items():
    if not edges:
        continue
    res = bmesh.ops.holes_fill(bm, edges=edges, sides=0)
    for f in res["faces"]:
        filled += 1
        f.smooth = True
        for lp in f.loops:
            other = next((l2 for l2 in lp.vert.link_loops if l2.face is not f and l2.face not in res["faces"]), None)
            if other is not None:
                lp[uvl].uv = other[uvl].uv.copy()
# (holes_fill winds the new faces to match their neighbours; no global recalc on this open AI mesh)
report["faces_removed"] = len(dead)
report["fill_faces"] = filled
report["open_edges_before"] = boundary_before
report["open_edges_after"] = sum(1 for e in bm.edges if e.is_boundary)
bm.to_mesh(body.data)
bm.free()
body.data.update()
bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(out))
json.dump(report, open(os.path.splitext(out)[0] + "_arms.json", "w"), indent=1)
print("AUNTIE_ARMS_OK", json.dumps(report))
