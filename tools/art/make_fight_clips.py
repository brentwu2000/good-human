"""Fighting-game style combat clips on the P-04 OwnerSkeleton (Claude, at the
owner's request 2026-10-07: 「打鬥的方式太生硬，建議可以去學習其他格鬥類型遊戲
的打鬥風格」).

What fighting games do that the first-pass clips did not:
- a stance: bladed (lead shoulder and lead foot forward), knees bent, weight
  low, hands up — never standing straight with feet together;
- life between moves: a rhythmic bounce and weight shift;
- weight transfer on every blow: the lead foot steps in on the jab, the hips
  and rear heel turn into the cross and the hook, the body leans over a kick;
- clear anticipation, a fast strike, a held extension, an eased recovery back
  to the stance;
- footwork that keeps the stance (shuffles, never feet crossing);
- hit reactions that move the whole body (head snap, fold, a step back).

Poses are authored as targets — pelvis offset/turn/lean, chest turn/lean,
head, hand and foot positions — interpolated between keys and solved with
two-bone IK every frame, so feet plant and do not slide.

  blender -b --factory-startup --python tools/art/make_fight_clips.py

Writes `assets/characters/human/animations/p04_fight_clips.glb`: the skeleton,
a tiny skinned stub and only these clips (loaded as the "fight" library, like
Codex's relaxed clips). Armature space: Z up, the character faces -Y, its
left (lead side in an orthodox stance) is +X.
"""
import math
import os

import bpy
from mathutils import Matrix, Quaternion, Vector

ROOT = r"C:\Users\b\Documents\good-human"
OWNER = os.path.join(ROOT, "assets", "characters", "human", "models", "p04_owner", "p04_owner.glb")
OUT = os.path.join(ROOT, "assets", "characters", "human", "animations", "p04_fight_clips.glb")
FPS = 30

# --- The stance (orthodox), and the poses built from it ------------------------------
STANCE = {
    "pelvis": (-0.02, 0.0, -0.075),     # offset from the rest pelvis head
    "yaw": -24.0,                        # bladed: lead (left) side forward
    "tilt": 6.0,                         # lean forward a little
    "chest_yaw": 8.0,                    # shoulders come back round a little
    "chest_lean": 4.0,
    "head_yaw": 18.0,                    # eyes on the opponent
    "head_pitch": 6.0,                   # chin tucked
    "hand_l": (0.07, -0.36, 1.33),       # lead hand out in front
    "hand_r": (-0.09, -0.21, 1.4),       # rear hand by the chin
    "foot_l": (0.1, -0.24, 0.075),       # lead foot forward
    "foot_r": (-0.17, 0.17, 0.09),       # rear foot back, heel up
    "toe_l": (0.12, -0.9, -0.42),        # lead toes forward
    "toe_r": (-0.55, -0.62, -0.62),      # rear foot turned out, on the ball
    "hand_up": 0.15,                     # fists cocked up a little
    "aim_l": (0.0, 0.0, 0.0),            # a held weapon's direction (0 = follow the forearm)
    "aim_r": (0.0, 0.0, 0.0),
}


def pose(**changes):
    p = dict(STANCE)
    for k, v in changes.items():
        if isinstance(v, tuple) and k in p and isinstance(p[k], tuple) and k.startswith("d_"):
            continue
        p[k] = v
    return p


def moved(base, **deltas):
    """`base` with tuples/numbers offset by `deltas` (d_ prefixed names)."""
    p = dict(base)
    for k, v in deltas.items():
        key = k[2:]
        if isinstance(v, tuple):
            p[key] = tuple(a + b for a, b in zip(p[key], v))
        else:
            p[key] = p[key] + v
    return p


def lerp_pose(a, b, t):
    out = {}
    for k in a:
        va, vb = a[k], b[k]
        if isinstance(va, tuple):
            out[k] = tuple(x + (y - x) * t for x, y in zip(va, vb))
        else:
            out[k] = va + (vb - va) * t
    return out


def smooth(t):
    return t * t * (3 - 2 * t)


def snap(t):
    """Fast out, slow settle: a strike."""
    return 1 - (1 - t) ** 3


