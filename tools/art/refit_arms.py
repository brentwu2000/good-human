"""Refit a character's arm joints to its own arms (Claude, 2026-10-17; LESSONS 6.30).
  blender -b --factory-startup --python tools/art/refit_arms.py -- <in.glb> <out.glb> [elbow 0.40] [wrist 0.78]
For a model whose OwnerSkeleton arms were scaled from a smaller body (the gym coach: elbow at
24 % of his arm, wrist at 48 %), so the shared fight clips bend his arm mid-bicep:
1. The arm's length is measured from the shoulder to the farthest arm-chain vertex.
2. The joints go onto the arm's own centreline (slab centroids from the shoulder): the elbow
   where the arm reaches furthest out sideways, the wrist a hand's length short of the tip;
   the fingers move with the wrist. The shared fight clips set each bone's own rotation, so
   what matters is that a bone lies along its limb; its roll follows the old one through
   the swing (the least twist).
3. Arm vertices (below the shoulder blend) are re-weighted along the chain: upper arm /
   forearm blended over +-4 % of the arm at the elbow, forearm / hand over +-3 % at the
   wrist; vertices past the wrist go to the hand (the fists are mittens).
Everything else (body weights, clips, materials) is untouched.
"""
import math
import os
import sys

import bpy
import numpy as np
from mathutils import Vector

a = sys.argv[sys.argv.index("--") + 1:]
src, out = a[0], a[1]
ELBOW = float(a[2]) if len(a) > 2 else 0.40
WRIST = float(a[3]) if len(a) > 3 else 0.78
ARM = ("upperarm", "lowerarm", "hand", "index", "middle", "ring", "pinky", "thumb")
FINGERS = ("index", "middle", "ring", "pinky", "thumb")

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=os.path.abspath(src))
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
for o in bpy.data.objects:
    if o.animation_data:
        o.animation_data.action = None
arm.data.pose_position = "REST"
body = bpy.data.objects["Character"]
me = body.data
mw = body.matrix_world
amw = arm.matrix_world
V = np.array([tuple(mw @ v.co) for v in me.vertices])
gn = {g.index: g.name for g in body.vertex_groups}
dom = [gn[max(v.groups, key=lambda e: e.weight).group] if v.groups else "" for v in me.vertices]
rest_before = {b.name: (amw.to_3x3() @ b.matrix_local.to_3x3()).to_quaternion() for b in arm.data.bones}

def arm_line(s):
    """The arm's own centreline: slab centroids by distance from the shoulder; the elbow is
    where the arm reaches furthest out sideways, the wrist a hand's length short of the tip."""
    sh = np.array(tuple(amw @ arm.data.bones["upperarm_" + s].head_local))
    sel = np.array([d.startswith(ARM) and d.endswith("_" + s) for d in dom])
    P = V[sel]
    r = np.linalg.norm(P - sh, axis=1)
    rmax = np.percentile(r, 99.5)
    cents = []
    for k in np.arange(0.05, rmax, 0.025):
        m = (r > k - 0.02) & (r < k + 0.02)
        if m.sum() >= 5:
            cents.append((k, P[m].mean(0)))
    out_x = [(abs(c[0] - sh[0]), k, c) for k, c in cents if 0.3 * rmax <= k <= 0.75 * rmax]
    _, k_el, elbow = max(out_x, key=lambda x: x[0])
    k_wr = rmax - 0.085
    wrist = min(cents, key=lambda kc: abs(kc[0] - k_wr))[1]
    tip = min(cents, key=lambda kc: abs(kc[0] - (rmax - 0.01)))[1]
    return Vector(sh), Vector(elbow), Vector(wrist), Vector(tip), rmax


def set_bone(b, head_w, tail_w):
    """Head/tail in world; the roll follows the old one through the swing between the old
    and the new direction (the least twist the shared clips would see)."""
    old_axis = (amw.to_3x3() @ (b.tail - b.head)).normalized()
    old_z = amw.to_3x3() @ b.z_axis
    new_axis = (tail_w - head_w).normalized()
    swing = old_axis.rotation_difference(new_axis)
    b.head = inv @ head_w
    b.tail = inv @ tail_w
    b.align_roll(inv.to_3x3() @ (swing @ old_z))


bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="EDIT")
eb = arm.data.edit_bones
inv = amw.inverted()
plan = {}
for s in "lr":
    up, lo, hand = eb["upperarm_" + s], eb["lowerarm_" + s], eb["hand_" + s]
    sh, elbow, wrist, tip, L = arm_line(s)
    old_el, old_wr = amw @ lo.head, amw @ hand.head
    print("REFIT %s arm %.2f m: elbow moved %.1f cm, wrist moved %.1f cm" % (s, L, (elbow - old_el).length * 100, (wrist - old_wr).length * 100))
    shift = wrist - old_wr
    fingers = [x for x in eb if x.name.startswith(FINGERS) and x.name.endswith("_" + s)]
    finger_ends = {x.name: (amw @ x.head + shift, amw @ x.tail + shift) for x in fingers}
    set_bone(up, sh, elbow)
    set_bone(lo, elbow, wrist)
    hand_len = max((tip - wrist).length, 0.05)
    set_bone(hand, wrist, wrist + (tip - wrist).normalized() * hand_len)
    for x in fingers:
        h, tl = finger_ends[x.name]
        x.head = inv @ h
        x.tail = inv @ tl
    plan[s] = (sh, elbow, wrist, L)
bpy.ops.object.mode_set(mode="OBJECT")

worst = 0.0
for b in arm.data.bones:
    q = (amw.to_3x3() @ b.matrix_local.to_3x3()).to_quaternion()
    worst = max(worst, math.degrees(rest_before[b.name].rotation_difference(q).angle))
print("REFIT largest rest-rotation change %.1f deg (the swing onto the arm itself)" % worst)

# ---- re-weight the arm chain by position along it
for s, (sh, el, wr, L) in plan.items():
    groups = {n: body.vertex_groups[n + "_" + s] for n in ("upperarm", "lowerarm", "hand")}
    finger_groups = [g for g in body.vertex_groups if g.name.startswith(FINGERS) and g.name.endswith("_" + s)]
    shoulder_cut = 0.12 * L  # above this the shoulder/torso blend stays as it was
    d1 = (el - sh).normalized()
    d2 = (wr - el).normalized()
    n = 0
    for i, v in enumerate(me.vertices):
        if not (dom[i].startswith(ARM) and dom[i].endswith("_" + s)):
            continue
        p = Vector(V[i])
        t1 = (p - sh).dot(d1)
        if t1 < shoulder_cut:
            continue
        len1 = (el - sh).length
        len2 = (wr - el).length
        t_el = t1 - len1                      # past the elbow along the upper arm
        t_wr = (p - el).dot(d2) - len2        # past the wrist along the forearm
        be, bw = 0.04 * L, 0.03 * L
        w_lo = float(np.clip(0.5 + t_el / (2 * be), 0, 1))
        w_hand = float(np.clip(0.5 + t_wr / (2 * bw), 0, 1)) if w_lo > 0.5 else 0.0
        weights = {"upperarm": 1 - w_lo, "lowerarm": w_lo * (1 - w_hand), "hand": w_lo * w_hand}
        for g in [*groups.values(), *finger_groups]:
            g.remove([i])
        for k, w in weights.items():
            if w > 0.001:
                groups[k].add([i], w, "REPLACE")
        n += 1
    print("REFIT %s re-weighted %d arm vertices" % (s, n))

for o in bpy.context.scene.objects:
    o.select_set(o.type == "ARMATURE" or (o.type == "MESH" and any(m.type == "ARMATURE" for m in o.modifiers)))
    if o.type == "ARMATURE":
        o.data.pose_position = "POSE"
bpy.ops.export_scene.gltf(filepath=os.path.abspath(out), export_format="GLB", use_selection=True,
                          export_animations=True, export_animation_mode="ACTIONS", export_skins=True,
                          export_image_format="AUTO")
print("REFIT exported", out)
