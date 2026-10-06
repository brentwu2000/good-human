"""ART-005 walk kit, modelled (Claude, at the owner's request 2026-10-06 while
Codex works on the dogs). Visual models for EnvironmentKit's pieces; the kit
keeps its collision and fade bodies and swaps only what is drawn.

Run headless:  blender --background --python tools/art/build_walk_kit.py

Game axes (x, y up, z) converted to Blender; each GLB is one mesh. Origins
match where EnvironmentKit attaches them:
  tree_trunk / tree_canopy  root on the ground (scaled by the kit)
  bush, lamp, bus_stop      on the ground at the node
  park_bench, bin           on the ground (the kit offsets them under its body)
  gate_pillar, gate_lintel  pillar on the ground; lintel in the gate's frame
  shop_a/b (9 x 6 x 6), block_a/b (8 x 5 x 10)  centred on the building box,
                            street front facing -z
A Taiwanese street: tiled facades, shop fronts with signboards and roller
shutters, iron window grilles, air-conditioner boxes, a park with real trees.
"""
import bpy, bmesh, math, os, random
from mathutils import Vector, noise

ROOT = r"C:\Users\b\Documents\good-human"
OUT = os.path.join(ROOT, "assets", "environment", "walk_kit")
SOURCE = r"C:\Users\b\Documents\good-human-3d-pipeline\blender\environment\walk_kit"
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


def box(name, centre, size, material, bevel=0.0, tilt_x=0.0):
    bpy.ops.mesh.primitive_cube_add(location=g2b(*centre))
    o = active()
    o.name = name
    o.scale = (size[0] / 2, size[2] / 2, size[1] / 2)
    o.rotation_euler = (-tilt_x, 0, 0)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = o.modifiers.new("bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    o.data.materials.append(material)
    return o


def upright(name, x, z, y0, y1, radius, material, verts=16, top=None):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=radius, radius2=radius if top is None else top, depth=y1 - y0, location=g2b(x, (y0 + y1) / 2, z))
    o = active()
    o.name = name
    o.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return o


def lump(name, centre, radius, squash, material, rough=0.3, seed=0, subdiv=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdiv, radius=radius, location=(0, 0, 0))
    o = active()
    o.name = name
    for v in o.data.vertices:
        v.co *= 1.0 + noise.noise(v.co * 2.5 + Vector((seed, seed * 1.7, seed * 2.3))) * rough
    o.scale = (squash[0], squash[2], squash[1])
    bpy.ops.object.transform_apply(scale=True)
    o.location = g2b(*centre)
    o.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return o


def branch(name, start, end, r0, r1, material):
    a = Vector(g2b(*start))
    b = Vector(g2b(*end))
    d = b - a
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=r0, radius2=r1, depth=d.length, location=(a + b) / 2)
    o = active()
    o.name = name
    o.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
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


# --- Park ---------------------------------------------------------------------------
def build_tree():
    reset()
    random.seed(31)
    bark = mat("Tree_Bark", (0.33, 0.25, 0.18), 0.9)
    # Trunk with a slight lean, three main limbs.
    branch("Tree_Trunk", (0, 0, 0), (0.08, 2.6, 0.02), 0.26, 0.15, bark)
    upright("Tree_Root_Flare", 0, 0, 0.0, 0.3, 0.36, bark, 10, 0.24)
    for ang, h, length in ((0.4, 2.2, 1.0), (2.5, 2.5, 0.9), (4.4, 2.35, 0.95)):
        end = (0.08 + math.cos(ang) * length, h + 0.9, 0.02 + math.sin(ang) * length)
        branch("Tree_Limb", (0.08, h, 0.02), end, 0.12, 0.05, bark)
    export("tree_trunk")
    reset()
    leaves = [mat("Tree_Leaf_Dark", (0.2, 0.36, 0.18), 0.75), mat("Tree_Leaf", (0.27, 0.45, 0.22), 0.75), mat("Tree_Leaf_Light", (0.36, 0.53, 0.27), 0.75)]
    random.seed(32)
    for i in range(16):
        a = random.uniform(0, math.tau)
        r = random.uniform(0.2, 1.25)
        y = 3.35 + random.uniform(-0.45, 0.85) * (1.2 - r * 0.4)
        lump("Tree_Foliage", (math.cos(a) * r, y, math.sin(a) * r), random.uniform(0.55, 0.85), (1.0, 0.8, 1.0), leaves[i % 3], 0.32, i)
    export("tree_canopy")


