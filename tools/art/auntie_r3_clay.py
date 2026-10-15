"""Market auntie r3 (Claude): clay renders (no texture) of the head and hands in rest pose,
to tell geometry from paint. blender -b --factory-startup --python tools/art/auntie_r3_clay.py -- <glb> <out dir>"""
import math
import os
import sys

import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
glb, out = argv[:2]
MODE = argv[2] if len(argv) > 2 else "detail"
os.makedirs(out, exist_ok=True)
bpy.ops.import_scene.gltf(filepath=glb)
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
arm.data.pose_position = "REST"
for o in bpy.data.objects:
    if o.type == "MESH" and not any(m.type == "ARMATURE" for m in o.modifiers):
        o.hide_render = True
clay = bpy.data.materials.new("clay")
clay.use_nodes = True
clay.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.7, 0.7, 0.7, 1)
for o in bpy.data.objects:
    if o.type == "MESH":
        o.data.materials.clear()
        o.data.materials.append(clay)
scn = bpy.context.scene
scn.render.engine = "BLENDER_EEVEE"
scn.render.resolution_x = scn.render.resolution_y = 640
scn.view_settings.view_transform = "Standard"
w = bpy.data.worlds.new("w")
w.use_nodes = True
w.node_tree.nodes["Background"].inputs["Color"].default_value = (0.5, 0.52, 0.55, 1)
scn.world = w
for name, rot, e in (("key", (math.radians(50), 0, math.radians(30)), 1.4), ("fill", (math.radians(70), 0, math.radians(200)), 0.5)):
    ld = bpy.data.lights.new(name, "SUN")
    ld.energy = e
    lo = bpy.data.objects.new(name, ld)
    lo.rotation_euler = rot
    scn.collection.objects.link(lo)
cd = bpy.data.cameras.new("c")
cd.type = "ORTHO"
cam = bpy.data.objects.new("c", cd)
scn.collection.objects.link(cam)
scn.camera = cam


def bone(n):
    return arm.matrix_world @ arm.data.bones[n].head_local


def shot(target, yaw, pitch, size, path):
    t, p = math.radians(yaw), math.radians(pitch)
    d = Vector((math.sin(t) * math.cos(p), -math.cos(t) * math.cos(p), math.sin(p)))
    cam.location = target + d * 5
    cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    cd.ortho_scale = size
    scn.render.filepath = os.path.abspath(path)
    bpy.ops.render.render(write_still=True)


if MODE == "arms":
    for s in ("l", "r"):
        c = bone(f"hand_{s}")
        for v, y in (("front", 0), ("out", 90 if s == "l" else -90), ("back", 180), ("in", -90 if s == "l" else 90)):
            shot(c, y, 5, 0.4, f"{out}/clay_arm_{s}_{v}.png")
    sys.exit(0)
head = bone("head") + Vector((0, 0, 0.2))
for v, y, p in (("front", 0, 0), ("tq", 40, 0), ("side", 90, 0), ("back", 180, 0), ("top", 0, 70)):
    shot(head, y, p, 0.6, f"{out}/clay_head_{v}.png")
for s in ("l", "r"):
    hp = bone(f"hand_{s}") + Vector((0, 0, -0.07))
    shot(hp, 60 if s == "l" else -60, 10, 0.32, f"{out}/clay_hand_{s}.png")
    shot(hp, 0, 10, 0.32, f"{out}/clay_hand_{s}_front.png")
