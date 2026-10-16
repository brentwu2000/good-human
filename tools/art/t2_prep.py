"""Trellis2 texture pass, step 1 (Claude, 2026-10-17): the body in rest pose, subdivided.
  blender -b --factory-startup --python tools/art/t2_prep.py -- <config.json> <work_dir>
Source is the character's .blend checkpoint or its runtime GLB (config "src"). Writes
<work_dir>/hi.glb (positions only, for Trellis2) and <work_dir>/hi.blend (all objects kept:
props are needed by the bake). Simple subdivision keeps the surface and the UVs.
"""
import json
import os
import sys

import bpy

cfg_path, work = sys.argv[sys.argv.index("--") + 1:][:2]
cfg = json.load(open(cfg_path, encoding="utf-8"))
os.makedirs(work, exist_ok=True)
src = os.path.abspath(cfg["src"])
if src.endswith(".blend"):
    bpy.ops.wm.open_mainfile(filepath=src)
else:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=src)
for o in bpy.data.objects:
    if o.type == "ARMATURE":
        o.data.pose_position = "REST"
body = bpy.data.objects[cfg.get("body", "Character")]
bpy.context.view_layer.update()
dg = bpy.context.evaluated_depsgraph_get()
me = bpy.data.meshes.new_from_object(body.evaluated_get(dg), preserve_all_data_layers=True, depsgraph=dg)
hi = bpy.data.objects.new("hi", me)
bpy.context.scene.collection.objects.link(hi)
hi.matrix_world = body.matrix_world  # vertex group names travel with the mesh data
sub = hi.modifiers.new("sub", "SUBSURF")
sub.subdivision_type = "SIMPLE"
sub.levels = sub.render_levels = int(cfg.get("subdiv", 2))
bpy.ops.object.select_all(action="DESELECT")
hi.select_set(True)
bpy.context.view_layer.objects.active = hi
bpy.ops.object.modifier_apply(modifier="sub")
print("T2_PREP hi faces", len(hi.data.polygons))
bpy.ops.export_scene.gltf(filepath=os.path.join(work, "hi.glb"), use_selection=True,
                          export_materials="NONE", export_skins=False, export_animations=False,
                          export_texcoords=False, export_normals=True, export_vertex_color="NONE")
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(work, "hi.blend"))
