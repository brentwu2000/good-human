"""Market auntie r3 (Claude, 2026-10-15): chubby stylised hands in place of the
generator's mittens.

  blender -b --factory-startup --python tools/art/auntie_r3_hands.py -- build/market_auntie_refine_r2/04_skin_refined.blend <out.blend>

Why the bones move: the rig was fitted from the owner, and her hand bones sit
~7 cm above the mesh's real wrist (the mitten hangs from 0.69 to 0.50 m). The
shared fight/m2m/relaxed libraries key only the pelvis position, so a bone's
place is the model's own rest: moving hand + finger bones down to the mesh wrist
is safe for every clip (the model's own clips are re-exported against the new rest).

Steps per side: find the mesh wrist (narrowest forearm section before the fist) →
move the hand/finger bones there (fingers shortened and drawn together: chubby,
not the owner's slender spread) → cut the mitten inside the arm tube only and close
the wrist → forearm skin past the old wrist rides the forearm, not the hand → build
the hand on the bones (palm + one tube per finger, each segment skinned 1:1 to its
bone, so fists close). Colour: UVs on the forearm's skin texel (no extra material).
"""
import json
import math
import os
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Vector

src, out = sys.argv[sys.argv.index("--") + 1:][:2]
# Start from Codex's r2 checkpoint (.blend), not the GLB: a mesh re-imported from
# the GLB exports its towel colour attribute as plain white (Blender 5.2 glTF).
if src.endswith(".blend"):
    bpy.ops.wm.open_mainfile(filepath=os.path.abspath(src))
else:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=src)
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
body = bpy.data.objects["Character"]
aw, bw_ = arm.matrix_world, body.matrix_world
FINGERS = ("thumb", "index", "middle", "ring", "pinky")
FINGER_SCALE = 0.78     # chain length (chubby, short)
GATHER = 0.35           # finger bases drawn toward the knuckle centre
RADIUS = {"thumb": 0.0175, "index": 0.0158, "middle": 0.0162, "ring": 0.0155, "pinky": 0.0138}   # thick: her forearms are thick
SIDES = 10
ELBOW_FRAC = 0.60
HAND_LEN = 0.125       # wrist to fingertip, chubby (palm ~6 cm, fingers ~4.5 cm)
report = {}


def arm_chain(name, s):
    return name in (f"lowerarm_{s}", f"hand_{s}") or (name.endswith("_" + s) and name.split("_")[0] in FINGERS)


def hand_owned(name, s):
    return name == f"hand_{s}" or (name.endswith("_" + s) and name.split("_")[0] in FINGERS)


names = {g.index: g.name for g in body.vertex_groups}
co = np.array([bw_ @ v.co for v in body.data.vertices])


def weights(v):
    return {names[g.group]: g.weight for g in v.groups}


# ---- 1. mesh wrist per side.
wrist_of = {}
for s in "lr":
    elbow = aw @ arm.data.bones[f"lowerarm_{s}"].head_local
    # The bone line elbow → old hand tip, extended to where the mitten ends; only
    # vertices near it count (the right hand has a garment strip fused to it).
    old_tip = aw @ arm.data.bones[f"middle_03_{s}"].tail_local
    line = (old_tip - elbow).normalized()
    idx = [v.index for v in body.data.vertices
           if sum(w for n, w in weights(v).items() if arm_chain(n, s)) > 0.6]
    pts = co[idx]
    tl = (pts - np.array(elbow)) @ np.array(line)
    rl = np.sqrt((((pts - np.array(elbow)) - np.outer(tl, np.array(line))) ** 2).sum(1))
    pts = pts[(rl < 0.10) & (tl > 0)]
    tip = pts[np.argmax((pts - np.array(elbow)) @ np.array(line))]
    axis = (Vector(tip) - elbow).normalized()
    t = (pts - np.array(elbow)) @ np.array(axis)
    L = t.max()
    radial = pts - np.array(elbow) - np.outer(t, np.array(axis))
    r = np.sqrt((radial ** 2).sum(1))
    # Forearm and fist are one even sausage (no narrowing to find): the wrist is
    # HAND_LEN up from the end of the fist.
    tw = L - HAND_LEN
    m = np.abs(t - tw) < 0.012
    rw = float(np.clip(np.percentile(r[m], 75) if m.sum() > 5 else 0.055, 0.04, 0.07))
    centre = Vector(pts[m].mean(0)) if m.sum() > 5 else elbow + axis * tw
    wrist_of[s] = (centre, axis, rw, elbow, L)
    report[s] = {"mesh_wrist": [round(x, 4) for x in centre], "wrist_radius": round(float(rw), 4),
                 "old_bone_wrist": [round(x, 4) for x in (aw @ arm.data.bones[f"hand_{s}"].head_local)]}

