"""Trellis2 texture pass, step 3 (Claude, 2026-10-17): vertex colours -> the body's own UVs.
  blender -b <work>/hi.blend --python tools/art/t2_bake.py -- <config.json> <colours.npz[@front|@left],...> <work_dir>
Several colour sets (dogs: front/back run + side run) blend per vertex by normal: a "front"
set weighs normals along the body axis (y), a "left" set normals across it (x).
A Cycles emit bake (no nvdiffrast). Writes <work>/t2_basecolor.png (Trellis2 colour in the game
UVs, raw) and <work>/t2_facemask.png (white over the drawn face, soft rim).
Config options used here:
  exclude_material_keywords  body faces left out (own material, e.g. the auntie's towel)
  bake_materials             only these materials' faces are baked (dogs with a separate
                             face/collar material)
  props [{object, min_z}]    real straps/bags: the generator also paints them onto the body,
                             offset; body texels near them (front view) are refilled from the
                             mirrored side
  strap_radius               front-view refill distance (m), default 0.06
  bare_forearms              forearm past `hem` (elbow -> wrist) is skin; hands too
  hands_skin                 hands get forearm skin (hands whose UVs are one point)
  top_from front|left        run that colours upward-facing surfaces (the back)
  stray_red {near, radius, hue_max, sat_min, below_value}  red texels farther than radius (m) from that joint are refilled
  clear_dark_bones, dark_value  dark texels (raw value < dark_value) on those bones refilled
  nose_object                with eye_objects: clear the band from above the nose to above
                             the eyes (painted eyes sit where the sheet has them)
  eye_objects, eye_clear     separate eye meshes: body texels within eye_clear x their radius
                             are refilled from the fur around (no painted second eyes)
  face {zc, az, ax}          face ellipse (rest pose, m); measured from the head when absent
  keep_face                  false: no face/hair masks
  face_auto {zc, az, ax}     coefficients of the measured ellipse (dogs: wider, eyes included)
Also writes t2_hairmask.png (crown + back of head) for t2_finish's hair_tone.
"""
import colorsys
import json
import sys
from collections import deque
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Vector, kdtree

cfg_path, npz, work = sys.argv[sys.argv.index("--") + 1:][:3]
cfg = json.load(open(cfg_path, encoding="utf-8"))
work = Path(work)
size = int(cfg.get("texture_size", 2048))
sets = []
for spec in npz.split(","):
    path, _, facing = spec.partition("@")
    d = np.load(path)
    gp, gc = d["pos"], d["col"].astype(np.float32) / 255.0
    # Trellis2 colours are sRGB bytes; a float colour attribute is linear.
    gc = np.where(gc <= 0.04045, gc / 12.92, ((gc + 0.055) / 1.055) ** 2.4)
    bp = np.stack([gp[:, 0], -gp[:, 2], gp[:, 1]], 1)  # glTF (Y up, +Z front) -> Blender
    kd = kdtree.KDTree(len(bp))
    for i, p in enumerate(bp):
        kd.insert(p, i)
    kd.balance()
    sets.append((kd, gc, facing or "front"))

hi = bpy.data.objects["hi"]
dg0 = bpy.context.evaluated_depsgraph_get()
# Props float a few cm in front of the body: distance is measured in the front view (x, z).
sv = []
for pr in cfg.get("props", []):
    ob = bpy.data.objects.get(pr["object"])
    if ob is None:
        print("T2_BAKE missing prop", pr["object"]); continue
    ev = ob.evaluated_get(dg0)
    sv += [v for v in (ev.matrix_world @ x.co for x in ev.data.vertices) if v.z > pr.get("min_z", -9)]
skd = None
if sv:
    skd = kdtree.KDTree(len(sv))
    for i, v in enumerate(sv):
        skd.insert(Vector((v.x, 0.0, v.z)), i)
    skd.balance()
# Separate eye meshes (player shiba): the generator paints eyes around them as well.
eyes = []
for name in cfg.get("eye_objects", []):
    ob = bpy.data.objects.get(name)
    if ob is None:
        continue
    ev = ob.evaluated_get(dg0)
    vs = np.array([tuple(ev.matrix_world @ x.co) for x in ev.data.vertices])
    c_ = vs.mean(0)
    eyes.append((c_, float(np.linalg.norm(vs - c_, axis=1).max())))
