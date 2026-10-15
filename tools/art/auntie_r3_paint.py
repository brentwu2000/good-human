"""Market auntie r3 (Claude, 2026-10-15): texture fixes on the r3 mesh.

  blender -b --factory-startup --python tools/art/auntie_r3_paint.py -- <in.blend> <out.blend> <out_basecolor.png>

Forearms: the projection put towel red and sleeve purple on the bare forearms
(seen in every guard pose). Below the elbow, on faces that ride the forearm, every
texel that is not skin becomes the sheet's skin colour; skin texels keep their
shading. The texture is written as a new file; Codex's r2 basecolor stays as it is.
"""
import json
import os
import sys

import bpy
import numpy as np

src, out, png = sys.argv[sys.argv.index("--") + 1:][:3]
bpy.ops.wm.open_mainfile(filepath=os.path.abspath(src))
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
body = bpy.data.objects["Character"]
aw, bw_ = arm.matrix_world, body.matrix_world
me = body.data
mat = me.materials[0]
tex = next(n for n in mat.node_tree.nodes if n.type == "TEX_IMAGE" and n.image and "rough" not in n.image.name.lower())
img = tex.image
W, H = img.size
px = np.array(img.pixels[:], dtype=np.float32).reshape(H, W, img.channels)
SKIN = np.array([0.969, 0.780, 0.631])     # sheet skin (sRGB, as stored)
names = {g.index: g.name for g in body.vertex_groups}
uvl = me.uv_layers.active.data
me.calc_loop_triangles()
report = {"faces": 0, "texels_repainted": 0, "texels_seen": 0}


def tri_texels(uv3):
    x0, y0 = np.floor(uv3.min(0)).astype(int)
    x1, y1 = np.ceil(uv3.max(0)).astype(int)
    x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, W - 1), min(y1, H - 1)
    if x1 < x0 or y1 < y0:
        return None, None
    xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
    (ax, ay), (bx, by), (cx, cy) = uv3
    det = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
    if abs(det) < 1e-12:
        return None, None
    l1 = ((by - cy) * (xs - cx) + (cx - bx) * (ys - cy)) / det
    l2 = ((cy - ay) * (xs - cx) + (ax - cx) * (ys - cy)) / det
    ins = (l1 >= -0.05) & (l2 >= -0.05) & (1 - l1 - l2 >= -0.05)
    return (ys[ins] - 0.5).astype(int), (xs[ins] - 0.5).astype(int)


# Sleeve hem: the sheet has a clean hem at the elbow; the projection left a zigzag
# of purple and skin. Per arm, every texel of the arm faces gets its rest-pose 3D
# point (barycentric); its distance along the upper arm decides: above the hem
# sleeve (non-purple → sleeve colour), below it skin. The hem is where sleeve
# purple drops below half, measured on the texels themselves.


def purple_px(c):
    return (c[..., 2] > c[..., 0] * 0.9) & (c[..., 2] > c[..., 1])


arm_faces_of = {}
for s in "lr":
    pit = (aw @ arm.data.bones[f"upperarm_{s}"].head_local).z - 0.075
    ids = set()
    for p in me.polygons:
        if p.material_index != 0:
            continue
        vs = [me.vertices[i] for i in p.vertices]
        if not all(v.groups for v in vs):
            continue
        dom = [names[max(v.groups, key=lambda g: g.weight).group] for v in vs]
        if all(d in (f"upperarm_{s}", f"lowerarm_{s}", f"hand_{s}") for d in dom) and (bw_ @ p.center).z < pit:
            ids.add(p.index)
    arm_faces_of[s] = ids
