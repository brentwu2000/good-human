"""Street clutter for the walk (Claude, at the owner's request 2026-10-07):
the things that make a Taiwanese lane feel lived in.

Run headless:  blender --background --python tools/art/build_street_clutter.py

Each piece stands on the ground at its origin, front facing -z (the street);
game axes converted to Blender; one mesh each:
  scooter, potted_plant, light_box_sign, a_board, plastic_stool, cone,
  utility_box
"""
import bpy, math, os, random
from mathutils import Vector, noise

ROOT = r"C:\Users\b\Documents\good-human"
OUT = os.path.join(ROOT, "assets", "environment", "walk_kit", "clutter")
SOURCE = r"C:\Users\b\Documents\good-human-3d-pipeline\blender\environment\walk_kit\clutter"
os.makedirs(OUT, exist_ok=True)
os.makedirs(SOURCE, exist_ok=True)

_mats = {}


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _mats.clear()


def mat(name, color, roughness=0.7, metallic=0.0, emission=0.0):
    if name in _mats:
        return _mats[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bs = m.node_tree.nodes.get("Principled BSDF")
    bs.inputs["Base Color"].default_value = (*color, 1)
    bs.inputs["Roughness"].default_value = roughness
    bs.inputs["Metallic"].default_value = metallic
    if emission:
        bs.inputs["Emission Color"].default_value = (*color, 1)
        bs.inputs["Emission Strength"].default_value = emission
    m.diffuse_color = (*color, 1)
    _mats[name] = m
    return m


def active():
    return bpy.context.view_layer.objects.active


def g2b(x, y, z):
    return (x, -z, y)


def box(centre, size, material, bevel=0.0, tilt_x=0.0):
    bpy.ops.mesh.primitive_cube_add(location=g2b(*centre))
    o = active()
    o.scale = (size[0] / 2, size[2] / 2, size[1] / 2)
    o.rotation_euler = (-tilt_x, 0, 0)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = o.modifiers.new("bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    o.data.materials.append(material)
    return o


def upright(x, z, y0, y1, radius, material, verts=16, top=None):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=radius, radius2=radius if top is None else top, depth=y1 - y0, location=g2b(x, (y0 + y1) / 2, z))
    o = active()
    o.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return o


def wheel(x, y, z, radius, width, material):
    bpy.ops.mesh.primitive_torus_add(major_radius=radius, minor_radius=width, major_segments=24, minor_segments=8, location=g2b(x, y, z), rotation=(0, math.pi / 2, 0))
    active().data.materials.append(material)


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


def build_scooter():
    reset()
    body = mat("Scooter_Body", (0.82, 0.82, 0.8), 0.35)
    accent = mat("Scooter_Accent", (0.62, 0.16, 0.14), 0.4)
    tyre = mat("Scooter_Tyre", (0.07, 0.07, 0.08), 0.9)
    seat = mat("Scooter_Seat", (0.1, 0.09, 0.09), 0.6)
    metal = mat("Scooter_Metal", (0.5, 0.52, 0.54), 0.3, 0.8)
    lamp = mat("Scooter_Lamp", (0.95, 0.93, 0.85), 0.2)
    # Parked side-on to the shop front: it runs along x.
    for x in (-0.62, 0.6):
        bpy.ops.mesh.primitive_torus_add(major_radius=0.2, minor_radius=0.06, major_segments=24, minor_segments=8, location=g2b(x, 0.26, 0), rotation=(math.pi / 2, 0, 0))
        active().data.materials.append(tyre)
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.1, depth=0.06, location=g2b(x, 0.26, 0), rotation=(math.pi / 2, 0, 0))
        active().data.materials.append(metal)
    box((0.0, 0.34, 0), (0.7, 0.08, 0.3), body, 0.03)
    box((0.42, 0.56, 0), (0.62, 0.36, 0.38), body, 0.08)
    box((0.42, 0.79, 0), (0.62, 0.09, 0.3), seat, 0.03)
    box((0.62, 0.62, 0), (0.1, 0.18, 0.2), accent, 0.02)
    box((-0.5, 0.66, 0), (0.12, 0.62, 0.34), body, 0.05)
    box((-0.58, 0.88, 0), (0.06, 0.12, 0.2), lamp, 0.02)
    upright(-0.45, 0, 0.9, 1.05, 0.02, metal, 8)
    bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.016, depth=0.62, location=g2b(-0.45, 1.05, 0), rotation=(math.pi / 2, 0, 0))
    active().data.materials.append(metal)
    for z in (-0.32, 0.32):
        box((-0.45, 1.05, z), (0.04, 0.03, 0.1), seat)
    export("scooter")


