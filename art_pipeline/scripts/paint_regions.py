"""Texturing v5, stages D + E: region-masked detail, baked to game textures.

  blender -b --factory-startup --python art_pipeline/scripts/paint_regions.py -- \
      --config art_pipeline/config/characters/grandma.json \
      --approved art_pipeline/assets/work/grandma_B_approved.blend \
      --report art_pipeline/reports/grandma \
      --work art_pipeline/assets/work/grandma_E_baked.blend \
      --export art_pipeline/assets/export/grandma.glb

Refuses to run without reports/<asset>/approval.json = APPROVED (the stage-B gate).

D (detail, v5 §5): every region gets a small palette of its *own* colours, taken
from the existing base colour inside that region only (k-means, fixed seed; config
"detail_k"). Each texel of a face takes the nearest colour of its face's region
palette, so a texel can never carry another region's colour: the cardigan's
flowers stay on the cardigan, the face's features on the skin, nothing bleeds.
A light 3x3 majority inside each region removes speckle.
E (UV and bake, v5 §6): the existing UVs are kept (stage A: no overlap, no
zero-area faces). Base Color (sRGB, no lighting) and Roughness (Non-Color, from
each region's role) are written as separate textures with 16 px padding.
The game GLB carries one material (one draw call) with both maps; the glasses
keep their flat material. Skeleton, weights and clips are exported unchanged.
"""
import argparse
import json
import os
import sys

import bpy
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import inspect_asset as ia  # noqa: E402


def args():
    argv = sys.argv[sys.argv.index("--") + 1:]
    p = argparse.ArgumentParser()
    for k in ("config", "approved", "report", "work", "export"):
        p.add_argument("--" + k, required=True)
    p.add_argument("--size", type=int, default=0, help="texture size (0 = the source's)")
    p.add_argument("--rough-size", type=int, default=512)
    return p.parse_args(argv)


def kmeans(x, k, seed=7, iters=30):
    rng = np.random.default_rng(seed)
    if len(x) <= k:
        return x.copy()
    c = x[rng.choice(len(x), k, replace=False)]
    for _ in range(iters):
        lab = ((x[:, None] - c[None]) ** 2).sum(-1).argmin(1)
        c = np.array([x[lab == i].mean(0) if (lab == i).any() else c[i] for i in range(k)])
    return c


def tri_texels(uv3, T):
    x0, y0 = np.floor(uv3.min(0)).astype(int)
    x1, y1 = np.ceil(uv3.max(0)).astype(int)
    x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, T - 1), min(y1, T - 1)
    if x1 < x0 or y1 < y0:
        return None, None
    xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
    (ax, ay), (bx, by), (cx, cy) = uv3
    det = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
    if abs(det) < 1e-12:
        return None, None
    l1 = ((by - cy) * (xs - cx) + (cx - bx) * (ys - cy)) / det
    l2 = ((cy - ay) * (xs - cx) + (ax - cx) * (ys - cy)) / det
    ins = (l1 >= -0.02) & (l2 >= -0.02) & (1 - l1 - l2 >= -0.02)
    if not ins.any():
        # A sliver thinner than a texel: its corners and centre still get paint,
        # or the face samples unpainted black (gym coach, 2 faces).
        pts = np.vstack([uv3, uv3.mean(0)])
        ys_ = np.clip(pts[:, 1].astype(int), 0, T - 1)
        xs_ = np.clip(pts[:, 0].astype(int), 0, T - 1)
        return ys_, xs_
    return (ys[ins] - 0.5).astype(int), (xs[ins] - 0.5).astype(int)


def dilate(img, filled, steps):
    filled = filled.copy()
    for _ in range(steps):
        acc = np.zeros_like(img)
        cnt = np.zeros(filled.shape)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            acc += np.roll(np.roll(img * filled[..., None], dy, 0), dx, 1)
            cnt += np.roll(np.roll(filled, dy, 0), dx, 1)
        grow = ~filled & (cnt > 0)
        img[grow] = acc[grow] / cnt[grow][:, None]
        filled |= grow


def save_image(name, arr, path, colourspace):
    h, w = arr.shape[:2]
    img = bpy.data.images.new(name, w, h, alpha=False, float_buffer=False)
    img.colorspace_settings.name = colourspace
    rgba = np.concatenate([np.clip(arr, 0, 1), np.ones((h, w, 1))], -1).astype(np.float32)
    img.pixels.foreach_set(rgba.ravel())
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    img.pack()
    return img


