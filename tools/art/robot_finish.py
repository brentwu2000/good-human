"""Bunny robot (Xiaomi toy proxy, Phase 3; Claude 2026-10-17), step 4: colour, cut, export.
  blender -b <work>/low.blend --python tools/art/robot_finish.py -- <colours.npz> <sheet_front.png> <out.glb> [config.json]
1. Trellis2 vertex colours -> the low mesh's UVs (Cycles emit bake, no nvdiffrast), white-
   balanced to the sheet (median of its robot pixels).
2. Cut into rigid toy parts by height/width (Head with ears, Torso, ArmL/R, LegL/R) — a toy
   robot is rigid pieces, so FighterPuppet3D's greybox actions turn them on their joints.
3. Kept facing glTF +Z (as generated): FighterPuppet3D's greybox actions swing limbs towards
   their local +Z, so BunnyRobot3D turns the whole body 180 deg once instead. Scaled so the hip
   pivot sits at Greybox.HIP_HEIGHT (0.72), each part's origin at its joint (ArmL/LegL at -X).
Config (defaults from the measured width profile): hip_z, neck_z, shoulder_z, arm_x, leg_x
(metres on the 1.0 m prep mesh).
"""
import json
import os
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Vector, kdtree

a = sys.argv[sys.argv.index("--") + 1:]
npz, sheet, out = a[0], a[1], a[2]
cfg = {"hip_z": 0.13, "neck_z": 0.42, "shoulder_z": 0.36, "arm_x": 0.21, "leg_x": 0.11, "texture": 1024}
if len(a) > 3:
    cfg.update(json.load(open(a[3], encoding="utf-8")))
HIP = 0.72

low = bpy.data.objects["low"]
me = low.data

# ---- 1. colour
d = np.load(npz)
gp, gc = d["pos"], d["col"].astype(np.float64) / 255.0
bp = np.stack([gp[:, 0], -gp[:, 2], gp[:, 1]], 1)
kd = kdtree.KDTree(len(bp))
for i, p in enumerate(bp):
    kd.insert(p, i)
kd.balance()
cols = np.zeros((len(me.vertices), 3))
for i, v in enumerate(me.vertices):
    near = kd.find_n(v.co, 4)
    w = np.array([1.0 / max(dd, 1e-5) for _, _, dd in near])
    cols[i] = (gc[[j for _, j, _ in near]] * w[:, None]).sum(0) / w.sum()
img = bpy.data.images.load(os.path.abspath(sheet))
W, H = img.size
px = np.empty(W * H * 4, np.float32); img.pixels.foreach_get(px)
px = px.reshape(H, W, 4)[..., :3]
fg = px.sum(-1) < 2.75  # not the white background
sheet_med = np.median(px[fg], 0)  # linear already (Blender pixels)
srgb_sheet = np.where(sheet_med <= 0.0031308, sheet_med * 12.92, 1.055 * sheet_med ** (1 / 2.4) - 0.055)
gain = np.clip(srgb_sheet / np.maximum(np.median(cols, 0), 1e-3), 0.8, 2.2)
print("ROBOT white balance sheet %s mesh %s gain %s" % ((srgb_sheet * 255).round(), (np.median(cols, 0) * 255).round(), gain.round(3)))
cols = np.clip(cols * gain, 0, 1)
lin = np.where(cols <= 0.04045, cols / 12.92, ((cols + 0.055) / 1.055) ** 2.4)
attr = me.color_attributes.new("t2", "FLOAT_COLOR", "POINT")
for i in range(len(me.vertices)):
    attr.data[i].color = (*lin[i], 1.0)

