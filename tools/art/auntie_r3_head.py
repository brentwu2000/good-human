"""Market auntie r3 (Claude, 2026-10-15): the head, redrawn against the sheet.

  blender -b --factory-startup --python tools/art/auntie_r3_head.py -- <in.blend> <out.blend> <out_basecolor.png>

Sheet vs r3 (front grid, docs/06_art/MARKET_AUNTIE_R3_2026-10-15.md):
- nose: an 11 cm bulb sticking out 4 cm → a button: the part in front of the face
  plane keeps 45 % of its depth and draws in toward its centre;
- face drawn in the mesh's own front coordinates (x, z in metres, rest pose):
  a smooth hairline arch, thin arched brows, closed happy eyes, a wide smile, soft
  blush, a pink nose tip; ears skin (the sheet shows them);
- hair: the sheet's dark brown, lighter where the curls face the light (curls read
  from the lumps of the shell), thin lighter strands;
- headband: a band over the crown and the knot, not a red cap: red texels outside
  the band and knot become hair.
Every texel gets its rest-pose 3D point and normal (barycentric), so all rules are
shapes in 3D, independent of the UV layout.
"""
import json
import math
import os
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Vector

src, out, png = sys.argv[sys.argv.index("--") + 1:][:3]
bpy.ops.wm.open_mainfile(filepath=os.path.abspath(src))
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
body = bpy.data.objects["Character"]
bw = body.matrix_world
me = body.data
report = {}

SKIN = np.array([0.969, 0.780, 0.631])
SKIN_PINK = np.array([0.965, 0.655, 0.580])
BLUSH = np.array([0.960, 0.560, 0.520])
LINE = np.array([0.270, 0.160, 0.120])       # brows, eyes
LIP = np.array([0.560, 0.230, 0.200])
MOUTH_IN = np.array([0.420, 0.150, 0.140])
TEETH = np.array([0.980, 0.965, 0.930])
HAIR = np.array([0.205, 0.135, 0.105])       # sheet: dark brown, not black
HAIR_HI = np.array([0.395, 0.270, 0.200])
HAIR_LO = np.array([0.130, 0.085, 0.070])

NOSE_C = np.array([0.015, 1.176])            # x, z of the nose (front grid)
NOSE_BASE_Y = -0.205                         # face plane in front of the cheeks
NOSE_R = 0.072
NOSE_KEEP = 0.35

# ---- 1. nose geometry.
names = {g.index: g.name for g in body.vertex_groups}
inv = bw.inverted()
moved = 0
for v in me.vertices:
    p = bw @ v.co
    d = math.hypot(p.x - NOSE_C[0], p.z - NOSE_C[1])
    if d < NOSE_R and p.y < NOSE_BASE_Y:
        fall = (1 - d / NOSE_R) ** 0.5
        k = 1 - (1 - NOSE_KEEP) * fall
        ny = NOSE_BASE_Y + (p.y - NOSE_BASE_Y) * k
        nx = NOSE_C[0] + (p.x - NOSE_C[0]) * (1 - 0.25 * fall)
        nz = NOSE_C[1] + (p.z - NOSE_C[1]) * (1 - 0.25 * fall)
        v.co = inv @ Vector((nx, ny, nz))
        moved += 1
me.update()
report["nose_vertices_moved"] = moved

# ---- 2. texels of the head with their 3D point and normal.
mat = me.materials[0]
tex = next(n for n in mat.node_tree.nodes if n.type == "TEX_IMAGE" and n.image and "rough" not in n.image.name.lower())
img = tex.image
W, H = img.size
px = np.array(img.pixels[:], dtype=np.float32).reshape(H, W, img.channels)
rgb = px[..., :3].copy()
me.calc_loop_triangles()
uvl = me.uv_layers.active.data
vco = np.array([bw @ v.co for v in me.vertices])
rot = bw.to_3x3()
vno = np.array([(rot @ v.normal).normalized() for v in me.vertices])
head_poly = np.zeros(len(me.polygons), dtype=bool)
for p in me.polygons:
    if p.material_index != 0:
        continue
    acc = {}
    for vi in p.vertices:
        for g in me.vertices[vi].groups:
            acc[names[g.group]] = acc.get(names[g.group], 0) + g.weight
    if acc and max(acc, key=acc.get) in ("head", "neck_01") and min(vco[i][2] for i in p.vertices) > 1.0:
        head_poly[p.index] = True
