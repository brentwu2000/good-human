"""Texturing v5, stage B: semantic regions per face (candidates, not truth).

  blender -b --factory-startup --python art_pipeline/scripts/segment_regions.py -- \
      --config art_pipeline/config/characters/grandma.json \
      --work art_pipeline/assets/work/grandma_B_regions.blend \
      --report art_pipeline/reports/grandma

Sources, most reliable first (v5 §3):
1. separate meshes / names (config "separate_meshes": the glasses);
2. skin weights: each face's dominant bone class gives the regions allowed there
   (config "bone_priors": a foot face can be shoes or trousers, never hair);
3. the existing base-colour texture as a *candidate*: four samples per face,
   each matched to the nearest region colour (config "match").
A face is accepted when its colour candidate is allowed by its bone class and
the samples agree (confidence >= review.min_confidence). Otherwise it is marked
NEEDS_REVIEW with the reason; nothing is guessed. Islands of a region smaller
than review.min_island_faces are also flagged. World height is never used.

Writes: face INT attribute `region_id` (0 = needs review) on a work copy
(.blend checkpoint, the source is never saved), `region_map.json` (per region:
name, face indices, source, mean confidence; review faces with reasons; status
CANDIDATE or NEEDS_REVIEW), and flat ID-colour previews front/back/left/right/
three-quarter (review faces magenta).
"""
import argparse
import fnmatch
import json
import os
import sys

import bmesh
import bpy
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import inspect_asset as ia  # noqa: E402

REVIEW_RGB = (1.0, 0.0, 1.0)


def args():
    argv = sys.argv[sys.argv.index("--") + 1:]
    p = argparse.ArgumentParser()
    p.add_argument("--config", required=True)
    p.add_argument("--work", required=True)
    p.add_argument("--report", required=True)
    p.add_argument("--size", type=int, default=640)
    return p.parse_args(argv)


def base_image(o):
    for s in o.material_slots:
        if s.material and s.material.use_nodes:
            for n in s.material.node_tree.nodes:
                if n.type == "TEX_IMAGE" and n.image is not None and "normal" not in n.image.name.lower():
                    return n.image
    return None


def id_colour(i, n):
    import colorsys
    return colorsys.hsv_to_rgb((i * 0.618) % 1.0, 0.65, 0.95)


