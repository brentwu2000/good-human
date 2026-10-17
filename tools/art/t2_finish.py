"""Trellis2 texture pass, step 4 (Claude, 2026-10-17): new basecolor into the character, export.
  blender -b --factory-startup --python tools/art/t2_finish.py -- <config.json> <work_dir> <out.glb>
- White balance: Trellis2 colour has an orange/dark cast; per-channel gain so its skin (inside
  the face mask) matches the sheet's skin (config sheet_skin), or, with sheet_body (dogs), so
  the whole body's median matches the sheet front's foreground median.
- The drawn face (current texture) is kept under the face mask, tone-matched to the new skin
  (LESSONS 6.14: generated faces lose the drawn features).
- hands_skin: hands whose UVs collapse to a point get the forearm skin painted on that texel.
- hair_tone [r,g,b]: hair (t2_hairmask) scaled to the sheet's hair colour.
- gain [r,g,b]: fixed white-balance gain (a second texture of the same character).
- create_base: the body has no basecolor texture (vertex colours): one is created.
- keep_boxes (t2_keepmask): the current texture stays there, tone-matched (keep_tone).
- redraw_mouth {cx, z, half_w, depth, lift, teeth, erase{cx,z,ax,az}}: erase the drawn mouth,
  paint a symmetric grin in front coordinates.
- delete_materials [keyword]: faces of those materials removed before export.
- corner_cloth {noise, hem, hem_dark}: per-face grain and a darker band at the lowest end.
- corner_shade s: corner colours darkened up to s on faces turned away from an up-front light.
- corner_colors {material keyword: rgba}: corner colours of those faces (Godot multiplies them).
Texels the bake did not reach keep the current texture.
"""
import json
import os
import sys

import bpy
import numpy as np

cfg_path, work, out = sys.argv[sys.argv.index("--") + 1:][:3]
cfg = json.load(open(cfg_path, encoding="utf-8"))
src = os.path.abspath(cfg["src"])
if cfg["src"].startswith("git:"):
    src = os.path.join(os.path.abspath(work), "src.glb")  # extracted by t2_run.sh
if src.endswith(".blend"):
    bpy.ops.wm.open_mainfile(filepath=src)
else:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=src)
body = bpy.data.objects[cfg.get("body", "Character")]

def base_image(ob):
    def upstream(sock, depth=0):
        # Base Color may come through a Mix with the vertex colour (Codex's chihuahua).
        if not sock.is_linked or depth > 4:
            return None
        n = sock.links[0].from_node
        if n.type == "TEX_IMAGE":
            return n
        for s in n.inputs:
            r = upstream(s, depth + 1)
            if r is not None:
                return r
        return None
    for s in ob.material_slots:
        if not (s.material and s.material.node_tree):
            continue
        if cfg.get("material") and s.material.name != cfg["material"]:
            continue
        for n in s.material.node_tree.nodes:
            if n.type == "BSDF_PRINCIPLED":
                tex = upstream(n.inputs["Base Color"])
                if tex is not None:
                    return s.material, tex
    raise SystemExit("no basecolor texture on " + ob.name)

def make_base(ob):
    """Vertex-coloured body (player shiba): a new image texture replaces the colour attribute
    as Base Color, and the attribute is removed (Godot multiplies albedo by COLOR_0)."""
    mat = ob.material_slots[0].material
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    vc = [n for n in nt.nodes if n.type in ("VERTEX_COLOR", "ATTRIBUTE")]
    size = int(cfg.get("texture_size", 2048))
    # The old look, for texels the bake does not reach: the attribute's mean colour.
    ca = ob.data.color_attributes[0]
    mean = np.array([sum(d.color[k] for d in ca.data) / len(ca.data) for k in range(3)])
    img = bpy.data.images.new(cfg["id"] + "_old", size, size, alpha=False)
    img.pixels.foreach_set(np.tile(np.r_[mean, 1.0], size * size).astype(np.float32))
    tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = img
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    for n in vc:
        nt.nodes.remove(n)
    while ob.data.color_attributes:
        ob.data.color_attributes.remove(ob.data.color_attributes[0])
    print("T2_FINISH vertex colours -> texture on", mat.name)
    return mat, tex