def build_bush():
    reset()
    random.seed(33)
    leaves = [mat("Hedge_Leaf_Dark", (0.19, 0.34, 0.17), 0.8), mat("Hedge_Leaf", (0.26, 0.43, 0.21), 0.8), mat("Hedge_Leaf_Light", (0.34, 0.5, 0.25), 0.8)]
    for i in range(11):
        x = random.uniform(-0.6, 0.6)
        z = random.uniform(-0.38, 0.38)
        lump("Bush_Clump", (x, 0.42 + random.uniform(0, 0.3), z), random.uniform(0.32, 0.46), (1.0, 0.85, 1.0), leaves[i % 3], 0.35, i)
    export("bush")


def build_bench():
    reset()
    wood = mat("ParkBench_Wood", (0.5, 0.34, 0.2), 0.7)
    iron = mat("ParkBench_Iron", (0.12, 0.13, 0.14), 0.5, 0.7)
    for i in range(4):
        box("ParkBench_SeatSlat", (0, 0.56, -0.24 + i * 0.16), (2.2, 0.045, 0.13), wood, 0.008)
    for i in range(3):
        box("ParkBench_BackSlat", (0, 0.76 + i * 0.16, 0.28 + i * 0.02), (2.2, 0.12, 0.04), wood, 0.008, 0.18)
    for x in (-0.82, 0.82):
        box("ParkBench_LegFront", (x, 0.27, -0.24), (0.06, 0.54, 0.06), iron, 0.006)
        box("ParkBench_LegBack", (x, 0.55, 0.27), (0.06, 1.1, 0.06), iron, 0.006, 0.1)
        box("ParkBench_Rail", (x, 0.52, 0.02), (0.06, 0.05, 0.55), iron, 0.006)
        box("ParkBench_Arm", (x, 0.76, -0.06), (0.07, 0.05, 0.46), iron, 0.008)
    export("park_bench")


def build_lamp():
    reset()
    pole = mat("Lamp_Pole", (0.17, 0.19, 0.2), 0.45, 0.7)
    glass = mat("Lamp_Lens", (0.98, 0.95, 0.84), 0.3, 0.0, 0.8)
    upright("Lamp_Base", 0, 0, 0.0, 0.35, 0.11, pole, 12, 0.07)
    upright("Lamp_Pole", 0, 0, 0.35, 2.9, 0.05, pole, 12, 0.04)
    branch("Lamp_Arm", (0, 2.75, 0), (0.48, 2.82, 0), 0.03, 0.025, pole)
    box("Lamp_Head", (0.5, 2.72, 0), (0.42, 0.12, 0.24), pole, 0.02)
    box("Lamp_Lens", (0.5, 2.655, 0), (0.36, 0.02, 0.18), glass)
    export("lamp")


def build_bin():
    reset()
    body = mat("Bin_Body_Teal", (0.17, 0.42, 0.4), 0.5, 0.3)
    lid = mat("Bin_Lid", (0.13, 0.15, 0.16), 0.5, 0.4)
    label = mat("Bin_Label", (0.92, 0.88, 0.76), 0.7)
    box("Bin_Body", (0, 0.42, 0), (0.58, 0.84, 0.52), body, 0.04)
    box("Bin_Lid", (0, 0.88, 0), (0.66, 0.08, 0.6), lid, 0.02)
    box("Bin_Slot", (0, 0.76, -0.27), (0.36, 0.08, 0.02), lid)
    box("Bin_Label", (0, 0.42, -0.265), (0.32, 0.14, 0.01), label)
    for x in (-0.22, 0.22):
        box("Bin_Foot", (x, 0.02, 0), (0.06, 0.04, 0.46), lid)
    export("bin")


