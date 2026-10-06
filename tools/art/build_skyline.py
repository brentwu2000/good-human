"""The walk's distance: a ring of city beyond the map's edges (Claude, at the
owner's request 2026-10-07). Seen through the run's haze, it says "this is a
neighbourhood in a city", not "this is a box with walls".

Run headless:  blender --background --python tools/art/build_skyline.py

The map is x -32..32, z +12 (north, behind the street) .. -70 (south, the far
end of the park). The ring stands 8-40 m outside it: apartment blocks of
different heights with window bands and rooftop tanks, and a line of tall
trees beyond the park's far end. Game axes converted to Blender; one mesh.
"""
import bpy, math, os, random
from mathutils import Vector, noise

ROOT = r"C:\Users\b\Documents\good-human"
OUT = os.path.join(ROOT, "assets", "environment", "walk_kit")
SOURCE = r"C:\Users\b\Documents\good-human-3d-pipeline\blender\environment\walk_kit"
os.makedirs(OUT, exist_ok=True)
os.makedirs(SOURCE, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
random.seed(51)
_mats = {}


def mat(name, color, roughness=0.85):
    if name in _mats:
        return _mats[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bs = m.node_tree.nodes.get("Principled BSDF")
    bs.inputs["Base Color"].default_value = (*color, 1)
    bs.inputs["Roughness"].default_value = roughness
    m.diffuse_color = (*color, 1)
    _mats[name] = m
    return m


def active():
    return bpy.context.view_layer.objects.active


def g2b(x, y, z):
    return (x, -z, y)


def box(centre, size, material):
    bpy.ops.mesh.primitive_cube_add(location=g2b(*centre))
    o = active()
    o.scale = (size[0] / 2, size[2] / 2, size[1] / 2)
    bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(material)
    return o


facades = [mat("Skyline_Facade_A", (0.78, 0.74, 0.68)), mat("Skyline_Facade_B", (0.66, 0.68, 0.7)), mat("Skyline_Facade_C", (0.82, 0.78, 0.7)), mat("Skyline_Facade_D", (0.7, 0.64, 0.62))]
windows = mat("Skyline_WindowBand", (0.28, 0.33, 0.37), 0.3)
roof = mat("Skyline_Roof", (0.45, 0.45, 0.46))
tank = mat("Skyline_WaterTank", (0.86, 0.86, 0.84), 0.5)
trees = [mat("Skyline_Tree_Dark", (0.2, 0.34, 0.2)), mat("Skyline_Tree", (0.26, 0.42, 0.24))]


def block(x, z, width, depth, height, facing):
    """An apartment block; window bands on the side facing the map."""
    f = random.choice(facades)
    box((x, height / 2, z), (width, height, depth), f)
    box((x, height + 0.15, z), (width + 0.2, 0.3, depth + 0.2), roof)
    floors = int(height / 3.0)
    fx, fz = facing
    for k in range(1, floors):
        y = k * 3.0 + 1.2
        if fx == 0:
            box((x, y, z + fz * (depth / 2 + 0.02)), (width * 0.86, 1.1, 0.06), windows)
        else:
            box((x + fx * (width / 2 + 0.02), y, z), (0.06, 1.1, depth * 0.86), windows)
    if random.random() < 0.6:
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.9, depth=1.6, location=g2b(x + random.uniform(-width / 4, width / 4), height + 1.1, z + random.uniform(-depth / 4, depth / 4)))
        active().data.materials.append(tank)


# North, behind the street's buildings (they face the map: -z).
x = -60.0
while x < 60.0:
    w = random.uniform(8, 14)
    block(x + w / 2, random.uniform(24, 34), w, random.uniform(8, 12), random.uniform(10, 34), (0, -1))
    x += w + random.uniform(1, 4)
# East and west, along the map's sides.
for side in (-1, 1):
    z = 20.0
    while z > -95.0:
        d = random.uniform(8, 14)
        block(side * random.uniform(42, 52), z - d / 2, random.uniform(8, 12), d, random.uniform(9, 28), (-side, 0))
        z -= d + random.uniform(1, 5)
# South, past the far end of the park: a line of tall trees, blocks behind.
for i in range(26):
    tx = -58 + i * 4.6 + random.uniform(-1, 1)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=random.uniform(3.0, 4.6), location=g2b(tx, random.uniform(6, 9), random.uniform(-80, -76)))
    o = active()
    for v in o.data.vertices:
        v.co *= 1.0 + noise.noise(v.co * 0.4 + Vector((i, i * 2, 0))) * 0.25
    o.scale = (1.0, 1.0, 1.2)
    o.data.materials.append(trees[i % 2])
    box((tx, 2.5, random.uniform(-80, -76)), (0.7, 5.0, 0.7), mat("Skyline_Trunk", (0.3, 0.24, 0.18)))
x = -60.0
while x < 60.0:
    w = random.uniform(9, 16)
    block(x + w / 2, random.uniform(-100, -92), w, random.uniform(8, 12), random.uniform(14, 40), (0, 1))
    x += w + random.uniform(2, 5)

bpy.ops.object.select_all(action="SELECT")
meshes = [o for o in bpy.data.objects if o.type == "MESH"]
bpy.context.view_layer.objects.active = meshes[0]
bpy.ops.object.join()
active().name = "skyline"
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE, "skyline.blend"))
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "skyline.glb"), export_format="GLB", use_selection=True, export_yup=True, export_apply=True)
print("SKYLINE_DONE")