# --- Solving a pose onto the skeleton ------------------------------------------------
def aim(pb, direction):
    """Pose `pb` (armature space) so its Y axis points along `direction`, keeping its roll."""
    rest = pb.bone.matrix_local
    y = (rest.to_3x3() @ Vector((0, 1, 0))).normalized()
    q = y.rotation_difference(direction.normalized())
    m = (q.to_matrix() @ rest.to_3x3()).to_4x4()
    m.translation = pb.matrix.translation
    pb.matrix = m


def turn(pb, q):
    """Turn `pb` about its own head by `q` (armature axes)."""
    m = pb.matrix.copy()
    head = m.translation.copy()
    r = (q.to_matrix() @ m.to_3x3()).to_4x4()
    r.translation = head
    pb.matrix = r


def two_bone(root, target, a, b, hint):
    """Where the middle joint goes for a chain of lengths a, b from `root`
    reaching for `target`, bending towards `hint`."""
    d = target - root
    dist = min(max(d.length, 1e-4), a + b - 1e-4)
    dirn = d.normalized()
    x = (a * a - b * b + dist * dist) / (2 * dist)
    h = math.sqrt(max(a * a - x * x, 0.0))
    side = hint - dirn * hint.dot(dirn)
    side = side.normalized() if side.length > 1e-5 else Vector((0, -1, 0))
    return root + dirn * x + side * h


def apply_pose(arm, p):
    pbs = arm.pose.bones
    for pb in pbs:
        pb.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()
    # Pelvis: lowered, turned and leaning, about its own head.
    pel = pbs["pelvis"]
    rest = pel.bone.matrix_local
    # Positive tilt leans forward (towards -Y): a positive turn about +X.
    q = Quaternion((0, 0, 1), math.radians(p["yaw"])) @ Quaternion((1, 0, 0), math.radians(p["tilt"]))
    m = (q.to_matrix() @ rest.to_3x3()).to_4x4()
    m.translation = rest.translation + Vector(p["pelvis"])
    pel.matrix = m
    bpy.context.view_layer.update()
    # Chest turn and lean, shared over the upper spine.
    for name in ("spine_02", "spine_03"):
        turn(pbs[name], Quaternion((0, 0, 1), math.radians(p["chest_yaw"] / 2)) @ Quaternion((1, 0, 0), math.radians(p["chest_lean"] / 2)))
        bpy.context.view_layer.update()
    turn(pbs["head"], Quaternion((0, 0, 1), math.radians(p["head_yaw"])) @ Quaternion((1, 0, 0), math.radians(p["head_pitch"])))
    bpy.context.view_layer.update()
    # Arms: hands to their targets, elbows down and a little out.
    for side, sx in (("l", 1), ("r", -1)):
        up, low, hand = pbs[f"upperarm_{side}"], pbs[f"lowerarm_{side}"], pbs[f"hand_{side}"]
        shoulder = up.matrix.translation.copy()
        target = Vector(p[f"hand_{side}"])
        elbow = two_bone(shoulder, target, up.bone.length, low.bone.length, Vector((sx * 0.6, 0.2, -1.0)))
        aim(up, elbow - shoulder)
        bpy.context.view_layer.update()
        aim(low, target - low.matrix.translation)
        bpy.context.view_layer.update()
        held = Vector(p[f"aim_{side}"])
        if held.length > 0.05:
            aim(hand, held)
        else:
            aim(hand, (target - low.matrix.translation).normalized() + Vector((0, 0, p["hand_up"])))
        bpy.context.view_layer.update()
    # Legs: ankles to their targets, knees forward and a little out.
    for side, sx in (("l", 1), ("r", -1)):
        th, ca, ft = pbs[f"thigh_{side}"], pbs[f"calf_{side}"], pbs[f"foot_{side}"]
        hip = th.matrix.translation.copy()
        ankle = Vector(p[f"foot_{side}"])
        knee = two_bone(hip, ankle, th.bone.length, ca.bone.length, Vector((sx * 0.25, -1.0, 0.0)))
        aim(th, knee - hip)
        bpy.context.view_layer.update()
        aim(ca, ankle - ca.matrix.translation)
        bpy.context.view_layer.update()
        aim(ft, Vector(p[f"toe_{side}"]))
        bpy.context.view_layer.update()


