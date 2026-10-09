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
import json
import math
import os

import bpy
from mathutils import Matrix, Quaternion, Vector

ROOT = r"C:\Users\b\Documents\good-human"
OWNER = os.path.join(ROOT, "assets", "characters", "human", "models", "p04_owner", "p04_owner.glb")
OUT = os.path.join(ROOT, "assets", "characters", "human", "animations", "p04_fight_clips.glb")
RELAXED = os.path.join(ROOT, "assets", "characters", "human", "animations", "p04_relaxed_clips.glb")
# Where the hands hold a shaft (hand-bone frame), for WeaponProp3D.
GRIP_JSON = os.path.join(ROOT, "assets", "characters", "human", "animations", "p04_fight_grip.json")
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
    "aim_l": (0.0, 0.0, 0.0),            # a held weapon's direction (0 = empty-handed)
    "aim_r": (0.0, 0.0, 0.0),
    "grip_l": 0.0,                       # 0 a fist, 1 fingers round a shaft
    "grip_r": 0.0,
    "two_hand": 0.0,                     # 1: the rear hand holds the shaft too
}

# --- Hands (owner, 2026-10-09: "the way they hold weapons is not how people
# hold things") ---------------------------------------------------------------
# Real grips, from references (docs/99_notes/WEAPON_GRIP_REFERENCE.md):
# - a stick or umbrella is held in a hammer grip: the shaft runs ACROSS the
#   palm, from the heel of the hand under the little finger to between thumb
#   and index, with the thumb wrapped over the fingers (Barton-Wright,
#   "Self-Defence with a Walking Stick"); the fingers carry on from the
#   forearm and the shaft leaves the fist at about a right angle to it;
# - a broom is held in both hands, spread apart, like a short bayonet, and
#   mostly thrust;
# - empty hands punch with closed fists.
# Until now every hand was open, and a held thing was fixed along the
# fingers, so an umbrella stood on the fingertips like a torch.
CURL_FIST = (80.0, 95.0, 70.0)           # knuckle, middle, tip joint (degrees)
CURL_GRIP = (62.0, 82.0, 50.0)           # round a shaft about 3 cm thick
THUMB_FIST = (30.0, 40.0, 35.0)
THUMB_GRIP = (24.0, 34.0, 26.0)
THUMB_ACROSS = 35.0                      # thumb swung across the palm first (degrees)
FINGERS = ("index", "middle", "ring", "pinky")
# A two-handed shaft (the broom) is held near the END of its handle, the
# "rear-ended grip" of the reference: the rear hand at the very end, the lead
# hand a short way up, most of the shaft and the head out in front. Held in
# its middle (as first built) 0.7 m of handle stuck back past the lead hand
# and ran into the hip, belly and head (owner, 2026-10-09: 「穿模了」).
# The broom model's handle ends 0.695 m behind where the prop is mounted, so
# the prop is shifted forward in the lead hand by LONG_GRIP_SHIFT (Godot reads
# it from GRIP_JSON); clips keep the head where they put it by pulling the
# lead hand back by the same amount.
BROOM_HANDLE_BACK = 0.695
LONG_GRIP_SHIFT = 0.395
TWO_HAND_SPREAD = 0.25
HANDS = {}


