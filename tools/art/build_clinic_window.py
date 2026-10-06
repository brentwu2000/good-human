"""D6-01 / D6-03: the small animal hospital's front window, inside and out
(Claude, at the owner's request 2026-10-06 while Codex works on the dogs).

Run headless:  blender --background --python tools/art/build_clinic_window.py

Built in the game's own coordinates (Godot metres: x across the window, y up,
z from the street (−) into the clinic (+)), converted here to Blender's Z-up
so the exported glTF lands exactly on `ClinicWindow`'s layout: glass at
z = −1.3, the pen inside it, the pavement and the road outside. Five pieces,
each its own GLB, so scenes can leave one out (the adoption hides the pen's
back rail): clinic_inside, clinic_pen, clinic_pen_back, clinic_front,
clinic_street. Effects stay in code (the glass, its shine, the painted name,
the paper sign, nose prints).
Grounded, lived-in neighbourhood clinic (ART_DIRECTION v0.2); plain PBR.
"""
import bpy, math, os, random

ROOT = r"C:\Users\b\Documents\good-human"
OUT = os.path.join(ROOT, "assets", "environment", "clinic")
SOURCE = r"C:\Users\b\Documents\good-human-3d-pipeline\blender\environment\clinic"
os.makedirs(OUT, exist_ok=True)
os.makedirs(SOURCE, exist_ok=True)

WINDOW_Z = -1.3
SILL = 0.12
PEN_MAX_Z = 0.25

_materials = {}


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _materials.clear()


def mat(name, color, roughness=0.7, metallic=0.0, emission=0.0):
    if name in _materials:
        return _materials[name]
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
    _materials[name] = m
    return m


def active():
    return bpy.context.view_layer.objects.active


def g2b(x, y, z):
    """Game (x, y up, z) to Blender (x, y, z up)."""
    return (x, -z, y)


def box(name, centre, size, material, bevel=0.0):
    """`centre` and `size` in game axes (x, y up, z)."""
    bpy.ops.mesh.primitive_cube_add(location=g2b(*centre))
    o = active()
    o.name = name
    o.scale = (size[0] / 2, size[2] / 2, size[1] / 2)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = o.modifiers.new("bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    o.data.materials.append(material)
    return o


def post(name, x, z, y0, y1, radius, material, verts=12):
    """An upright cylinder at game (x, z) from height y0 to y1."""
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=y1 - y0, location=g2b(x, (y0 + y1) / 2, z))
    o = active()
    o.name = name
    o.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return o


def rail(name, x0, x1, y, z, radius, material):
    """A horizontal bar across x at height y, depth z."""
    bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=radius, depth=x1 - x0, location=g2b((x0 + x1) / 2, y, z), rotation=(0, math.pi / 2, 0))
    o = active()
    o.name = name
    o.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return o


def rail_z(name, z0, z1, y, x, radius, material):
    """A horizontal bar along z at height y, across position x."""
    bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=radius, depth=z1 - z0, location=g2b(x, y, (z0 + z1) / 2), rotation=(math.pi / 2, 0, 0))
    o = active()
    o.name = name
    o.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return o


def export(name):
    # One mesh per piece (materials kept): far fewer draw calls on mobile.
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
    for o in bpy.data.objects:
        o.select_set(True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE, name + ".blend"))
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, name + ".glb"), export_format="GLB", use_selection=True, export_yup=True, export_apply=True)
    print("EXPORTED", name, len(bpy.data.objects))


