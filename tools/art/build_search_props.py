"""ART-039 search props, modelled (Claude, at the owner's request 2026-10-06
while Codex works on the dogs). Same categories and silhouettes as
docs/06_art/3D_SEARCH_PROPS_SPEC.md, as grounded street objects:

  trash_bag  a tied black rubbish bag (and a smaller one), a coloured scrap
  mailbox    a raised box on a post, curved cap, mail slot, red flag
  bush       a clump of shrub with a half-hidden paper scrap
  bench      a slatted park bench, cast-iron ends, a forgotten paper bag
  gym_bag    a duffel bag with strap and patch, a water bottle beside it

Run headless:  blender --background --python tools/art/build_search_props.py
Origin on the ground at the search point; game axes (x, y up, z) converted to
Blender. One mesh per prop for draw calls; plain PBR materials.
"""
import bpy, bmesh, math, os, random
from mathutils import Vector, noise

ROOT = r"C:\Users\b\Documents\good-human"
OUT = os.path.join(ROOT, "assets", "items", "search_props", "models")
SOURCE = r"C:\Users\b\Documents\good-human-3d-pipeline\blender\props\search"
os.makedirs(OUT, exist_ok=True)
os.makedirs(SOURCE, exist_ok=True)

_mats = {}


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _mats.clear()


def mat(name, color, roughness=0.7, metallic=0.0):
    if name in _mats:
        return _mats[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bs = m.node_tree.nodes.get("Principled BSDF")
    bs.inputs["Base Color"].default_value = (*color, 1)
    bs.inputs["Roughness"].default_value = roughness
    bs.inputs["Metallic"].default_value = metallic
    m.diffuse_color = (*color, 1)
    _mats[name] = m
    return m


def active():
    return bpy.context.view_layer.objects.active


def g2b(x, y, z):
    return (x, -z, y)


def box(name, centre, size, material, bevel=0.0, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=g2b(*centre))
    o = active()
    o.name = name
    o.scale = (size[0] / 2, size[2] / 2, size[1] / 2)
    o.rotation_euler = (rotation[0], -rotation[2], rotation[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = o.modifiers.new("bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 3
    o.data.materials.append(material)
    return o


def upright(name, x, z, y0, y1, radius, material, verts=16, top=None):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=radius, radius2=radius if top is None else top, depth=y1 - y0, location=g2b(x, (y0 + y1) / 2, z))
    o = active()
    o.name = name
    o.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return o


def lump(name, centre, radius, squash, material, roughness=0.18, seed=0, subdiv=3):
    """A soft, lumpy blob: an icosphere pushed about by noise."""
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdiv, radius=radius, location=(0, 0, 0))
    o = active()
    o.name = name
    for v in o.data.vertices:
        n = noise.noise(v.co * 3.0 + Vector((seed, seed * 2, seed * 3)))
        v.co *= 1.0 + n * roughness
    o.scale = (squash[0], squash[2], squash[1])
    bpy.ops.object.transform_apply(scale=True)
    o.location = g2b(*centre)
    o.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return o


def export(name):
    for o in bpy.data.objects:
        for mod in list(o.modifiers):
            bpy.context.view_layer.objects.active = o
            bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.object.select_all(action="DESELECT")
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.join()
    active().name = name
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE, name + ".blend"))
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, name + ".glb"), export_format="GLB", use_selection=True, export_yup=True, export_apply=True)
    print("EXPORTED", name)