def measure_hands(arm):
    """Per side, in the hand bone's own frame: the palm normal, then — with the
    fingers actually curled round a shaft — the axis that shaft runs along
    (out of the thumb side) and its centre, from the ring the curled middle
    finger makes. Written to GRIP_JSON so Godot (WeaponProp3D) holds things
    exactly where these clips close the hand."""
    bones = arm.data.bones
    for side in ("l", "r"):
        hand = bones[f"hand_{side}"]
        rot = hand.matrix_local.inverted().to_3x3()
        normal = Vector((0, 0, 0))
        for f in FINGERS:
            normal += rot @ (bones[f"{f}_03_{side}"].matrix_local.col[1].xyz - bones[f"{f}_01_{side}"].matrix_local.col[1].xyz)
        fingers = Vector((0, 1, 0))
        # The rest pose's finger bones bend slightly towards the back of the
        # hand on this rig, so the palm is the opposite way (checked against
        # renders: curling towards this side closes the hand).
        normal = -(normal - fingers * normal.dot(fingers)).normalized()
        HANDS[side] = {"normal": normal}
    # Curl both hands round a shaft from the rest pose and measure the ring.
    for pb in arm.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()
    for side in ("l", "r"):
        curl_fingers(arm, side, 1.0)
        pbs = arm.pose.bones
        inv = pbs[f"hand_{side}"].matrix.inverted()
        ring = [inv @ pbs[f"middle_0{i}_{side}"].head for i in (1, 2, 3)] + [inv @ pbs[f"middle_03_{side}"].tail]
        centre = sum(ring, Vector((0, 0, 0))) / len(ring)
        # The shaft runs along the axis the finger curls about (towards the
        # index side), through the ring's centre.
        a1 = ring[1] - ring[0]
        a2 = ring[3] - ring[1]
        axis = a1.cross(a2).normalized()
        index = inv @ pbs[f"index_01_{side}"].head
        pinky = inv @ pbs[f"pinky_01_{side}"].head
        if axis.dot(index - pinky) < 0:
            axis = -axis
        HANDS[side]["axis"] = axis
        HANDS[side]["centre"] = centre
        print("HAND", side, "normal", tuple(round(v, 3) for v in HANDS[side]["normal"]), "axis", tuple(round(v, 3) for v in axis), "centre", tuple(round(v, 3) for v in centre))
    for pb in arm.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()
    with open(GRIP_JSON, "w", encoding="utf-8") as out:
        data = {side: {"axis": list(h["axis"]), "centre": list(h["centre"]), "normal": list(h["normal"])} for side, h in HANDS.items()}
        data["long_shift"] = LONG_GRIP_SHIFT
        json.dump(data, out, indent=1)


def hold_rotation(side, along, forearm):
    """The hand's 3x3 (bone frame -> armature) that runs the shaft through the
    fist along `along`, the fingers carrying on from `forearm` round it."""
    h = HANDS[side]
    g = along.normalized()
    y = forearm - g * forearm.dot(g)
    if y.length < 1e-4:
        y = g.orthogonal()
    y.normalize()
    gl = h["axis"]
    yl = Vector((0, 1, 0))
    yl = (yl - gl * yl.dot(gl)).normalized()
    src = Matrix((gl, yl, gl.cross(yl))).transposed()
    dst = Matrix((g, y, g.cross(y))).transposed()
    return dst @ src.inverted()


def hold_along(pb, side, along, forearm):
    m = hold_rotation(side, along, forearm).to_4x4()
    m.translation = pb.matrix.translation
    pb.matrix = m


def curl_fingers(arm, side, grip):
    """Close the hand: a fist at grip 0, round a shaft at grip 1, the thumb
    over the fingers."""
    pbs = arm.pose.bones
    hand = pbs[f"hand_{side}"]
    normal = (hand.matrix.to_3x3() @ HANDS[side]["normal"]).normalized()
    curls = [a + (b - a) * grip for a, b in zip(CURL_FIST, CURL_GRIP)]
    thumbs = [a + (b - a) * grip for a, b in zip(THUMB_FIST, THUMB_GRIP)]
    for f in FINGERS + ("thumb",):
        angles = thumbs if f == "thumb" else curls
        # A knuckle is a hinge: one axis per finger, across it, fixed before
        # it bends (recomputed per joint it swings sideways once the finger
        # points into the palm, and the hand becomes a claw).
        if f == "thumb":
            # The thumb first swings across the palm (opposition), about the
            # line the fingers run along, so it can lie over them.
            along = hand.matrix.col[1].xyz.normalized()
            swing = Quaternion(along, math.radians(THUMB_ACROSS * (1.0 if side == "l" else -1.0)))
            turn(pbs[f"thumb_01_{side}"], swing)
            bpy.context.view_layer.update()
        hinge = pbs[f"{f}_01_{side}"].matrix.col[1].xyz.normalized().cross(normal)
        if hinge.length < 1e-4:
            continue
        hinge.normalize()
        for i, angle in zip((1, 2, 3), angles):
            turn(pbs[f"{f}_0{i}_{side}"], Quaternion(hinge, math.radians(angle)))
            bpy.context.view_layer.update()


