"""D6-06 Pair Identity Home: the room the two of them live in (Claude, at the
owner's request 2026-10-06 while Codex works on the dogs).

Run headless:  blender --background --python tools/art/build_home_room.py

A small apartment living room, lived in: wood floor and a rug, a window with
curtains and daylight, a sofa with a throw pillow, a coffee table with a mug
and a book, a low bookcase, a photo on the wall (the remembered moment), the
dog's bed with its blanket and toy, the leash on its hook by the door, a
floor lamp and a plant. Built in the game's own coordinates around where
`home.gd` stands the human (-0.35, -0.5) and the dog (0.55, -0.1), seen from
(0.1, 1.15, 2.1). One mesh; plain PBR.
"""
import bpy, math, os, random

ROOT = r"C:\Users\b\Documents\good-human"
OUT = os.path.join(ROOT, "assets", "environment", "home")
SOURCE = r"C:\Users\b\Documents\good-human-3d-pipeline\blender\environment\home"
os.makedirs(OUT, exist_ok=True)
os.makedirs(SOURCE, exist_ok=True)

_mats = {}


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


def box(name, centre, size, material, bevel=0.0, yaw=0.0):
    bpy.ops.mesh.primitive_cube_add(location=g2b(*centre))
    o = active()
    o.name = name
    o.scale = (size[0] / 2, size[2] / 2, size[1] / 2)
    o.rotation_euler = (0, 0, yaw)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = o.modifiers.new("bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 3
    o.data.materials.append(material)
    return o


def upright(name, x, z, y0, y1, radius, material, verts=20, top=None):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=radius, radius2=radius if top is None else top, depth=y1 - y0, location=g2b(x, (y0 + y1) / 2, z))
    o = active()
    o.name = name
    o.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return o


bpy.ops.wm.read_factory_settings(use_empty=True)
random.seed(21)
plank = [mat("Home_Floor_Oak", (0.55, 0.38, 0.24), 0.55), mat("Home_Floor_Oak_Dark", (0.48, 0.32, 0.2), 0.55), mat("Home_Floor_Oak_Light", (0.6, 0.43, 0.28), 0.55)]
wall = mat("Home_Wall_Warm", (0.9, 0.84, 0.74), 0.9)
skirting = mat("Home_Skirting", (0.95, 0.93, 0.88), 0.5)
frame_white = mat("Home_Window_Frame", (0.93, 0.92, 0.88), 0.45)
sky = mat("Home_Window_Daylight", (0.86, 0.92, 0.98), 0.3, 0.0, 1.6)
curtain = mat("Home_Curtain_Linen", (0.84, 0.74, 0.58), 0.9)
sofa = mat("Home_Sofa_Fabric", (0.33, 0.47, 0.46), 0.9)
sofa_dark = mat("Home_Sofa_Fabric_Shade", (0.27, 0.39, 0.38), 0.9)
pillow = mat("Home_Pillow_Mustard", (0.82, 0.62, 0.25), 0.9)
wood = mat("Home_Furniture_Walnut", (0.38, 0.25, 0.16), 0.5)
rug = mat("Home_Rug_Cream", (0.86, 0.8, 0.68), 0.95)
rug_border = mat("Home_Rug_Border", (0.62, 0.36, 0.28), 0.95)
mug = mat("Home_Mug", (0.92, 0.9, 0.86), 0.4)
book_mats = [mat("Home_Book_Red", (0.6, 0.2, 0.18), 0.7), mat("Home_Book_Blue", (0.2, 0.3, 0.5), 0.7), mat("Home_Book_Green", (0.25, 0.42, 0.3), 0.7), mat("Home_Book_Cream", (0.88, 0.84, 0.72), 0.7)]
photo_frame = mat("Home_Photo_Frame", (0.2, 0.16, 0.12), 0.5)
photo = mat("Home_Photo_Print", (0.7, 0.78, 0.82), 0.4)
dog_bed = mat("Home_DogBed_Canvas", (0.62, 0.45, 0.32), 0.9)
dog_bed_cushion = mat("Home_DogBed_Cushion", (0.9, 0.84, 0.72), 0.95)
blanket = mat("Home_DogBlanket", (0.42, 0.55, 0.7), 0.95)
toy = mat("Home_DogToy", (0.9, 0.35, 0.3), 0.6)
leash = mat("Home_Leash_Teal", (0.18, 0.6, 0.58), 0.6)
hook = mat("Home_Hook_Brass", (0.75, 0.6, 0.3), 0.3, 0.9)
lamp_metal = mat("Home_Lamp_Metal", (0.15, 0.15, 0.16), 0.4, 0.7)
lamp_shade = mat("Home_Lamp_Shade", (0.95, 0.9, 0.78), 0.8, 0.0, 0.4)
pot = mat("Home_Pot_Terracotta", (0.62, 0.36, 0.24), 0.8)
leaf = mat("Home_Plant_Leaf", (0.22, 0.42, 0.22), 0.7)

