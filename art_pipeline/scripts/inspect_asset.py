"""Texturing v5, stage A: inspect a character asset without modifying it.

  blender -b --factory-startup --python art_pipeline/scripts/inspect_asset.py -- \
      --input art_pipeline/assets/source/grandma.glb --output art_pipeline/reports/grandma/inspection.json

Reads a .glb/.gltf (imported) or a .blend (opened read-only; never saved).
Reports: Blender version and devices, the command line; every object, mesh,
face and triangle counts, material slots, vertex groups, UV layers, image nodes
and whether they are packed; geometry problems (non-manifold edges, faces whose
normal disagrees with their neighbours, duplicate faces, degenerate triangles,
negative scale); UV problems (missing layer, zero-area faces, overlapping UV
area share, texel-density spread, island count). Renders front/back/left/right/
three-quarter with neutral lighting, Standard view transform and fixed exposure
into the report folder. Ends with a suggested repair path.
Nothing is fixed here, on purpose: the stages after this one decide.
"""
import argparse
import json
import math
import os
import platform
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Vector


def args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    p.add_argument("--input", required=True)
    p.add_argument("--output", required=True)
    p.add_argument("--size", type=int, default=640)
    return p.parse_args(argv)


def load(path):
    if path.lower().endswith(".blend"):
        bpy.ops.wm.open_mainfile(filepath=path)
    else:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=path)


def devices():
    out = {"cpu": platform.processor() or platform.machine(), "gpu": []}
    try:
        prefs = bpy.context.preferences.addons["cycles"].preferences
        for t in ("OPTIX", "CUDA", "HIP", "ONEAPI", "METAL"):
            try:
                prefs.compute_device_type = t
                prefs.get_devices()
                out["gpu"] += [f"{t}: {d.name}" for d in prefs.devices if d.type == t and f"{t}: {d.name}" not in out["gpu"]]
            except Exception:
                pass
    except Exception as e:
        out["gpu_error"] = str(e)
    return out


def is_character_mesh(o):
    """The glTF importer adds bone-shape helpers (an Icosphere) with no skin: not part of the character."""
    has_arm = any(m.type == "ARMATURE" for m in o.modifiers)
    any_arm = any(x.type == "ARMATURE" for x in bpy.context.scene.objects)
    return has_arm or not any_arm