vco = np.array([bw_ @ v.co for v in me.vertices])
hem_report, sleeve_px, skin_px = {}, np.zeros((H, W), bool), np.zeros((H, W), bool)
for s in "lr":
    S = aw @ arm.data.bones[f"upperarm_{s}"].head_local
    E = aw @ arm.data.bones[f"lowerarm_{s}"].head_local
    up = np.array((E - S).normalized())
    Sv = np.array(S)
    tys, txs, tas = [], [], []
    for t in me.loop_triangles:
        if t.polygon_index not in arm_faces_of[s]:
            continue
        uv3 = np.array([uvl[li].uv[:] for li in t.loops]) * [W, H]
        P = vco[list(t.vertices)]
        x0, y0 = np.floor(uv3.min(0)).astype(int)
        x1, y1 = np.ceil(uv3.max(0)).astype(int)
        x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, W - 1), min(y1, H - 1)
        if x1 < x0 or y1 < y0:
            continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        (ax_, ay_), (bx_, by_), (cx_, cy_) = uv3
        det = (by_ - cy_) * (ax_ - cx_) + (cx_ - bx_) * (ay_ - cy_)
        if abs(det) < 1e-12:
            continue
        l1 = ((by_ - cy_) * (xs - cx_) + (cx_ - bx_) * (ys - cy_)) / det
        l2 = ((cy_ - ay_) * (xs - cx_) + (ax_ - cx_) * (ys - cy_)) / det
        l3 = 1 - l1 - l2
        ins = (l1 >= -0.05) & (l2 >= -0.05) & (l3 >= -0.05)
        pts = l1[ins, None] * P[0] + l2[ins, None] * P[1] + l3[ins, None] * P[2]
        tys.append((ys[ins] - 0.5).astype(int))
        txs.append((xs[ins] - 0.5).astype(int))
        tas.append((pts - Sv) @ up)
    ty, tx, ta = np.concatenate(tys), np.concatenate(txs), np.concatenate(tas)
    pu = purple_px(px[ty, tx, :3])
    prof = []
    for a_ in np.arange(0.0, ta.max(), 0.02):
        m = (ta >= a_) & (ta < a_ + 0.02)
        if m.sum():
            prof.append((round(float(a_), 2), int(m.sum()), round(float(pu[m].mean()), 2)))
    report.setdefault("purple_profile", {})[s] = prof
    hem = None
    for a_ in np.arange(0.0, ta.max(), 0.004):
        m = (ta >= a_) & (ta < a_ + 0.012)
        if m.sum() > 30 and pu[m].mean() < 0.5 and a_ > 0.03:
            hem = a_
            break
    hem = ta.max() if hem is None else hem
    hem_report[s] = {"hem_along_upperarm_m": round(float(hem), 3), "upperarm_len_m": round(float(np.linalg.norm(np.array(E - S))), 3)}
    above = ta < hem
    sleeve_px[ty[above], tx[above]] = True
    skin_px[ty[~above], tx[~above]] = True
report["sleeve_hem"] = hem_report
sleeve_mask = sleeve_px & ~skin_px
forearm_faces = set()
mask = skin_px & ~sleeve_px
rgb = px[..., :3]
# Skin-like: warm, light, low blue relative to red (shaded skin included).
r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
skinlike = (r > 0.55) & (r >= g) & (g >= b * 0.95) & ((r - b) > 0.18) & ((r - g) < 0.32)
# Flat colour like the sheet: the whole forearm is skin (baked shading in the
# projection left darker patches that read as dirt or bruises).
bad = mask
report["texels_seen"] = int(mask.sum())
report["texels_repainted"] = int(bad.sum())
rgb[bad] = SKIN
sl = rgb[sleeve_mask]
is_pu = (sl[:, 2] > sl[:, 0] * 0.9) & (sl[:, 2] > sl[:, 1])
SLEEVE = np.median(sl[is_pu], 0) if is_pu.any() else np.array([0.52, 0.49, 0.68])
fix = sleeve_mask & ~mask & ~((rgb[..., 2] > rgb[..., 0] * 0.9) & (rgb[..., 2] > rgb[..., 1]))
rgb[fix] = SLEEVE
report["sleeve_texels_to_purple"] = int(fix.sum())
report["sleeve_colour"] = [round(float(x), 3) for x in SLEEVE]
px[..., :3] = rgb

# ---- Head: skin showing through the hair. The sheet's curly bob covers the ears;
# the projection left them (and specks) skin-coloured. Only skin -> hair: the drawn
# eyes, brows and mouth are dark strokes on skin and must never be touched.
import bmesh


def uniform_filter(a, size):
    """Box mean (Blender's Python has no scipy)."""
    k = size // 2
    pad = np.pad(a, k + 1, mode="edge")
    c = pad.cumsum(0).cumsum(1)
    n = size
    out = c[n:, n:] - c[:-n, n:] - c[n:, :-n] + c[:-n, :-n]
    return out[:a.shape[0], :a.shape[1]] / (n * n)

bm = bmesh.new()
bm.from_mesh(me)
bm.faces.ensure_lookup_table()
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
bm.faces.ensure_lookup_table()
uvb = bm.loops.layers.uv.active
dl = bm.verts.layers.deform.active


def face_rgb(f):
    pts = [l[uvb].uv for l in f.loops]
    u = np.mean([q[0] for q in pts]), np.mean([q[1] for q in pts])
    cs = [rgb[min(int(q[1] * H), H - 1), min(int(q[0] * W), W - 1)] for q in pts]
    cs.append(rgb[min(int(u[1] * H), H - 1), min(int(u[0] * W), W - 1)])
    return np.mean(cs, 0)