# Floor: oak planks running across.
for i in range(20):
    z = 1.5 - i * 0.2
    x_off = random.uniform(-0.6, 0.6)
    for k in range(3):
        box("Home_Plank", (-3.0 + x_off + k * 2.2 + 1.1, -0.025, z), (2.18, 0.05, 0.195), plank[(i + k) % 3])
# Back wall, skirting.
box("Home_BackWall", (0, 1.5, -1.8), (7, 3.0, 0.1), wall)
box("Home_Skirting", (0, 0.05, -1.745), (7, 0.1, 0.015), skirting)
# A window on the right, daylight behind it, curtains either side.
box("Home_Window_Light", (1.45, 1.55, -1.79), (1.2, 1.1, 0.02), sky)
for x in (0.85, 2.05):
    box("Home_Window_Jamb", (x, 1.55, -1.76), (0.06, 1.2, 0.06), frame_white, 0.006)
box("Home_Window_Head", (1.45, 2.13, -1.76), (1.26, 0.06, 0.06), frame_white, 0.006)
box("Home_Window_Sill", (1.45, 0.97, -1.72), (1.4, 0.04, 0.16), frame_white, 0.006)
box("Home_Window_Mullion", (1.45, 1.55, -1.77), (0.04, 1.1, 0.04), frame_white)
box("Home_CurtainRod", (1.45, 2.3, -1.68), (1.9, 0.025, 0.025), lamp_metal)
for x, w in ((0.62, 0.42), (2.28, 0.42)):
    for f in range(4):
        box("Home_Curtain_Fold", (x - w / 2 + (f + 0.5) * w / 4, 1.32, -1.66 + (0.025 if f % 2 else 0.0)), (w / 4 + 0.01, 1.95, 0.03), curtain, 0.01)
# The sofa, back left.
box("Home_Sofa_Base", (-1.6, 0.22, -1.3), (1.7, 0.3, 0.8), sofa_dark, 0.04)
for x in (-2.0, -1.2):
    box("Home_Sofa_Seat", (x, 0.43, -1.25), (0.78, 0.14, 0.7), sofa, 0.05)
    box("Home_Sofa_Back", (x, 0.72, -1.6), (0.78, 0.5, 0.18), sofa, 0.06)
for x in (-2.5, -0.7):
    box("Home_Sofa_Arm", (x, 0.5, -1.3), (0.16, 0.42, 0.8), sofa_dark, 0.05)
box("Home_Sofa_Pillow", (-2.2, 0.66, -1.42), (0.38, 0.32, 0.12), pillow, 0.06, 0.25)
for x in (-2.38, -0.82):
    upright("Home_Sofa_Foot", x, -0.98, 0.0, 0.07, 0.025, wood, 10)