# ---- 2. move the hand rig (edit bones, armature space).
bpy.context.view_layer.objects.active = arm
arm.select_set(True)
bpy.ops.object.mode_set(mode="EDIT")
eb = arm.data.edit_bones
inv = aw.inverted()
for s in "lr":
    centre, axis, rw, elbow, L = wrist_of[s]
    new_w = inv @ centre
    hand = eb[f"hand_{s}"]
    delta = new_w - hand.head
    old_hand_dir = (hand.tail - hand.head)
    # Rotate the whole hand rig so the hand bone follows the mesh forearm axis.
    a_local = (inv.to_3x3() @ axis).normalized()
    rot = old_hand_dir.normalized().rotation_difference(a_local)
    pivot = hand.head.copy()
    moved = [b for b in eb if hand_owned(b.name, s)]
    for b in moved:
        b.head = new_w + rot @ (b.head - pivot)
        b.tail = new_w + rot @ (b.tail - pivot)
    knuckles = [eb[f"{f}_01_{s}"].head.copy() for f in FINGERS[1:]]
    kc = sum(knuckles, Vector()) / 4
    for f in FINGERS:
        chain = [eb[f"{f}_0{i}_{s}"] for i in (1, 2, 3)]
        base = chain[0].head.copy()
        g = Vector() if f == "thumb" else (kc - base) * GATHER
        for b in chain:
            b.head = base + g + (b.head - base) * FINGER_SCALE
            b.tail = base + g + (b.tail - base) * FINGER_SCALE
    # Uniform scale about the wrist so wrist → middle fingertip is HAND_LEN.
    tipv = eb[f"middle_03_{s}"].tail
    k = HAND_LEN / max((tipv - new_w).length, 1e-6)
    for b in moved:
        b.head = new_w + (b.head - new_w) * k
        b.tail = new_w + (b.tail - new_w) * k
    low = eb[f"lowerarm_{s}"]
    if low.tail != new_w:
        low.tail = new_w
    # Elbow: the owner-fitted joint sat at 38 % of her arm, inside the sleeve (the
    # sleeve hem is at ~65 %), so the sleeve broke into shards on a bent arm. It
    # goes to ELBOW_FRAC of shoulder → wrist, just below the hem.
    up = eb[f"upperarm_{s}"]
    elbow = up.head + (new_w - up.head) * ELBOW_FRAC
    up.tail = elbow
    low.head = elbow
bpy.ops.object.mode_set(mode="OBJECT")


def bpos(name, tail=False):
    b = arm.data.bones[name]
    return aw @ (b.tail_local if tail else b.head_local)


# ---- 4. skin texel: the most common skin-like colour on the bare forearm.
me = body.data
img = next(n.image for s_ in body.material_slots if s_.material for n in s_.material.node_tree.nodes
           if n.type == "TEX_IMAGE" and n.image and "rough" not in n.image.name.lower())
W, H = img.size
px = np.array(img.pixels[:], dtype=np.float32).reshape(H, W, img.channels)[..., :3]
uvl = me.uv_layers.active.data
names = {g.index: g.name for g in body.vertex_groups}
target = np.array([0.97, 0.78, 0.63])   # sheet skin; Image.pixels of a byte PNG are sRGB
best, best_d = None, 9.0
for p in me.polygons:
    for li in p.loop_indices:
        u = uvl[li].uv
        c = px[min(int(u[1] * H), H - 1), min(int(u[0] * W), W - 1)]
        d = float(np.abs(c - target).sum())
        if d < best_d:
            # Only a texel inside a uniform patch (its 5x5 neighbourhood agrees).
            y, x = min(int(u[1] * H), H - 1), min(int(u[0] * W), W - 1)
            patch = px[max(y - 2, 0):y + 3, max(x - 2, 0):x + 3].reshape(-1, 3)
            if np.abs(patch - c).sum(1).max() < 0.03:
                best, best_d = (float(u[0]), float(u[1])), d