TY, TX, TP, TN, TF = [], [], [], [], []
for t in me.loop_triangles:
    if not head_poly[t.polygon_index]:
        continue
    uv3 = np.array([uvl[li].uv[:] for li in t.loops]) * [W, H]
    vi = list(t.vertices)
    x0, y0 = np.floor(uv3.min(0)).astype(int)
    x1, y1 = np.ceil(uv3.max(0)).astype(int)
    x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, W - 1), min(y1, H - 1)
    if x1 < x0 or y1 < y0:
        continue
    xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
    (ax, ay), (bx, by), (cx, cy) = uv3
    det = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
    if abs(det) < 1e-12:
        continue
    l1 = ((by - cy) * (xs - cx) + (cx - bx) * (ys - cy)) / det
    l2 = ((cy - ay) * (xs - cx) + (ax - cx) * (ys - cy)) / det
    l3 = 1 - l1 - l2
    ins = (l1 >= -0.05) & (l2 >= -0.05) & (l3 >= -0.05)
    if not ins.any():
        continue
    L = np.stack([l1[ins], l2[ins], l3[ins]], 1)
    TY.append((ys[ins] - 0.5).astype(int))
    TX.append((xs[ins] - 0.5).astype(int))
    TP.append(L @ vco[vi])
    nn = L @ vno[vi]
    TN.append(nn / np.linalg.norm(nn, axis=1, keepdims=True))
    TF.append(np.full(ins.sum(), t.polygon_index))
ty, tx = np.concatenate(TY), np.concatenate(TX)
P, N, F = np.concatenate(TP), np.concatenate(TN), np.concatenate(TF)
X, Y, Z = P[:, 0], P[:, 1], P[:, 2]
col = rgb[ty, tx]
lum = col @ np.array([0.299, 0.587, 0.114])
red = (col[:, 0] > 0.5) & (col[:, 0] > col[:, 1] * 1.6) & (col[:, 0] > col[:, 2] * 1.6)
dot_cream = (col[:, 0] > 0.8) & (col[:, 1] > 0.65) & (col[:, 2] < 0.65) & (Z > 1.33)
skinlike = (col[:, 0] > 0.6) & (col[:, 0] >= col[:, 1]) & (col[:, 1] >= col[:, 2] * 0.9) & ((col[:, 0] - col[:, 2]) > 0.18)
frontish = N[:, 1] < -0.25
report["head_texels"] = int(len(ty))

# ---- 3. regions.
# Hairline arch (front view): highest at the middle, down the temples.
hair_z = 1.348 - 5.0 * np.maximum(np.abs(X - 0.01) - 0.045, 0) ** 2
# Face oval below it; sides from the measured face width.
face_oval = (((X - 0.01) / 0.168) ** 2 + ((Z - 1.17) / np.where(Z < 1.17, 0.145, 0.24)) ** 2) < 1.0
# The middle of the face counts whatever way it faces (the nose's underside).
inner = (np.abs(X - 0.012) < 0.11) & (Z > 1.08) & (Z < 1.30) & (Y < -0.12)
face = face_oval & (Z < hair_z) & (frontish | inner)
# Ears: skin at the sides at cheek height (the sheet shows them).
# Only the ear islands themselves: skin-coloured faces in connected groups of
# 8-60 at the sides (the specks around them are hair).
bm = bmesh.new()
bm.from_mesh(me)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
bm.faces.ensure_lookup_table()
img_px = rgb


def face_skin(f):
    us = [l[bm.loops.layers.uv.active].uv for l in f.loops]
    u = (sum(q[0] for q in us) / len(us), sum(q[1] for q in us) / len(us))
    c = img_px[min(int(u[1] * H), H - 1), min(int(u[0] * W), W - 1)]
    return c[0] > 0.6 and c[0] >= c[1] >= c[2] * 0.9 and (c[0] - c[2]) > 0.18


side = [f for f in bm.faces if f.index < len(head_poly) and head_poly[f.index]
        and abs((bw @ f.calc_center_median()).x) > 0.19 and face_skin(f)]
sset, seen, ear_faces = set(side), set(), set()
for f in side:
    if f in seen:
        continue
    comp, st = [], [f]
    while st:
        g = st.pop()
        if g in seen:
            continue
        seen.add(g)
        comp.append(g)
        st += [h for e in g.edges for h in e.link_faces if h in sset and h not in seen]
    cz = np.mean([(bw @ g.calc_center_median()).z for g in comp])
    if 8 <= len(comp) <= 60 and 1.04 < cz < 1.20:   # ears are at cheek height
        ear_faces.update(g.index for g in comp)
bm.free()
report["ear_faces"] = len(ear_faces)
ear = np.isin(F, list(ear_faces))
# Headband: a band around the crown through the top and above the ears, and the knot.
A = np.array([0.0, -0.07, 1.47]); B = np.array([0.27, 0.02, 1.27]); C = np.array([-0.27, 0.02, 1.27])
bn = np.cross(B - A, C - A); bn /= np.linalg.norm(bn)
band = np.abs((P - A) @ bn) < 0.03
redP = P[red | dot_cream]
top = redP[redP[:, 2] > np.percentile(redP[:, 2], 92)] if len(redP) else np.zeros((1, 3))
knot_c = top.mean(0)
knot = np.linalg.norm(P - knot_c, axis=1) < 0.11
fabric = (red | dot_cream | skinlike) & (band | knot)
report["knot_centre"] = [round(float(v), 3) for v in knot_c]
report["headband_plane_normal"] = [round(float(v), 3) for v in bn]

