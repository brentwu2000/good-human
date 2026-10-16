"""Trellis2 texture pass, step 4 (Claude, 2026-10-17): new basecolor into the character, export.
  blender -b --factory-startup --python tools/art/t2_finish.py -- <config.json> <work_dir> <out.glb>
- White balance: Trellis2 colour has an orange/dark cast; per-channel gain so its skin (inside
  the face mask) matches the sheet's skin (config sheet_skin, else measured on the front view).
- The drawn face (current texture) is kept under the face mask, tone-matched to the new skin
  (LESSONS 6.14: generated faces lose the drawn features).
- hands_skin: hands whose UVs collapse to a point get the forearm skin painted on that texel.
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
if src.endswith(".blend"):
    bpy.ops.wm.open_mainfile(filepath=src)
else:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=src)
body = bpy.data.objects[cfg.get("body", "Character")]

def base_image(ob):
    for s in ob.material_slots:
        if not (s.material and s.material.node_tree):
            continue
        for n in s.material.node_tree.nodes:
            if n.type == "BSDF_PRINCIPLED" and n.inputs["Base Color"].is_linked:
                src_n = n.inputs["Base Color"].links[0].from_node
                if src_n.type == "TEX_IMAGE":
                    return s.material, src_n
    raise SystemExit("no basecolor texture on " + ob.name)

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
    if "sheet_skin" in cfg:
        return np.array(cfg["sheet_skin"], float) / 255.0
    im = bpy.data.images.load(os.path.abspath(cfg["front"]))
    w, h = im.size
    a = np.empty(w * h * 4, np.float32); im.pixels.foreach_get(a)
    a = a.reshape(h, w, 4)[::-1, :, :3]  # top row first
    bg = np.median(np.concatenate([a[:8, :8].reshape(-1, 3), a[:8, -8:].reshape(-1, 3)]), 0)
    fg = np.abs(a - bg).sum(-1) > 0.12
    ys = np.nonzero(fg.any(1))[0]
    top, bot = ys[0], ys[-1]
    head = a[top: top + int(0.3 * (bot - top))]
    r, g, b = head[..., 0], head[..., 1], head[..., 2]
    sk = (r > 0.55) & (r - b > 0.18) & (r - g > 0.06) & (g > b) & (fg[top: top + int(0.3 * (bot - top))])
    if sk.sum() < 200:
        raise SystemExit("sheet skin not found; set sheet_skin in the config")
    return np.median(head[sk], 0)

skin_ref = sheet_skin()
tt = t[m > 0.6]
sk = (tt[:, 0] > 0.3) & (tt[:, 0] > tt[:, 1]) & (tt[:, 1] > tt[:, 2])
gain = np.clip(skin_ref / np.median(tt[sk], 0), 0.8, 2.2)
print("T2_FINISH sheet skin", (skin_ref * 255).round(), "gain", gain.round(3))
t3 = np.clip(t * gain, 0, 1)
res = np.where(coverage, t3, c)

# Drawn face, tone-matched.
sel = m > 0.6
cs, ts = c[sel], t3[sel]
skin = (cs[:, 0] > 0.55) & (cs[:, 0] > cs[:, 2] + 0.1)
if skin.sum() > 100:
    gface = np.median(ts[skin], 0) / np.maximum(np.median(cs[skin], 0), 1e-3)
    print("T2_FINISH face tone gain", gface.round(3))
    res = res * (1 - m[..., None]) + np.clip(c * gface, 0, 1) * m[..., None]

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
    n = 0
    for f in body.data.polygons:
        if f.material_index in idx:
            for li in f.loop_indices:
                ca.data[li].color = rgba
            n += 1
    print("T2_FINISH corner colour", kw, n, "faces")

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
