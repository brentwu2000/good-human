"""Mesh2Motion (CC0) animations onto GOOD HUMAN!'s owner and dogs.

Owner, 2026-10-09: Mesh2Motion's library is to be used for the people and
the dogs (「好的，狗的部分也要使用」). Sources are pinned in
assets/_source/mesh2motion/ (see PROVENANCE.md there).

  blender -b --factory-startup --python tools/art/retarget_mesh2motion.py -- [human|dogs|all]

How: every frame, each mapped bone takes the source bone's rotation away
from its own rest pose (in world space) on top of the target bone's rest;
the hips also move by the source hips' movement scaled by leg length. The
target is the game's own model file, so the exported library has the same
armature and bone names and drops straight onto it in Godot.

Writes (skeleton, a tiny skinned stub and only these clips):
  assets/characters/human/animations/p04_m2m_clips.glb       (owner rig)
  assets/characters/dog/animations/m2m/<model>.glb           (one per dog model)
"""
import os
import sys

import bpy
from mathutils import Vector, Quaternion
import math
import numpy as np

ROOT = r"C:\Users\b\Documents\good-human"
SOURCE = os.path.join(ROOT, "assets", "_source", "mesh2motion")
FPS = 30

# --- What is taken, and under which name -------------------------------------------
HUMAN_CLIPS = {
    "human-addon-animations.glb": {
        "Idle Hurt": "M2M_Idle_Hurt", "Tired Hunched": "M2M_Tired", "Kneeling Tired": "M2M_Kneel_Tired",
        "Victory Fist Pump": "M2M_Victory", "Greeting": "M2M_Greeting", "Head Nod": "M2M_Nod",
        "Idle_Subtle": "M2M_Idle_Subtle", "Dizzy": "M2M_Dizzy", "Shivering": "M2M_Shiver",
        "Dodge_back": "M2M_Dodge_Back", "Dodge_left": "M2M_Dodge_Left", "Dodge_right": "M2M_Dodge_Right",
    },
    "human-base-animations.glb": {
        "PickUp_Table": "M2M_PickUp", "Walk_Carry": "M2M_Walk_Carry", "Idle_Talking": "M2M_Talk",
        "Idle_TalkingPhone": "M2M_Phone", "Hit_Knockback": "M2M_Knockback", "Interact": "M2M_Interact",
        "Sitting_Idle": "M2M_Sit_Idle",
    },
    "human-mocap-animations.glb": {
        "Cheering_Two_Hands": "M2M_Cheer", "Cheer_One_arm": "M2M_Cheer_One",
    },
}
DOG_CLIPS = {
    "fox-animations.glb": {
        "Run": "M2M_Run", "Sneak": "M2M_Sneak", "Fetch": "M2M_Fetch", "Bark": "M2M_Bark",
        "Idle Alert": "M2M_Alert", "Jump": "M2M_Jump", "Howl": "M2M_Howl", "Sit": "M2M_Sit", "Idle": "M2M_Idle",
    },
}

HUMAN_MAP = {b: b for b in ["pelvis", "spine_01", "spine_02", "spine_03", "neck_01", "head",
    "clavicle_l", "upperarm_l", "lowerarm_l", "hand_l", "clavicle_r", "upperarm_r", "lowerarm_r", "hand_r",
    "thigh_l", "calf_l", "foot_l", "ball_l", "thigh_r", "calf_r", "foot_r", "ball_r"]
    + [f"{f}_0{i}_{s}" for f in ("index", "middle", "ring", "pinky", "thumb") for i in (1, 2, 3) for s in ("l", "r")]}
# Mesh2Motion's fox (a 49-bone quadruped) onto the 23-bone Shiba_Rig every
# dog model shares.
DOG_MAP = {"Hips": "pelvis", "Spine_1": "spine_01", "Spine_3": "spine_02", "Spine_4": "neck", "Head": "head",
    "Ear_L": "ear_L", "Ear_R": "ear_R",
    "Front_Leg_Upper_L": "front_leg_L", "Front_Leg_Lower_L": "front_shin_L", "Front_Leg_Ankle_L": "front_paw_L",
    "Front_Leg_Upper_R": "front_leg_R", "Front_Leg_Lower_R": "front_shin_R", "Front_Leg_Ankle_R": "front_paw_R",
    "Back_Leg_Upper_L": "rear_leg_L", "Back_Leg_Lower_L": "rear_shin_L", "Back_Leg_Ankle_L": "rear_paw_L",
    "Back_Leg_Upper_R": "rear_leg_R", "Back_Leg_Lower_R": "rear_shin_R", "Back_Leg_Ankle_R": "rear_paw_R",
    "Tail_Base": "tail_01", "Tail_Mid": "tail_02", "Tail_End": "tail_03"}