def build_trash_bag():
    reset()
    plastic = mat("Trash_Plastic_Black", (0.05, 0.055, 0.06), 0.35)
    plastic2 = mat("Trash_Plastic_Grey", (0.12, 0.13, 0.14), 0.4)
    scrap = mat("Trash_Scrap_Coral", (0.85, 0.44, 0.34), 0.8)
    paper = mat("Trash_Scrap_Paper", (0.92, 0.89, 0.8), 0.9)
    bag = lump("Trash_Bag", (0, 0.3, 0), 0.3, (1.0, 1.1, 0.95), plastic, 0.14, 1)
    # Slumped where it sits on the pavement, gathered towards the neck.
    for v in bag.data.vertices:
        if v.co.z < -0.22:
            v.co.z = -0.22 + (v.co.z + 0.22) * 0.3
        if v.co.z > 0.12:
            k = 1.0 - (v.co.z - 0.12) / 0.3 * 0.55
            v.co.x *= k
            v.co.y *= k
    upright("Trash_Neck", 0, 0, 0.58, 0.68, 0.045, plastic, 12, 0.02)
    for side in (-1, 1):
        lump("Trash_Ear", (side * 0.035, 0.7, 0), 0.03, (1.0, 1.4, 0.45), plastic, 0.1, 3 + side, 2)
    lump("Trash_Bag_Small", (0.36, 0.15, 0.12), 0.17, (1.0, 0.9, 1.0), plastic2, 0.2, 5)
    upright("Trash_Small_Neck", 0.36, 0.12, 0.28, 0.36, 0.03, plastic2, 10, 0.015)
    box("Trash_Scrap", (0.04, 0.5, -0.26), (0.2, 0.035, 0.035), scrap, 0.004, (0, 0, -0.1))
    box("Trash_Paper", (-0.18, 0.04, -0.3), (0.16, 0.004, 0.12), paper, 0.0, (0, 0.5, 0))
    export("trash_bag")


def build_mailbox():
    reset()
    paint = mat("Mailbox_Paint_Teal", (0.18, 0.44, 0.42), 0.45, 0.4)
    post_mat = mat("Mailbox_Post", (0.15, 0.17, 0.18), 0.5, 0.6)
    flag = mat("Mailbox_Flag_Red", (0.78, 0.2, 0.16), 0.5, 0.2)
    slot = mat("Mailbox_Slot", (0.06, 0.06, 0.07), 0.6)
    label = mat("Mailbox_Label", (0.93, 0.9, 0.82), 0.8)
    upright("Mailbox_Post", 0, 0, 0.0, 0.72, 0.045, post_mat, 12)
    box("Mailbox_Base_Plate", (0, 0.72, 0), (0.3, 0.02, 0.3), post_mat, 0.004)
    box("Mailbox_Body", (0, 0.92, 0), (0.48, 0.4, 0.34), paint, 0.012)
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.17, depth=0.48, location=g2b(0, 1.12, 0), rotation=(0, math.pi / 2, 0))
    active().name = "Mailbox_Cap"
    active().data.materials.append(paint)
    bpy.ops.object.shade_smooth()
    box("Mailbox_Slot", (0, 1.0, -0.172), (0.28, 0.035, 0.01), slot)
    box("Mailbox_Label", (0, 0.85, -0.172), (0.18, 0.07, 0.006), label)
    box("Mailbox_FlagArm", (0.26, 1.06, 0.02), (0.025, 0.36, 0.025), flag)
    box("Mailbox_Flag", (0.34, 1.2, 0.02), (0.16, 0.1, 0.012), flag, 0.003)
    export("mailbox")


def build_bush():
    reset()
    random.seed(4)
    leaves = [mat("Bush_Leaf_Dark", (0.17, 0.33, 0.16), 0.75), mat("Bush_Leaf", (0.24, 0.42, 0.2), 0.75), mat("Bush_Leaf_Light", (0.33, 0.5, 0.25), 0.75)]
    paper = mat("Bush_Paper", (0.92, 0.89, 0.8), 0.9)
    soil = mat("Bush_Soil", (0.28, 0.21, 0.15), 0.95)
    box("Bush_Soil", (0, 0.01, 0), (1.3, 0.02, 0.9), soil, 0.05)
    for i in range(14):
        x = random.uniform(-0.5, 0.5)
        z = random.uniform(-0.3, 0.3)
        y = 0.35 + random.uniform(0.0, 0.5) * (1 - abs(x))
        lump("Bush_Clump", (x, y, z), random.uniform(0.22, 0.34), (1.0, 0.85, 1.0), leaves[i % 3], 0.35, i, 2)
    box("Bush_Paper", (0.18, 0.15, -0.48), (0.23, 0.025, 0.18), paper, 0.0, (0.05, 0.2, 0.12))
    export("bush")


