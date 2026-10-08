"""Close-up renders of the fight clips' hands (fists and grips) for review.

  blender -b --factory-startup --python tools/art/preview_fight_hands.py -- <out dir>

Poses the P-04 owner with `make_fight_clips.py`'s solver (not its export),
puts a shaft through each holding fist where WeaponProp3D will, and renders
each pose from the side and three-quarter front with Workbench.
"""
import math
import os
import sys

import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
source = open(os.path.join(HERE, "make_fight_clips.py"), encoding="utf-8").read()
source = source.replace("\nmain()\n", "\n")
namespace = {"__name__": "make_fight_clips"}
exec(compile(source, "make_fight_clips.py", "exec"), namespace)

OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.path.join(HERE, "..", "..", "build", "fight_hands")
os.makedirs(OUT, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=namespace["OWNER"])
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
# The model's own clips would re-pose it at render time.
if arm.animation_data is not None:
    arm.animation_data.action = None
for act in list(bpy.data.actions):
    bpy.data.actions.remove(act)
for pb in arm.pose.bones:
    pb.rotation_mode = "QUATERNION"
namespace["measure_hands"](arm)
# Experiments: PREVIEW_PALM_SIGN=-1 flips which side counts as the palm.
if os.environ.get("PREVIEW_PALM_SIGN") == "-1":
    for h in namespace["HANDS"].values():
        h["normal"] = -h["normal"]
poses = namespace["preview_poses"]() if "preview_poses" in namespace else {"stance": namespace["STANCE"]}

scene = bpy.context.scene
scene.render.engine = "BLENDER_WORKBENCH"
scene.display.shading.light = "STUDIO"
scene.display.shading.color_type = "MATERIAL"
scene.render.resolution_x = 640
scene.render.resolution_y = 640
cam_data = bpy.data.cameras.new("cam")
cam_data.lens = 60
cam = bpy.data.objects.new("cam", cam_data)
scene.collection.objects.link(cam)
scene.camera = cam


def shaft(name, start, direction, length, back):
    bpy.ops.mesh.primitive_cylinder_add(radius=0.015, depth=length + back)
    rod = bpy.context.object
    rod.name = name
    d = direction.normalized()
    rod.location = start + d * (length - back) * 0.5
    rod.rotation_mode = "QUATERNION"
    rod.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(d)
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (0.9, 0.2, 0.2, 1)
    rod.data.materials.append(mat)
    return rod


for name, pose in poses.items():
    namespace["apply_pose"](arm, pose)
    bpy.context.view_layer.update()
    rods = []
    held = Vector(pose["aim_l"])
    hand = arm.matrix_world @ arm.pose.bones["hand_l"].matrix
    if held.length > 0.05:
        centre = hand @ namespace["HANDS"]["l"]["centre"]
        rods.append(shaft("rod", centre, arm.matrix_world.to_3x3() @ held, 0.6, 0.6))
    focus = hand.translation
    views = (("side", focus, Vector((0.45, 0.05, 0.05))), ("front", focus, Vector((0.2, -0.45, 0.1))), ("top", focus, Vector((0.05, -0.1, 0.5))),
             ("body", Vector((0.0, -0.2, 1.0)), Vector((2.4, -1.4, 0.3))), ("body_r", Vector((0.0, -0.2, 1.0)), Vector((-2.2, -1.6, 0.4))))
    for view, at, offset in views:
        cam.location = at + offset
        focus_point = at
        cam.rotation_mode = "QUATERNION"
        cam.rotation_quaternion = (focus_point - cam.location).to_track_quat("-Z", "Y")
        scene.render.filepath = os.path.join(OUT, f"{name}_{view}.png")
        bpy.ops.render.render(write_still=True)
    for rod in rods:
        bpy.data.objects.remove(rod, do_unlink=True)
print("PREVIEW_OK", OUT)
