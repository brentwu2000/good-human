# Walk Kit, Modelled — Claude (owner request, 2026-10-06)

ART-005 (environment starter kit) is Codex's. At the owner's request, while Codex works on the dogs, Claude modelled what EnvironmentKit draws, without touching its gameplay: every collision body and the camera's fade group stay exactly as they were; `EnvironmentKit._dress` hides the greybox meshes under a body and puts the model there (`EnvironmentKit.use_models = false` brings the greybox back).

Models (`tools/art/build_walk_kit.py` → `assets/environment/walk_kit/`; sources in `good-human-3d-pipeline/blender/environment/walk_kit/`), one mesh each:
- park: `tree_trunk` + `tree_canopy` (a leaning trunk with three limbs; a crown of leaf clumps — under the kit's trunk and canopy bodies, so each still fades on its own), `bush`, `park_bench` (slats on cast iron), `lamp`, `bin`, `gate_pillar` + `gate_lintel`, `bus_stop` (shelter, glass back, advert, seat, stop sign).
- street: Taiwanese shophouse fronts in two sizes and two palettes each — `shop_a/b` (9 x 6 x 6), `block_a/b` (8 x 5 x 10): small-tile facades, a parapet, a shop front with glass on one side and a roller shutter on the other, a signboard with glyph blocks, an awning, upper windows behind iron grilles (鐵窗), air-conditioner boxes.

Ground (`world/environment/ground_materials.gd`): textures generated in code and laid in world space (triplanar), so scale is constant on any box — asphalt (road, alley), concrete pavers 0.5 m (pavements, the park approach), grass (park), concrete (base, map edges). Collision boxes unchanged.

Grade B; not final approval. Codex: the greybox builders are untouched underneath, and any of these can be replaced piece by piece in `EnvironmentKit.MODELS`.

## Sky, distance and street clutter (2026-10-07)

- Sky: `ProceduralSkyMaterial` (day top / horizon colours) that the walk's tension turns towards evening together with the light, plus a light distance haze (`fog_density` 0.003, horizon-coloured) and filmic tonemapping. `run_tension_test` now checks the sky itself turns.
- Distance (`tools/art/build_skyline.py` → `walk_kit/skyline.glb`, one mesh): a ring of apartment blocks of mixed heights 8–40 m outside the map's edges, window bands facing in, rooftop water tanks; a line of tall trees past the park's far end with blocks behind. Seen through the haze.
- Clutter (`tools/art/build_street_clutter.py` → `walk_kit/clutter/*.glb`): scooters, glazed pot plants, light-box signs, a chalk A-board, red plastic stools, a traffic cone, utility boxes. Placed by `RunMap3D.CLUTTER` against the shop fronts and the far pavement, clear of the dog's start, the owner, the search spots, lamps and the bus stop. Scooters and utility boxes are solid (the dog goes round them) and in the camera's fade group, like trees.