def build_bench():
    reset()
    wood = mat("Bench_Wood_Slat", (0.52, 0.36, 0.22), 0.7)
    iron = mat("Bench_CastIron", (0.12, 0.13, 0.14), 0.5, 0.7)
    bag = mat("Bench_PaperBag", (0.76, 0.6, 0.4), 0.85)
    cup = mat("Bench_Cup", (0.93, 0.92, 0.88), 0.6)
    for i in range(4):
        box("Bench_SeatSlat", (0, 0.47, -0.2 + i * 0.13), (1.65, 0.04, 0.1), wood, 0.008)
    for i in range(3):
        box("Bench_BackSlat", (0, 0.66 + i * 0.13, 0.27), (1.65, 0.1, 0.035), wood, 0.008, (0.18, 0, 0))
    for x in (-0.66, 0.66):
        box("Bench_End_Leg_Front", (x, 0.23, -0.2), (0.05, 0.46, 0.05), iron, 0.006)
        box("Bench_End_Leg_Back", (x, 0.45, 0.25), (0.05, 0.9, 0.05), iron, 0.006, (0.12, 0, 0))
        box("Bench_End_Rail", (x, 0.44, 0.02), (0.05, 0.04, 0.5), iron, 0.006)
        box("Bench_Arm", (x, 0.66, -0.05), (0.06, 0.04, 0.42), iron, 0.008)
    # Forgotten on the seat: a folded paper bag and a takeaway cup.
    box("Bench_PaperBag", (0.36, 0.56, -0.1), (0.26, 0.14, 0.18), bag, 0.01, (0.04, -0.15, 0.08))
    upright("Bench_Cup", -0.4, -0.05, 0.49, 0.61, 0.04, cup, 16, 0.048)
    export("bench")


def build_gym_bag():
    reset()
    canvas = mat("GymBag_Canvas", (0.25, 0.3, 0.38), 0.85)
    trim = mat("GymBag_Trim", (0.1, 0.11, 0.13), 0.7)
    patch = mat("GymBag_Patch_Teal", (0.23, 0.56, 0.52), 0.7)
    bottle = mat("GymBag_Bottle", (0.8, 0.36, 0.28), 0.35)
    cap = mat("GymBag_Bottle_Cap", (0.9, 0.9, 0.88), 0.4)
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.19, depth=0.68, location=g2b(0, 0.2, 0), rotation=(0, math.pi / 2, 0))
    o = active()
    o.name = "GymBag_Body"
    o.scale = (1, 1.0, 0.95)
    bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(canvas)
    bpy.ops.object.shade_smooth()
    # Squash it where it sits.
    for v in o.data.vertices:
        if v.co.z < 0.06:
            v.co.z = 0.06 + (v.co.z - 0.06) * 0.35
    for x in (-0.345, 0.345):
        bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.17, depth=0.02, location=g2b(x, 0.2, 0), rotation=(0, math.pi / 2, 0))
        active().name = "GymBag_EndPanel"
        active().data.materials.append(trim)
    box("GymBag_Zip", (0, 0.39, 0), (0.6, 0.012, 0.03), trim)
    box("GymBag_Patch", (0, 0.22, -0.19), (0.26, 0.16, 0.012), patch, 0.004)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.22, minor_radius=0.014, major_segments=24, minor_segments=6, location=g2b(0, 0.42, 0), rotation=(math.pi / 2, 0, 0))
    o = active()
    o.name = "GymBag_Handles"
    o.scale = (1.3, 1, 0.5)
    o.data.materials.append(trim)
    upright("GymBag_Bottle", 0.52, 0.05, 0.0, 0.22, 0.04, bottle, 16)
    upright("GymBag_Bottle_Cap", 0.52, 0.05, 0.22, 0.25, 0.025, cap, 12)
    export("gym_bag")


build_trash_bag()
build_mailbox()
build_bush()
build_bench()
build_gym_bag()
print("SEARCH_PROPS_DONE")