if cfg.get("create_base"):
    mat, tex_node = make_base(body)
else:
    mat, tex_node = base_image(body)
cur = tex_node.image
W, H = cur.size

def px(img):
    if tuple(img.size) != (W, H):
        img.scale(W, H)
    arr = np.empty(W * H * 4, np.float32); img.pixels.foreach_get(arr); return arr.reshape(H, W, 4)

def load(path):
    return px(bpy.data.images.load(os.path.abspath(path)))

c = px(cur)[..., :3].copy()
t = load(os.path.join(work, "t2_basecolor.png"))[..., :3]
m = load(os.path.join(work, "t2_facemask.png"))[..., 0].copy()
coverage = (t.sum(-1) > 0.003)[..., None]

def sheet_skin():
    # Measured outside Blender: median of the largest face-skin blob on the sheet front
    # (a top-of-figure measure picks up jackets/blouses, LESSONS 6.25).
    if "sheet_skin" not in cfg:
        raise SystemExit("set sheet_skin [r,g,b] in the config (largest face-skin blob on the sheet front)")
    return np.array(cfg["sheet_skin"], float) / 255.0

if cfg.get("gain"):
    gain = np.array(cfg["gain"], float)  # shared with another part of the same character
    print("T2_FINISH fixed gain", gain.round(3))
elif cfg.get("sheet_body"):
    # No skin to match (dogs): the whole baked body against the sheet's foreground median.
    ref = np.array(cfg["sheet_body"], float) / 255.0
    gain = np.clip(ref / np.median(t[coverage[..., 0]], 0), 0.8, 2.2)
    print("T2_FINISH sheet body", cfg["sheet_body"], "gain", gain.round(3))
else:
    skin_ref = sheet_skin()
    tt = t[m > 0.6]
    sk = (tt[:, 0] > 0.3) & (tt[:, 0] > tt[:, 1]) & (tt[:, 1] > tt[:, 2])
    gain = np.clip(skin_ref / np.median(tt[sk], 0), 0.8, 2.2)
    print("T2_FINISH sheet skin", (skin_ref * 255).round(), "gain", gain.round(3))
t3 = np.clip(t * gain, 0, 1)
res = np.where(coverage, t3, c)

# Hair tone: a light hair colour (grandma's silver) comes out dark.
if cfg.get("hair_tone") and os.path.exists(os.path.join(work, "t2_hairmask.png")):
    hm = load(os.path.join(work, "t2_hairmask.png"))[..., 0] > 0.5
    hm &= coverage[..., 0]
    gh = (np.array(cfg["hair_tone"], float) / 255.0) / np.maximum(np.median(res[hm], 0), 1e-3)
    res[hm] = np.clip(res[hm] * gh, 0, 1)
    print("T2_FINISH hair tone", hm.sum(), "texels, gain", gh.round(2))

# Drawn face, tone-matched.
sel = m > 0.6 if cfg.get("keep_face", True) else np.zeros_like(m, bool)
cs, ts = c[sel], t3[sel]
skin = (cs[:, 0] > 0.55) & (cs[:, 0] > cs[:, 2] + 0.1)
if skin.sum() > 100:
    gface = np.median(ts[skin], 0) / np.maximum(np.median(cs[skin], 0), 1e-3)
    if not cfg.get("face_tone", True):
        gface = np.ones(3)  # dogs: the body white balance already matches the old face
    print("T2_FINISH face tone gain", gface.round(3))
    res = res * (1 - m[..., None]) + np.clip(c * gface, 0, 1) * m[..., None]