def armed_guards():
    """The two ways of standing with something in hand.
    Umbrella (one hand): the walking-stick front guard — lead arm forward and
    a little down, the umbrella held near its handle, its point on the other
    person's face; the rear fist up by the chin.
    Broom (two hands): held like a short bayonet — lead hand on the handle at
    the waist, rear hand further back on it, the head forward and a little up."""
    # Hand at chest height a little in front, standing taller than the
    # empty-handed crouch (a stick-fighter's guard), the point at the face.
    # Held up steeply, the point towards the face but short of it: even when
    # an empty-handed opponent closes in to fist range nothing held reaches
    # the other body (owner, 2026-10-09: 「穿模了」 — level and
    # far out, the guard sat inside the other person).
    umbrella = moved(STANCE, d_hand_l=(0.03, 0.12, -0.16), d_tilt=-3.0, d_pelvis=(0, 0, 0.03))
    umbrella["aim_l"] = (-0.06, -0.28, 0.96)
    umbrella["grip_l"] = 1.0
    # The shaft runs from the rear hand at the right hip, across the body, out
    # past the lead hand in front of the belly.
    # A staff's high guard: both hands in front of the chest, the broom
    # standing up at about 66 degrees towards the other person's head. Held
    # at the handle's end it is 1.2 m long in front of the lead hand; level,
    # it reached 1.5 m, well inside anyone at broom distance.
    broom = moved(STANCE, d_hand_l=(-0.003, 0.022, 0.079))
    broom["aim_l"] = (0.12, -0.40, 0.91)
    broom["grip_l"] = 1.0
    broom["grip_r"] = 1.0
    broom["two_hand"] = 1.0
    return umbrella, broom


def preview_poses():
    umbrella, broom = armed_guards()
    return {"fists": STANCE, "umbrella": umbrella, "broom": broom}


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
    # Arms: hands to their targets, elbows down and a little out. Holding
    # something, the lead hand turns so the shaft through the fist points
    # along `aim_l`; two-handed, the rear hand takes the same shaft further back.
    held = Vector(p["aim_l"])
    armed = held.length > 0.05
    two_handed = armed and p["two_hand"] > 0.5
    # Two-handed, the shaft is kept in front of the body (owner, 2026-10-09:
    # 「穿模了」 — with the rear hand 0.4 m back along it, a shaft angled down
    # or across ran through the belly): if it passes too close to the trunk,
    # both hands go further out in front until it clears.
    push = Vector((0, 0, 0))
    for clearing in range(8 if two_handed else 1):
        solve_arms(arm, p, held, armed, push)
        if not two_handed:
            break
        deficit, away = shaft_deficit(arm, held)
        if deficit <= 0.0:
            break
        push += away * (deficit + 0.01)
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


# A two-handed shaft's handle runs this far back from the lead grip (the
# broom model's handle end), and must stay this far from each body part's
# line (its radius plus a margin): trunk, head, thighs.
SHAFT_BACK = BROOM_HANDLE_BACK - LONG_GRIP_SHIFT
SHAFT_FORWARD = 0.79 + LONG_GRIP_SHIFT
SHAFT_CLEARANCE = {"trunk": 0.17, "head": 0.15, "thigh": 0.11}


def shaft_deficit(arm, held):
    """How much closer than allowed (m) the held broom — the whole of it, from
    its handle end to its head — comes to the body; 0 when clear."""
    pbs = arm.pose.bones
    lead = pbs["hand_l"].matrix @ HANDS["l"]["centre"]
    butt = lead - held.normalized() * SHAFT_BACK
    tip = lead + held.normalized() * SHAFT_FORWARD
    parts = [("trunk", pbs["pelvis"].matrix.translation, pbs["neck_01"].matrix.translation),
             ("head", pbs["head"].matrix.translation + Vector((0, 0, 0.09)), pbs["head"].matrix.translation + Vector((0, 0, 0.09))),
             ("thigh", pbs["thigh_l"].matrix.translation, pbs["calf_l"].matrix.translation),
             ("thigh", pbs["thigh_r"].matrix.translation, pbs["calf_r"].matrix.translation)]
    worst = 0.0
    away = Vector((0, -1, 0))
    for kind, a, b in parts:
        line = b - a
        for i in range(25):
            point = butt.lerp(tip, i / 24.0)
            t = 0.0 if line.length_squared < 1e-8 else max(0.0, min(1.0, (point - a).dot(line) / line.length_squared))
            off = point - (a + line * t)
            short = SHAFT_CLEARANCE[kind] - off.length
            if short > worst:
                worst = short
                # Out the way the shaft already is from that part, level
                # (never up or down through the body), and never backwards.
                flat = Vector((off.x, min(off.y, 0.0), 0.0))
                forward = Vector((0, -1, 0))
                away = (flat.normalized() + forward).normalized() if flat.length > 1e-4 else forward
    return worst, away