def main():
    a = args()
    cfg = json.load(open(a.config, encoding="utf-8"))
    appr = os.path.join(a.report, "approval.json")
    if not os.path.exists(appr) or json.load(open(appr, encoding="utf-8")).get("status") != "APPROVED":
        sys.exit("PAINT_REFUSED: the stage-B regions are not approved (reports/<asset>/approval.json)")
    bpy.ops.wm.open_mainfile(filepath=os.path.abspath(a.approved))
    regions = {r["id"]: r for r in cfg["regions"]}
    by_name_ = {r["name"]: r for r in cfg["regions"]}
    rough = cfg.get("roughness", {})
    rep = {"stage": "D_E_paint_bake", "regions": {}}
    body = bpy.data.objects[cfg.get("body", "Character")]
    me = body.data
    rid = np.zeros(len(me.polygons), dtype=np.int32)
    me.attributes["region_id"].data.foreach_get("value", rid)
    # The source base colour (stage A found it packed in the original material).
    # The existing colour, as a local reference only: a texture (config
    # "reference_texture") or a colour attribute interpolated into UV space.
    if cfg.get("color_attribute"):
        T = a.size or cfg.get("texture_size", 1024)
        ca = me.color_attributes[cfg["color_attribute"]]
        vals = np.array([d.color_srgb[:3] for d in ca.data], dtype=np.float32)
        corner = vals if ca.domain == "CORNER" else vals[[l.vertex_index for l in me.loops]]
        srcpx = np.zeros((T, T, 3), dtype=np.float32)
        uvl = np.array([d.uv[:] for d in me.uv_layers.active.data]) * T
        me.calc_loop_triangles()
        for t in me.loop_triangles:
            lp = list(t.loops)
            tri = uvl[lp]
            x0, y0 = np.floor(tri.min(0)).astype(int)
            x1, y1 = np.ceil(tri.max(0)).astype(int)
            x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, T - 1), min(y1, T - 1)
            if x1 < x0 or y1 < y0:
                continue
            xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
            (ax, ay), (bx, by), (cx, cy) = tri
            det = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
            if abs(det) < 1e-12:
                continue
            l1 = ((by - cy) * (xs - cx) + (cx - bx) * (ys - cy)) / det
            l2 = ((cy - ay) * (xs - cx) + (ax - cx) * (ys - cy)) / det
            l3 = 1 - l1 - l2
            ins = (l1 >= -0.02) & (l2 >= -0.02) & (l3 >= -0.02)
            col = l1[..., None] * corner[lp[0]] + l2[..., None] * corner[lp[1]] + l3[..., None] * corner[lp[2]]
            srcpx[y0:y1 + 1, x0:x1 + 1][ins] = col[ins]
    else:
        src = bpy.data.images.load(os.path.abspath(cfg["reference_texture"]))
        W, H = src.size
        T = a.size or W
        srcpx = np.array(src.pixels[:], dtype=np.float32).reshape(H, W, src.channels)[..., :3]
        if T != W:
            idx = (np.arange(T) * W / T).astype(int)
            srcpx = srcpx[idx][:, idx]
    uv = np.array([d.uv[:] for d in me.uv_layers.active.data]) * T
    me.calc_loop_triangles()
    # Boundary faces may resolve the line between their own region and an edge
    # neighbour's at texel level (a curved hairline across triangles); interior
    # faces keep their own region only. Nothing outside the two regions can appear.
    import bmesh
    bmw = bmesh.new()
    bmw.from_mesh(me)
    bmesh.ops.remove_doubles(bmw, verts=bmw.verts, dist=1e-5)
    bmw.faces.ensure_lookup_table()
    neigh = [set() for _ in range(len(me.polygons))]
    for f in bmw.faces:
        for e in f.edges:
            for g in e.link_faces:
                if g.index != f.index and rid[g.index] != rid[f.index]:
                    neigh[f.index].add(int(rid[g.index]))
    bmw.free()
    # Texels of each region.
    region_px = np.zeros((T, T), dtype=np.int16)
    alt_px = np.zeros((T, T), dtype=np.int16)  # one neighbouring region a boundary texel may take
    # Bone class (stage B attribute) and how far the face points forward, per texel,
    # for palette_limits.
    fcls = np.zeros(len(me.polygons), dtype=np.int32)
    if "bone_class_id" in me.attributes:
        me.attributes["bone_class_id"].data.foreach_get("value", fcls)
    rot = body.matrix_world.to_3x3()
    ffront = np.array([-(rot @ p.normal).normalized().y for p in me.polygons], dtype=np.float32)
    cls_px = np.zeros((T, T), dtype=np.int16)
    front_px = np.zeros((T, T), dtype=np.float32)
    for t in me.loop_triangles:
        ys, xs = tri_texels(uv[list(t.loops)], T)
        if ys is not None:
            region_px[ys, xs] = rid[t.polygon_index]
            cls_px[ys, xs] = fcls[t.polygon_index]
            front_px[ys, xs] = ffront[t.polygon_index]
            nb = neigh[t.polygon_index]
            if len(nb) == 1:
                alt_px[ys, xs] = next(iter(nb))
    painted = region_px > 0
    out = np.zeros((T, T, 3), dtype=np.float32)
    lab = np.full((T, T), -1, dtype=np.int16)
    palettes = {}
    far_px = np.zeros((T, T), dtype=bool)  # repainted texels: never moved at a boundary
    detail_k = cfg.get("detail_k", {})
    for r_id, r in regions.items():
        m = region_px == r_id
        if not m.any():
            continue
        k = int(detail_k.get(r["name"], 1))
        cols = srcpx[m]
        keep = cols.sum(1) > 0.02  # unpainted padding
        foreign = cfg.get("repaint", {}).get(r["name"])
        far = np.zeros(len(cols), dtype=bool)
        if foreign:
            # Texels that read as a named foreign region (skin projected onto a sleeve)
            # leave the palette and take the region's dominant colour; the region's
            # own pattern colours stay.
            def ref(names_):
                return np.array([[x * s_ for x in c] for n_ in names_ for c in by_name_[n_]["match"] for s_ in (1.0, 0.82, 0.66)])
            d_own = np.sqrt(((cols[:, None] - ref([r["name"]])[None]) ** 2).sum(-1)).min(1)
            d_for = np.sqrt(((cols[:, None] - ref(foreign)[None]) ** 2).sum(-1)).min(1)
            far = d_for < d_own
        fit = cols[keep & ~far]
        dp = cfg.get("design_palette", [])
        if dp is True or r["name"] in dp:
            # The sheet's colours themselves (config "match"), not k-means centres of
            # the baked reference (which carry its shading and come out muddy). Each
            # texel is compared with every design colour and its shaded copies.
            pal = np.array(list(dict.fromkeys(tuple(c) for c in r["match"])), dtype=np.float32)
            shades = (1.0, 0.82, 0.66)
            cand = np.concatenate([pal * s_ for s_ in shades])
            d = ((cols[:, None] - cand[None]) ** 2).sum(-1)
            lb = d.argmin(1) % len(pal)
        else:
            pal = kmeans(fit, k) if (k > 1 and len(fit) > k) else np.array([r["colour"]], dtype=np.float32)
            d = ((cols[:, None] - pal[None]) ** 2).sum(-1)
            lb = d.argmin(1)
        palettes[r_id] = pal
        if far.any():
            dom = np.bincount(lb[~far], minlength=len(pal)).argmax() if (~far).any() else 0
            lb[far] = dom
        cls_names = list(cfg["bone_classes"])
        lims = cfg.get("palette_limits", {}).get(r["name"], [])
        if lims and len(pal) > 1:
            # A palette colour only where the sheet has it: the rider's white hoodie on
            # the front of the torso (not on the orange sleeves), the coach's dark print
            # on the front of his tank top (not as blotches on its sides). All limits
            # apply together, so a texel cannot hop between two limited whites.
            banned = np.zeros((int(m.sum()), len(pal)), dtype=bool)
            for lim in lims:
                e = int(np.argmin(((pal - np.array(lim["colour"], dtype=np.float32)) ** 2).sum(1)))
                ok_cls = np.isin(cls_px[m], [cls_names.index(c) + 1 for c in lim.get("classes", cls_names)])
                ok = ok_cls & (front_px[m] >= lim.get("front_min", -2.0))
                if "back_min" in lim:
                    # Also allowed facing backwards, whatever the bone class (the
                    # rider's box rides on his arm and thigh weights).
                    ok |= front_px[m] <= -lim["back_min"]
                banned[:, e] = ~ok
            bad = banned[np.arange(len(lb)), lb] & ~banned.all(1)
            if bad.any():
                d2 = ((cols[bad][:, None] - pal[None]) ** 2).sum(-1)
                d2[banned[bad]] = np.inf
                lb[bad] = d2.argmin(1)
        lab[m] = lb
        far_px[m] = far
        rep.setdefault("repainted_texels", {})[r["name"]] = int(far.sum())
        rep["regions"][r["name"]] = {"texels": int(m.sum()), "palette": np.round(pal, 3).tolist()}
    # Light majority inside each region (never across regions).
    for _ in range(2):
        best = lab.copy()
        for r_id, pal in palettes.items():
            m = region_px == r_id
            counts = np.zeros((len(pal), T, T), dtype=np.int16)
            for k in range(len(pal)):
                mk = ((lab == k) & m).astype(np.int16)
                acc = np.zeros_like(mk)
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        acc += np.roll(np.roll(mk, dy, 0), dx, 1)
                counts[k] = acc
            best[m] = counts.argmax(0)[m]
        lab = best
    # Boundary texels: if the reference colour is clearly the neighbour region's,
    # the texel takes that region (and its palette).
    if cfg.get("boundary_texels", True):
        bt = (alt_px > 0) & (region_px > 0) & ~far_px
        moved = 0
        for r_id, pal in palettes.items():
            for n_id, npal in palettes.items():
                m = bt & (region_px == r_id) & (alt_px == n_id)
                if not m.any():
                    continue
                c = srcpx[m]
                d_own = ((c[:, None] - pal[None]) ** 2).sum(-1).min(1)
                d_nb = ((c[:, None] - npal[None]) ** 2).sum(-1)
                take = d_nb.min(1) < d_own * 0.5
                ys, xs = np.nonzero(m)
                region_px[ys[take], xs[take]] = n_id
                lab[ys[take], xs[take]] = d_nb.argmin(1)[take]
                moved += int(take.sum())
        rep["boundary_texels_moved"] = moved
    rough_map = np.zeros((T, T, 3), dtype=np.float32)
    keep_ref = set(cfg.get("keep_reference", []))
    for r_id, pal in palettes.items():
        m = region_px == r_id
        out[m] = pal[lab[m]]
        if regions[r_id]["name"] in keep_ref:
            # Drawn faces are already flat vector art in the reference (draw_face_map):
            # quantising them lost eye whites, blush and teeth. They are kept as drawn.
            keep = m & (srcpx.sum(-1) > 0.02)
            out[keep] = srcpx[keep]
        rough_map[m] = rough.get(regions[r_id]["role"], 0.8)
    dilate(out, painted, 16)
    dilate(rough_map, painted, 16)
    tex_dir = os.path.dirname(os.path.abspath(a.export))
    os.makedirs(tex_dir, exist_ok=True)
    name = cfg["asset"]
    base_img = save_image(f"{name}_basecolor", out, os.path.join(tex_dir, f"{name}_basecolor.png"), "sRGB")
    rs = a.rough_size
    ridx = (np.arange(rs) * T / rs).astype(int)
    rough_img = save_image(f"{name}_roughness", rough_map[ridx][:, ridx], os.path.join(tex_dir, f"{name}_roughness.png"), "Non-Color")
    # One game material: base colour + roughness (glTF reads roughness from G).
    mat = bpy.data.materials.new(f"{name}_game")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    tb = nt.nodes.new("ShaderNodeTexImage")
    tb.image = base_img
    nt.links.new(tb.outputs["Color"], bsdf.inputs["Base Color"])
    tr = nt.nodes.new("ShaderNodeTexImage")
    tr.image = rough_img
    sep = nt.nodes.new("ShaderNodeSeparateColor")
    nt.links.new(tr.outputs["Color"], sep.inputs["Color"])
    nt.links.new(sep.outputs["Green"], bsdf.inputs["Roughness"])
    bsdf.inputs["Metallic"].default_value = 0.0
    bsdf.inputs["Specular IOR Level"].default_value = 0.3
    me.materials.clear()
    me.materials.append(mat)
    for p in me.polygons:
        p.material_index = 0
    # Separate meshes (the glasses): a flat Principled material of their region
    # (no UVs needed for a flat colour). Replaces the stage-B preview material.
    def lin(c):
        return tuple((x / 12.92) if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)
    by_name = {r["name"]: r for r in cfg["regions"]}
    for obj_name, reg_name in cfg.get("separate_meshes", {}).items():
        ob = bpy.data.objects.get(obj_name)
        if ob is None:
            continue
        r = by_name[reg_name]
        fm = bpy.data.materials.new(f"M_{reg_name}")
        fm.use_nodes = True
        fb = fm.node_tree.nodes.get("Principled BSDF")
        fb.inputs["Base Color"].default_value = (*lin(r["colour"]), 1)
        fb.inputs["Roughness"].default_value = rough.get(r["role"], 0.6)
        fb.inputs["Metallic"].default_value = 0.0
        ob.data.materials.clear()
        ob.data.materials.append(fm)
    for o in bpy.context.scene.objects:
        if o.type == "ARMATURE":
            o.data.pose_position = "POSE"
    bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(a.work))
    for o in bpy.context.scene.objects:
        o.select_set(o.type in ("MESH", "ARMATURE") and (o.type == "ARMATURE" or ia.is_character_mesh(o)))
    bpy.ops.export_scene.gltf(filepath=os.path.abspath(a.export), export_format="GLB", use_selection=True,
                              export_animations=True, export_animation_mode="ACTIONS", export_skins=True,
                              export_image_format="AUTO")
    rep["textures"] = {"base_color": [T, T, "sRGB"], "roughness": [rs, rs, "Non-Color"], "padding_px": 16}
    rep["export"] = os.path.abspath(a.export)
    rep["checkpoint"] = os.path.abspath(a.work)
    json.dump(rep, open(os.path.join(a.report, "paint_bake.json"), "w", encoding="utf-8"), indent=1)
    print("PAINT_BAKE_OK", rep["export"])


if __name__ == "__main__":
    main()