# Kept regions (keep_boxes): the current texture, tone-matched to the new one around them.
kp = os.path.join(work, "t2_keepmask.png")
if cfg.get("keep_boxes") and os.path.exists(kp):
    import numpy as _np
    km = load(kp)[..., 0]
    # soften the edge a little in texture space
    try:
        from scipy import ndimage as _nd
        km = _nd.gaussian_filter(km, 3)
    except Exception:
        pass
    sel_k = km > 0.6
    if sel_k.sum() > 100:
        gk = _np.median(t3[sel_k], 0) / _np.maximum(_np.median(c[sel_k], 0), 1e-3)
        gk = _np.clip(gk, 0.8, 1.25) if cfg.get("keep_tone", True) else _np.ones(3)
        res = res * (1 - km[..., None]) + _np.clip(c * gk, 0, 1) * km[..., None]
        print("T2_FINISH kept old texture", int(sel_k.sum()), "texels, tone", gk.round(3))

# redraw_mouth: erase the drawn mouth and paint a symmetric grin in the face's own front
# coordinates (x, z rest pose, m). Texels get their 3D point by rasterising the body's
# triangles in UV space.
rm = cfg.get("redraw_mouth")
if rm:
    er = rm["erase"]
    me_ = body.data
    me_.calc_loop_triangles()
    uvl = me_.uv_layers[0].data
    mw = body.matrix_world
    V = np.array([tuple(mw @ v.co) for v in me_.vertices])
    NZ = np.array([tuple((mw.to_3x3() @ v.normal).normalized()) for v in me_.vertices])
    box = (abs(V[:, 0] - er["cx"]) < er["ax"] * 1.3) & (abs(V[:, 2] - er["z"]) < er["az"] * 1.6) & (NZ[:, 1] < -0.2)
    tex_x = np.full((H, W), np.nan); tex_z = np.full((H, W), np.nan)
    for tri in me_.loop_triangles:
        vs = tri.vertices
        if not all(box[i] for i in vs):
            continue
        uv = np.array([uvl[li].uv[:] for li in tri.loops]) * [W, H]
        x0, y0 = np.floor(uv.min(0)).astype(int); x1, y1 = np.ceil(uv.max(0)).astype(int)
        if x1 - x0 > 200 or y1 - y0 > 200:
            continue
        gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        (ax_, ay_), (bx_, by_), (cx_, cy_) = uv
        den = (by_ - cy_) * (ax_ - cx_) + (cx_ - bx_) * (ay_ - cy_)
        if abs(den) < 1e-9:
            continue
        l1 = ((by_ - cy_) * (gx - cx_) + (cx_ - bx_) * (gy - cy_)) / den
        l2 = ((cy_ - ay_) * (gx - cx_) + (ax_ - cx_) * (gy - cy_)) / den
        l3 = 1 - l1 - l2
        inside = (l1 >= -0.02) & (l2 >= -0.02) & (l3 >= -0.02)
        P3 = V[list(vs)]
        X = l1 * P3[0, 0] + l2 * P3[1, 0] + l3 * P3[2, 0]
        Z = l1 * P3[0, 2] + l2 * P3[1, 2] + l3 * P3[2, 2]
        yy, xx = gy[inside].astype(int), gx[inside].astype(int)
        ok = (yy >= 0) & (yy < H) & (xx >= 0) & (xx < W)
        tex_x[yy[ok], xx[ok]] = X[inside][ok]; tex_z[yy[ok], xx[ok]] = Z[inside][ok]
    # Grow the 3D map a few texels over island borders (seams would keep old pixels).
    for _ in range(6):
        for sh in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            nx = np.roll(tex_x, sh, (0, 1)); nzz = np.roll(tex_z, sh, (0, 1))
            m_ = np.isnan(tex_x) & ~np.isnan(nx)
            tex_x[m_] = nx[m_]; tex_z[m_] = nzz[m_]
    have = ~np.isnan(tex_x)
    # image rows: Blender pixels are bottom-up, uv v also bottom-up -> same orientation
    d_er = ((tex_x - er["cx"]) / er["ax"]) ** 2 + ((tex_z - er["z"]) / er["az"]) ** 2
    ring = have & (d_er > 1.3) & (d_er < 2.2)
    # Skin fill: a linear colour-vs-height fit over skin-coloured ring texels (smooth, no bands).
    rr = res[ring]
    skin_ok = (rr[:, 0] > 0.45) & (rr[:, 0] > rr[:, 1]) & (rr[:, 1] > rr[:, 2]) & (rr[:, 0] - rr[:, 2] < 0.5)
    zr = tex_z[ring][skin_ok]; cr = rr[skin_ok]
    A = np.stack([zr - er["z"], np.ones_like(zr)], 1)
    coef, *_ = np.linalg.lstsq(A, cr, rcond=None)
    zz = np.nan_to_num(tex_z, nan=er["z"]) - er["z"]
    fill = np.clip(zz[..., None] * coef[0] + coef[1], 0, 1)
    skin_c = coef[1]
    ew = np.clip((1.3 - np.nan_to_num(d_er, nan=9)) / 0.5, 0, 1)[..., None] * have[..., None]
    res = res * (1 - ew) + fill * ew
    # the grin: u in [-1, 1] across the mouth
    cx0, zm, hw = rm["cx"], rm["z"], rm["half_w"]
    u = (tex_x - cx0) / hw
    up = zm + rm["lift"] * u ** 2                       # upper lip: corners lifted
    lo = zm - rm["depth"] * (1 - u ** 2) + rm["lift"] * u ** 2 * 0.9  # lower lip: deep U
    inside_m = have & (np.abs(u) <= 1) & (tex_z <= up) & (tex_z >= lo)
    teeth = inside_m & (tex_z >= up - rm["teeth"] * np.sqrt(np.clip(1 - u ** 2, 0, 1)))
    px_m = 0.0018  # ~ one texel in metres on this face, for the outline
    edge = have & (np.abs(u) <= 1.06) & (
        (np.abs(tex_z - up) < px_m * 1.4) | (np.abs(tex_z - lo) < px_m * 1.4) & (np.abs(u) <= 1))
    mouth_col = np.array(rm.get("inner", [0.42, 0.09, 0.10]))
    res[inside_m] = mouth_col
    tongue = inside_m & (tex_z < lo + rm["depth"] * 0.26) & (np.abs(u) < 0.42)
    res[tongue] = np.array(rm.get("tongue", [0.80, 0.38, 0.40]))
    res[teeth] = np.array([0.97, 0.96, 0.94])
    res[edge] = np.array(rm.get("line", [0.30, 0.08, 0.08]))
    print("T2_FINISH redrew mouth: %d texels, erase %d, skin %s" % (inside_m.sum(), (ew[..., 0] > 0.5).sum(), (skin_c * 255).round()))