def mesh_report(o):
    me = o.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.faces.ensure_lookup_table()
    # Geometry checks on a welded copy: glTF splits vertices along UV seams, which
    # would otherwise show up as thousands of boundary / non-manifold edges.
    gm = bm.copy()
    split_verts = len(gm.verts)
    bmesh.ops.remove_doubles(gm, verts=gm.verts, dist=1e-5)
    welded = split_verts - len(gm.verts)
    tris = sum(len(f.verts) - 2 for f in bm.faces)
    non_manifold = sum(1 for e in gm.edges if not e.is_manifold)
    boundary = sum(1 for e in gm.edges if e.is_boundary)
    # Normal disagreement: an edge between two faces that walk it the same way.
    flipped = 0
    for e in gm.edges:
        if len(e.link_faces) == 2:
            a, b = e.link_faces
            la = [l for l in a.loops if l.edge is e][0]
            lb = [l for l in b.loops if l.edge is e][0]
            if la.vert is lb.vert:
                flipped += 1
    keys = {}
    dup = 0
    for f in gm.faces:
        k = tuple(sorted(v.index for v in f.verts))
        if k in keys:
            dup += 1
        keys[k] = 1
    degenerate = sum(1 for f in bm.faces if f.calc_area() < 1e-10)
    rep = {
        "name": o.name, "mesh": me.name, "vertices": len(bm.verts), "faces": len(bm.faces), "triangles": tris,
        "material_slots": [s.material.name if s.material else None for s in o.material_slots],
        "faces_per_material": {},
        "vertex_groups": len(o.vertex_groups), "vertex_group_names_sample": [g.name for g in o.vertex_groups][:12],
        "uv_layers": [u.name for u in me.uv_layers],
        "color_attributes": [c.name for c in me.color_attributes],
        "face_attributes": [a.name for a in me.attributes if a.domain == "FACE" and not a.name.startswith(".")],
        "scale": [round(x, 4) for x in o.scale], "negative_scale": any(x < 0 for x in o.scale),
        "seam_split_vertices_welded_for_checks": welded,
        "non_manifold_edges": non_manifold, "boundary_edges": boundary,
        "inconsistent_normal_edges": flipped, "duplicate_faces": dup, "degenerate_faces": degenerate,
    }
    for f in bm.faces:
        n = rep["material_slots"][f.material_index] if f.material_index < len(rep["material_slots"]) else f.material_index
        rep["faces_per_material"][str(n)] = rep["faces_per_material"].get(str(n), 0) + 1
    # UV
    uvl = bm.loops.layers.uv.active
    if uvl is None:
        rep["uv"] = {"missing": True}
    else:
        zero, areas3, areas2 = 0, [], []
        res = 512
        cover = np.zeros((res, res), dtype=np.int16)
        for f in bm.faces:
            uv = [l[uvl].uv.copy() for l in f.loops]
            a2 = 0.0
            for i in range(1, len(uv) - 1):
                a2 += abs((uv[i] - uv[0]).cross(uv[i + 1] - uv[0])) / 2
            a3 = f.calc_area()
            if a2 < 1e-10:
                zero += 1
            else:
                areas3.append(a3)
                areas2.append(a2)
            # exact coverage raster (texel centres inside each UV triangle)
            for i in range(1, len(uv) - 1):
                tri = np.array([[uv[0].x, uv[0].y], [uv[i].x, uv[i].y], [uv[i + 1].x, uv[i + 1].y]]) * res
                x0, y0 = np.floor(tri.min(0)).astype(int)
                x1, y1 = np.ceil(tri.max(0)).astype(int)
                x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, res - 1), min(y1, res - 1)
                if x1 < x0 or y1 < y0:
                    continue
                xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
                (ax, ay), (bx, by), (cx, cy) = tri
                det = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
                if abs(det) < 1e-12:
                    continue
                l1 = ((by - cy) * (xs - cx) + (cx - bx) * (ys - cy)) / det
                l2 = ((cy - ay) * (xs - cx) + (ax - cx) * (ys - cy)) / det
                inside = (l1 >= 0) & (l2 >= 0) & (1 - l1 - l2 >= 0)
                cover[y0:y1 + 1, x0:x1 + 1] += inside.astype(np.int16)
        dens = np.sqrt(np.array(areas2) / np.maximum(np.array(areas3), 1e-12)) if areas2 else np.array([0.0])
        # islands
        seen, islands = set(), 0
        for f in bm.faces:
            if f.index in seen:
                continue
            islands += 1
            stack = [f]
            while stack:
                g = stack.pop()
                if g.index in seen:
                    continue
                seen.add(g.index)
                for l in g.loops:
                    e = l.edge
                    for h in e.link_faces:
                        if h.index in seen:
                            continue
                        lh = [x for x in h.loops if x.edge is e]
                        if lh and (l[uvl].uv - lh[0].link_loop_next[uvl].uv).length < 1e-5:
                            stack.append(h)
        used = (cover > 0).sum()
        rep["uv"] = {
            "missing": False, "zero_area_faces": zero, "islands": islands,
            "uv_space_used": round(float(used / cover.size), 3),
            "overlap_share_of_used": round(float((cover > 1).sum() / max(used, 1)), 3),
            "texel_density_p10_p50_p90": [round(float(x), 3) for x in np.percentile(dens, [10, 50, 90])],
            "texel_density_spread_p90_over_p10": round(float(np.percentile(dens, 90) / max(np.percentile(dens, 10), 1e-9)), 2),
            "note": "coverage rasterised at 512^2 from the triangles; deliberate mirrored UVs would count as overlap",
        }
    bm.free()
    gm.free()
    return rep