OWNER = os.path.join(ROOT, "assets", "characters", "human", "models", "p04_owner", "p04_owner.glb")
HUMAN_OUT = os.path.join(ROOT, "assets", "characters", "human", "animations", "p04_m2m_clips.glb")
DOG_MODELS = [os.path.join(ROOT, "assets", "characters", "dog", "models", "shiba_01", "shiba_01.glb")] + [
    os.path.join(ROOT, "assets", "characters", "dog", "models", "breeds", f"{b}.glb")
    for b in ("chihuahua", "corgi", "frenchie", "golden", "pomeranian", "poodle", "shiba")]
DOG_OUT = os.path.join(ROOT, "assets", "characters", "dog", "animations", "m2m")


def world_rest(arm, name):
    return (arm.matrix_world @ arm.data.bones[name].matrix_local).to_3x3().normalized()


def leg_length(arm, names):
    return sum(arm.data.bones[n].length for n in names if n in arm.data.bones)


def dog_pose_cleanup(target, meshes, clip, height):
    """Ground the receiving skin after world-space joint limits.

    Fox gallop/fetch bends are too large for these inherited breed skins.
    A smooth angular response keeps motion instead of clamping frames flat.
    Ground clearance uses evaluated skin, not poorly fitted paw bone tips.
    """
    for pb in target.pose.bones:
        pb.scale = (1, 1, 1)
    hips = target.pose.bones["pelvis"]
    hips.location *= 0.35 if clip != "M2M_Jump" else 0.7
    bpy.context.view_layer.update()
    deps = bpy.context.evaluated_depsgraph_get()
    low = float("inf")
    for obj in meshes:
        evaluated = obj.evaluated_get(deps)
        co = np.empty(len(evaluated.data.vertices) * 3, dtype=np.float32)
        evaluated.data.vertices.foreach_get("co", co)
        points = co.reshape(-1, 3)
        matrix = np.asarray(evaluated.matrix_world)
        z = points @ matrix[2, :3] + matrix[2, 3]
        low = min(low, float(z.min()))
    # Preserve jump airtime; other clips maintain a sole at ground level.
    if clip == "M2M_Jump":
        correction = max(0.0, -low)
    elif clip == "M2M_Run":
        correction = -min(low, 0.0) - max(low - 0.04 * height, 0.0)
    else:
        correction = -low
    if abs(correction) > 1e-6:
        matrix = hips.matrix.copy()
        matrix.translation += target.matrix_world.inverted().to_3x3() @ Vector((0, 0, correction))
        hips.matrix = matrix
        bpy.context.view_layer.update()


def dog_front_pivots(target, meshes, height):
    """Virtual front-chain pivots fitted to the receiving mesh's front paws.

    Preserve the published bind rig; bake compensating translations so this
    is equivalent to rotating a correctly positioned bind chain.
    """
    points = np.concatenate([np.array([target.matrix_world.inverted() @ o.matrix_world @ v.co for v in o.data.vertices]) for o in meshes])
    floor = float(points[:, 2].min())
    low = points[points[:, 2] < floor + height * .12]
    split = (float(low[:, 1].min()) + float(low[:, 1].max())) * .5
    pivots = {b.name: b.head_local.copy() for b in target.data.bones}
    for side, sign in [("L", 1), ("R", -1)]:
        paw = low[(low[:, 1] < split) & (low[:, 0] * sign > 0)]
        if len(paw) < 3: continue
        x, y = np.median(paw[:, :2], axis=0)
        for segment, z in [("leg", .48), ("shin", .25), ("paw", .055)]:
            pivots[f"front_{segment}_{side}"] = Vector((float(x), float(y), floor + height * z))
    return pivots


def apply_dog_pivots(target, pivots):
    rotations = {p.name: p.matrix.to_3x3().normalized() for p in target.pose.bones}
    heads = {}
    hip_move = target.pose.bones["pelvis"].head - target.data.bones["pelvis"].head_local
    for bone in target.data.bones:
        name = bone.name
        if bone.parent:
            parent = bone.parent.name
            parent_delta = rotations[parent] @ bone.parent.matrix_local.to_3x3().inverted()
            heads[name] = heads[parent] + parent_delta @ (pivots[name] - pivots[parent])
        else:
            heads[name] = pivots[name].copy()
        if name == "pelvis": heads[name] += hip_move
        delta = rotations[name] @ bone.matrix_local.to_3x3().inverted()
        matrix = rotations[name].to_4x4()
        matrix.translation = heads[name] + delta @ (bone.head_local - pivots[name])
        target.pose.bones[name].matrix = matrix
        bpy.context.view_layer.update()