# A rug and the coffee table on it.
box("Home_Rug_Border", (0.15, 0.003, -0.35), (2.3, 0.006, 1.5), rug_border)
box("Home_Rug", (0.15, 0.005, -0.35), (2.1, 0.006, 1.3), rug)
box("Home_Table_Top", (-1.45, 0.38, -0.45), (0.9, 0.04, 0.5), wood, 0.01)
for x in (-1.82, -1.08):
    for z in (-0.65, -0.25):
        upright("Home_Table_Leg", x, z, 0.0, 0.36, 0.02, wood, 10)
upright("Home_Mug", -1.65, -0.4, 0.4, 0.5, 0.04, mug, 18)
box("Home_Book_OnTable", (-1.25, 0.415, -0.5), (0.22, 0.03, 0.16), book_mats[1], 0.004, 0.3)
# A low bookcase against the wall, the photo above it.
box("Home_Bookcase", (0.05, 0.42, -1.6), (0.9, 0.84, 0.32), wood, 0.01)
for shelf, y in enumerate((0.12, 0.5)):
    x = -0.35
    for b in range(9):
        w = random.uniform(0.035, 0.06)
        h = random.uniform(0.22, 0.3)
        box("Home_Book", (x + w / 2, y + h / 2, -1.45), (w, h, 0.2), book_mats[(b + shelf) % 4])
        x += w + 0.005
box("Home_PhotoFrame", (0.05, 1.55, -1.735), (0.5, 0.38, 0.03), photo_frame, 0.004)
box("Home_Photo", (0.05, 1.55, -1.718), (0.42, 0.3, 0.005), photo)
# The dog's bed by the window: a padded ring, its cushion, its blanket, a toy.
bpy.ops.mesh.primitive_torus_add(major_radius=0.36, minor_radius=0.1, major_segments=32, minor_segments=12, location=g2b(1.15, 0.1, -1.0))
active().name = "Home_DogBed_Ring"
active().scale = (1.0, 0.8, 0.9)
active().data.materials.append(dog_bed)
bpy.ops.object.shade_smooth()
upright("Home_DogBed_Cushion", 1.15, -1.0, 0.0, 0.1, 0.3, dog_bed_cushion, 32)
box("Home_DogBlanket", (1.05, 0.12, -1.05), (0.42, 0.03, 0.34), blanket, 0.02, 0.4)
bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.05, location=g2b(1.62, 0.05, -0.62))
active().name = "Home_DogToy"
active().scale = (1.6, 0.7, 0.7)
active().data.materials.append(toy)
# The leash on its hook by the door.
box("Home_Leash_Hook", (-0.62, 1.45, -1.74), (0.04, 0.06, 0.05), hook, 0.004)
for i in range(10):
    t = i / 9
    box("Home_Leash", (-0.62 + math.sin(t * math.pi) * 0.09, 1.42 - t * 0.6, -1.725), (0.022, 0.08, 0.008), leash)
# A floor lamp and a plant.
upright("Home_Lamp_Base", -2.85, -1.45, 0.0, 0.03, 0.15, lamp_metal, 20)
upright("Home_Lamp_Pole", -2.85, -1.45, 0.03, 1.55, 0.015, lamp_metal, 10)
upright("Home_Lamp_Shade", -2.85, -1.45, 1.5, 1.78, 0.2, lamp_shade, 24, 0.13)
upright("Home_Pot", 2.6, -1.45, 0.0, 0.34, 0.17, pot, 20, 0.2)
for i in range(10):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=random.uniform(0.12, 0.2), location=g2b(2.6 + random.uniform(-0.15, 0.15), 0.5 + random.uniform(0.0, 0.55), -1.45 + random.uniform(-0.15, 0.15)))
    active().name = "Home_Plant"
    active().scale = (0.8, 0.8, 1.3)
    active().data.materials.append(leaf)

# One mesh, then export.
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
active().name = "home_room"
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE, "home_room.blend"))
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "home_room.glb"), export_format="GLB", use_selection=True, export_yup=True, export_apply=True)
print("HOME_ROOM_DONE")