def bake(arm, name, keys, seconds, loop=False, bounce=0.0, bounces=2):
    """`keys`: [(t 0..1, pose, ease)] — ease is how the segment into this key
    moves. `bounce` adds the stance's rhythmic bob (metres)."""
    action = bpy.data.actions.new(name)
    arm.animation_data.action = action
    for pb in arm.pose.bones:
        pb.rotation_mode = "QUATERNION"
    frames = max(2, int(round(seconds * FPS)))
    for f in range(frames + 1):
        t = f / frames
        prev = keys[0]
        nxt = keys[-1]
        for i in range(len(keys) - 1):
            if keys[i][0] <= t <= keys[i + 1][0]:
                prev, nxt = keys[i], keys[i + 1]
                break
        span = max(nxt[0] - prev[0], 1e-6)
        k = (t - prev[0]) / span
        p = lerp_pose(prev[1], nxt[1], nxt[2](k))
        if bounce:
            phase = math.sin(t * math.tau * bounces)
            dz = (phase * 0.5 - 0.5) * bounce
            p = moved(p, d_pelvis=(0, 0, dz), d_hand_l=(0, 0, dz * 0.6), d_hand_r=(0, 0, dz * 0.6))
            p["yaw"] += math.sin(t * math.tau * bounces * 0.5) * 2.0
        apply_pose(arm, p)
        for pb in arm.pose.bones:
            pb.keyframe_insert("rotation_quaternion", frame=f)
            if pb.name in ("Root", "pelvis"):
                pb.keyframe_insert("location", frame=f)
    print("CLIP", name, frames)
    return action