sc = bpy.context.scene
sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 1
bake = bpy.data.materials.new("bake"); bake.use_nodes = True
nt = bake.node_tree; nt.nodes.clear()
an = nt.nodes.new("ShaderNodeAttribute"); an.attribute_name = "t2"
em = nt.nodes.new("ShaderNodeEmission"); on = nt.nodes.new("ShaderNodeOutputMaterial")
nt.links.new(an.outputs["Color"], em.inputs["Color"]); nt.links.new(em.outputs[0], on.inputs[0])
tex = nt.nodes.new("ShaderNodeTexImage")
size = int(cfg["texture"])
base = bpy.data.images.new("bunny_robot_basecolor", size, size, alpha=False)
tex.image = base; nt.nodes.active = tex
me.materials.clear(); me.materials.append(bake)
bpy.ops.object.select_all(action="DESELECT"); low.select_set(True); bpy.context.view_layer.objects.active = low
bpy.ops.object.bake(type="EMIT", margin=6, use_clear=True)
base.filepath_raw = os.path.join(os.path.dirname(os.path.abspath(out)), "bunny_robot_basecolor.png")
base.file_format = "PNG"; base.save()
# Game material: the baked colour, a soft toy-plastic finish.
mat = bpy.data.materials.new("BunnyRobot"); mat.use_nodes = True
bsdf = mat.node_tree.nodes["Principled BSDF"]
ti = mat.node_tree.nodes.new("ShaderNodeTexImage"); ti.image = base
mat.node_tree.links.new(ti.outputs["Color"], bsdf.inputs["Base Color"])
bsdf.inputs["Roughness"].default_value = 0.45
me.materials.clear(); me.materials.append(mat)
me.color_attributes.remove(me.color_attributes["t2"])

# ---- 2. cut into parts (by face centre)
def part_of(c: Vector) -> str:
    if c.z >= cfg["neck_z"]:
        return "Head"
    if c.z < cfg["hip_z"]:
        return "LegL" if c.x < 0 else "LegR"
    if abs(c.x) > cfg["arm_x"]:
        return "ArmL" if c.x < 0 else "ArmR"
    return "Torso"

names = ["Head", "Torso", "ArmL", "ArmR", "LegL", "LegR"]
pivots = {
    "Torso": Vector((0, 0, cfg["hip_z"])),
    "Head": Vector((0, 0, cfg["neck_z"])),
    "ArmL": Vector((-cfg["arm_x"], 0, cfg["shoulder_z"])),
    "ArmR": Vector((cfg["arm_x"], 0, cfg["shoulder_z"])),
    "LegL": Vector((-cfg["leg_x"], 0, cfg["hip_z"])),
    "LegR": Vector((cfg["leg_x"], 0, cfg["hip_z"])),
}
counts = {}
parts = {}
for name in names:
    dup = low.copy(); dup.data = low.data.copy(); dup.name = "Part_" + name
    sc.collection.objects.link(dup)
    bm = bmesh.new(); bm.from_mesh(dup.data)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if part_of(f.calc_center_median()) != name], context="FACES")
    bm.to_mesh(dup.data); bm.free()
    counts[name] = len(dup.data.polygons)
    parts[name] = dup
bpy.data.objects.remove(low)
print("ROBOT parts " + ", ".join("%s %d" % (k, v) for k, v in counts.items()))

# ---- 3. hip at 0.72, origins at the joints; facing unchanged (see the docstring).
k = HIP / cfg["hip_z"]
for name, ob in parts.items():
    piv = pivots[name]
    for v in ob.data.vertices:
        p = v.co - piv
        v.co = p * k
    ob.data.update()
    ob.location = piv * k
print("ROBOT scale k %.3f, hip %.3f, neck %.3f, shoulder %.3f (body units); toy height at body_scale s = %.3f*s m" % (k, cfg["hip_z"] * k, cfg["neck_z"] * k, cfg["shoulder_z"] * k, k))

bpy.ops.object.select_all(action="DESELECT")
for ob in parts.values():
    ob.select_set(True)
os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
bpy.ops.export_scene.gltf(filepath=os.path.abspath(out), export_format="GLB", use_selection=True,
                          export_image_format="AUTO", export_apply=True)
print("ROBOT exported", out, os.path.getsize(out))