# --- Inside -------------------------------------------------------------------------
def build_inside():
    reset()
    random.seed(11)
    tile = mat("Clinic_Floor_Vinyl", (0.6, 0.63, 0.61), 0.55)
    grout = mat("Clinic_Floor_Seam", (0.6, 0.63, 0.62), 0.7)
    wall = mat("Clinic_Wall_White", (0.93, 0.94, 0.92), 0.85)
    mint = mat("Clinic_Wainscot_Mint", (0.62, 0.8, 0.74), 0.6)
    trim = mat("Clinic_Trim", (0.86, 0.88, 0.86), 0.5)
    ceiling = mat("Clinic_Ceiling", (0.95, 0.95, 0.94), 0.9)
    tube = mat("Clinic_Light_Panel", (1.0, 0.99, 0.95), 0.4, 0.0, 2.5)
    laminate = mat("Clinic_Counter_Laminate", (0.72, 0.6, 0.45), 0.5)
    top = mat("Clinic_Counter_Top", (0.92, 0.91, 0.88), 0.35)
    screen = mat("Clinic_Monitor", (0.08, 0.08, 0.09), 0.3)
    bell_mat = mat("Clinic_Bell", (0.8, 0.72, 0.4), 0.25, 0.9)
    cork = mat("Clinic_Corkboard", (0.72, 0.56, 0.38), 0.9)
    paper = mat("Clinic_Paper", (0.97, 0.96, 0.92), 0.9)
    pink = mat("Clinic_Paper_Pink", (0.95, 0.78, 0.78), 0.9)
    blue_paper = mat("Clinic_Paper_Blue", (0.72, 0.84, 0.95), 0.9)
    seat = mat("Clinic_Seat_Blue", (0.22, 0.42, 0.6), 0.45)
    steel = mat("Clinic_Steel", (0.62, 0.64, 0.66), 0.35, 0.8)
    pot = mat("Clinic_Pot", (0.55, 0.35, 0.25), 0.8)
    leaf = mat("Clinic_Leaf", (0.22, 0.45, 0.24), 0.7)
    shelf_mat = mat("Clinic_Shelf", (0.82, 0.82, 0.8), 0.6)
    bag_colours = [mat("Clinic_FoodBag_Red", (0.72, 0.2, 0.18), 0.6), mat("Clinic_FoodBag_Green", (0.25, 0.5, 0.3), 0.6), mat("Clinic_FoodBag_Yellow", (0.88, 0.72, 0.25), 0.6)]

    # Floor: big vinyl tiles with seams.
    box("Clinic_Floor", (0, -0.02, 0.4), (8, 0.04, 3.4), tile)
    for i in range(-5, 6):
        box("Clinic_Floor_SeamX", (i * 0.6, 0.0005, 0.4), (0.008, 0.002, 3.4), grout)
    for i in range(0, 6):
        box("Clinic_Floor_SeamZ", (0, 0.0005, -1.2 + i * 0.6), (8, 0.002, 0.008), grout)
    # Walls: white above a mint wainscot, a chair rail, a skirting.
    box("Clinic_BackWall", (0, 1.5, 2.1), (8, 3.0, 0.1), wall)
    box("Clinic_Wainscot", (0, 0.5, 2.045), (8, 1.0, 0.012), mint)
    box("Clinic_ChairRail", (0, 1.01, 2.035), (8, 0.04, 0.03), trim)
    box("Clinic_Skirting", (0, 0.05, 2.035), (8, 0.1, 0.02), trim)
    for x in (-4.0, 4.0):
        box("Clinic_SideWall", (x, 1.5, 0.4), (0.1, 3.0, 3.4), wall)
        box("Clinic_SideWainscot", (x - math.copysign(0.055, x), 0.5, 0.4), (0.012, 1.0, 3.4), mint)
    box("Clinic_Ceiling", (0, 2.95, 0.4), (8, 0.1, 3.4), ceiling)
    for x in (-1.6, 1.6):
        box("Clinic_LightPanel", (x, 2.895, 0.6), (1.2, 0.02, 0.3), tube)
    # The front counter: laminate front, white top, a monitor, the bell,
    # a stack of leaflets.
    box("Clinic_Counter_Front", (-2.5, 0.52, 1.12), (1.8, 1.04, 0.04), laminate, 0.006)
    box("Clinic_Counter_Body", (-2.5, 0.5, 1.4), (1.76, 1.0, 0.56), wall)
    box("Clinic_Counter_Top", (-2.5, 1.06, 1.38), (1.9, 0.04, 0.66), top, 0.008)
    box("Clinic_Monitor_Screen", (-2.85, 1.3, 1.5), (0.42, 0.28, 0.03), screen, 0.004)
    box("Clinic_Monitor_Stand", (-2.85, 1.12, 1.52), (0.08, 0.1, 0.06), screen)
    post("Clinic_Bell_Base", -2.1, 1.18, 1.08, 1.1, 0.04, screen, 16)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=0.035, location=g2b(-2.1, 1.11, 1.18))
    active().name = "Clinic_Bell_Dome"
    active().scale = (1, 1, 0.7)
    active().data.materials.append(bell_mat)
    for i in range(5):
        box("Clinic_Leaflet", (-2.4 + random.uniform(-0.02, 0.02), 1.085 + i * 0.004, 1.2), (0.15, 0.003, 0.21), [paper, pink, blue_paper][i % 3])
    # Shelves of food bags on the back wall behind the counter.
    for level, y in enumerate((0.55, 1.15, 1.75)):
        box("Clinic_Shelf", (-2.6, y, 1.9), (1.6, 0.03, 0.32), shelf_mat)
        for i in range(5):
            h = random.uniform(0.28, 0.4)
            box("Clinic_FoodBag", (-3.25 + i * 0.32, y + h / 2 + 0.015, 1.9), (0.24, h, 0.12), bag_colours[(i + level) % 3], 0.02)
    # The notice board with pinned notices.
    box("Clinic_NoticeBoard", (0.4, 1.7, 2.04), (0.9, 0.7, 0.025), cork, 0.006)
    for i in range(6):
        w = random.uniform(0.14, 0.22)
        h = random.uniform(0.16, 0.24)
        box("Clinic_Notice", (0.08 + (i % 3) * 0.3 + random.uniform(-0.03, 0.03), 1.86 - (i // 3) * 0.3 + random.uniform(-0.02, 0.02), 2.025), (w, h, 0.004), [paper, pink, blue_paper, paper][i % 4])
    # Waiting seats: a steel bench of three moulded seats.
    rail("Clinic_Bench_Beam", 1.55, 2.95, 0.38, 1.75, 0.025, steel)
    for x in (1.65, 2.85):
        post("Clinic_Bench_Leg", x, 1.75, 0.0, 0.38, 0.02, steel)
    for i in range(3):
        x = 1.8 + i * 0.47
        box("Clinic_Seat", (x, 0.43, 1.72), (0.42, 0.04, 0.4), seat, 0.02)
        box("Clinic_SeatBack", (x, 0.68, 1.92), (0.42, 0.46, 0.04), seat, 0.02)
    # A pot plant by the door.
    post("Clinic_Pot", 3.5, 0.6, 0.0, 0.32, 0.16, pot, 16)
    for i in range(9):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=random.uniform(0.12, 0.18), location=g2b(3.5 + random.uniform(-0.12, 0.12), 0.45 + random.uniform(0.0, 0.45), 0.6 + random.uniform(-0.12, 0.12)))
        active().name = "Clinic_PlantLeaves"
        active().scale = (1, 1, 1.3)
        active().data.materials.append(leaf)
    export("clinic_inside")


# --- The pen ------------------------------------------------------------------------
def build_pen(back_only=False):
    reset()
    random.seed(13)
    wire = mat("Pen_Wire_White", (0.93, 0.93, 0.9), 0.4, 0.3)
    blanket = mat("Pen_Blanket", (0.36, 0.5, 0.64), 0.95)
    blanket_edge = mat("Pen_Blanket_Edge", (0.27, 0.38, 0.5), 0.95)
    steel = mat("Pen_Bowl_Steel", (0.7, 0.72, 0.75), 0.25, 0.9)
    ball = mat("Pen_Ball", (0.9, 0.55, 0.3), 0.6)
    pad = mat("Pen_PeePad", (0.82, 0.86, 0.9), 0.9)
    h = 0.45
    def panel(x0, x1, z):
        rail("Pen_TopRail", x0, x1, h, z, 0.012, wire)
        rail("Pen_BottomRail", x0, x1, 0.03, z, 0.01, wire)
        n = int((x1 - x0) / 0.09)
        for i in range(n + 1):
            post("Pen_Bar", x0 + (x1 - x0) * i / n, z, 0.03, h, 0.005, wire, 6)
    def panel_z(z0, z1, x):
        rail_z("Pen_TopRail", z0, z1, h, x, 0.012, wire)
        rail_z("Pen_BottomRail", z0, z1, 0.03, x, 0.01, wire)
        n = int((z1 - z0) / 0.09)
        for i in range(n + 1):
            post("Pen_Bar", x, z0 + (z1 - z0) * i / n, 0.03, h, 0.005, wire, 6)
    back = PEN_MAX_Z + 0.08
    if back_only:
        panel(-1.35, 1.35, back)
        for x in (-1.35, -0.45, 0.45, 1.35):
            post("Pen_Post", x, back, 0.0, h + 0.02, 0.016, wire)
        export("clinic_pen_back")
        return
    # Two sides, from the glass to the back.
    for x in (-1.35, 1.35):
        panel_z(WINDOW_Z + 0.08, back, x)
        for z in (WINDOW_Z + 0.08, -0.6, back):
            post("Pen_Post", x, z, 0.0, h + 0.02, 0.016, wire)
    # A fleece blanket, a pee pad, a bowl and a chewed ball.
    box("Pen_Blanket", (0, 0.012, -0.5), (2.5, 0.02, 1.45), blanket, 0.01)
    box("Pen_Blanket_Hem", (0, 0.013, -0.5), (2.56, 0.018, 1.51), blanket_edge, 0.01)
    box("Pen_PeePad", (1.0, 0.026, 0.0), (0.45, 0.004, 0.45), pad)
    post("Pen_Bowl", 1.0, -0.25, 0.022, 0.07, 0.08, steel, 24)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=10, radius=0.05, location=g2b(-0.9, 0.07, 0.1))
    active().name = "Pen_Ball"
    active().data.materials.append(ball)
    export("clinic_pen")


# --- The shop front -------------------------------------------------------------------
def build_front():
    reset()
    render = mat("Front_Render_Cream", (0.88, 0.87, 0.82), 0.85)
    tile = mat("Front_Sill_Tile", (0.62, 0.6, 0.58), 0.6)
    frame = mat("Front_Aluminium", (0.32, 0.34, 0.36), 0.4, 0.7)
    fascia = mat("Front_Fascia_Teal", (0.18, 0.42, 0.4), 0.55)
    handle = mat("Front_Door_Handle", (0.75, 0.76, 0.78), 0.3, 0.9)
    mat_door = mat("Front_Doormat", (0.2, 0.2, 0.22), 0.95)
    # A low tiled sill under the glass, rendered wall above.
    box("Front_Sill", (0, SILL / 2, WINDOW_Z), (8, SILL, 0.14), tile, 0.008)
    box("Front_Sill_Cap", (0, SILL + 0.012, WINDOW_Z - 0.02), (8, 0.024, 0.2), tile, 0.006)
    box("Front_Header", (0, 2.65, WINDOW_Z), (8, 0.5, 0.14), render)
    # The sign board over the window, where the name sits.
    box("Front_Fascia", (0, 2.62, WINDOW_Z - 0.09), (5.6, 0.42, 0.06), fascia, 0.01)
    # Aluminium frames: mullions and transoms.
    for x in (-3.0, -0.95, 0.95, 2.75, 3.85):
        box("Front_Mullion", (x, 1.2, WINDOW_Z), (0.07, 2.4, 0.1), frame, 0.004)
    box("Front_Head", (0, 2.4, WINDOW_Z), (8, 0.06, 0.1), frame, 0.004)
    box("Front_Bottom", (0, SILL + 0.02, WINDOW_Z), (8, 0.04, 0.1), frame, 0.004)
    # The door (glass in a frame) between 2.75 and 3.85, with its handle.
    box("Front_Door_Rail", (3.3, 2.05, WINDOW_Z - 0.02), (1.1, 0.05, 0.05), frame)
    box("Front_Door_Kick", (3.3, 0.12, WINDOW_Z - 0.02), (1.1, 0.24, 0.05), frame)
    post("Front_Door_Handle", 2.9, WINDOW_Z - 0.07, 0.85, 1.25, 0.012, handle)
    box("Front_Doormat", (3.3, 0.005, WINDOW_Z - 0.45), (1.0, 0.01, 0.6), mat_door, 0.005)
    export("clinic_front")


# --- The street ---------------------------------------------------------------------
def build_street():
    reset()
    random.seed(17)
    paver = mat("Street_Paver", (0.7, 0.67, 0.62), 0.85)
    paver_dark = mat("Street_Paver_Dark", (0.62, 0.59, 0.55), 0.85)
    kerb = mat("Street_Kerb", (0.6, 0.6, 0.58), 0.8)
    asphalt = mat("Street_Asphalt", (0.27, 0.28, 0.3), 0.9)
    paint = mat("Street_Paint", (0.9, 0.88, 0.8), 0.7)
    yellow = mat("Street_Paint_Yellow", (0.85, 0.68, 0.2), 0.7)
    bark = mat("Street_Tree_Bark", (0.36, 0.28, 0.2), 0.9)
    canopy = mat("Street_Tree_Leaves", (0.27, 0.46, 0.26), 0.8)
    grate = mat("Street_Tree_Grate", (0.2, 0.2, 0.21), 0.5, 0.7)
    pole = mat("Street_Pole", (0.3, 0.32, 0.33), 0.5, 0.6)
    lamp = mat("Street_Lamp", (0.95, 0.92, 0.82), 0.4, 0.0, 0.6)
    scooter_body = mat("Street_Scooter_Body", (0.82, 0.83, 0.8), 0.4)
    tyre = mat("Street_Tyre", (0.08, 0.08, 0.09), 0.9)
    seat = mat("Street_Scooter_Seat", (0.12, 0.1, 0.1), 0.6)
    facades = [mat("Street_Facade_Tan", (0.82, 0.7, 0.58), 0.85), mat("Street_Facade_Grey", (0.68, 0.72, 0.74), 0.85), mat("Street_Facade_Cream", (0.86, 0.82, 0.68), 0.85), mat("Street_Facade_Mauve", (0.74, 0.68, 0.74), 0.85)]
    glass = mat("Street_Shop_Glass", (0.3, 0.38, 0.42), 0.15, 0.3)
    awnings = [mat("Street_Awning_Red", (0.72, 0.28, 0.24), 0.7), mat("Street_Awning_Green", (0.26, 0.5, 0.44), 0.7)]
    shutter = mat("Street_Shutter", (0.55, 0.57, 0.58), 0.5, 0.6)
    # Pavement in square pavers, a granite kerb, the road and its lines.
    box("Street_Pavement", (0, -0.04, -2.65), (20, 0.08, 2.6), paver)
    for i in range(-33, 34):
        for j in range(4):
            if (i + j) % 3 == 0:
                box("Street_Paver_Variant", (i * 0.3, 0.001, -1.55 - j * 0.6), (0.29, 0.002, 0.58), paver_dark)
    box("Street_Kerb", (0, 0.0, -4.0), (20, 0.14, 0.2), kerb, 0.01)
    box("Street_Road", (0, -0.06, -7.0), (20, 0.04, 6), asphalt)
    box("Street_EdgeLine", (0, -0.038, -4.3), (20, 0.002, 0.1), yellow)
    for x in range(-9, 10, 3):
        box("Street_CentreDash", (x, -0.038, -7.0), (1.2, 0.002, 0.12), paint)
    # Across the road: a row of small shops, roller shutters, awnings, signs.
    for i in range(6):
        x = -10.0 + i * 4.0
        f = facades[i % len(facades)]
        box("Street_Facade", (x, 2.25, -11.0), (3.8, 4.5, 1.0), f)
        box("Street_ShopWindow", (x - 0.4, 1.2, -10.48), (2.2, 1.6, 0.05), glass)
        box("Street_ShopDoor", (x + 1.15, 1.05, -10.48), (0.8, 2.1, 0.05), glass)
        if i % 3 == 2:
            box("Street_Shutter", (x - 0.4, 1.2, -10.46), (2.2, 1.6, 0.06), shutter)
        box("Street_Awning", (x, 2.3, -10.1), (3.0, 0.08, 0.9), awnings[i % 2], 0.02)
        box("Street_Awning_Valance", (x, 2.18, -9.66), (3.0, 0.2, 0.03), awnings[i % 2])
        box("Street_ShopSign", (x, 3.1, -10.47), (2.6, 0.5, 0.06), facades[(i + 2) % len(facades)], 0.01)
        box("Street_UpperWindow", (x - 0.8, 3.9, -10.48), (0.9, 0.8, 0.04), glass)
        box("Street_UpperWindow", (x + 0.8, 3.9, -10.48), (0.9, 0.8, 0.04), glass)
    # A street tree in a grate on this side.
    post("Street_TreeTrunk", -4.5, -3.7, 0.0, 2.6, 0.11, bark, 10)
    box("Street_TreeGrate", (-4.5, 0.002, -3.7), (0.9, 0.004, 0.9), grate)
    for k in range(7):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=random.uniform(0.7, 1.0), location=g2b(-4.5 + random.uniform(-0.7, 0.7), 2.9 + random.uniform(-0.2, 0.6), -3.7 + random.uniform(-0.7, 0.7)))
        active().name = "Street_TreeCanopy"
        active().data.materials.append(canopy)
    # A lamp post at the kerb.
    post("Street_LampPost", 2.2, -3.85, 0.0, 4.2, 0.05, pole, 10)
    box("Street_LampArm", (2.2, 4.15, -4.25), (0.08, 0.06, 0.8), pole)
    box("Street_LampHead", (2.2, 4.08, -4.6), (0.22, 0.1, 0.42), lamp, 0.02)
    # A parked scooter on the pavement edge.
    sx, sz = 5.5, -3.55
    for dz in (-0.55, 0.55):
        bpy.ops.mesh.primitive_torus_add(major_radius=0.19, minor_radius=0.06, major_segments=24, minor_segments=8, location=g2b(sx, 0.25, sz + dz), rotation=(0, math.pi / 2, 0))
        active().name = "Street_Scooter_Tyre"
        active().data.materials.append(tyre)
    box("Street_Scooter_Floor", (sx, 0.36, sz), (0.32, 0.08, 0.7), scooter_body, 0.03)
    box("Street_Scooter_Rear", (sx, 0.55, sz + 0.4), (0.4, 0.38, 0.6), scooter_body, 0.08)
    box("Street_Scooter_Seat", (sx, 0.78, sz + 0.35), (0.3, 0.08, 0.6), seat, 0.03)
    box("Street_Scooter_Front", (sx, 0.65, sz - 0.5), (0.32, 0.6, 0.12), scooter_body, 0.04)
    rail_z("Street_Scooter_Bars", sz - 0.56, sz - 0.54, 1.02, sx, 0.02, pole)
    rail("Street_Scooter_Handlebar", sx - 0.3, sx + 0.3, 1.04, sz - 0.55, 0.015, pole)
    export("clinic_street")


build_inside()
build_pen()
build_pen(back_only=True)
build_front()
build_street()
print("CLINIC_DONE")