skin_uv = best
report["skin_uv"] = skin_uv
report["skin_texel_srgb"] = [float(x) for x in px[min(int(skin_uv[1] * H), H - 1), min(int(skin_uv[0] * W), W - 1)]]



# ---- 3. cut the mitten inside the arm tube; forearm skin rides the forearm.
bm = bmesh.new()
bm.from_mesh(body.data)
deform = bm.verts.layers.deform.verify()
gid = {g.name: g.index for g in body.vertex_groups}
gname = {i: n for n, i in gid.items()}
reweighted = 0
removed = 0
wrist_sec = {}
for s in "lr":
    centre, axis, rw, elbow, L = wrist_of[s]
    # Forearm skin up to the wrist rides the forearm, not the hand.
    for v in bm.verts:
        w = v[deform]
        if sum(x for g, x in w.items() if arm_chain(gname[g], s)) < 0.3:
            continue
        if (bw_ @ v.co - centre).dot(axis) <= 0.0:
            hw = sum(x for g, x in w.items() if hand_owned(gname[g], s))
            if hw > 0:
                for g in [g for g in list(w.keys()) if hand_owned(gname[g], s)]:
                    del w[g]
                lg = gid[f"lowerarm_{s}"]
                w[lg] = w.get(lg, 0.0) + hw
                reweighted += 1

    # The arm's own faces near its axis, from a little above the wrist down.
    def on_arm(f):
        ws = [f_v[deform] for f_v in f.verts]
        cw = np.mean([sum(x for g, x in w.items() if arm_chain(gname[g], s)) for w in ws])
        c = bw_ @ f.calc_center_median()
        t = (c - centre).dot(axis)
        rad = ((c - centre) - axis * t).length
        return cw > 0.3 and t > -0.04 and rad < 0.11
    faces = [f for f in bm.faces if on_arm(f)]
    geom = list({v for f in faces for v in f.verts}) + list({e for f in faces for e in f.edges}) + faces
    n0 = len(bm.verts)
    res = bmesh.ops.bisect_plane(bm, geom=geom, dist=1e-5, plane_co=bw_.inverted() @ centre,
                                 plane_no=(bw_.inverted().to_3x3() @ axis).normalized(), clear_outer=True)
    removed += max(n0 - len(bm.verts), 0)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    # The AI forearm is not a clean tube: the cut leaves open fragments, not one
    # ring. Close what can be closed; the palm starts inside the stump and covers it.
    near = [e for e in bm.edges if e.is_boundary and
            min(abs((bw_ @ v.co - centre).dot(axis)) for v in e.verts) < 0.02 and
            min((bw_ @ v.co - centre).length for v in e.verts) < 0.12]
    if near:
        bmesh.ops.holes_fill(bm, edges=near, sides=0)
    # Wrist section (for the palm): the vertices the plane cut made (they lie on it).
    sec = [bw_ @ v.co for v in {v for e in res["geom_cut"] if isinstance(e, bmesh.types.BMEdge) and e.is_valid
                                for v in e.verts}
           if ((bw_ @ v.co - centre) - axis * (bw_ @ v.co - centre).dot(axis)).length < 0.11]
    if len(sec) >= 6:
        c = sum(sec, Vector()) / len(sec)
        wrist_sec[s] = (c - axis * (c - centre).dot(axis), [p - c - axis * (p - c).dot(axis) for p in sec])
# Whatever still rides the hand bones now is not hand (garment remnants fused to
# the mittens): it follows the pelvis, like the skirt it belongs to.
# Near the arm axis it is forearm; far from it, a skirt remnant (pelvis).
loose_hand = {"lowerarm": 0, "pelvis": 0}
for v in bm.verts:
    w = v[deform]
    for s in "lr":
        hw = sum(x for g, x in w.items() if hand_owned(gname[g], s))
        if hw <= 0:
            continue
        centre, axis, rw, elbow, L = wrist_of[s]
        p = bw_ @ v.co
        t = (p - centre).dot(axis)
        rad = ((p - centre) - axis * t).length
        to = f"lowerarm_{s}" if rad < 0.13 else "pelvis"
        for g in [g for g in list(w.keys()) if hand_owned(gname[g], s)]:
            del w[g]
        w[gid[to]] = w.get(gid[to], 0.0) + hw
        loose_hand["lowerarm" if to != "pelvis" else "pelvis"] += 1
