# Search Props, Modelled — Claude (owner request, 2026-10-06)

ART-039 (`3D_SEARCH_PROPS_SPEC.md`, Codex) defined five silhouettes for the searchable spots; these are grounded models of the same five, built by script in a separate headless Blender (`tools/art/build_search_props.py` → `assets/items/search_props/models/*.glb`; sources in `good-human-3d-pipeline/blender/props/search/`):

- `trash_bag` — a tied black rubbish bag slumped on the pavement, a smaller one beside it, a coloured scrap and a paper in front.
- `mailbox` — a raised teal box on a post, curved cap, mail slot, label, red flag.
- `bush` — a clump of shrub on a patch of soil, a paper scrap half under it.
- `bench` — a slatted park bench on cast-iron ends with a folded paper bag and a takeaway cup left on it.
- `gym_bag` — a duffel bag with handles, zip and teal patch, a water bottle beside it.

`SearchProp3D.build` now returns these (the greybox stays as `build_greybox`). Rules are untouched: radius, duration, loot, scent (rarity is still only the scent), one-time fade (`Greybox.set_faded` handles imported meshes). One mesh per prop. Grade B; not final approval.