def render_views(out_dir, size, prefix="view"):
    for o in bpy.context.scene.objects:
        if o.type == "MESH" and not is_character_mesh(o):
            o.hide_render = True
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH" and is_character_mesh(o)]
    pts = np.array([o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box])
    lo, hi = pts.min(0), pts.max(0)
    centre = Vector(((lo + hi) / 2).tolist())
    height = float(hi[2] - lo[2])
    scn = bpy.context.scene
    scn.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] else "BLENDER_EEVEE"
    scn.render.resolution_x = scn.render.resolution_y = size
    scn.render.film_transparent = False
    scn.view_settings.view_transform = "Standard"
    scn.view_settings.look = "None"
    scn.view_settings.exposure = 0.0
    scn.view_settings.gamma = 1.0
    world = bpy.data.worlds.new("neutral")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.78, 0.78, 0.80, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.0
    scn.world = world
    for name, rot, energy in (("key", (math.radians(50), 0, math.radians(30)), 3.0), ("fill", (math.radians(60), 0, math.radians(200)), 1.2)):
        ld = bpy.data.lights.new(name, "SUN")
        ld.energy = energy
        lo_ = bpy.data.objects.new(name, ld)
        lo_.rotation_euler = rot
        scn.collection.objects.link(lo_)
    cam_d = bpy.data.cameras.new("qa")
    cam_d.type = "ORTHO"
    cam_d.ortho_scale = height * 1.12
    cam = bpy.data.objects.new("qa", cam_d)
    scn.collection.objects.link(cam)
    scn.camera = cam
    out = {}
    for view, yaw in (("front", 0), ("back", 180), ("left", 90), ("right", -90), ("three_quarter", 45)):
        t = math.radians(yaw)
        d = Vector((math.sin(t), -math.cos(t), 0.0))  # glTF front faces -Y in Blender
        cam.location = centre + d * 10.0
        cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
        path = os.path.abspath(os.path.join(out_dir, f"{prefix}_{view}.png"))
        scn.render.filepath = path
        bpy.ops.render.render(write_still=True)
        out[view] = path
    return out


def main():
    a = args()
    out_dir = os.path.dirname(os.path.abspath(a.output))
    os.makedirs(out_dir, exist_ok=True)
    load(a.input)
    rep = {
        "stage": "A_inspect", "input": os.path.abspath(a.input),
        "blender": bpy.app.version_string, "python": sys.version.split()[0],
        "command_line": " ".join(sys.argv), "devices": devices(),
        "objects": [{"name": o.name, "type": o.type, "parent": o.parent.name if o.parent else None} for o in bpy.context.scene.objects],
        "images": [{"name": i.name, "size": list(i.size), "packed": i.packed_file is not None,
                    "filepath": i.filepath, "colorspace": i.colorspace_settings.name} for i in bpy.data.images],
        "meshes": [mesh_report(o) for o in bpy.context.scene.objects if o.type == "MESH" and is_character_mesh(o)],
        "ignored_helpers": [o.name for o in bpy.context.scene.objects if o.type == "MESH" and not is_character_mesh(o)],
        "armatures": [{"name": o.name, "bones": len(o.data.bones)} for o in bpy.context.scene.objects if o.type == "ARMATURE"],
        "actions": len(bpy.data.actions),
    }
    # Rest pose for the renders.
    for o in bpy.context.scene.objects:
        if o.type == "ARMATURE":
            o.data.pose_position = "REST"
    rep["renders"] = render_views(out_dir, a.size)
    # Suggested path, from what was found.
    sug = []
    for m in rep["meshes"]:
        if len([s for s in m["material_slots"] if s]) <= 1 and m["faces"] > 2000:
            sug.append(f"{m['name']}: one material over the whole body: regions must come from stage B (vertex groups, connectivity, texture colour as candidates); expect NEEDS_REVIEW where they disagree")
        if m.get("uv", {}).get("missing"):
            sug.append(f"{m['name']}: no UVs: stage E smart-unwrap candidate")
        elif m.get("uv", {}).get("overlap_share_of_used", 0) > 0.15:
            sug.append(f"{m['name']}: UV overlap upper bound {m['uv']['overlap_share_of_used']}: check islands before baking")
        if m["inconsistent_normal_edges"]:
            sug.append(f"{m['name']}: {m['inconsistent_normal_edges']} edges between faces with disagreeing normals: review (glTF seam splits can cause false positives)")
        if m["non_manifold_edges"]:
            sug.append(f"{m['name']}: {m['non_manifold_edges']} non-manifold edges (glTF splits vertices at UV seams; most are boundary edges of that split)")
    rep["suggested_repair_path"] = sug
    with open(a.output, "w", encoding="utf-8") as f:
        json.dump(rep, f, indent=2, ensure_ascii=False)
    print("INSPECT_OK", a.output)


if __name__ == "__main__":
    main()