report["remaining_hand_weights_moved"] = loose_hand
bm.to_mesh(body.data)
bm.free()
report["mitten_vertices_removed"] = removed
report["forearm_vertices_moved_to_lowerarm"] = reweighted

# ---- 5. hands on the bones.
hb = bmesh.new()
deform = hb.verts.layers.deform.verify()
uvlay = hb.loops.layers.uv.new(body.data.uv_layers.active.name)  # same name, or join drops it
gidx = {g.name: g.index for g in body.vertex_groups}
inv_b = bw_.inverted()


def frame(axis):
    up = Vector((0, 0, 1)) if abs(axis.z) < 0.9 else Vector((1, 0, 0))
    x = axis.cross(up).normalized()
    return x, axis.cross(x).normalized()


def ring_tube(points, sections, bones_w, caps=(True, True), cap_len=(0.6, 0.9)):
    """Rings through `points`; `sections[i]` = (rx, ry, xdir or None); weights per ring."""
    n_side = len(sections[0]) if isinstance(sections[0], list) else SIDES
    rings = []
    for i, p in enumerate(points):
        a = (points[min(i + 1, len(points) - 1)] - points[max(i - 1, 0)]).normalized()
        rx, ry, xd = sections[i]
        x, y = frame(a) if xd is None else (xd, a.cross(xd).normalized())
        if xd is not None:
            x = (xd - a * xd.dot(a)).normalized()
            y = a.cross(x).normalized()
        ring = []
        for k in range(n_side):
            t = 2 * math.pi * k / n_side
            v = hb.verts.new(inv_b @ (p + x * math.cos(t) * rx + y * math.sin(t) * ry))
            for b, w in bones_w[i].items():
                v[deform][gidx[b]] = w
            ring.append(v)
        rings.append(ring)
    for r0, r1 in zip(rings, rings[1:]):
        for k in range(n_side):
            hb.faces.new((r0[k], r0[(k + 1) % n_side], r1[(k + 1) % n_side], r1[k]))
    for ring, i, sign, flip, on in ((rings[0], 0, -1, True, caps[0]), (rings[-1], -1, 1, False, caps[1])):
        if not on:
            continue
        a = (points[1] - points[0]).normalized() if i == 0 else (points[-1] - points[-2]).normalized()
        r = max(sections[i][0], sections[i][1])
        c = hb.verts.new(inv_b @ (points[i] + a * sign * r * cap_len[0 if i == 0 else 1]))
        for b, w in bones_w[i].items():
            c[deform][gidx[b]] = w
        for k in range(n_side):
            f = (ring[k], ring[(k + 1) % n_side], c)
            hb.faces.new(f[::-1] if flip else f)


