"""Style Bible v1 proportions for an already rigged character (owner request,
AI 3D pipeline v5): bigger head, hands, feet / ears, paws — without touching the
skeleton or the animations.

  blender -b --factory-startup --python tools/art/stylize_rigged.py -- \
      <in.glb> <out.glb> <preset: human|shiba>

In the rest pose each vertex moves by its own skin weights: for a part (a set of
bones) the weight w is the vertex's summed weight on those bones, and the vertex
moves w·(s−1)·(v − pivot), the pivot being the part's joint. Skin weights already
blend at the joints, so the neck and wrists stay smooth. Meshes parented to a bone
(eyes, nose) move with that bone's part as a whole. Bones stay where they are, so
every clip plays unchanged. The input file is not modified.
"""
import os
import sys

import bpy
from mathutils import Vector

PRESETS = {
    # part: (bones, scale, pivot bone, pivot on the ground?)
    "human": [
        (("head",), 1.20, "neck_01", False),
        (("hand_l", "thumb_01_l", "thumb_02_l", "thumb_03_l", "index_01_l", "index_02_l", "index_03_l",
          "middle_01_l", "middle_02_l", "middle_03_l", "ring_01_l", "ring_02_l", "ring_03_l",
          "pinky_01_l", "pinky_02_l", "pinky_03_l"), 1.10, "hand_l", False),
        (("hand_r", "thumb_01_r", "thumb_02_r", "thumb_03_r", "index_01_r", "index_02_r", "index_03_r",
          "middle_01_r", "middle_02_r", "middle_03_r", "ring_01_r", "ring_02_r", "ring_03_r",
          "pinky_01_r", "pinky_02_r", "pinky_03_r"), 1.10, "hand_r", False),
        (("foot_l", "ball_l"), 1.08, "foot_l", True),
        (("foot_r", "ball_r"), 1.08, "foot_r", True),
    ],
    "shiba": [
        (("head", "ear_L", "ear_R"), 1.20, "neck", False),
        (("ear_L",), 1.25, "ear_L", False),
        (("ear_R",), 1.25, "ear_R", False),
        (("front_paw_L",), 1.15, "front_paw_L", True),
        (("front_paw_R",), 1.15, "front_paw_R", True),
        (("rear_paw_L",), 1.15, "rear_paw_L", True),
        (("rear_paw_R",), 1.15, "rear_paw_R", True),
    ],
}


def main():
    src, out, preset = sys.argv[sys.argv.index("--") + 1:][:3]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=src)
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    for o in list(bpy.data.objects):  # importer bone-shape helpers
        if o.type == "MESH" and o.parent is not arm:
            bpy.data.objects.remove(o, do_unlink=True)
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    ground = min((o.matrix_world @ v.co).z for o in meshes for v in o.data.vertices)
    bones = arm.data.bones
    report = []
    for part, s, pivot_bone, on_ground in PRESETS[preset]:
        pv = arm.matrix_world @ bones[pivot_bone].head_local
        if on_ground:
            pv = Vector((pv.x, pv.y, ground))
        moved = 0
        for o in meshes:
            inv = o.matrix_world.inverted()
            if o.parent_type == "BONE":
                whole = 1.0 if o.parent_bone in part else 0.0
                if whole:
                    for v in o.data.vertices:
                        w = o.matrix_world @ v.co
                        v.co = inv @ (w + (s - 1) * (w - pv))
                    moved += len(o.data.vertices)
                continue
            idx = {g.index for g in o.vertex_groups if g.name in part}
            if not idx:
                continue
            for v in o.data.vertices:
                w = sum(g.weight for g in v.groups if g.group in idx)
                if w <= 0.001:
                    continue
                p = o.matrix_world @ v.co
                v.co = inv @ (p + w * (s - 1) * (p - pv))
                moved += 1
        report.append(f"{','.join(part[:2])}{'…' if len(part) > 2 else ''} x{s}: {moved} verts")
    for o in meshes:
        o.data.update()
    first = bpy.data.actions.get("Idle")
    if first and arm.animation_data:
        arm.animation_data.action = first
    for o in bpy.context.scene.objects:
        o.select_set(o is arm or o in meshes)
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True,
                              export_animation_mode="ACTIONS", export_skins=True)
    print("STYLIZE_RIGGED_OK", os.path.getsize(out), "; ".join(report))


if __name__ == "__main__":
    main()