def solve_arms(arm, p, held, armed, push):
    pbs = arm.pose.bones
    grip_point = None
    for side, sx in (("l", 1), ("r", -1)):
        up, low, hand = pbs[f"upperarm_{side}"], pbs[f"lowerarm_{side}"], pbs[f"hand_{side}"]
        shoulder = up.matrix.translation.copy()
        target = Vector(p[f"hand_{side}"]) + (push if side == "l" else Vector((0, 0, 0)))
        if side == "l" and armed and p["two_hand"] > 0.5:
            # Held near the end of the handle: the hand sits further back
            # along the shaft, the head stays where the pose puts it.
            target -= held.normalized() * LONG_GRIP_SHIFT
        on_shaft = armed and (side == "l" or p["two_hand"] > 0.5)
        want = None
        if on_shaft and side == "r" and grip_point is not None:
            # The rear grip is on the shaft behind the lead one; place the
            # wrist so that grip lands there (refined, since how the hand
            # turns depends on where the forearm ends up).
            want = grip_point - held.normalized() * TWO_HAND_SPREAD
            target = want - hold_rotation(side, held, (want - shoulder).normalized()) @ HANDS[side]["centre"]
        for attempt in range(4 if want is not None else 1):
            elbow = two_bone(shoulder, target, up.bone.length, low.bone.length, Vector((sx * 0.6, 0.2, -1.0)))
            aim(up, elbow - shoulder)
            bpy.context.view_layer.update()
            aim(low, target - low.matrix.translation)
            bpy.context.view_layer.update()
            if on_shaft:
                hold_along(hand, side, held, (target - low.matrix.translation).normalized())
            else:
                aim(hand, (target - low.matrix.translation).normalized() + Vector((0, 0, p["hand_up"])))
            bpy.context.view_layer.update()
            if want is None:
                break
            target = target + (want - hand.matrix @ HANDS[side]["centre"])
        curl_fingers(arm, side, p[f"grip_{side}"])
        if side == "l" and armed:
            grip_point = hand.matrix @ HANDS["l"]["centre"]


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


def with_aim(pose, aim):
    pose = dict(pose)
    pose["aim_l"] = aim
    return pose


def strike(arm, name, guard, load, hit, follow, seconds, arc=(0.0, 0.0, 0.0), lag=0.35, back_out=(0.06, -0.10, 0.0)):
    """A weapon blow the way game animators build one (docs/99_notes/
    WEAPON_GRIP_REFERENCE.md, "Other games"): a wind-up, then the hand
    travels a curve, not a straight line (`arc` bows the path out at its
    middle), the weapon lagging behind the hand (`lag`: how far its direction
    has turned when the hand is most of the way) and snapping through at the
    strike, then carrying on past the target (`follow`) before the recovery.
    The game opens the contact window at 0.5 and holds to 0.64."""
    accel = lambda t: t * t
    lin = lambda t: t
    mid = lerp_pose(load, hit, 0.7)
    mid["hand_l"] = tuple(a + b for a, b in zip(mid["hand_l"], arc))
    la, ha = Vector(load["aim_l"]), Vector(hit["aim_l"])
    if la.length > 0.05 and ha.length > 0.05:
        mid["aim_l"] = tuple(la.normalized().slerp(ha.normalized(), lag))
    # Coming back, the hands stay out in front (`back_out`) while the weapon
    # turns back to the guard, so a long shaft's butt end passes beside the
    # body rather than through it.
    back = lerp_pose(follow, guard, 0.5)
    back["hand_l"] = tuple(a + b for a, b in zip(back["hand_l"], back_out))
    fa, ga = Vector(follow["aim_l"]), Vector(guard["aim_l"])
    if fa.length > 0.05 and ga.length > 0.05:
        back["aim_l"] = tuple(fa.normalized().slerp(ga.normalized(), 0.5))
    bake(arm, name, [(0, guard, lin), (0.32, load, smooth), (0.44, mid, accel), (0.5, hit, snap), (0.6, follow, smooth), (0.66, follow, lin), (0.82, back, smooth), (1, guard, smooth)], seconds)


