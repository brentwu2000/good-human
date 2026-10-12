"""Owner head refinement r1 (Claude, owner request 2026-10-12 「請你負責精修人物」).

Target: assets/characters/human/concepts/owner_visual_target_01.png — a full
head of messy dark-brown curls, round glasses, brows.

The 2026-09-29 hair fix left a cap that sat behind and below the skull: in the
game the crown and forehead showed bald, with two lumps at the sides. This
replaces every hair mesh with one built from the skull itself:

1. a scalp shell: a sphere shrink-wrapped onto the head, offset outward, cut
   at a hairline that runs low at the nape and over the ears, high at the brow;
2. curl clumps scattered over the shell (bigger and taller on top, a few
   falling onto the forehead), seeded so every run is the same;
3. shell + clumps voxel-remeshed into one closed mesh, smoothed, decimated.

Also adds round glasses and brows, and lays the jacket's collar points, zip
and seams onto the jacket body. (Stubble was tried and dropped: the face
mesh is too coarse for a clean edge, and the skin material ignores ArtTone.)
Everything new is skinned 100 % to `head`. Body, rig, clips: untouched.

  blender -b --factory-startup --python tools/art/refine_owner_head.py
"""
import bpy, bmesh, math, random, os, json
from mathutils import Vector

SOURCE = r"C:\Users\b\Documents\good-human-3d-pipeline\blender\human\p04_owner\owner_11_hair_fix.blend"
WORK = r"C:\Users\b\Documents\good-human-3d-pipeline\blender\human\p04_owner\owner_12_head_refine.blend"
REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(REPO, "assets", "characters", "human", "models", "p04_owner", "p04_owner_refined.glb")

# Measured on Face_Module (inspect: head slices, eyes at z 1.631..1.648).
CENTER = Vector((0.0, -0.063, 1.655))
EYE_X, EYE_Y, EYE_Z = 0.041, -0.162, 1.640
SEED = 12

bpy.ops.wm.open_mainfile(filepath=SOURCE)
rig = bpy.data.objects["OwnerSkeleton"]
face = bpy.data.objects["Face_Module"]
for name in ("Hair_Cap_Refined", "Hair_Fringe_00", "Hair_Fringe_01", "Hair_Fringe_02", "Hair_Module"):
    o = bpy.data.objects.get(name)
    if o:
        bpy.data.objects.remove(o)


def material(name, color, roughness):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    m.diffuse_color = color
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = roughness
    return m


HAIR = material("GH_Hair_Curls", (0.075, 0.048, 0.032, 1.0), 0.62)
FRAME = material("GH_Glasses", (0.035, 0.03, 0.03, 1.0), 0.35)
BROW = material("GH_Brow", (0.06, 0.04, 0.03, 1.0), 0.8)


def hairline(d: Vector) -> float:
    """Lowest z with hair, for the direction `d` from CENTER."""
    phi = abs(math.atan2(d.x, -d.y))  # 0 = forehead, pi = nape
    keys = [(0.0, 1.708), (0.45, 1.700), (0.95, 1.672), (1.35, 1.655), (1.75, 1.648), (2.3, 1.610), (math.pi, 1.578)]
    for (a0, z0), (a1, z1) in zip(keys, keys[1:]):
        if phi <= a1:
            t = (phi - a0) / (a1 - a0)
            return z0 + (z1 - z0) * t
    return keys[-1][1]


def skin_to_head(o):
    o.parent = rig
    o.matrix_parent_inverse = rig.matrix_world.inverted()
    group = o.vertex_groups.new(name="head")
    group.add(list(range(len(o.data.vertices))), 1.0, "REPLACE")
    mod = o.modifiers.new("Armature", "ARMATURE")
    mod.object = rig


def apply_all(o):
    bpy.context.view_layer.objects.active = o
    for m in list(o.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)


# 1. Scalp shell.
bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=32, radius=0.16, location=CENTER)
shell = bpy.context.active_object
shell.name = "Hair_Shell"
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)  # world coords below
wrap = shell.modifiers.new("wrap", "SHRINKWRAP")
wrap.target = face
wrap.wrap_method = "NEAREST_SURFACEPOINT"
wrap.offset = 0.010
apply_all(shell)
bm = bmesh.new()
bm.from_mesh(shell.data)
bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < hairline(v.co - CENTER) or (v.co - CENTER).length > 0.15], context="VERTS")
bm.to_mesh(shell.data)
bm.free()
shell.modifiers.new("thick", "SOLIDIFY").thickness = 0.012
apply_all(shell)