def main():
    a = args()
    cfg = json.load(open(a.config, encoding="utf-8"))
    os.makedirs(a.report, exist_ok=True)
    os.makedirs(os.path.dirname(os.path.abspath(a.work)), exist_ok=True)
    ia.load(cfg["source"])
    regions = cfg["regions"]
    by_name = {r["name"]: r for r in regions}
    names = [r["name"] for r in regions]
    match_cols, match_reg = [], []
    for r in regions:
        for c in r["match"]:
            # The texture carries baked shading (AO): match shaded copies too.
            for k in (1.0, 0.82, 0.66):
                match_cols.append([x * k for x in c])
                match_reg.append(r["id"])
    match_cols = np.array(match_cols)
    match_reg = np.array(match_reg)

    def bone_class(name):
        for cls, pats in cfg["bone_classes"].items():
            if any(fnmatch.fnmatch(name, p) for p in pats):
                return cls
        return None

    rep = {"stage": "B_segment", "config": a.config, "source": cfg["source"], "objects": {}}
    preview_mats = {}
    for r in regions:
        m = bpy.data.materials.new(f"ID_{r['name']}")
        m.use_nodes = True
        nt = m.node_tree
        nt.nodes.clear()
        e = nt.nodes.new("ShaderNodeEmission")
        e.inputs["Color"].default_value = (*id_colour(r["id"], len(regions)), 1)
        out = nt.nodes.new("ShaderNodeOutputMaterial")
        nt.links.new(e.outputs[0], out.inputs[0])
        preview_mats[r["id"]] = m
    rm = bpy.data.materials.new("ID_NEEDS_REVIEW")
    rm.use_nodes = True
    rm.node_tree.nodes.clear()
    e = rm.node_tree.nodes.new("ShaderNodeEmission")
    e.inputs["Color"].default_value = (*REVIEW_RGB, 1)
    o_ = rm.node_tree.nodes.new("ShaderNodeOutputMaterial")
    rm.node_tree.links.new(e.outputs[0], o_.inputs[0])
    preview_mats[0] = rm

    total_faces, total_review = 0, 0
    for o in [x for x in bpy.context.scene.objects if x.type == "MESH" and ia.is_character_mesh(x)]:
        me = o.data
        nf = len(me.polygons)
        total_faces += nf
        region = np.zeros(nf, dtype=np.int32)
        conf = np.zeros(nf)
        source = ["" for _ in range(nf)]
        reasons = {}
        face_rgb = {}
        fallback = {}
        cls_ids = {c: i + 1 for i, c in enumerate(cfg["bone_classes"])}
        face_cls = np.zeros(nf, dtype=np.int32)
        if o.name in cfg.get("separate_meshes", {}):
            rid = by_name[cfg["separate_meshes"][o.name]]["id"]
            region[:] = rid
            conf[:] = 1.0
            source = ["separate_mesh"] * nf
        else:
            ca_name = cfg.get("color_attribute")
            corner_rgb = None
            if ca_name:
                # Candidates from a colour attribute (the shiba's coat is vertex-coloured).
                ca = me.color_attributes[ca_name]
                vals = np.array([d.color_srgb[:3] for d in ca.data], dtype=np.float32)
                corner_rgb = vals if ca.domain == "CORNER" else vals[[l.vertex_index for l in me.loops]]
            else:
                img = base_image(o)
                if img is None:
                    sys.exit(f"SEGMENT_FAIL: {o.name} has no base colour image to take candidates from")
                w, h = img.size
                px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, img.channels)[..., :3]
                uv = me.uv_layers.active.data
            groups = {g.index: g.name for g in o.vertex_groups}
            vclass = []
            for v in me.vertices:
                acc = {}
                for g in v.groups:
                    c = bone_class(groups[g.group])
                    if c:
                        acc[c] = acc.get(c, 0) + g.weight
                vclass.append(acc)
            for f in me.polygons:
                # Bone class: summed weights of the face's vertices.
                acc = {}
                for vi in f.vertices:
                    for c, wgt in vclass[vi].items():
                        acc[c] = acc.get(c, 0) + wgt
                cls = max(acc, key=acc.get) if acc else None
                face_cls[f.index] = cls_ids.get(cls, 0)
                forced = None
                for rule in cfg.get("share_force", []):
                    # A sleeve that ends below the bone joint: faces carrying at least
                    # `min` of their weight on these bones are that region.
                    tot = sum(sum(g.weight for g in me.vertices[vi].groups) for vi in f.vertices) or 1.0
                    share = sum(g.weight for vi in f.vertices for g in me.vertices[vi].groups
                                if any(fnmatch.fnmatch(groups[g.group], b) for b in rule["bones"])) / tot
                    if share >= rule["min"] and cls in rule.get("classes", [cls]):
                        forced = rule["region"]
                if forced:
                    region[f.index] = by_name[forced]["id"]
                    conf[f.index] = 1.0
                    source[f.index] = "share_force"
                    continue
                if cls in cfg.get("bone_force", {}):
                    # The sheet decides here, not the projected colour (the auntie's
                    # sleeves came out skin-coloured; her sheet has purple sleeves).
                    region[f.index] = by_name[cfg["bone_force"][cls]]["id"]
                    conf[f.index] = 1.0
                    source[f.index] = f"bone_force:{cls}"
                    continue
                allowed = cfg["bone_priors"].get(cls, names)
                facing = cfg.get("front_only_regions", {})
                if facing:
                    # Drawn eyes and mouth are on the front of the face: a face turned
                    # away (the back of a cap brim) cannot be one. Rest pose, the
                    # character faces -Y.
                    fy = -(o.matrix_world.to_3x3() @ f.normal).normalized().y

                    def facing_ok(n_):
                        rule = facing.get(n_)
                        if rule is None:
                            return True
                        if isinstance(rule, dict):
                            # e.g. skin on the head only where it can be seen from the
                            # front or side (flecks on the back of the hair are hair).
                            return cls not in rule.get("classes", [cls]) or fy >= rule["min"]
                        return fy >= rule
                    allowed = [n_ for n_ in allowed if facing_ok(n_)]
                # Colour candidates: per-corner colours (colour attribute), or the face
                # centre and three points near it (texture: small UV triangles sit next
                # to unpainted padding).
                if corner_rgb is not None:
                    samples = [corner_rgb[li] for li in f.loop_indices] + [corner_rgb[list(f.loop_indices)].mean(0)]
                else:
                    uvs = np.array([uv[li].uv[:] for li in f.loop_indices])
                    cen = uvs.mean(0)
                    pts = [cen] + [cen + (u - cen) * 0.3 for u in uvs[:3]]
                    samples = [px[min(max(int(pnt[1] * h), 0), h - 1), min(max(int(pnt[0] * w), 0), w - 1)] for pnt in pts]
                votes = []
                for c in samples:
                    if c.sum() < 0.02:  # padding (never painted): no vote
                        continue
                    d = ((match_cols - c) ** 2).sum(1)
                    # nearest *allowed* region and the nearest overall
                    ok = np.isin(match_reg, [by_name[n]["id"] for n in allowed])
                    best_any = match_reg[np.argmin(d)]
                    best_ok = match_reg[ok][np.argmin(d[ok])] if ok.any() else 0
                    # Colours shared by two regions (white blouse / white shoes): the
                    # allowed one is as good as the overall nearest -> it is the colour's reading.
                    # Bone weights are the more reliable source (v5 §3 order): when an allowed
                    # region is nearly as close as the overall nearest, the allowed one stands.
                    if ok.any() and np.sqrt(d[ok].min()) - np.sqrt(d.min()) < cfg["review"].get("prior_tolerance", 0.06):
                        best_any = best_ok
                    # Aliases: allowed regions whose colours are as near as the best (an
                    # orange vest and an orange bag strap) cannot be told apart by colour.
                    # The bone prior's order decides (first listed wins), and an alias is
                    # not a competitor in the margin.
                    tie = cfg["review"].get("tie_eps", 0.03)
                    dreg = {}
                    for n_ in allowed:
                        sel = match_reg == by_name[n_]["id"]
                        if sel.any():
                            dreg[n_] = float(np.sqrt(d[sel].min()))
                    if dreg:
                        dmin = min(dreg.values())
                        pref = next(n_ for n_ in allowed if n_ in dreg and dreg[n_] <= dmin + tie)
                        if best_any == best_ok:
                            best_any = by_name[pref]["id"]
                        best_ok = by_name[pref]["id"]
                    aliases = {by_name[n_]["id"] for n_, dd in dreg.items() if dd <= dmin + tie} if dreg else set()
                    # margin: how much nearer the chosen region is than the nearest other region
                    other = d[~np.isin(match_reg, list(aliases | {best_ok})) & ok]  # competitors that are possible here
                    d1 = float(np.sqrt(d[match_reg == best_ok].min())) if best_ok else 9.0
                    d2 = float(np.sqrt(other.min())) if len(other) else 9.0
                    votes.append((best_any, best_ok, d1, d2, c))
                if not votes:
                    reasons[f.index] = "no painted texel inside the face"
                    # Fallback candidate if no painted neighbour gives one: the bone
                    # class's main region.
                    fallback[f.index] = by_name[allowed[0]]["id"]
                    continue
                any_ids = [v[0] for v in votes]
                ok_ids = [v[1] for v in votes]
                top = max(set(ok_ids), key=ok_ids.count)
                agree = ok_ids.count(top) / len(ok_ids)
                in_allowed = sum(1 for x in any_ids if x == top) / len(any_ids)
                d1 = np.mean([v[2] for v in votes])
                d2 = np.mean([v[3] for v in votes])
                # Colour support: far from every region -> none; else the margin to the next region.
                support = 0.0 if d1 > 0.45 else min(1.0, 0.4 + (d2 - d1) / max(d2, 1e-6))
                c_ = agree * (0.5 + 0.5 * in_allowed) * support
                conf[f.index] = c_
                face_rgb[f.index] = np.mean([v[4] for v in votes], 0)
                if top == 0:
                    reasons[f.index] = f"no allowed region for bone class {cls}"
                elif c_ < cfg["review"]["min_confidence"]:
                    reasons[f.index] = (f"low confidence {c_:.2f} (class {cls}; colour says "
                                        f"{names[int(np.bincount(any_ids).argmax()) - 1] if max(any_ids) else '?'}, allowed {allowed})")
                    region[f.index] = top  # kept as candidate; status decides
                    source[f.index] = "candidate_low_confidence"
                else:
                    region[f.index] = top
                    source[f.index] = f"bone:{cls}+texture"
        # Small islands of a region: flag, do not change.
        bm = bmesh.new()
        bm.from_mesh(me)
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
        bm.faces.ensure_lookup_table()
        # A face with no painted texel (a sliver between UV islands) gets its edge
        # neighbours' majority as the *candidate*; it stays in review.
        for _ in range(4):
            for f in bm.faces:
                if region[f.index] == 0 and f.index in reasons:
                    nb = [int(region[g.index]) for e in f.edges for g in e.link_faces if region[g.index]]
                    if nb:
                        region[f.index] = max(set(nb), key=nb.count)
        for fi, rid_ in fallback.items():
            if region[fi] == 0:
                region[fi] = rid_
        seen = np.zeros(nf, dtype=bool)
        minf = cfg["review"]["min_island_faces"]
        for f in bm.faces:
            if seen[f.index]:
                continue
            rid = region[f.index]
            comp, stack = [], [f]
            while stack:
                g = stack.pop()
                if seen[g.index] or region[g.index] != rid:
                    continue
                seen[g.index] = True
                comp.append(g.index)
                stack.extend(hh for e in g.edges for hh in e.link_faces if not seen[hh.index])
            if len(comp) < minf and o.name not in cfg.get("separate_meshes", {}):
                for fi in comp:
                    reasons.setdefault(fi, f"island of {len(comp)} face(s) of {names[rid - 1] if rid else '?'}")
            merge = cfg["review"].get("merge_islands", 0)
            if len(comp) < merge and o.name not in cfg.get("separate_meshes", {}):
                # Specks (red bandana flecks on the back of the hair): the candidate is
                # the surrounding region; still a review face.
                cs = set(comp)
                nb = [int(region[hh.index]) for fi in comp for e in bm.faces[fi].edges for hh in e.link_faces
                      if hh.index not in cs and region[hh.index]]
                if nb:
                    to = max(set(nb), key=nb.count)
                    for fi in comp:
                        region[fi] = to
                        reasons.setdefault(fi, f"speck island of {len(comp)} face(s) of {names[rid - 1] if rid else '?'} inside {names[to - 1]}")
        bm.free()
        final = region.copy()
        for fi in reasons:
            final[fi] = 0
        total_review += len(reasons)
        attr = me.attributes.get("region_id") or me.attributes.new("region_id", "INT", "FACE")
        attr.data.foreach_set("value", final.astype(np.int32))
        # Bone class per face (1-based in config order, 0 = none) for paint-stage rules.
        ca_ = me.attributes.get("bone_class_id") or me.attributes.new("bone_class_id", "INT", "FACE")
        ca_.data.foreach_set("value", face_cls)
        # preview materials
        me.materials.clear()
        order = [0] + [r["id"] for r in regions]
        for rid in order:
            me.materials.append(preview_mats[rid])
        me.polygons.foreach_set("material_index", np.array([order.index(int(x)) for x in final], dtype=np.int32))
        me.update()
        rep["objects"][o.name] = {
            "faces": nf,
            "regions": {names[r["id"] - 1]: {"id": r["id"], "faces": int((final == r["id"]).sum()),
                                             "face_indices": np.nonzero(final == r["id"])[0].tolist(),
                                             "mean_confidence": round(float(conf[final == r["id"]].mean()), 3) if (final == r["id"]).any() else None,
                                             "source": "separate_mesh" if o.name in cfg.get("separate_meshes", {}) else "bone_prior+texture_candidate"}
                        for r in regions},
            "needs_review": [{"face": int(k), "candidate": names[region[k] - 1] if region[k] else None, "reason": v,
                              "sampled_rgb": [round(float(x), 3) for x in face_rgb[k]] if k in face_rgb else None} for k, v in sorted(reasons.items())],
        }
    share = total_review / max(total_faces, 1)
    rep["needs_review_faces"] = total_review
    rep["needs_review_share"] = round(share, 4)
    rep["status"] = "NEEDS_REVIEW" if share > cfg["review"]["max_review_share"] else "CANDIDATE (needs human approval)"
    for o in bpy.context.scene.objects:
        if o.type == "ARMATURE":
            o.data.pose_position = "REST"
    rep["previews"] = ia.render_views(a.report, a.size, prefix="regions")
    bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(a.work))
    rep["checkpoint"] = os.path.abspath(a.work)
    with open(os.path.join(a.report, "region_map.json"), "w", encoding="utf-8") as fh:
        json.dump(rep, fh, indent=1, ensure_ascii=False)
    print("SEGMENT_OK", rep["status"], "review", total_review, "of", total_faces)


if __name__ == "__main__":
    main()