def armed_sets(arm):
    """Everything a fighter does while holding something, one set per way of
    holding it: "_Armed" for the umbrella (one hand), "_Long" for the broom
    (both hands). The puppet picks the set by the weapon's archetype."""
    lin = lambda t: t
    umbrella, broom = armed_guards()
    for suffix, G in (("_Armed", umbrella), ("_Long", broom)):
        bake(arm, "Fight_Stance" + suffix, [(0, G, lin), (1, G, lin)], 1.0, loop=True, bounce=0.03)
        fwd = moved(G, d_foot_l=(0, -0.12, 0.03), d_pelvis=(0, -0.04, 0.0))
        fwd_follow = moved(G, d_foot_r=(0, -0.1, 0.03), d_pelvis=(0, -0.02, -0.01))
        bake(arm, "Fight_Step_Fwd" + suffix, [(0, G, lin), (0.3, fwd, smooth), (0.6, fwd_follow, smooth), (1, G, smooth)], 0.55, bounce=0.015, bounces=1)
        back = moved(G, d_foot_r=(0, 0.12, 0.03), d_pelvis=(0, 0.04, 0.0))
        back_follow = moved(G, d_foot_l=(0, 0.1, 0.03), d_pelvis=(0, 0.02, -0.01))
        bake(arm, "Fight_Step_Back" + suffix, [(0, G, lin), (0.3, back, smooth), (0.6, back_follow, smooth), (1, G, smooth)], 0.5, bounce=0.015, bounces=1)
        side = moved(G, d_foot_l=(0.1, 0.0, 0.03), d_pelvis=(0.04, 0.0, 0.0), d_yaw=-4.0)
        side_follow = moved(G, d_foot_r=(0.09, 0.0, 0.03), d_pelvis=(0.02, 0.0, -0.01))
        bake(arm, "Fight_Circle" + suffix, [(0, G, lin), (0.3, side, smooth), (0.6, side_follow, smooth), (1, G, smooth)], 0.5, bounce=0.015, bounces=1)
        # Hit and slipping: the whole body answers, the hands keep hold.
        hit_light = moved(G, d_head_pitch=-22.0, d_head_yaw=10.0, d_chest_lean=-10.0, d_pelvis=(0, 0.05, 0.0), d_hand_l=(0.02, 0.08, -0.04) if suffix == "_Armed" else (0.03, 0.02, 0.02))
        bake(arm, "Fight_HitLight" + suffix, [(0, G, lin), (0.2, hit_light, snap), (0.45, hit_light, lin), (1, G, smooth)], 0.35)
        hit_heavy = moved(G, d_head_pitch=20.0, d_chest_lean=16.0, d_tilt=8.0, d_pelvis=(0, 0.22, -0.06), d_foot_r=(0, 0.2, 0.0), d_hand_l=(-0.04, 0.2, -0.12), d_yaw=12.0)
        hit_heavy["aim_l"] = tuple(a + b for a, b in zip(G["aim_l"], (0.0, 0.0, -0.35)))
        bake(arm, "Fight_HitHeavy" + suffix, [(0, G, lin), (0.18, hit_heavy, snap), (0.55, hit_heavy, lin), (1, G, smooth)], 0.55)
        slip = moved(G, d_pelvis=(0.1, 0.08, -0.06), d_tilt=-6.0, d_chest_lean=-8.0, d_chest_yaw=10.0, d_hand_l=(0.06, 0.1, -0.02), d_foot_r=(0.04, 0.1, 0.0))
        bake(arm, "Fight_Dodge" + suffix, [(0, G, lin), (0.4, slip, snap), (0.7, slip, lin), (1, G, smooth)], 0.45)

    # Umbrella, after the walking stick (Barton-Wright): thrusts at the face
    # off a straight arm, and cuts that come from the hips, not the elbow.
    U = umbrella
    # Chambered back clearly, then driven out off a long lunge; a thrust
    # runs straight, so no arc, and it settles a little past the point.
    thrust_load = with_aim(moved(U, d_pelvis=(0, 0.06, -0.01), d_hand_l=(0.0, 0.06, 0.02), d_yaw=6.0, d_chest_yaw=4.0), (-0.1, -1.0, 0.45))
    thrust_hit = with_aim(moved(U, d_pelvis=(-0.01, -0.12, -0.03), d_foot_l=(0, -0.15, 0), d_hand_l=(-0.02, -0.19, 0.0), d_yaw=-12.0, d_chest_yaw=-8.0, d_tilt=5.0), (-0.06, -1.0, 0.22))
    thrust_follow = with_aim(moved(thrust_hit, d_hand_l=(0.0, -0.03, -0.02), d_tilt=2.0), (-0.06, -1.0, 0.16))
    strike(arm, "Fight_Thrust", U, thrust_load, thrust_hit, thrust_follow, 0.65, lag=0.8)
    # The cut: raised high beside the head, brought down across on a curve
    # with the hips, the wrist snapping it through, carried on down past the
    # target to the far hip.
    cut_load = with_aim(moved(U, d_hand_l=(0.05, -0.02, 0.48), d_yaw=-14.0, d_chest_yaw=-10.0, d_pelvis=(0.02, 0.02, -0.01), d_tilt=-4.0), (0.25, 0.55, 0.8))
    cut_hit = with_aim(moved(U, d_hand_l=(-0.12, -0.24, 0.10), d_yaw=22.0, d_chest_yaw=16.0, d_head_yaw=-12.0, d_pelvis=(-0.03, -0.05, -0.03), d_tilt=6.0, d_foot_l=(0, -0.06, 0), d_toe_l=(-0.4, 0.2, 0.0)), (-0.55, -0.8, -0.15))
    cut_follow = with_aim(moved(cut_hit, d_hand_l=(-0.16, 0.06, -0.24), d_yaw=10.0, d_chest_yaw=8.0, d_tilt=4.0), (-0.6, -0.3, -0.75))
    strike(arm, "Fight_Swing", U, cut_load, cut_hit, cut_follow, 0.75, arc=(0.04, -0.10, 0.10))
    # The hanging guard: the hand up above the head, the umbrella slanting
    # down across the front of the body, the weight back.
    hang = with_aim(moved(U, d_hand_l=(-0.04, 0.0, 0.62), d_pelvis=(0, 0.06, -0.03), d_head_pitch=10.0, d_chest_lean=-4.0, d_tilt=-4.0), (-0.8, -0.12, -0.58))
    bake(arm, "Fight_Block_Armed", [(0, hang, lin), (1, hang, lin)], 0.3)

    # Broom, like a short bayonet: the thrust is the main blow, both hands
    # driving it; a chop from overhead; a shove with the shaft up close.
    L = broom
    lthrust_load = with_aim(moved(L, d_pelvis=(0, 0.06, -0.01), d_hand_l=(-0.067, 0.158, -0.279), d_yaw=6.0), (0.25, -0.9, 0.35))
    lthrust_hit = with_aim(moved(L, d_pelvis=(-0.01, -0.13, -0.03), d_foot_l=(0, -0.16, 0), d_hand_l=(-0.187, 0.118, -0.219), d_yaw=-8.0, d_tilt=6.0), (0.34, -0.92, 0.2))
    lthrust_follow = with_aim(moved(lthrust_hit, d_hand_l=(0.0, -0.03, -0.02), d_tilt=2.0), (0.34, -0.92, 0.15))
    strike(arm, "Fight_Thrust_Long", L, lthrust_load, lthrust_hit, lthrust_follow, 0.7, lag=0.8)
    # Chop: the whole trunk behind it — lifted high, brought down over the
    # top on a curve, the head carrying on down towards the ground.
    # Lifted right over the head (the hand target is raised to allow for the
    # rear-ended grip pulling it back down the upright shaft).
    chop_load = with_aim(moved(L, d_hand_l=(0.013, 0.118, 0.601), d_pelvis=(0, 0.04, 0.0), d_tilt=-8.0, d_chest_lean=-6.0), (0.1, -0.35, 0.93))
    chop_hit = with_aim(moved(L, d_hand_l=(-0.047, -0.122, -0.179), d_pelvis=(0, -0.06, -0.04), d_tilt=12.0, d_chest_lean=10.0, d_foot_l=(0, -0.08, 0)), (0.12, -0.95, -0.28))
    # The butt end goes past the lead hip, not into the belly.
    chop_follow = with_aim(moved(chop_hit, d_hand_l=(0.08, -0.06, -0.12), d_tilt=5.0, d_chest_lean=6.0, d_pelvis=(0, -0.02, -0.03)), (0.3, -0.82, -0.5))
    strike(arm, "Fight_Swing_Long", L, chop_load, chop_hit, chop_follow, 0.8, arc=(0.0, -0.12, 0.12))
    # Sweep (P-05's long sweep; a staff's sweeping blow at the legs, as Sifu's
    # broom and staff do): wound back to the lead side with the trunk turned
    # away, then swept low across in front with a full trunk turn, carried on
    # round past the target.
    sweep_load = with_aim(moved(L, d_hand_l=(0.133, 0.118, -0.339), d_yaw=-26.0, d_chest_yaw=-14.0, d_pelvis=(0.03, 0.03, -0.05), d_tilt=6.0), (0.8, 0.45, -0.25))
    sweep_hit = with_aim(moved(L, d_hand_l=(-0.167, -0.062, -0.439), d_yaw=20.0, d_chest_yaw=12.0, d_head_yaw=-10.0, d_pelvis=(-0.02, -0.06, -0.08), d_tilt=10.0, d_foot_l=(0, -0.06, 0)), (-0.25, -0.92, -0.38))
    sweep_follow = with_aim(moved(sweep_hit, d_hand_l=(-0.12, -0.20, 0.0), d_yaw=14.0, d_chest_yaw=8.0), (-0.7, -0.62, -0.3))
    # Coming back up to the high guard the hands rise first, so the handle's
    # end clears the thigh.
    strike(arm, "Fight_Sweep_Long", L, sweep_load, sweep_hit, sweep_follow, 0.8, arc=(0.0, -0.14, 0.0), back_out=(0.0, -0.16, 0.28))
    shove = with_aim(moved(L, d_hand_l=(0.033, -0.102, 0.021), d_pelvis=(0, -0.06, -0.01), d_foot_l=(0, -0.07, 0)), (0.97, -0.1, 0.2))
    shove_load = with_aim(moved(L, d_hand_l=(0.053, 0.058, 0.001)), (0.97, -0.1, 0.2))
    bake(arm, "Fight_Shove_Long", [(0, L, lin), (0.3, shove_load, smooth), (0.5, shove, snap), (0.62, shove, lin), (1, L, smooth)], 0.6)
    # Blocking with a staff: the shaft raised across in front of the face.
    # Elbows bent, the shaft across in front of the forehead.
    staff_block = with_aim(moved(L, d_hand_l=(0.203, 0.038, 0.071), d_pelvis=(0, 0.06, -0.03), d_head_pitch=10.0, d_chest_lean=-4.0, d_tilt=-4.0), (0.97, -0.05, 0.1))
    bake(arm, "Fight_Block_Long", [(0, staff_block, lin), (1, staff_block, lin)], 0.3)