# 2. Curl clumps over the shell.
rng = random.Random(SEED)
spots = []
for v in shell.data.vertices:
    d = (v.co - CENTER)
    if d.length < 0.07:
        continue
    spots.append((v.co.copy(), d.normalized()))
rng.shuffle(spots)
clumps = []
for co, n in spots[:260]:
    top = max(0.0, (co.z - 1.66) / 0.10)  # 0 at the ears, 1 on the crown
    r = rng.uniform(0.013, 0.020) + 0.007 * top
    lift = r * rng.uniform(0.25, 0.60) + 0.004 * top
    clumps.append((co + n * lift, r))
# Forelock: a few curls fall onto the forehead, off-centre like the sheet.
for x, z, r in ((-0.045, 1.712, 0.020), (-0.015, 1.705, 0.022), (0.022, 1.712, 0.019), (-0.065, 1.722, 0.018), (0.055, 1.724, 0.017)):
    clumps.append((Vector((x, -0.170, z)), r))
bm = bmesh.new()
for c, r in clumps:
    m = bmesh.ops.create_icosphere(bm, subdivisions=2, radius=r)
    sx, sz = rng.uniform(0.85, 1.2), rng.uniform(0.8, 1.15)
    for v in m["verts"]:
        v.co = Vector((v.co.x * sx, v.co.y, v.co.z * sz)) + c
clump_mesh = bpy.data.meshes.new("Hair_Clumps")
bm.to_mesh(clump_mesh)
bm.free()
clump_obj = bpy.data.objects.new("Hair_Clumps", clump_mesh)
bpy.context.collection.objects.link(clump_obj)

# 3. One closed mesh.
bpy.ops.object.select_all(action="DESELECT")
shell.select_set(True)
clump_obj.select_set(True)
bpy.context.view_layer.objects.active = shell
bpy.ops.object.join()
hair = shell
hair.name = "Hair_Curls"
remesh = hair.modifiers.new("remesh", "REMESH")
remesh.mode = "VOXEL"
remesh.voxel_size = 0.004
smooth = hair.modifiers.new("smooth", "SMOOTH")
smooth.factor = 0.6
smooth.iterations = 4
dec = hair.modifiers.new("dec", "DECIMATE")
dec.ratio = 0.12
apply_all(hair)
# Never inside the skin: push any vertex under the face surface back out.
bm = bmesh.new()
bm.from_mesh(hair.data)
depsgraph = bpy.context.evaluated_depsgraph_get()
face_eval = face.evaluated_get(depsgraph)
inv = face.matrix_world.inverted()
pushed = 0
for v in bm.verts:
    ok, loc, normal, _ = face_eval.closest_point_on_mesh(inv @ v.co)
    if ok:
        world = face.matrix_world @ loc
        nw = (face.matrix_world.to_3x3() @ normal).normalized()
        if (v.co - world).dot(nw) < 0.003:
            v.co = world + nw * 0.003
            pushed += 1
bm.to_mesh(hair.data)
bm.free()
hair.data.materials.clear()
hair.data.materials.append(HAIR)
for p in hair.data.polygons:
    p.use_smooth = True
skin_to_head(hair)

# Glasses: two round rims, a bridge, temples back to the ears.
RIM_R, WIRE = 0.023, 0.0022
RIM_Y = EYE_Y - 0.016
rims = []
for sx in (-1, 1):
    bpy.ops.mesh.primitive_torus_add(major_segments=28, minor_segments=6, major_radius=RIM_R, minor_radius=WIRE,
                                     location=(sx * EYE_X, RIM_Y, EYE_Z), rotation=(math.radians(90), 0.0, 0.0))
    rims.append(bpy.context.active_object)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
glasses = rims[0]
glasses.name = "Glasses"


def bar(name, a: Vector, b: Vector, r: float):
    mid, d = (a + b) / 2, b - a
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=r, depth=d.length, location=mid)
    o = bpy.context.active_object
    o.name = name
    o.rotation_mode = "QUATERNION"
    o.rotation_quaternion = d.to_track_quat("Z", "Y")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return o


