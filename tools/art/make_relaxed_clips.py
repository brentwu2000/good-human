"""Relaxed, non-combat Idle and Walk on the P-04 OwnerSkeleton.

Every authored P-04 clip (Idle, Idle_Calm/Untrained/Scrapper, Walk) holds a
guard with both hands up, so characters stood in a fighting pose outside
fights. These two clips keep each source clip's legs, hips, spine and head
(breathing, weight shift, stride) and replace the arms: upper arms hang a
little away from the body, elbows slightly bent, open hands; while walking the
arms swing opposite to the legs.

  blender -b --factory-startup --python scripts/make_relaxed_clips.py -- \
      --owner <p04_owner.glb> --library-out <relaxed_clips.glb> --source-out <owner_plus_relaxed.glb>

library-out: skeleton + a tiny skinned stub + only Idle_Relaxed / Walk_Relaxed
  (shared by every character built on the P-04 skeleton in the game).
source-out: the owner with all 19 clips, used as the retarget source for
  characters with their own proportions (rig_character.OWNER_GLB).
"""
import argparse
import math
import os
import sys

import bpy
from mathutils import Matrix, Vector

ARM_CHAIN = ("clavicle", "upperarm", "lowerarm", "hand")
FINGERS = ("thumb", "index", "middle", "ring", "pinky")
# Hanging directions in the armature's space (Blender: Z up, the character faces -Y).
UPPER_OUT = 0.14        # sideways tilt of the upper arm (x per unit down)
UPPER_FWD = -0.04       # slightly in front of the body
LOWER_OUT = 0.08
LOWER_FWD = -0.22       # elbows a little bent
HAND_FWD = -0.18
SWING = 0.55            # arm swing per unit of the opposite thigh's forward swing


def args():
    argv = sys.argv[sys.argv.index("--") + 1:]
    p = argparse.ArgumentParser()
    p.add_argument("--owner", required=True)
    p.add_argument("--library-out", required=True)
    p.add_argument("--source-out", required=True)
    return p.parse_args(argv)


def order(arm):
    out = []

    def walk(b):
        out.append(b.name)
        for c in b.children:
            walk(c)
    for b in arm.data.bones:
        if b.parent is None:
            walk(b)
    return out


def aim(pb, direction):
    """Pose `pb` (armature space) so its Y axis points along `direction`, keeping its roll."""
    rest = pb.bone.matrix_local
    y = (rest.to_3x3() @ Vector((0, 1, 0))).normalized()
    q = y.rotation_difference(direction.normalized())
    m = (q.to_matrix() @ rest.to_3x3()).to_4x4()
    parent = pb.parent
    head = (parent.matrix @ parent.bone.matrix_local.inverted() @ rest).translation if parent else rest.translation
    m.translation = head
    pb.matrix = m


def thigh_forward(arm, side):
    pb = arm.pose.bones[f"thigh_{side}"]
    d = (pb.matrix.to_3x3() @ Vector((0, 1, 0))).normalized()
    return -d.y  # thigh points down (-Z); a forward swing gives it -Y


def make(arm, src_name, new_name, swing):
    src = bpy.data.actions[src_name]
    arm.animation_data.action = src
    if hasattr(arm.animation_data, "action_slot") and len(getattr(src, "slots", [])):
        arm.animation_data.action_slot = src.slots[0]
    f0, f1 = int(math.floor(src.frame_range[0])), int(math.ceil(src.frame_range[1]))
    names = order(arm)
    frames = {}
    sc = bpy.context.scene
    for f in range(f0, f1 + 1):
        sc.frame_set(f)
        frames[f] = {n: arm.pose.bones[n].matrix_basis.copy() for n in names}
        frames[f]["_thigh"] = {s: thigh_forward(arm, s) for s in ("l", "r")}
    dst = bpy.data.actions.new(new_name)
    arm.animation_data.action = dst
    for pb in arm.pose.bones:
        pb.rotation_mode = "QUATERNION"
    for f in range(f0, f1 + 1):
        for n in names:
            arm.pose.bones[n].matrix_basis = frames[f][n]
        bpy.context.view_layer.update()
        for side, sx in (("l", 1), ("r", -1)):
            opp = "r" if side == "l" else "l"
            fwd = frames[f]["_thigh"][opp] * SWING if swing else 0.0
            arm.pose.bones[f"clavicle_{side}"].matrix_basis = Matrix.Identity(4)
            bpy.context.view_layer.update()
            aim(arm.pose.bones[f"upperarm_{side}"], Vector((sx * UPPER_OUT, UPPER_FWD - fwd, -1)))
            bpy.context.view_layer.update()
            aim(arm.pose.bones[f"lowerarm_{side}"], Vector((sx * LOWER_OUT, LOWER_FWD - 1.3 * fwd, -1)))
            bpy.context.view_layer.update()
            aim(arm.pose.bones[f"hand_{side}"], Vector((sx * 0.02, HAND_FWD - 1.3 * fwd, -1)))
            bpy.context.view_layer.update()
            for n in names:
                if n.startswith(FINGERS) and n.endswith("_" + side):
                    arm.pose.bones[n].matrix_basis = Matrix.Identity(4)
        for n in names:
            pb = arm.pose.bones[n]
            pb.keyframe_insert("rotation_quaternion", frame=f)
            if n in ("Root", "pelvis"):
                pb.keyframe_insert("location", frame=f)
    return dst


def main():
    a = args()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=a.owner)
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    if arm.animation_data is None:
        arm.animation_data_create()
    make(arm, "Idle", "Idle_Relaxed", swing=False)
    make(arm, "Walk", "Walk_Relaxed", swing=True)
    arm.animation_data.action = bpy.data.actions["Idle_Relaxed"]

    # 1. The full owner + all clips (retarget source for other characters).
    for o in bpy.context.scene.objects:
        o.select_set(True)
    os.makedirs(os.path.dirname(os.path.abspath(a.source_out)), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=a.source_out, export_format="GLB", use_selection=True,
                              export_animation_mode="ACTIONS", export_skins=True)

    # 2. The shared library: skeleton, a tiny skinned stub (so Godot builds a
    # Skeleton3D and the tracks target its bones), and only the relaxed clips.
    for o in list(bpy.context.scene.objects):
        if o is not arm:
            bpy.data.objects.remove(o, do_unlink=True)
    for act in list(bpy.data.actions):
        if act.name not in ("Idle_Relaxed", "Walk_Relaxed"):
            bpy.data.actions.remove(act)
    me = bpy.data.meshes.new("Stub")
    me.from_pydata([(0, 0, 0), (0.001, 0, 0), (0, 0, 0.001)], [], [(0, 1, 2)])
    stub = bpy.data.objects.new("Stub", me)
    bpy.context.scene.collection.objects.link(stub)
    g = stub.vertex_groups.new(name="Root")
    g.add([0, 1, 2], 1.0, "REPLACE")
    stub.parent = arm
    mod = stub.modifiers.new("Armature", "ARMATURE")
    mod.object = arm
    for o in bpy.context.scene.objects:
        o.select_set(True)
    os.makedirs(os.path.dirname(os.path.abspath(a.library_out)), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=a.library_out, export_format="GLB", use_selection=True,
                              export_animation_mode="ACTIONS", export_skins=True)
    print("RELAXED_OK", os.path.getsize(a.library_out), os.path.getsize(a.source_out))


if __name__ == "__main__":
    main()
