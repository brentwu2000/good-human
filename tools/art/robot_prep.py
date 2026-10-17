"""Bunny robot (Xiaomi toy proxy, Phase 3; Claude 2026-10-17), step 2: clean the TripoSG mesh.
  blender -b --factory-startup --python tools/art/robot_prep.py -- <raw.glb> <work_dir>
Keeps the big connected pieces, stands it on the ground facing -Y (glTF +Z), scales it to 1.0 m,
and writes <work>/hi.glb (~150k tris, for Trellis2) and <work>/low.blend (~12k tris with a smart
UV unwrap, for the bake and the split). Prints the width profile used to find the joints.
"""
import os
import sys

import bmesh
import bpy
from mathutils import Vector

raw, work = sys.argv[sys.argv.index("--") + 1:][:2]
os.makedirs(work, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=os.path.abspath(raw))
meshes = [o for o in bpy.data.objects if o.type == "MESH"]
bpy.ops.object.select_all(action="DESELECT")
for o in meshes:
    o.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
ob = bpy.context.view_layer.objects.active
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

# Keep pieces with at least 2 % of the faces (TripoSG leaves specks).
bm = bmesh.new(); bm.from_mesh(ob.data)
bm.faces.ensure_lookup_table()
seen = set(); pieces = []
for f in bm.faces:
    if f.index in seen:
        continue
    stack = [f]; comp = []; seen.add(f.index)
    while stack:
        g = stack.pop(); comp.append(g)
        for e in g.edges:
            for h in e.link_faces:
                if h.index not in seen:
                    seen.add(h.index); stack.append(h)
    pieces.append(comp)
total = len(bm.faces)
drop = [f for comp in pieces if len(comp) < 0.02 * total for f in comp]
bmesh.ops.delete(bm, geom=drop, context="FACES")
bm.to_mesh(ob.data); bm.free()
print("ROBOT pieces %d, kept faces %d of %d" % (len(pieces), len(ob.data.polygons), total))

# On the ground, centred, 1.0 m tall.
pts = [ob.matrix_world @ v.co for v in ob.data.vertices]
lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
s = 1.0 / (hi.z - lo.z)
for v in ob.data.vertices:
    v.co = Vector(((v.co.x - (lo.x + hi.x) / 2) * s, (v.co.y - (lo.y + hi.y) / 2) * s, (v.co.z - lo.z) * s))
ob.data.update()

# Width profile (x extent per 2 cm band), to read neck / shoulders / hips.
prof = {}
for v in ob.data.vertices:
    b = int(v.co.z / 0.02)
    lo_, hi_ = prof.get(b, (9.0, -9.0))
    prof[b] = (min(lo_, v.co.x), max(hi_, v.co.x))
print("ROBOT profile " + " ".join("%.2f:%.2f" % (b * 0.02, prof[b][1] - prof[b][0]) for b in sorted(prof)))

def decimated(name: str, faces: int) -> bpy.types.Object:
    dup = ob.copy(); dup.data = ob.data.copy(); dup.name = name
    bpy.context.scene.collection.objects.link(dup)
    m = dup.modifiers.new("dec", "DECIMATE")
    m.ratio = min(1.0, faces / max(len(ob.data.polygons), 1))
    bpy.ops.object.select_all(action="DESELECT")
    dup.select_set(True); bpy.context.view_layer.objects.active = dup
    bpy.ops.object.modifier_apply(modifier="dec")
    return dup

hi_ob = decimated("hi", 150000)
bpy.ops.object.select_all(action="DESELECT"); hi_ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(work, "hi.glb"), use_selection=True, export_materials="NONE",
                          export_texcoords=False, export_vertex_color="NONE")
low = decimated("low", 12000)
bpy.ops.object.select_all(action="DESELECT"); low.select_set(True); bpy.context.view_layer.objects.active = low
bpy.ops.object.shade_smooth()
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.004)
bpy.ops.object.mode_set(mode="OBJECT")
bpy.data.objects.remove(hi_ob)
bpy.data.objects.remove(ob)
print("ROBOT low faces %d" % len(low.data.polygons))
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(work, "low.blend"))