def carry_clips(arm):
    """Walking and standing about holding something, outside a fight: Codex's
    relaxed Idle/Walk unchanged except the lead hand, which closes round the
    thing carried — the umbrella point-down like a walking stick, the broom
    on the shoulder, its head resting back over it."""
    before_objects = set(bpy.data.objects)
    before_actions = set(bpy.data.actions)
    bpy.ops.import_scene.gltf(filepath=RELAXED)
    sources = {a.name: a for a in set(bpy.data.actions) - before_actions}
    carried = {"_Armed": Vector((0.0, -0.25, -1.0)), "_Long": Vector((-0.15, 0.85, 0.5))}
    scene = bpy.context.scene
    pbs = arm.pose.bones
    for source_name, out in (("Idle_Relaxed", "Carry_Idle"), ("Walk_Relaxed", "Carry_Walk")):
        source = sources[source_name]
        arm.animation_data.action = source
        if source.slots:
            arm.animation_data.action_slot = source.slots[0]
        start, end = (int(v) for v in source.frame_range)
        poses = []
        for f in range(start, end + 1):
            scene.frame_set(f)
            poses.append({pb.name: pb.matrix_basis.copy() for pb in pbs})
        for suffix, along in carried.items():
            action = bpy.data.actions.new(out + suffix)
            arm.animation_data.action = action
            for i, pose in enumerate(poses):
                for pb in pbs:
                    pb.matrix_basis = pose[pb.name]
                bpy.context.view_layer.update()
                hand = pbs["hand_l"]
                if suffix == "_Long":
                    # Shouldered, the way long things are carried in games
                    # and in life: the hand in front of the shoulder, the
                    # head of the broom resting back over it.
                    up, low = pbs["upperarm_l"], pbs["lowerarm_l"]
                    shoulder = up.matrix.translation.copy()
                    target = shoulder + Vector((0.04, -0.16, -0.12))
                    elbow = two_bone(shoulder, target, up.bone.length, low.bone.length, Vector((0.6, 0.2, -1.0)))
                    aim(up, elbow - shoulder)
                    bpy.context.view_layer.update()
                    aim(low, target - low.matrix.translation)
                    bpy.context.view_layer.update()
                forearm = (hand.matrix.translation - pbs["lowerarm_l"].matrix.translation).normalized()
                hold_along(hand, "l", along, forearm)
                bpy.context.view_layer.update()
                curl_fingers(arm, "l", 1.0)
                for pb in pbs:
                    pb.keyframe_insert("rotation_quaternion", frame=i)
                    if pb.name in ("Root", "pelvis"):
                        pb.keyframe_insert("location", frame=i)
            print("CLIP", out + suffix, len(poses))
    for obj in set(bpy.data.objects) - before_objects:
        bpy.data.objects.remove(obj, do_unlink=True)
    for action in sources.values():
        bpy.data.actions.remove(action)


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

    armed_sets(arm)

    # Defence: a shell — forearms up in front of the face, chin tucked, and
    # the weight sitting back, so the head goes away from the blow and not
    # into the other person's lead hand.
    block = moved(S, d_hand_l=(-0.06, 0.16, 0.14), d_hand_r=(0.04, 0.05, 0.08), d_pelvis=(0, 0.06, -0.03), d_head_pitch=10.0, d_chest_lean=-4.0, d_tilt=-4.0)
    bake(arm, "Fight_Block", [(0, block, lin), (1, block, lin)], 0.3)
    slip = moved(S, d_pelvis=(0.1, 0.08, -0.06), d_tilt=-6.0, d_chest_lean=-8.0, d_chest_yaw=10.0, d_hand_l=(0.06, 0.12, -0.04), d_hand_r=(0.08, 0.1, -0.06), d_foot_r=(0.04, 0.1, 0.0))
    bake(arm, "Fight_Dodge", [(0, S, lin), (0.4, slip, snap), (0.7, slip, lin), (1, S, smooth)], 0.45)
    # Hit reactions: the whole body answers.
    hit_light = moved(S, d_head_pitch=-22.0, d_head_yaw=10.0, d_chest_lean=-10.0, d_pelvis=(0, 0.05, 0.0), d_hand_l=(0.03, 0.1, -0.06), d_hand_r=(-0.02, 0.05, -0.05))
    bake(arm, "Fight_HitLight", [(0, S, lin), (0.2, hit_light, snap), (0.45, hit_light, lin), (1, S, smooth)], 0.35)
    # A heavy blow folds them over it and drives them back: the hips go back
    # further than the chest comes forward, so the head is knocked away and
    # never lunges into the person who hit them.
    hit_heavy = moved(S, d_head_pitch=20.0, d_chest_lean=16.0, d_tilt=8.0, d_pelvis=(0, 0.22, -0.06), d_foot_r=(0, 0.2, 0.0), d_hand_l=(-0.04, 0.24, -0.28), d_hand_r=(0.04, 0.18, -0.26), d_yaw=12.0)
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
    measure_hands(arm)
    build(arm)
    carry_clips(arm)
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