if cfg.get("hands_skin"):
    gn = {g.index: g.name for g in body.vertex_groups}
    def dom(v):
        b = max(v.groups, key=lambda e: e.weight, default=None)
        return gn[b.group] if b else ""
    vb = [dom(v) for v in body.data.vertices]
    uvl = body.data.uv_layers[0].data
    hand_uv, fore_uv = set(), []
    for f in body.data.polygons:
        bs = [vb[i] for i in f.vertices]
        uvs = [(min(W - 1, int(uvl[li].uv[0] * W)), min(H - 1, int(uvl[li].uv[1] * H))) for li in f.loop_indices]
        if all(b.startswith(("hand_", "index_", "middle_", "ring_", "pinky_", "thumb_")) for b in bs):
            if max(abs(u[0] - uvs[0][0]) + abs(u[1] - uvs[0][1]) for u in uvs) <= 2:
                hand_uv.update(uvs)
        elif all(b.startswith("lowerarm") for b in bs):
            fore_uv += uvs
    if hand_uv and fore_uv:
        fs = np.array([res[y, x] for x, y in fore_uv])
        fs = fs[(fs[:, 0] > fs[:, 1]) & (fs[:, 1] > fs[:, 2]) & (fs[:, 0] > 0.5)]
        sc_ = np.median(fs, 0)
        for x, y in hand_uv:
            res[max(0, y - 3):y + 4, max(0, x - 3):x + 4] = sc_
        print("T2_FINISH hand uv spots", len(hand_uv), "<- forearm skin", sc_.round(3))