def build_potted_plant():
    reset()
    random.seed(61)
    pot = mat("Clutter_Pot_Glazed", (0.32, 0.42, 0.5), 0.35)
    leaf = [mat("Clutter_Leaf", (0.24, 0.44, 0.22), 0.7), mat("Clutter_Leaf_Light", (0.33, 0.52, 0.26), 0.7)]
    upright(0, 0, 0.0, 0.42, 0.2, pot, 20, 0.25)
    for i in range(9):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=random.uniform(0.15, 0.22), location=g2b(random.uniform(-0.15, 0.15), 0.55 + random.uniform(0, 0.4), random.uniform(-0.15, 0.15)))
        o = active()
        o.scale = (0.8, 0.8, 1.3)
        o.data.materials.append(leaf[i % 2])
        bpy.ops.object.shade_smooth()
    export("potted_plant")


def build_light_box_sign():
    reset()
    frame = mat("LightBox_Frame", (0.85, 0.85, 0.82), 0.4)
    face = mat("LightBox_Face", (0.96, 0.95, 0.9), 0.3, 0.0, 0.6)
    red = mat("LightBox_Text_Red", (0.78, 0.18, 0.14), 0.4, 0.0, 0.3)
    base = mat("LightBox_Base", (0.2, 0.2, 0.22), 0.6)
    box((0, 0.06, 0), (0.5, 0.12, 0.4), base, 0.02)
    box((0, 0.75, 0), (0.42, 1.3, 0.24), frame, 0.03)
    for side in (-1, 1):
        box((0, 0.78, side * 0.125), (0.36, 1.14, 0.01), face)
        for i in range(3):
            box((0, 1.1 - i * 0.3, side * 0.132), (0.22, 0.2, 0.004), red)
    export("light_box_sign")


def build_a_board():
    reset()
    wood = mat("ABoard_Wood", (0.45, 0.32, 0.2), 0.7)
    slate = mat("ABoard_Chalk", (0.14, 0.16, 0.15), 0.85)
    chalk = mat("ABoard_ChalkText", (0.9, 0.9, 0.86), 0.9)
    for side in (-1, 1):
        box((0, 0.45, side * 0.14), (0.56, 0.9, 0.03), wood, 0.01, side * 0.16)
        box((0, 0.47, side * 0.155), (0.46, 0.7, 0.01), slate, 0.0, side * 0.16)
        for i in range(4):
            box((0, 0.68 - i * 0.14, side * 0.163), (0.32 - (i % 2) * 0.08, 0.04, 0.004), chalk, 0.0, side * 0.16)
    export("a_board")


def build_plastic_stool():
    reset()
    red = mat("Stool_Plastic_Red", (0.78, 0.16, 0.14), 0.45)
    upright(0, 0, 0.0, 0.42, 0.17, red, 20, 0.14)
    upright(0, 0, 0.42, 0.46, 0.15, red, 20, 0.15)
    export("plastic_stool")


def build_cone():
    reset()
    orange = mat("Cone_Orange", (0.92, 0.42, 0.12), 0.5)
    white = mat("Cone_Reflective", (0.95, 0.95, 0.92), 0.3)
    box((0, 0.02, 0), (0.36, 0.04, 0.36), orange, 0.01)
    upright(0, 0, 0.04, 0.62, 0.13, orange, 20, 0.02)
    upright(0, 0, 0.3, 0.38, 0.085, white, 20, 0.072)
    export("cone")


def build_utility_box():
    reset()
    green = mat("UtilityBox_Green", (0.36, 0.45, 0.36), 0.6, 0.3)
    plate = mat("UtilityBox_Plate", (0.92, 0.88, 0.32), 0.5)
    box((0, 0.65, 0), (0.8, 1.3, 0.45), green, 0.02)
    box((0, 1.33, 0), (0.86, 0.06, 0.5), green, 0.01)
    box((0, 1.0, -0.23), (0.18, 0.12, 0.01), plate)
    box((0.18, 0.7, -0.23), (0.02, 0.5, 0.02), green)
    export("utility_box")


build_scooter()
build_potted_plant()
build_light_box_sign()
build_a_board()
build_plastic_stool()
build_cone()
build_utility_box()
print("CLUTTER_DONE")