def dog_run_contact_envelope(target, meshes, action, last_frame):
    """Lift neighboring keys by measured between-key penetration, not a fixed offset.

    At 120 Hz the required clearance is only millimeters. Checking quarter
    frames prevents a grounded sole from dipping below the floor between keys.
    All channels are linear so the correction is not undone by Bezier overshoot.
    """
    for layer in action.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                for curve in bag.fcurves:
                    for key in curve.keyframe_points:
                        key.interpolation = 'LINEAR'
    lifts = np.zeros(last_frame + 1)
    scene = bpy.context.scene
    for frame in range(last_frame):
        deficit = 0.0
        for fraction in (.25, .5, .75):
            scene.frame_set(frame, subframe=fraction)
            bpy.context.view_layer.update()
            deps = bpy.context.evaluated_depsgraph_get()
            for obj in meshes:
                evaluated = obj.evaluated_get(deps)
                co = np.empty(len(evaluated.data.vertices) * 3, dtype=np.float32)
                evaluated.data.vertices.foreach_get('co', co)
                world = np.asarray(evaluated.matrix_world)
                low = float((co.reshape(-1, 3) @ world[2, :3] + world[2, 3]).min())
                deficit = max(deficit, -low)
        if deficit > 1e-6:
            lifts[frame:frame+2] = np.maximum(lifts[frame:frame+2], deficit + .0001)
    hips = target.pose.bones['pelvis']
    for frame, lift in enumerate(lifts):
        if lift == 0: continue
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        matrix = hips.matrix.copy()
        matrix.translation += target.matrix_world.inverted().to_3x3() @ Vector((0, 0, float(lift)))
        hips.matrix = matrix
        hips.keyframe_insert('location', frame=frame)
    print('RUN_CONTACT_ENVELOPE_MAX_M', float(lifts.max()))