# ---- 4. paint.
out_col = col.copy()
# Hair everywhere on the head that is not face, ear or headband fabric.
# Only texels that are hair, headband red or skin specks now (never the blouse
# collar or the towel at the neck).
hair = ~face & ~ear & ~fabric & ((lum < 0.3) | red | dot_cream | skinlike)
# Below the jaw at the front (neck) keep what is there.
keep_neck = (Z < 1.06) & frontish & ~face_oval
hair &= ~keep_neck
# Curl shading from the shell's own lumps: lighter where facing an up-front light.
Lgt = np.array([0.25, -0.45, 0.86]); Lgt /= np.linalg.norm(Lgt)
ndl = N @ Lgt
strands = 0.5 + 0.5 * np.sin(140 * (Z + 0.35 * np.sin(18 * X + 9 * Y)) + 40 * X)
hi = np.clip((ndl - 0.45) / 0.4, 0, 1) * (0.55 + 0.45 * (strands > 0.82))
lo = np.clip((0.05 - ndl) / 0.5, 0, 1) * 0.7
hc = HAIR + (HAIR_HI - HAIR) * hi[:, None] + (HAIR_LO - HAIR) * lo[:, None]
out_col[hair] = hc[hair]
out_col[ear] = SKIN
# Headband: flat red with even cream polka dots on a 3D lattice (the projected
# dots had grown into blotches).
RED = np.array([0.800, 0.200, 0.170])
CREAM = np.array([0.960, 0.860, 0.600])
g = 0.022
q = P / g
d = np.linalg.norm(q - np.round(q), axis=1) * g
dots = d < 0.0042
out_col[fabric] = RED
out_col[fabric & dots] = CREAM
# Face: flat skin, then the drawn features.
out_col[face] = SKIN
fx, fz = X - 0.012, Z


def arc(cx, cz, half_w, rise, thick, up=True):
    """Points near a parabolic arc through (cx±half_w, cz) with apex cz±rise."""
    u = (fx - cx) / half_w
    zc = cz + (rise if up else -rise) * (1 - u ** 2)
    return (np.abs(u) <= 1.0) & (np.abs(fz - zc) < thick * (1 - 0.45 * u ** 2))


def ell(cx, cz, rx, rz):
    return ((fx - cx) / rx) ** 2 + ((fz - cz) / rz) ** 2


feat = face | (frontish & (np.abs(fx) < 0.2) & (Z > 1.04) & (Z < 1.36) & ~hair)
# blush (soft)
for sx in (-1, 1):
    e = ell(sx * 0.118, 1.188, 0.05, 0.032)
    a = np.clip(1.15 - e, 0, 1) * 0.75
    m = feat & (a > 0)
    out_col[m] = out_col[m] * (1 - a[m, None]) + BLUSH * a[m, None]
# nose tip pink (on the shrunken nose)
nt = feat & (ell(0.003, 1.172, 0.032, 0.026) < 1) & (Y < NOSE_BASE_Y + 0.005)
a = np.clip(1 - ell(0.003, 1.165, 0.032, 0.024), 0, 1) * 0.6
out_col[nt] = out_col[nt] * (1 - a[nt, None]) + SKIN_PINK * a[nt, None]
# brows: thin, arched, a little outward-down
for sx in (-1, 1):
    m = feat & arc(sx * 0.088, 1.302, 0.042, 0.012, 0.0045)
    out_col[m] = LINE
# closed happy eyes (arched up) with a small lash at the outer end
for sx in (-1, 1):
    m = feat & arc(sx * 0.085, 1.236, 0.033, 0.013, 0.0042)
    out_col[m] = LINE
    lash = feat & (np.abs(fx - sx * 0.122) < 0.006) & (np.abs(fz - (1.236 + 0.004 * 0 - (fx - sx * 0.118) * sx * 0.6)) < 0.0035)
    out_col[lash] = LINE
# smile: open mouth (sheet 開心 / default happy), upper teeth, lip line
mouth_top = 1.128 + 0.010 * ((fx - 0.0) / 0.062) ** 2          # corners up
mouth_bot = 1.128 - 0.030 * (1 - ((fx - 0.0) / 0.062) ** 2)
inside = feat & (np.abs(fx) < 0.062) & (fz < mouth_top) & (fz > mouth_bot)
out_col[inside] = MOUTH_IN
teeth = inside & (fz > mouth_top - 0.009) & (np.abs(fx) < 0.045)
out_col[teeth] = TEETH
rim = feat & (np.abs(fx) < 0.068) & ~inside & (
    (np.abs(fz - mouth_top) < 0.003) | ((np.abs(fz - mouth_bot) < 0.004) & (np.abs(fx) < 0.062)))
out_col[rim] = LIP
report["texels"] = {"hair": int(hair.sum()), "face": int(face.sum()), "ear": int(ear.sum()),
                    "headband": int(fabric.sum()), "mouth": int(inside.sum())}

rgb[ty, tx] = out_col
px[..., :3] = rgb
new = bpy.data.images.new("market_auntie_r3_basecolor_head", W, H, alpha=img.channels == 4)
new.pixels.foreach_set(px.ravel())
new.filepath_raw = os.path.abspath(png)
new.file_format = "PNG"
new.save()
tex.image = new
bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(out))
json.dump(report, open(os.path.splitext(out)[0] + "_head.json", "w"), indent=1)
print("AUNTIE_HEAD_OK", json.dumps(report))
