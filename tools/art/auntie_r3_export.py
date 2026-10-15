"""Market auntie r3 (Claude): export a checkpoint to GLB (rig, 19 clips, skinned meshes).
  blender -b --factory-startup --python tools/art/auntie_r3_export.py -- <in.blend> <out.glb>"""
import os
import sys

import bpy

src, out = sys.argv[sys.argv.index("--") + 1:][:2]
bpy.ops.wm.open_mainfile(filepath=os.path.abspath(src))
for o in bpy.context.scene.objects:
    o.select_set(o.type == "ARMATURE" or (o.type == "MESH" and any(m.type == "ARMATURE" for m in o.modifiers)))
    if o.type == "ARMATURE":
        o.data.pose_position = "POSE"
os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
bpy.ops.export_scene.gltf(filepath=os.path.abspath(out), export_format="GLB", use_selection=True,
                          export_animations=True, export_animation_mode="ACTIONS", export_skins=True,
                          export_image_format="AUTO")
print("AUNTIE_EXPORT_OK", out, os.path.getsize(out))