def build_gate():
    reset()
    stone = mat("Gate_Stone", (0.7, 0.67, 0.6), 0.85)
    cap = mat("Gate_Cap", (0.9, 0.86, 0.76), 0.7)
    box("Gate_Pillar", (0, 1.3, 0), (0.52, 2.6, 0.52), stone, 0.02)
    for i in range(6):
        box("Gate_Pillar_Course", (0, 0.2 + i * 0.42, 0), (0.54, 0.02, 0.54), cap)
    box("Gate_Pillar_Cap", (0, 2.66, 0), (0.66, 0.12, 0.66), cap, 0.02)
    export("gate_pillar")
    reset()
    beam = mat("Gate_Beam_Teal", (0.16, 0.42, 0.4), 0.55, 0.3)
    board = mat("Gate_Board", (0.92, 0.88, 0.76), 0.7)
    trim = mat("Gate_Board_Trim", (0.78, 0.36, 0.28), 0.6)
    box("Gate_Beam", (0, 2.88, 0), (7.0, 0.3, 0.32), beam, 0.03)
    box("Gate_Board", (0, 2.9, -0.2), (2.9, 0.82, 0.12), board, 0.02)
    box("Gate_Board_Trim", (0, 2.9, -0.27), (2.6, 0.56, 0.02), trim)
    export("gate_lintel")


def build_bus_stop():
    reset()
    frame = mat("BusStop_Frame", (0.15, 0.17, 0.18), 0.45, 0.7)
    roof = mat("BusStop_Roof_Teal", (0.16, 0.42, 0.4), 0.5, 0.2)
    glass = mat("BusStop_Glass", (0.6, 0.72, 0.76), 0.1, 0.2)
    ad = mat("BusStop_Advert", (0.82, 0.42, 0.32), 0.6, 0.0, 0.3)
    seat = mat("BusStop_Seat", (0.62, 0.64, 0.66), 0.4, 0.8)
    for x in (-1.35, 1.35):
        box("BusStop_Post", (x, 1.2, 0.62), (0.08, 2.4, 0.08), frame)
        box("BusStop_PostFront", (x, 1.2, -0.3), (0.08, 2.4, 0.08), frame)
    box("BusStop_Roof", (0, 2.44, 0.15), (3.1, 0.1, 1.5), roof, 0.02)
    box("BusStop_Back", (0, 1.28, 0.62), (2.7, 1.72, 0.03), glass)
    box("BusStop_Rail", (0, 0.4, 0.62), (2.74, 0.06, 0.06), frame)
    box("BusStop_Advert", (-0.9, 1.5, 0.6), (0.62, 0.9, 0.04), ad)
    box("BusStop_Seat", (0.3, 0.48, 0.42), (1.6, 0.04, 0.3), seat, 0.01)
    for x in (-0.4, 1.0):
        box("BusStop_SeatLeg", (x, 0.24, 0.42), (0.05, 0.48, 0.05), frame)
    upright("BusStop_SignPole", 1.6, -0.5, 0.0, 2.6, 0.035, frame, 10)
    box("BusStop_Sign", (1.6, 2.35, -0.5), (0.5, 0.36, 0.04), roof, 0.01)
    export("bus_stop")