def build(arm):
    S = STANCE
    lin = lambda t: t
    # Stance: alive between moves — a bounce on the balls of the feet.
    bake(arm, "Fight_Stance", [(0, S, lin), (1, S, lin)], 1.0, loop=True, bounce=0.03)
    # Footwork, in place (the fight moves the body): shuffles that keep the stance.
    fwd_reach = moved(S, d_foot_l=(0, -0.12, 0.03), d_pelvis=(0, -0.04, 0.0))
    fwd_follow = moved(S, d_foot_r=(0, -0.1, 0.03), d_pelvis=(0, -0.02, -0.01))
    bake(arm, "Fight_Step_Fwd", [(0, S, lin), (0.3, fwd_reach, smooth), (0.6, fwd_follow, smooth), (1, S, smooth)], 0.55, bounce=0.015, bounces=1)
    back_reach = moved(S, d_foot_r=(0, 0.12, 0.03), d_pelvis=(0, 0.04, 0.0))
    back_follow = moved(S, d_foot_l=(0, 0.1, 0.03), d_pelvis=(0, 0.02, -0.01))
    bake(arm, "Fight_Step_Back", [(0, S, lin), (0.3, back_reach, smooth), (0.6, back_follow, smooth), (1, S, smooth)], 0.5, bounce=0.015, bounces=1)
    side_reach = moved(S, d_foot_l=(0.1, 0.0, 0.03), d_pelvis=(0.04, 0.0, 0.0), d_yaw=-4.0)
    side_follow = moved(S, d_foot_r=(0.09, 0.0, 0.03), d_pelvis=(0.02, 0.0, -0.01))
    bake(arm, "Fight_Circle", [(0, S, lin), (0.3, side_reach, smooth), (0.6, side_follow, smooth), (1, S, smooth)], 0.5, bounce=0.015, bounces=1)

    # Strikes: the clip's halfway point is the contact window opening (the
    # game times them that way). Anticipate, strike fast, hold, settle.
    # Extension is measured to the reach calibration (P-04: a fist at contact
    # ends at the other body's front, about reach - 0.17 m forward), so a
    # blow lands on the body and not through it.
    # Jab: lead hand straight out, lead foot steps in, shoulder turns over.
    jab_load = moved(S, d_pelvis=(0, 0.01, -0.01), d_hand_l=(0.01, 0.04, 0.0), d_yaw=3.0)
    jab_hit = moved(S, d_pelvis=(0, -0.07, -0.005), d_foot_l=(0, -0.1, 0), d_hand_l=(-0.03, -0.27, 0.08), d_yaw=-10.0, d_chest_yaw=-8.0, d_head_pitch=4.0)
    bake(arm, "Fight_Jab", [(0, S, lin), (0.3, jab_load, smooth), (0.5, jab_hit, snap), (0.62, jab_hit, lin), (1, S, smooth)], 0.6)
    # Cross: rear hand straight, hips and rear heel turn through.
    cross_load = moved(S, d_pelvis=(0.0, 0.03, -0.01), d_yaw=-6.0, d_hand_r=(0, 0.04, 0))
    cross_hit = moved(S, d_pelvis=(0.02, -0.08, -0.01), d_hand_r=(0.14, -0.43, 0.02), d_hand_l=(0.0, 0.14, 0.06), d_yaw=26.0, d_chest_yaw=14.0, d_head_yaw=-18.0, d_toe_r=(0.45, -0.25, -0.2))
    bake(arm, "Fight_Cross", [(0, S, lin), (0.3, cross_load, smooth), (0.5, cross_hit, snap), (0.62, cross_hit, lin), (1, S, smooth)], 0.65)
    # Thrust (a held weapon: umbrella, pole): the whole body goes in behind
    # a straight lead arm, wrist level, so the weapon points where it hits.
    thrust_load = moved(S, d_pelvis=(0, 0.04, -0.01), d_hand_l=(0.0, 0.08, -0.02), d_yaw=4.0)
    # The weapon does the reaching: a short step and a level wrist.
    thrust_hit = moved(S, d_pelvis=(-0.01, -0.05, -0.02), d_foot_l=(0, -0.07, 0), d_hand_l=(-0.03, -0.1, 0.0), d_yaw=-10.0, d_chest_yaw=-6.0, d_tilt=3.0, d_aim_l=(0.0, -1.0, 0.02))
    bake(arm, "Fight_Thrust", [(0, S, lin), (0.3, thrust_load, smooth), (0.5, thrust_hit, snap), (0.64, thrust_hit, lin), (1, S, smooth)], 0.65)
    # Lead hook: the lead arm bent at shoulder height, sweeping across with the hips.
    hook_load = moved(S, d_yaw=-14.0, d_chest_yaw=-10.0, d_hand_l=(0.22, 0.06, 0.02), d_pelvis=(0.02, 0.0, -0.02))
    hook_hit = moved(S, d_yaw=22.0, d_chest_yaw=16.0, d_hand_l=(-0.22, -0.28, 0.08), d_head_yaw=-16.0, d_pelvis=(-0.03, -0.03, -0.02), d_toe_l=(-0.4, 0.2, 0.0))
    bake(arm, "Fight_Hook", [(0, S, lin), (0.32, hook_load, smooth), (0.5, hook_hit, snap), (0.6, hook_hit, lin), (1, S, smooth)], 0.7)
    # Rear hook: the same off the back hand.
    rhook_load = moved(S, d_yaw=-14.0, d_hand_r=(-0.18, 0.04, -0.02), d_pelvis=(0, 0.02, -0.02))
    rhook_hit = moved(S, d_yaw=36.0, d_chest_yaw=18.0, d_hand_r=(0.32, -0.32, 0.02), d_hand_l=(0.0, 0.12, 0.06), d_head_yaw=-24.0, d_pelvis=(0.02, -0.05, -0.02), d_toe_r=(0.5, -0.2, -0.2))
    bake(arm, "Fight_Hook_Rear", [(0, S, lin), (0.32, rhook_load, smooth), (0.5, rhook_hit, snap), (0.6, rhook_hit, lin), (1, S, smooth)], 0.72)
    # Rear-leg kick: the knee chambers up, the leg drives out, the body leans
    # back over the standing leg, hands stay up.
    kick_chamber = moved(S, d_foot_r=(0.08, -0.1, 0.42), d_toe_r=(0.3, -0.3, 0.2), d_pelvis=(0.04, 0.02, 0.01), d_tilt=-10.0, d_yaw=10.0, d_hand_r=(0.02, 0.06, 0.02))
    kick_hit = moved(S, d_foot_r=(0.16, -0.66, 0.52), d_toe_r=(0.55, -0.8, 0.62), d_pelvis=(0.05, -0.06, 0.0), d_tilt=-18.0, d_yaw=30.0, d_chest_yaw=-12.0, d_hand_r=(0.04, 0.1, 0.0), d_hand_l=(-0.04, 0.08, 0.0))
    bake(arm, "Fight_Kick", [(0, S, lin), (0.32, kick_chamber, smooth), (0.5, kick_hit, snap), (0.64, kick_hit, lin), (0.82, kick_chamber, smooth), (1, S, smooth)], 0.85)
    # Lead-leg kick (the switch side of the same).
    lkick_chamber = moved(S, d_foot_l=(0.0, 0.02, 0.4), d_toe_l=(0.0, 0.1, 0.4), d_pelvis=(-0.02, 0.06, 0.01), d_tilt=-10.0)
    lkick_hit = moved(S, d_foot_l=(-0.02, -0.28, 0.5), d_toe_l=(0.0, -0.6, 0.7), d_pelvis=(-0.02, 0.0, 0.0), d_tilt=-18.0, d_yaw=-6.0)
    bake(arm, "Fight_Kick_Lead", [(0, S, lin), (0.32, lkick_chamber, smooth), (0.5, lkick_hit, snap), (0.62, lkick_hit, lin), (0.82, lkick_chamber, smooth), (1, S, smooth)], 0.8)

    # Defence.
    block = moved(S, d_hand_l=(-0.06, 0.12, 0.14), d_hand_r=(0.04, 0.03, 0.08), d_pelvis=(0, 0.02, -0.03), d_head_pitch=10.0, d_chest_lean=6.0)
    bake(arm, "Fight_Block", [(0, block, lin), (1, block, lin)], 0.3)
    slip = moved(S, d_pelvis=(0.1, 0.08, -0.06), d_tilt=-6.0, d_chest_lean=-8.0, d_chest_yaw=10.0, d_hand_l=(0.06, 0.12, -0.04), d_hand_r=(0.08, 0.1, -0.06), d_foot_r=(0.04, 0.1, 0.0))
    bake(arm, "Fight_Dodge", [(0, S, lin), (0.4, slip, snap), (0.7, slip, lin), (1, S, smooth)], 0.45)
    # Hit reactions: the whole body answers.
    hit_light = moved(S, d_head_pitch=-22.0, d_head_yaw=10.0, d_chest_lean=-10.0, d_pelvis=(0, 0.05, 0.0), d_hand_l=(0.03, 0.1, -0.06), d_hand_r=(-0.02, 0.05, -0.05))
    bake(arm, "Fight_HitLight", [(0, S, lin), (0.2, hit_light, snap), (0.45, hit_light, lin), (1, S, smooth)], 0.35)
    hit_heavy = moved(S, d_head_pitch=24.0, d_chest_lean=22.0, d_tilt=14.0, d_pelvis=(0, 0.12, -0.06), d_foot_r=(0, 0.14, 0.0), d_hand_l=(-0.04, 0.16, -0.28), d_hand_r=(0.04, 0.1, -0.26), d_yaw=12.0)
    bake(arm, "Fight_HitHeavy", [(0, S, lin), (0.18, hit_heavy, snap), (0.55, hit_heavy, lin), (1, S, smooth)], 0.55)


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=OWNER)
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    if arm.animation_data is None:
        arm.animation_data_create()
    for act in list(bpy.data.actions):
        bpy.data.actions.remove(act)
    bpy.context.scene.render.fps = FPS
    build(arm)
    arm.animation_data.action = bpy.data.actions["Fight_Stance"]
    # The shared library: skeleton, a tiny skinned stub, only these clips.
    for o in list(bpy.context.scene.objects):
        if o is not arm:
            bpy.data.objects.remove(o, do_unlink=True)
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
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_animation_mode="ACTIONS", export_skins=True)
    print("FIGHT_CLIPS_OK", os.path.getsize(OUT))


main()
