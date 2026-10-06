# Clinic Window Models — Claude (owner request, 2026-10-06)

While Codex works on the dogs, the owner asked Claude to help with other art. This is the environment part of D6-01 (Shelter Opening) and D6-03 (Dog POV Adoption): the small animal hospital's front window where both opening scenes happen, replacing the greybox in `scenes/clinic_window.gd`.

Built by script in a separate headless Blender (`tools/art/build_clinic_window.py`; sources in `good-human-3d-pipeline/blender/environment/clinic/`; Codex's open Blender session untouched), in the game's own coordinates so each GLB lands on `ClinicWindow`'s layout. Each piece is one mesh (materials kept) for mobile draw calls:

- `clinic_inside.glb` — vinyl tile floor with seams, white walls over a mint wainscot with chair rail and skirting, ceiling with two light panels, the front counter (laminate front, white top, monitor, service bell, leaflets), shelves of pet-food bags, a cork notice board with notices, a three-seat steel waiting bench, a pot plant by the door.
- `clinic_pen.glb` — white wire pen sides, a blue fleece blanket with hem, a pee pad, a steel bowl, a chewed ball.
- `clinic_pen_back.glb` — the pen's back panel, separate so the adoption (seen from inside the pen) can leave it out.
- `clinic_front.glb` — tiled sill and cap, rendered header, teal sign board, aluminium mullions and transoms, the door frame and handle, a doormat.
- `clinic_street.glb` — pavement in pavers, granite kerb, road with edge and centre lines, six small shops across the road (windows, doors, a shutter, awnings, signs, upper windows), a street tree in a grate, a lamp post, a parked scooter.

In code still: the glass and its shine, the clinic's painted name, the paper sign, nose prints, lighting (now filmic tonemapped, a little softer). Grade B; not final approval. Rebuild: `"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" --background --python tools/art/build_clinic_window.py`.