nose_c = None
if cfg.get("nose_object") and bpy.data.objects.get(cfg["nose_object"]):
    ev = bpy.data.objects[cfg["nose_object"]].evaluated_get(dg0)
    nose_c = np.array([tuple(ev.matrix_world @ x.co) for x in ev.data.vertices]).mean(0)
arm_ob = next(o for o in bpy.data.objects if o.type == "ARMATURE")
JOINT = {b.name: arm_ob.matrix_world @ b.head_local for b in arm_ob.data.bones}
for o in list(bpy.data.objects):
    if o is not hi:
        bpy.data.objects.remove(o)
me = hi.data
only = cfg.get("bake_materials")
excl = [i for i, s in enumerate(hi.material_slots)
        if s.material and (any(k in s.material.name for k in cfg.get("exclude_material_keywords", []))
                           or (only and s.material.name not in only))]
if excl:
    bm = bmesh.new(); bm.from_mesh(me)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.material_index in excl], context="FACES")
    bm.to_mesh(me); bm.free()
mw = hi.matrix_world
nv = len(me.vertices)
pts = [mw @ v.co for v in me.vertices]
P = np.array([tuple(p) for p in pts])
nrm = np.array([tuple(mw.to_3x3() @ v.normal) for v in me.vertices])

lin = np.zeros((nv, 3))
wsum = np.zeros(nv)
# Upward-facing surfaces (the back) are seen by neither run straight on; "top_from" picks the
# run that owns them (the player shiba's side run paints a collar bar along the spine).
top_from = cfg.get("top_from")
up = nrm[:, 2] > 0.55
for kd, gc, facing in sets:
    ax_i = 1 if facing == "front" else 0
    wv = (nrm[:, ax_i] ** 2 + 0.05) if len(sets) > 1 else np.ones(nv)
    if top_from and len(sets) > 1:
        wv = np.where(up, 1.0 if facing == top_from else 0.0, wv)
    for i, p in enumerate(pts):
        near = kd.find_n(p, 4)
        w = np.array([1.0 / max(dist, 1e-5) for _, _, dist in near])
        lin[i] += wv[i] * (gc[[j for _, j, _ in near]] * w[:, None]).sum(0) / w.sum()
    wsum += wv
lin /= wsum[:, None]
srgb = np.where(lin <= 0.0031308, lin * 12.92, 1.055 * np.power(np.maximum(lin, 0), 1 / 2.4) - 0.055)
hsv = np.array([colorsys.rgb_to_hsv(*c) for c in srgb])

gname = {g.index: g.name for g in hi.vertex_groups}
def dom(v):
    best = max(v.groups, key=lambda e: e.weight, default=None)
    return gname[best.group] if best else ""
bone = [dom(v) for v in me.vertices]
HAND = ("hand_", "index_", "middle_", "ring_", "pinky_", "thumb_")
is_hand = np.array([b.startswith(HAND) for b in bone])
is_head = np.array([b in ("head", "neck_01") for b in bone])
lower = np.array([b.startswith("lowerarm") for b in bone])
torso = np.array([b.startswith(("spine", "pelvis")) for b in bone])
torso_hw = float(np.percentile(np.abs(P[torso, 0]), 95)) if torso.any() else 0.2
adj = [[] for _ in range(nv)]
for e in me.edges:
    a_, b_ = e.vertices
    adj[a_].append(b_); adj[b_].append(a_)

# ---- 1. painted props under the real ones: refill from the mirrored side.
flag = np.zeros(nv, bool)
if skd is not None:
    front = (nrm[:, 1] < -0.2) & ~is_hand & ~is_head & (np.abs(P[:, 0]) < torso_hw)
    sd = np.array([skd.find(Vector((p.x, 0.0, p.z)))[2] for p in pts])
    olive = (hsv[:, 0] * 360 > 32) & (hsv[:, 0] * 360 < 85) & (hsv[:, 1] > 0.2)
    flag = front & ((sd < float(cfg.get("strap_radius", 0.06))) | ((sd < 0.15) & olive))
for c_, r_ in eyes:
    near_eye = np.linalg.norm(P - c_, axis=1) < r_ * float(cfg.get("eye_clear", 2.2))
    flag |= near_eye
    print("T2_BAKE painted eye cleared: %d verts (eye radius %.3f)" % (near_eye.sum(), r_))