def klass(c):
    if c @ np.array([0.299, 0.587, 0.114]) < 0.22:
        return "H"
    r_, g_, b_ = c
    if r_ > 0.6 and r_ >= g_ >= b_ * 0.9 and (r_ - b_) > 0.18 and (r_ - g_) < 0.3:
        return "S"
    return "O"


head = []
for f in bm.faces:
    if f.material_index != 0:
        continue
    ws = {}
    for v in f.verts:
        for gi, w in v[dl].items():
            ws[names[gi]] = ws.get(names[gi], 0) + w
    if ws and max(ws, key=ws.get) in ("head", "neck_01") and min((bw_ @ v.co).z for v in f.verts) > 1.0:
        head.append(f)
hs = set(head)
C = {f: klass(face_rgb(f)) for f in head}
hair_px = rgb[np.array([[min(int(l[uvb].uv[1] * H), H - 1), min(int(l[uvb].uv[0] * W), W - 1)]
                        for f in head if C[f] == "H" for l in f.loops])[:, 0],
              np.array([[min(int(l[uvb].uv[1] * H), H - 1), min(int(l[uvb].uv[0] * W), W - 1)]
                        for f in head if C[f] == "H" for l in f.loops])[:, 1]]
HAIR = np.median(hair_px, 0)
report["hair_colour"] = [round(float(x), 3) for x in HAIR]
seen, flip = set(), []
for f in head:
    if f in seen or C[f] != "S":
        continue
    comp, st = [], [f]
    while st:
        g = st.pop()
        if g in seen:
            continue
        seen.add(g)
        comp.append(g)
        st += [h for e in g.edges for h in e.link_faces if h in hs and h not in seen and C[h] == "S"]
    if len(comp) < 80:       # the face itself is ~470 faces; ears 17-33; specks 1-5
        flip += comp
report["head_skin_islands_to_hair_faces"] = len(flip)
head_mask = np.zeros((H, W), dtype=bool)      # head faces not facing the front
flip_mask = np.zeros((H, W), dtype=bool)
nose_mask = np.zeros((H, W), dtype=bool)      # the nose's side walls
rot = bw_.to_3x3()
for f in head:
    n_ = (rot @ f.normal).normalized()
    c_ = bw_ @ f.calc_center_median()
    front = -n_.y > 0.5
    nose_side = abs(c_.x) < 0.09 and c_.y < -0.17 and abs(n_.x) > 0.55 and 1.08 < c_.z < 1.25
    lp = list(f.loops)
    for i in range(1, len(lp) - 1):
        uv3 = np.array([lp[0][uvb].uv[:], lp[i][uvb].uv[:], lp[i + 1][uvb].uv[:]]) * [W, H]
        ys, xs = tri_texels(uv3)
        if ys is None:
            continue
        if not front:
            head_mask[ys, xs] = True
        if nose_side:
            nose_mask[ys, xs] = True
        if f in flip:
            flip_mask[ys, xs] = True
r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
is_hair = (rgb @ np.array([0.299, 0.587, 0.114])) < 0.22
is_skin = (r > 0.6) & (r >= g) & (g >= b * 0.9) & ((r - b) > 0.18) & ((r - g) < 0.3)
# Texel specks: skin texels mostly surrounded by hair (7x7), inside the head region.
around = uniform_filter(is_hair.astype(np.float32), size=7)
speck = head_mask & is_skin & (around > 0.45)
to_hair = (flip_mask & ~is_hair) | speck
report["head_texels_to_hair"] = int(to_hair.sum())
rgb[to_hair] = HAIR
# The mouth stroke projected onto the nose's side walls: back to skin.
nose_dark = nose_mask & ((rgb @ np.array([0.299, 0.587, 0.114])) < 0.45)
report["nose_side_texels_to_skin"] = int(nose_dark.sum())
rgb[nose_dark] = SKIN
bm.free()
px[..., :3] = rgb
new = bpy.data.images.new("market_auntie_r3_basecolor", W, H, alpha=img.channels == 4)
new.pixels.foreach_set(px.ravel())
new.filepath_raw = os.path.abspath(png)
new.file_format = "PNG"
new.save()
new.colorspace_settings.name = "sRGB"
tex.image = new
bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(out))
json.dump(report, open(os.path.splitext(out)[0] + "_paint.json", "w"), indent=1)
print("AUNTIE_PAINT_OK", json.dumps(report))