# --- Street buildings ---------------------------------------------------------------
def build_building(name, size, palette, seed):
    reset()
    random.seed(seed)
    sx, sy, sz = size
    tile = mat(name + "_Tile", palette["tile"], 0.75)
    trim = mat(name + "_Trim", palette["trim"], 0.6)
    glass = mat("Bldg_Glass", (0.32, 0.4, 0.45), 0.12, 0.3)
    grille = mat("Bldg_Grille", (0.25, 0.27, 0.28), 0.45, 0.7)
    shutter = mat("Bldg_Shutter", (0.6, 0.62, 0.62), 0.45, 0.7)
    sign = mat(name + "_Sign", palette["sign"], 0.5, 0.0, 0.25)
    sign_text = mat("Bldg_SignText", (0.96, 0.94, 0.86), 0.5)
    ac = mat("Bldg_AC", (0.88, 0.88, 0.85), 0.5)
    awning = mat(name + "_Awning", palette["awning"], 0.7)
    front = -sz / 2
    # The block, faced in small tiles; a parapet on top.
    box(name + "_Body", (0, 0, 0), (sx, sy, sz), tile)
    box(name + "_Parapet", (0, sy / 2 + 0.25, front + 0.15), (sx + 0.1, 0.5, 0.3), trim, 0.02)
    box(name + "_FloorBand", (0, -sy / 2 + 2.6, front - 0.04), (sx + 0.06, 0.18, 0.1), trim)
    # Ground floor: a shop front — glass and door on one side, a roller
    # shutter on the other — and its signboard and awning.
    shop_y = -sy / 2 + 1.2
    box(name + "_ShopGlass", (-sx * 0.18, shop_y, front - 0.02), (sx * 0.5, 2.0, 0.05), glass)
    box(name + "_ShopFrame", (-sx * 0.18, shop_y + 1.02, front - 0.04), (sx * 0.52, 0.06, 0.08), grille)
    box(name + "_Shutter", (sx * 0.28, shop_y - 0.05, front - 0.03), (sx * 0.34, 1.9, 0.06), shutter)
    for i in range(12):
        box(name + "_ShutterRib", (sx * 0.28, shop_y - 0.95 + i * 0.16, front - 0.065), (sx * 0.34, 0.015, 0.01), grille)
    box(name + "_Signboard", (0, -sy / 2 + 2.35, front - 0.3), (sx * 0.86, 0.42, 0.12), sign, 0.02)
    for i in range(4):
        box(name + "_SignGlyph", (-sx * 0.25 + i * sx * 0.16, -sy / 2 + 2.35, front - 0.37), (0.36, 0.24, 0.01), sign_text)
    box(name + "_Awning", (-sx * 0.18, -sy / 2 + 2.12, front - 0.45), (sx * 0.52, 0.06, 0.9), awning, 0.01, -0.18)
    # Upper floors: windows behind iron grilles, an AC box under some.
    floors = max(1, int((sy - 2.8) / 1.6) + 1)
    columns = max(2, int(sx / 2.2))
    for f in range(floors):
        y = -sy / 2 + 3.5 + f * 1.6
        if y + 0.6 > sy / 2:
            break
        for c in range(columns):
            x = -sx / 2 + (c + 0.5) * sx / columns
            box(name + "_Window", (x, y, front - 0.02), (1.1, 1.0, 0.04), glass)
            box(name + "_WindowFrame", (x, y - 0.54, front - 0.05), (1.2, 0.06, 0.1), trim)
            # The iron grille (鐵窗): a cage of bars stood off the wall.
            box(name + "_GrilleTop", (x, y + 0.56, front - 0.22), (1.26, 0.04, 0.36), grille)
            box(name + "_GrilleBottom", (x, y - 0.56, front - 0.22), (1.26, 0.04, 0.36), grille)
            for b in range(7):
                box(name + "_GrilleBar", (x - 0.6 + b * 0.2, y, front - 0.4), (0.018, 1.12, 0.018), grille)
            if random.random() < 0.55:
                box(name + "_AC", (x + random.uniform(-0.3, 0.3), y - 0.85, front - 0.2), (0.7, 0.42, 0.3), ac, 0.02)
    export(name)


build_tree()
build_bush()
build_bench()
build_lamp()
build_bin()
build_gate()
build_bus_stop()
build_building("shop_a", (9, 6, 6), {"tile": (0.8, 0.72, 0.62), "trim": (0.62, 0.55, 0.48), "sign": (0.72, 0.22, 0.18), "awning": (0.7, 0.3, 0.24)}, 41)
build_building("shop_b", (9, 6, 6), {"tile": (0.7, 0.72, 0.72), "trim": (0.5, 0.53, 0.55), "sign": (0.16, 0.38, 0.52), "awning": (0.24, 0.48, 0.42)}, 42)
build_building("block_a", (8, 5, 10), {"tile": (0.78, 0.66, 0.6), "trim": (0.58, 0.48, 0.42), "sign": (0.2, 0.42, 0.28), "awning": (0.78, 0.62, 0.26)}, 43)
build_building("block_b", (8, 5, 10), {"tile": (0.84, 0.8, 0.7), "trim": (0.6, 0.58, 0.52), "sign": (0.62, 0.42, 0.16), "awning": (0.5, 0.3, 0.42)}, 44)
print("WALK_KIT_DONE")