parts = rims + [bar("Glasses_Bridge", Vector((-EYE_X + RIM_R, RIM_Y, EYE_Z + 0.004)), Vector((EYE_X - RIM_R, RIM_Y, EYE_Z + 0.004)), 0.0016)]
for sx in (-1, 1):
    parts.append(bar("Glasses_Temple", Vector((sx * (EYE_X + RIM_R), RIM_Y, EYE_Z + 0.004)), Vector((sx * 0.101, -0.05, EYE_Z + 0.002)), 0.0017))
bpy.ops.object.select_all(action="DESELECT")
for o in parts:
    o.select_set(True)
bpy.context.view_layer.objects.active = glasses
bpy.ops.object.join()
glasses.data.materials.clear()
glasses.data.materials.append(FRAME)
skin_to_head(glasses)

# Brows: soft slabs following the forehead just above the rims.
brows = []
for sx in (-1, 1):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=6, radius=1.0, location=(sx * 0.040, -0.170, 1.671))
    b = bpy.context.active_object
    b.scale = (0.021, 0.006, 0.0042)
    b.rotation_euler = (0.0, sx * math.radians(-8), 0.0)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    w = b.modifiers.new("wrap", "SHRINKWRAP")
    w.target = face
    w.wrap_mode = "OUTSIDE_SURFACE"
    w.offset = 0.0012
    apply_all(b)
    brows.append(b)
bpy.ops.object.select_all(action="DESELECT")
for b in brows:
    b.select_set(True)
bpy.context.view_layer.objects.active = brows[0]
bpy.ops.object.join()
brow = brows[0]
brow.name = "Brows"
brow.data.materials.clear()
brow.data.materials.append(BROW)
skin_to_head(brow)

# Jacket details: the collar points, zip and seams were boxes floating off the
# chest (the collar points stood out like boomerangs). Each loose detail part
# is laid onto the jacket body: every vertex moves to the nearest point on the
# body plus a small lift, keeping half of its original thickness.
top = bpy.data.objects["Top_Module"]
body_mat = [i for i, m in enumerate(top.data.materials) if m and m.name.startswith("GH_Jacket.001")][0]
shell_mesh = top.data.copy()
shell_obj = bpy.data.objects.new("Jacket_Body_Tmp", shell_mesh)
bpy.context.collection.objects.link(shell_obj)
shell_obj.matrix_world = top.matrix_world
bm = bmesh.new()
bm.from_mesh(shell_mesh)
bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.material_index != body_mat], context="FACES")
bm.to_mesh(shell_mesh)
bm.free()
bpy.context.view_layer.update()
bm = bmesh.new()
bm.from_mesh(top.data)
bm.verts.ensure_lookup_table()
mw, mwi = top.matrix_world, top.matrix_world.inverted()
seen = set()
laid = 0
for f in bm.faces:
    if f.index in seen or f.material_index == body_mat:
        continue
    part, stack = [], [f]
    while stack:
        g = stack.pop()
        if g.index in seen:
            continue
        seen.add(g.index)
        part.append(g)
        stack.extend(h for e in g.edges for h in e.link_faces if h.index not in seen)
    if len(part) > 40:  # hem and cuff bands already sit on the body
        continue
    verts = {v for g in part for v in g.verts}
    hits = {}
    for v in verts:
        ok, loc, normal, _ = shell_obj.closest_point_on_mesh(v.co)
        hits[v] = (loc, normal.normalized(), (v.co - loc).dot(normal.normalized()))
    base = min(h[2] for h in hits.values())
    for v, (loc, n, d) in hits.items():
        v.co = loc + n * (0.0015 + (d - base) * 0.5)
    laid += 1
bm.to_mesh(top.data)
bm.free()
bpy.data.objects.remove(shell_obj)

bpy.ops.wm.save_as_mainfile(filepath=WORK)
meshes = [o for o in bpy.data.objects if o.type == "MESH" and not o.hide_render and o.name != "SOURCE_HIDDEN_DO_NOT_EXPORT"]
for o in bpy.data.objects:
    o.hide_set(False)
    o.select_set(o is rig or o in meshes)
bpy.context.view_layer.objects.active = rig
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_animations=True,
                          export_animation_mode="ACTIONS", export_skins=True, export_yup=True, export_apply=False)
report = {o.name: sum(len(p.vertices) - 2 for p in o.data.polygons) for o in meshes}
print("OWNER_HEAD_REFINED", OUT, json.dumps(report), "pushed", pushed, "laid parts", laid)