if cfg.get("stray_red"):
    # A collar painted away from the neck (player shiba: a red bar on the back).
    sr = cfg["stray_red"]
    hue = hsv[:, 0] * 360
    red = ((hue < float(sr.get("hue_max", 18))) | (hue > 335)) & (hsv[:, 1] > float(sr.get("sat_min", 0.4)))
    if "below_value" in sr:
        red &= hsv[:, 2] < float(sr["below_value"])
    far = np.linalg.norm(P - np.array(JOINT[sr.get("near", "neck")]), axis=1) > float(sr.get("radius", 0.14))
    flag |= red & far
    print("T2_BAKE stray red cleared: %d verts" % (red & far).sum())
if cfg.get("clear_dark_bones"):
    # Dark painted marks (shadow of the sheet's tail curl) on these bones' skin.
    on = np.array([b.startswith(tuple(cfg["clear_dark_bones"])) for b in bone])
    dark = on & (hsv[:, 2] < float(cfg.get("dark_value", 0.3)))
    flag |= dark
    print("T2_BAKE dark marks cleared: %d verts" % dark.sum())
if eyes and nose_c is not None:
    # The generator places its eyes where the sheet has them, not on the eye meshes: clear
    # the front of the head from just above the nose to above the eyes (fur on the model).
    ez = float(np.mean([c_[2] for c_, _ in eyes])); ex = float(np.mean([abs(c_[0]) for c_, _ in eyes]))
    er = float(np.mean([r_ for _, r_ in eyes]))
    band = (is_head & (nrm[:, 1] < -0.2) & (P[:, 2] > nose_c[2] + 0.25 * (ez - nose_c[2]))
            & (P[:, 2] < ez + 3 * er) & (np.abs(P[:, 0]) < 2.6 * ex))
    flag |= band
    print("T2_BAKE eye band cleared: %d verts" % band.sum())
if flag.any():
    fill = lin.copy()
    src_of = np.full(nv, -1)
    q = deque()
    for u in np.nonzero(flag)[0]:
        for w_ in adj[u]:
            if not flag[w_] and src_of[u] < 0:
                src_of[u] = w_; q.append(u)
    while q:
        u = q.popleft()
        for w_ in adj[u]:
            if flag[w_] and src_of[w_] < 0:
                src_of[w_] = src_of[u]; q.append(w_)
    idx = np.nonzero(flag & (src_of >= 0))[0]
    fill[idx] = lin[src_of[idx]]
    for _ in range(int(cfg.get("fill_smooth", 25))):
        fill[idx] = np.array([fill[adj[u]].mean(0) for u in idx])
    # A strap is diagonal: the mirrored point (-x) is plain cloth with the same print.
    vkd = kdtree.KDTree(nv)
    for i, p in enumerate(pts):
        vkd.insert(p, i)
    vkd.balance()
    n_m = 0
    for u in np.nonzero(flag)[0]:
        _, j, dist = vkd.find(Vector((-pts[u].x, pts[u].y, pts[u].z)))
        if dist < 0.02 and not flag[j]:
            fill[u] = lin[j]; n_m += 1
    lin = np.where(flag[:, None], fill, lin)
    print("T2_BAKE prop refill %d verts (%d mirrored), torso half width %.3f" % (flag.sum(), n_m, torso_hw))

# ---- 2. bare forearms / hands: Trellis2's own forearm skin.
fore = lower & (hsv[:, 0] * 360 < 42) & (hsv[:, 1] > 0.2) & (hsv[:, 2] > 0.5)
if (cfg.get("bare_forearms") or cfg.get("hands_skin")) and fore.sum() > 50:
    skin_lin = np.median(lin[fore], 0)
    if cfg.get("hands_skin") or cfg.get("bare_forearms"):
        lin[is_hand] = skin_lin
    if cfg.get("bare_forearms"):
        tpos = np.zeros(nv)
        for side in ("l", "r"):
            e = np.array(JOINT["lowerarm_" + side]); w_ = np.array(JOINT["hand_" + side])
            ax_ = w_ - e
            sel_ = np.array([b == "lowerarm_" + side for b in bone])
            tpos[sel_] = ((P[sel_] - e) @ ax_) / (ax_ @ ax_)
        fix = lower & (tpos > float(cfg.get("hem", 0.15)))
        lin[fix] = skin_lin
        print("T2_BAKE forearm skin %d verts" % fix.sum())
    print("T2_BAKE hands %d verts <- forearm skin %s" % (is_hand.sum(), np.median(srgb[fore], 0).round(3)))