for s in "lr":
    centre, axis, rw, elbow, L = wrist_of[s]
    wrist = bpos(f"hand_{s}")
    kn = {f: bpos(f"{f}_01_{s}") for f in FINGERS[1:]}
    kc = sum(kn.values(), Vector()) / 4
    across = (kn["index"] - kn["pinky"]).normalized()
    half_w = (kn["index"] - kn["pinky"]).length * 0.5 + RADIUS["index"] * 1.1
    pal = kc - wrist
    Lp = pal.length
    a = pal.normalized()
    xdir = (across - a * across.dot(a)).normalized()
    # Palm: starts 1.5 cm inside the stump at the wrist's own section (measured
    # per axis), widens a little to the knuckles, rounded end. Chubby, not slender.
    ydir = a.cross(xdir).normalized()
    wc, rels = wrist_sec.get(s, (centre, []))
    if rels:
        sx = float(np.percentile([abs(r.dot(xdir)) for r in rels], 95))
        sy = float(np.percentile([abs(r.dot(ydir)) for r in rels], 95))
    else:
        sx, sy = rw, rw * 0.8
    sx, sy = max(sx, 0.025), max(sy, 0.02)
    report[s]["wrist_section_measured"] = [round(sx, 4), round(sy, 4), len(rels)]
    pw = max(sx * 1.05, half_w)
    pts = [wc - a * 0.015, wc + a * (0.2 * Lp), wc + a * (0.6 * Lp), wc + a * (0.95 * Lp), wc + a * (1.1 * Lp)]
    py = min(sy * 0.85, pw * 0.75)   # a hand is flatter than a wrist
    secs = [(sx * 0.98, sy * 0.98, xdir), (sx * 1.0, sy * 0.92, xdir), (pw, py, xdir),
            (pw * 1.0, py * 0.95, xdir), (pw * 0.88, py * 0.8, xdir)]
    wts = [{f"lowerarm_{s}": 0.5, f"hand_{s}": 0.5}, {f"hand_{s}": 1.0}, {f"hand_{s}": 1.0},
           {f"hand_{s}": 1.0}, {f"hand_{s}": 1.0}]
    ring_tube(pts, secs, wts, caps=(True, True), cap_len=(0.2, 0.55))
    report[s]["palm_section"] = [round(sx, 4), round(sy, 4), round(pw, 4)]
    for f in FINGERS:
        j = [bpos(f"{f}_01_{s}"), bpos(f"{f}_02_{s}"), bpos(f"{f}_03_{s}"), bpos(f"{f}_03_{s}", True)]
        start = j[0] - (j[1] - j[0]).normalized() * 0.012
        pts = [start, j[0], (j[0] + j[1]) / 2, j[1], (j[1] + j[2]) / 2, j[2], j[3]]
        wts = [{f"hand_{s}": 1.0}, {f"hand_{s}": 0.5, f"{f}_01_{s}": 0.5}, {f"{f}_01_{s}": 1.0},
               {f"{f}_01_{s}": 0.5, f"{f}_02_{s}": 0.5}, {f"{f}_02_{s}": 1.0},
               {f"{f}_02_{s}": 0.5, f"{f}_03_{s}": 0.5}, {f"{f}_03_{s}": 1.0}]
        r = RADIUS[f]
        rs = [r, r, r * 0.98, r * 0.96, r * 0.93, r * 0.9, r * 0.86]
        ring_tube(pts, [(x * 1.06, x * 0.94, None) for x in rs], wts)
    report[s]["palm_length"] = round(Lp, 4)

for face in hb.faces:
    for lp in face.loops:
        lp[uvlay].uv = skin_uv
    face.smooth = True
bmesh.ops.recalc_face_normals(hb, faces=hb.faces)
hand_me = bpy.data.meshes.new("auntie_hands")
hb.to_mesh(hand_me)
hb.free()
hand_ob = bpy.data.objects.new("auntie_hands", hand_me)
bpy.context.scene.collection.objects.link(hand_ob)
hand_ob.matrix_world = bw_
for g in body.vertex_groups:
    hand_ob.vertex_groups.new(name=g.name)
hand_me.materials.append(body.data.materials[0])
def towel_probe(tag):
    ca = body.data.color_attributes[0]
    v = np.array([d.color[:] for d in ca.data])
    li = [l for p in body.data.polygons if p.material_index == 1 for l in p.loop_indices]
    report.setdefault("towel_probe", {})[tag] = np.unique(np.round(v[li, :3], 1), axis=0)[:4].tolist()


towel_probe("before_join")
bpy.ops.object.select_all(action="DESELECT")
hand_ob.select_set(True)
body.select_set(True)
bpy.context.view_layer.objects.active = body
bpy.ops.object.join()
towel_probe("after_join")
# The body carries a corner colour attribute that Godot multiplies into the albedo;
# new corners (hands, wrist caps) come in black. They are white like the rest.
whitened = 0
for ca in body.data.color_attributes:
    vals = np.array([d.color[:] for d in ca.data])
    dark = vals[:, :3].sum(1) < 0.01
    vals[dark] = (1.0, 1.0, 1.0, 1.0)
    ca.data.foreach_set("color", vals.ravel())
    whitened += int(dark.sum())
report["corners_whitened"] = whitened
towel_probe("after_whiten")
bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(out))
json.dump(report, open(os.path.splitext(out)[0] + "_hands.json", "w"), indent=1)
print("AUNTIE_HANDS_OK", json.dumps(report))