name = cfg["id"] + "_t2_basecolor"
img = bpy.data.images.new(name, W, H, alpha=False)
img.pixels.foreach_set(np.concatenate([res, np.ones((H, W, 1))], -1).astype(np.float32).ravel())
img.filepath_raw = os.path.join(os.path.abspath(work), name + ".png"); img.file_format = "PNG"; img.save()
tex_node.image = img

for kw, rgba in cfg.get("corner_colors", {}).items():
    idx = [i for i, s in enumerate(body.material_slots) if s.material and kw in s.material.name]
    ca = body.data.color_attributes[0]
    shade = cfg.get("corner_shade")  # soft light/shadow so a plain cloth does not read as paper
    cloth = cfg.get("corner_cloth", {})  # {"noise": per-face grain, "hem": end band share, "hem_dark": k}
    rng = np.random.default_rng(1)
    fz = [f.center.z for f in body.data.polygons if f.material_index in idx]
    z_lo, z_hi = (min(fz), max(fz)) if fz else (0.0, 1.0)
    n = 0
    for f in body.data.polygons:
        if f.material_index in idx:
            for li in f.loop_indices:
                col_ = list(rgba)
                if shade:
                    nz = f.normal
                    # Lambert from an up-front-left light; s = darkest share (folds, the side away)
                    lam = max(0.0, 0.35 * nz[0] - 0.55 * nz[1] + 0.76 * nz[2])
                    k_ = 1.0 - float(shade) * (1.0 - lam)
                    col_ = [col_[0] * k_, col_[1] * k_, col_[2] * min(1.0, k_ * 1.04), col_[3]]
                ca.data[li].color = col_
            if cloth:
                g = 1.0 + float(cloth.get("noise", 0.0)) * rng.uniform(-1, 1)
                hz = (f.center.z - z_lo) / max(z_hi - z_lo, 1e-6)
                if hz < float(cloth.get("hem", 0.0)):
                    g *= float(cloth.get("hem_dark", 0.8))
                for li in f.loop_indices:
                    c4 = ca.data[li].color
                    ca.data[li].color = (min(1, c4[0] * g), min(1, c4[1] * g), min(1, c4[2] * g), c4[3])
            n += 1
    print("T2_FINISH corner colour", kw, n, "faces", "shaded" if shade else "")

# delete_materials: faces of these materials are removed (the auntie's flat towel slab).
dm = cfg.get("delete_materials", [])
if dm:
    import bmesh
    idx = [i for i, s in enumerate(body.material_slots) if s.material and any(k in s.material.name for k in dm)]
    bm = bmesh.new(); bm.from_mesh(body.data)
    gone = [f for f in bm.faces if f.material_index in idx]
    bmesh.ops.delete(bm, geom=gone, context="FACES")
    bm.to_mesh(body.data); bm.free()
    print("T2_FINISH deleted", len(gone), "faces of", dm)

# Export what the character is made of: the rig, skinned meshes, meshes on the rig.
for o in bpy.context.scene.objects:
    keep = o.type == "ARMATURE" or (o.type == "MESH" and (
        any(md.type == "ARMATURE" for md in o.modifiers) or bool(o.parent and o.parent.type == "ARMATURE")))
    o.select_set(keep)
    if o.type == "ARMATURE":
        o.data.pose_position = "POSE"
os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
bpy.ops.export_scene.gltf(filepath=os.path.abspath(out), export_format="GLB", use_selection=True,
                          export_animations=True, export_animation_mode="ACTIONS", export_skins=True,
                          export_image_format="AUTO")
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.path.abspath(work), "t2_final.blend"))
print("T2_FINISH exported", out, os.path.getsize(out), [o.name for o in bpy.context.selected_objects])