keep_face = cfg.get("keep_face", True) and is_head.any()
cx = zc = az = ax = 0.0
hair = np.zeros(nv, bool)
if keep_face:
    # ---- 3. face ellipse (rest pose): from the head when not given.
    hv = P[is_head & (nrm[:, 1] < -0.3)]
    hz0, hz1 = float(P[is_head, 2].min()), float(P[is_head, 2].max())
    hw = float(np.percentile(np.abs(hv[:, 0] - np.median(hv[:, 0])), 95)) if len(hv) else 0.15
    f = cfg.get("face") or {}
    fa = {"zc": 0.43, "az": 0.35, "ax": 0.56, **cfg.get("face_auto", {})}  # fitted on the auntie
    cx = float(f.get("cx", np.median(hv[:, 0]) if len(hv) else 0.0))
    zc = float(f.get("zc", hz0 + fa["zc"] * (hz1 - hz0)))
    az = float(f.get("az", fa["az"] * (hz1 - hz0)))
    ax = float(f.get("ax", fa["ax"] * hw))
    print("T2_BAKE head z %.3f-%.3f half width %.3f -> face cx %.3f zc %.3f az %.3f ax %.3f" % (hz0, hz1, hw, cx, zc, az, ax))

    # ---- 4. hair mask (crown above the face and the back of the head, not ears/cheeks):
    # t2_finish scales it to the sheet's hair colour after the white balance (hair_tone).
    rf = ((P[:, 0] - cx) / ax) ** 2 + ((P[:, 2] - zc) / az) ** 2
    hair = is_head & (((nrm[:, 1] <= 0.2) & (rf > 1.0) & (P[:, 2] > zc + 0.2 * az))
                      | ((nrm[:, 1] > 0.2) & (P[:, 2] > zc - az)))
    print("T2_BAKE hair mask %d verts" % hair.sum())

col = me.color_attributes.new("t2", "FLOAT_COLOR", "POINT")
msk = me.color_attributes.new("mask", "FLOAT_COLOR", "POINT")
hmk = me.color_attributes.new("hair", "FLOAT_COLOR", "POINT")
for i, p in enumerate(pts):
    col.data[i].color = (*lin[i], 1.0)
    r = ((p.x - cx) / ax) ** 2 + ((p.z - zc) / az) ** 2 if keep_face else 9.0
    m = 0.0
    if keep_face and nrm[i, 1] < -0.15 and r < 1.0:
        m = min(1.0, (1.0 - r) / 0.3) ** 1.2  # full core, soft rim
    msk.data[i].color = (m, m, m, 1.0)
    hv_ = 1.0 if hair[i] else 0.0
    hmk.data[i].color = (hv_, hv_, hv_, 1.0)

sc = bpy.context.scene
sc.render.engine = "CYCLES"
sc.cycles.device = "CPU"
sc.cycles.samples = 1
mat = bpy.data.materials.new("bake"); mat.use_nodes = True
nt = mat.node_tree; nt.nodes.clear()
attr = nt.nodes.new("ShaderNodeAttribute")
emi = nt.nodes.new("ShaderNodeEmission")
outn = nt.nodes.new("ShaderNodeOutputMaterial")
nt.links.new(attr.outputs["Color"], emi.inputs["Color"])
nt.links.new(emi.outputs[0], outn.inputs[0])
tex = nt.nodes.new("ShaderNodeTexImage")
me.materials.clear(); me.materials.append(mat)
for poly in me.polygons:
    poly.material_index = 0
bpy.context.view_layer.objects.active = hi
hi.select_set(True)
for name, layer, cs in [("t2_basecolor", "t2", "sRGB"), ("t2_facemask", "mask", "Non-Color"),
                       ("t2_hairmask", "hair", "Non-Color")]:
    img = bpy.data.images.new(name, size, size, alpha=False, float_buffer=False)
    img.colorspace_settings.name = cs
    tex.image = img; nt.nodes.active = tex
    attr.attribute_name = layer
    bpy.ops.object.bake(type="EMIT", margin=8, use_clear=True)
    img.filepath_raw = str(work / f"{name}.png"); img.file_format = "PNG"; img.save()
    print("T2_BAKE wrote", name)