def retarget(target_path, sources, mapping, hips, legs, out_path, bounce=1.0, clean_dog=False):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    # Dense dog contact sampling; the human bake retains its original 30 Hz.
    bpy.context.scene.render.fps = 120 if clean_dog else FPS
    bpy.ops.import_scene.gltf(filepath=target_path)
    target = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    target.animation_data_create()
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action)
    for pb in target.pose.bones:
        pb.rotation_mode = "QUATERNION"
    meshes = [o for o in bpy.data.objects if o.type == "MESH" and any(m.type == "ARMATURE" and m.object == target for m in o.modifiers)]
    height = max((o.matrix_world @ v.co).z for o in meshes for v in o.data.vertices) - min((o.matrix_world @ v.co).z for o in meshes for v in o.data.vertices)
    pivots = dog_front_pivots(target, meshes, height) if clean_dog and os.path.basename(target_path) != "shiba_01.glb" else None
    order = [b.name for b in target.data.bones]
    made = []
    for file, clips in sources.items():
        before = set(bpy.data.objects)
        before_actions = set(bpy.data.actions)
        bpy.ops.import_scene.gltf(filepath=os.path.join(SOURCE, file))
        source = next(o for o in set(bpy.data.objects) - before if o.type == "ARMATURE")
        actions = {a.name: a for a in set(bpy.data.actions) - before_actions}
        inverse = {t: s for s, t in mapping.items() if s in source.data.bones and t in target.data.bones}
        scale = leg_length(target, legs[1]) / max(leg_length(source, legs[0]), 1e-4)
        reference = {n: world_rest(source, n) for n in inverse.values()}
        hips_rest = source.matrix_world @ source.data.bones[hips[0]].head_local
        for name, out_name in clips.items():
            action = actions.get(name)
            if action is None:
                print("MISSING", file, name)
                continue
            source.animation_data_create()
            source.animation_data.action = action
            if action.slots:
                source.animation_data.action_slot = action.slots[0]
            start, end = (int(v) for v in action.frame_range)
            baked = bpy.data.actions.new(out_name)
            target.animation_data.action = baked
            for i, f in enumerate(range(start, end + 1)):
                bpy.context.scene.frame_set(f)
                if clean_dog:
                    for pb in target.pose.bones:
                        pb.location = (0, 0, 0)
                        pb.scale = (1, 1, 1)
                    bpy.context.view_layer.update()
                for bone in order:
                    if bone not in inverse:
                        continue
                    s = source.pose.bones[inverse[bone]]
                    s_world = (source.matrix_world @ s.matrix).to_3x3().normalized()
                    delta = s_world @ reference[inverse[bone]].inverted()
                    if clean_dog and os.path.basename(target_path) != "shiba_01.glb":
                        # Limit world-space displacement before solving the
                        # local pose, preserving parent/head compensation.
                        cap_deg = 80.0
                        if bone == "pelvis": cap_deg = 25.0
                        elif "_leg_" in bone or "_shin_" in bone or "_paw_" in bone:
                            cap_deg = 24.0 if out_name == "M2M_Run" and os.path.basename(target_path) in ("chihuahua.glb", "poodle.glb") else 36.0
                        q = delta.to_quaternion().normalized()
                        if q.w < 0: q.negate()
                        angle = q.angle
                        cap = math.radians(cap_deg)
                        if angle > 1e-6:
                            q = Quaternion((1, 0, 0, 0)).slerp(q, cap * math.tanh(angle / cap) / angle)
                        delta = q.to_matrix()
                    t_world = delta @ world_rest(target, bone)
                    pb = target.pose.bones[bone]
                    m = (target.matrix_world.inverted().to_3x3() @ t_world).to_4x4()
                    m.translation = pb.matrix.translation
                    if bone == hips[1]:
                        move = ((source.matrix_world @ s.matrix).translation - hips_rest) * scale
                        # A fox bounds; a dog's gallop stays lower (scaled up
                        # to a golden, the full bounce left all four paws
                        # 0.37 m off the ground).
                        move.z *= bounce
                        m.translation = target.data.bones[bone].head_local + target.matrix_world.inverted().to_3x3() @ move
                    pb.matrix = m
                    bpy.context.view_layer.update()
                if clean_dog:
                    if pivots is not None: apply_dog_pivots(target, pivots)
                    dog_pose_cleanup(target, meshes, out_name, height)
                for pb in target.pose.bones:
                    pb.keyframe_insert("rotation_quaternion", frame=i)
                    if pb.name == hips[1] or clean_dog:
                        pb.keyframe_insert("location", frame=i)
            if clean_dog and out_name == "M2M_Run":
                dog_run_contact_envelope(target, meshes, baked, end - start)
            made.append(out_name)
            print("CLIP", out_name, end - start + 1)
        for obj in set(bpy.data.objects) - before:
            bpy.data.objects.remove(obj, do_unlink=True)
        for action in actions.values():
            bpy.data.actions.remove(action)
    # Only the skeleton, a stub and the baked clips go out.
    for obj in list(bpy.data.objects):
        if obj is not target:
            bpy.data.objects.remove(obj, do_unlink=True)
    mesh = bpy.data.meshes.new("Stub")
    mesh.from_pydata([(0, 0, 0), (0.001, 0, 0), (0, 0, 0.001)], [], [(0, 1, 2)])
    stub = bpy.data.objects.new("Stub", mesh)
    bpy.context.scene.collection.objects.link(stub)
    group = stub.vertex_groups.new(name=hips[1])
    group.add([0, 1, 2], 1.0, "REPLACE")
    stub.parent = target
    stub.modifiers.new("Armature", "ARMATURE").object = target
    target.animation_data.action = bpy.data.actions[made[0]] if made else None
    for obj in bpy.context.scene.objects:
        obj.select_set(True)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=out_path, export_format="GLB", use_selection=True, export_animation_mode="ACTIONS", export_skins=True)
    print("WROTE", out_path, len(made), "clips")


def main():
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("job", nargs="?", choices=("human", "dogs", "all"), default="all")
    parser.add_argument("--dog-output", default=DOG_OUT, help="Stage dog libraries without publishing them")
    parser.add_argument("--dog-breeds", nargs="+", help="Restrict staged dog rebuilds to these model names")
    parser.add_argument("--dog-model-root", help="Use staged breed models; shiba_01 remains at its published path")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    job = args.job
    if job in ("human", "all"):
        retarget(OWNER, HUMAN_CLIPS, HUMAN_MAP, ("pelvis", "pelvis"), (["thigh_l", "calf_l"], ["thigh_l", "calf_l"]), HUMAN_OUT)
    if job in ("dogs", "all"):
        for model in DOG_MODELS:
            if args.dog_breeds and os.path.splitext(os.path.basename(model))[0] not in args.dog_breeds:
                continue
            if args.dog_model_root and os.path.basename(model) != "shiba_01.glb":
                model = os.path.join(args.dog_model_root, os.path.basename(model))
            out = os.path.join(args.dog_output, os.path.basename(model))
            retarget(model, DOG_CLIPS, DOG_MAP, ("Hips", "pelvis"), (["Back_Leg_Upper_L", "Back_Leg_Lower_L"], ["rear_leg_L", "rear_shin_L"]), out, bounce=0.55, clean_dog=True)
    print("M2M_OK")


if __name__ == "__main__":
    main()
