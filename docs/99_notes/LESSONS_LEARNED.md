# Lessons learned — read before working on the game

Owner, 2026-10-09: 「把開發遇到的問題要寫回，讓下次開發不會再遇到」. Problems that cost real time, written as rules. Claude (gameplay) and Codex (art) read this before starting. Codex acting as **blind QA does not** — it holds implementation notes. **When you fix a problem that was not obvious, add it here** (symptom → cause → rule → how to check), in the section it belongs to. Keep entries short; the detail lives in `SPRINT_STATUS.md` notes and the commit.

---

## 1. Posing people and things they hold

**1.1 Hands were never closed.** *Symptom:* weapons looked fake — an umbrella stood on the fingertips like a torch. *Cause:* the fight clips posed the hand bone only; every finger stayed open, and the prop was mounted along the hand bone, i.e. out past the fingertips. *Rule:* the owner rig has full finger bones (`thumb/index/middle/ring/pinky_01..03_l/r`). Any clip that holds or hits must close the hands (fists empty-handed, round the shaft when holding). A held object runs **through the closed fist**, across the hand — mount it on `WeaponProp3D.grip()`, never on the bare hand bone. *Check:* `weapon_test._test_grip`; close-up renders with `tools/art/preview_fight_hands.py`.

**1.2 Look up how people really hold and use a thing before posing it.** *Symptom:* first attempt only re-aimed the weapon and still looked wrong (owner: 「請去找參考再回來做」). *Rule:* for any new held object or move, collect real references first (martial-arts manuals, sport technique, everyday use) and write them down — see `WEAPON_GRIP_REFERENCE.md` for the umbrella (walking stick), broom (two-handed, bayonet-like) and fists. One-handed vs two-handed is part of the design of the object, not a detail.

**1.3 Don't guess which side the palm is.** *Symptom:* curled fingers bent backwards; the grip landed on the back of the hand. *Cause:* the palm normal was inferred from the rest pose's finger bones, whose slight bend points the wrong way on this rig. *Rule:* verify any derived hand/limb axis with a render before building on it. On this rig the palm is `-normal` of that estimate (fixed in `measure_hands`).

**1.4 A knuckle is a hinge.** *Symptom:* "fists" looked like claws, fingers splayed sideways. *Cause:* each finger joint's bend axis was recomputed from the joint's current direction × palm normal; once the first joint pointed into the palm the cross product degenerated. *Rule:* one fixed hinge axis per finger, computed before bending, used for all three joints.

**1.5 Two-handed grips need the second hand solved onto the object.** *Symptom:* the broom's rear hand hung by the hip, off the shaft. *Cause:* the target was out of arm's reach, and the wrist target depended on a hand rotation computed from a guessed forearm. *Rule:* place the second grip on the shaft (lead grip − spread × shaft axis), keep it within reach (arm ≈ 0.50 m), and refine the IK a few times measuring the actual grip. *Check:* `_test_grip` (rear hand within 7 cm of the shaft).

**1.6 Carrying outside the fight counts too.** Holding a weapon on the walk used Codex's relaxed clips with open hands. Any state where something is held needs a closed-hand version (`Carry_Idle/Walk_*`).

## 2. Fight animation versus the simulation

**2.1 Clips are calibrated at maximum reach; blows land closer.** *Symptom:* fists sank 14 cm into faces, knees into thighs. *Rule:* a blow stops where it meets the body (`FighterPuppet3D.stop_at_body`). Measure bodies, not root distance: `fight_body_contact_test` (skeleton capsules over a long fight).

**2.2 Procedural layers stack on top of clips.** *Symptom:* bodies still overlapped after the clips were fixed. *Cause:* the first-pass choreography (strike lunge, guard push, knock-back) moved the whole body at full strength on top of clips that already step in and back; rotation had been scaled to the layer weight, position had not. *Rule:* anything layered over a clip must be scaled by the layer weight, position included (`P04HumanVisual.apply_layers`). When adding clip-driven motion, check what older procedural code still does to the same body.

**2.3 Order of evaluation matters.** Measure contact after **both** fighters are posed, with the layers applied (`apply_layers` is idempotent), and settle twice. Tweens update a frame after `_process`, so allow a few frames of transient press in tests rather than chasing it.

**2.4 Reach is a contract.** Changing a grip, prop length or clip extension changes where a weapon's tip lands. `weapon_test` measures the drawn tip of every thrust against its reach — re-run it after any pose or prop change, and recalibrate the clip, not the rule.

**2.6 Fit reach with the lunge, not by shrinking the move.** *Symptom:* after the grip moved the prop forward, thrusts were pulled in to keep the reach, and then barely moved — guard and strike were a few centimetres apart (owner: 「有進步，但需要再優化」). *Rule:* an attack reads by contrast: guard a little chambered, a clear pull-back on the wind-up, then a long drive with a step and the hips. Keep the strike's hand where the reach needs it and get the travel from the guard and the lunge. *Check:* the showcase capture (`weapon_showcase.tscn`), not only `weapon_test`.

**2.7 Two skills sharing an animation key share a look.** The broom's sweep and heavy blow were both `swing`, so the sweep played the overhead chop. Each move that should look different needs its own key and clip; check the moveset's skills against `ATTACK_CLIPS`/`ARMED_CLIPS` when adding one.

**2.8 Compare with how other games animate it, not only with real life.** Real grips fixed the hands; arcs, wrist lag, follow-through and trails (the craft of game melee animation) are what made the blows read. See `WEAPON_GRIP_REFERENCE.md` "Compared with other games".

**2.9 A held weapon is part of the body for collisions.** *Symptom (owner: 「穿模了」):* the umbrella and broom went through the other person, and the broom's handle through its own holder's belly, hips and head. *Cause:* contact and "stop at the body" counted bodies only; no test looked at the weapon. *Rule:* measure weapons from their model (`BodyContact.prop_capsules`); a blow stops when its weapon meets the other body; between blows the weapon turns away at the wrist (`_keep_weapon_clear`). *Check:* `weapon_clip_test` (against its own body, every clip), `weapon_fight_contact_test` (against the other person, real fights).

**2.10 A guard must fit the fighting distance.** A guard that points the weapon level at the other person reaches past their body at the move set's `ideal_min` — and an empty-handed opponent closes in further still. Hold long things up at an angle in guard (umbrella ~70°, broom ~66°) and bring them level only to strike. Measure guard reach against `ideal_min` − 0.17 m (their body front).

**2.11 Where a two-handed thing is held decides what sticks out.** Held in the middle, 0.7 m of broom handle stuck back past the hands into the hip and belly whatever the pose; held near the end of the handle (the reference's "rear-ended grip", `LONG_GRIP_SHIFT`), nothing does. Moving the off hand does not move the weapon — it hangs from the lead hand — so fix the grip, not the off hand. When a fix "changes nothing", check both sides compute the same geometry before tuning further.

**2.5 Reactions must not move the head into the attacker.** HitHeavy folding forward and Block leaning in caused overlaps a clamp cannot fix (a constant pose cannot be "held earlier"). Author reactions that move away from the blow.

## 3. Tests that lie

**3.1 Check that the thing still happens, not only that nothing bad happens.** *Symptom:* `fight_body_contact_test` passed while every blow was frozen at the start of its clip. *Cause:* the clamp compared against −0.02 but the depth function never returns below 0, so every pose counted as "inside" and was clamped to t = 0 — no overlap, no fight. *Rule:* every "nothing overlaps / nothing breaks" test also asserts the behaviour is still there (blows are still thrown).

**3.2 Set thresholds from what the bug looks like, not from one good run.** A "blow reaches 0.5" check flaked because blows thrown up close rightly stop at 0.3–0.4. The bug it guards against is t = 0, so the bar is 0.25. Run a randomised test several times before trusting a threshold.

**3.3 Headless numbers can be wrong about the screen.** The headless viewport ignores `root.size`; framing judged from headless numbers was misleading. Judge framing from Movie Maker captures (`tests/capture/record.sh`, portrait 405×720), side views from the `inspect` case.

**3.4 Movie Maker ignores `--resolution` here.** The project's window override (405×720) wins, so captures are always portrait 405×720 — and 405 is odd, which libx264 refuses: scale to an even size (e.g. 540×960) when encoding MP4. Show a set of moves with `tests/capture/weapon_showcase.tscn -- <umbrella|broom>`.

## 4. Camera and what is drawn over the game

**4.1 A fade rule can hide what the player should see.** The walking camera faded the owner whenever they were nearer than the dog — i.e. always. Fade only at the lens or when actually covering the subject on screen (`_owner_covers_dog`). *Check:* `walk_framing_test`.

**4.2 Portrait screens are narrow.** Horizontal FOV is about 40°; a sideways camera offset of 1 m pushed the owner off screen. Aim between subjects instead of offsetting far.

**4.3 Anything with `no_depth_test` is drawn through bodies.** Sniff-spot names, the desire card and the nose arrow were written across the fighters. In a fight, world labels and HUD hints step aside (`DesireHUD._in_fight`, `SearchPoint3D` label fade). Check captures for text over faces whenever a new label or hint is added.

## 5. Godot and the export

**5.1 Non-resource files are not exported.** `.json` (and other non-imported files) are left out of builds unless listed in each preset's `include_filter` (`export_presets.cfg`). Reading one with `FileAccess` works in the editor and fails in the exe.

**5.2 `pose_clip` at speed 0 never cross-fades** (a held clip's blend never advances). Clip changes are blended by `P04HumanVisual._start_blend` instead.

**5.3 Imported clips drop constant tracks.** A bone a clip does not key keeps whatever was written last; a layer that reads it back as the base accumulates (the pelvis drifted 90–160°). `apply_layers` remembers what it wrote.

## 6. Blender

**6.6 Do not factory-reset inside a live MCP build call.** `read_factory_settings`
invalidated `bpy.context.active_object` during umbrella export and disconnected
the bridge. Save the scene, clear its objects instead, and leave preferences and
the bridge intact. The revised `build_p05_weapons.reset` works in batch and MCP.

**6.7 A wider handle changes the weapon capsule, even with the same tip.** The
first J-hook extended 74 mm from the shaft and raised Thrust self-contact to
61 mm. The compact 42 mm hook passes at 13 mm. Keep the collision tolerance;
adjust the art and rerun `weapon_clip_test`, rather than checking tip reach only.

**6.8 `primitive_*_add(location=…)` keeps the vertices local.** The owner's
hair shell was cut by a hairline written in world space and came out empty (0
verts, then 392 tris of hair) with no error. Apply the location
(`transform_apply`) before any world-space vertex test, or transform the bmesh.
Check: print vertex counts after every cut.

**6.9 A colour attribute is not a colour unless the material uses it.** The
P-04 skin has `ArtTone`, but its Color Attribute node is unlinked, so tinting it
(stubble) changed no pixel in Godot. Compare pixels before/after in a capture,
not the Blender data.

**6.10 A sheet view and a generated view are not the same head.** The office
worker's geometry came from a Qwen 3/4 view; projecting the sheet's front view onto
it put the glasses a few cm off (doubled rims, hair on the face) while the body
projected fine. Paint the head from the mesh's own geometry (rims from a depth
high-pass, hair from normal bumpiness): `paint_head_stylized.py`. Check: a face
close-up render, not the full-body one.

**6.11 Generators live in `C:/Users/b/tools/modly`, not in project folders.** The
Modly install inside a Documents experiment folder vanished with it, and the factory
batch still pointed at an earlier deleted folder. All launchers read
`C:/Users/b/tools/modly/env.sh`. Check: `curl :8765/health` before a batch.

**6.12 A rig scaled from the owner misplaces a big-headed character's neck.**
The office worker's fitted `neck_01` sat at his eye height: a nod would fold his
face. Fit neck/shoulders from the mesh's width profile (`rig_lods --measure-neck`).
Check: print the neck/head bone heights against the mesh's chin and shoulders.

**6.13 LOD0's normal map on a decimated LOD shines.** Hair showed white cracked
facets in Godot; the texture was fine. For flat stylized colour, export the game
LOD matte without the normal map (`--no-game-normal`), and dilate UV islands so a
downscaled texture does not pull the background into seams.

**6.14 Texture QA can pass while the face is gone.** The v5 batch quantised every
region to a palette; QA (bleed, blank, silhouette) passed for all six characters,
but the drawn faces lost eye whites, teeth and blush. Regions that are already
finished drawings keep the reference texels (`keep_reference: ["skin", "eyes"]`).
Check: a before/after face close-up for every character, not only QA numbers.

**6.15 Skinning by distance needs one coordinate space.** Xiaomi's fallback
skinning compared mesh-local vertices with armature-local bones (mesh scaled 0.76):
her head was bound to the pelvis and feet. Compare in world space. Check: count
vertices above the head joint whose dominant bone is not head/neck (0 expected).

**6.16 Colour alone cannot tell garments apart.** Generated configs gave the jacket
and the bag the same orange: every face tied, 45 % went to review. Identical colours
resolve by the bone prior's order, and sheet facts become rules — sleeves by bone
(`bone_force`, `share_force`), white only on the front of the torso
(`palette_limits`), no eyes or skin facing backwards (`front_only_regions`). Check:
the region contact sheet against the character sheet.

**6.17 A face drawn over a tilted sheet head lands skewed on a frontal mesh.** The
gym coach's sheet head is tilted 17°; projected, his mouth sat on his nose. Draw the
face in the mesh's own front-mapped pixels from measured landmarks (brow, eyes,
nose tip, lip, chin), and check the face zone reaches below the mouth.

**6.18 A GLB re-imported into Blender can lose vertex colours on export.** The auntie's
towel stripes (a corner colour attribute, correct in the .blend) exported as plain white
from a mesh that came from the GLB, with every exporter option; Codex's .blend checkpoint
exported them fine. Build from the .blend checkpoint. Check: read COLOR_0 from the exported
GLB (or look at the towel in Godot), not the Blender attribute.

**6.19 New faces on a mesh with a colour attribute are black in Godot.** Joined hands came
in with colour (0,0,0), and Godot multiplies albedo by COLOR_0: black hands. Set new
corners to white after a join. Check: count corners with colour sum < 0.01.

**6.20 Raised arms tear a generated character where arm and torso are one surface.**
Reweighting alone (Codex r2) and cutting alone both left strips; it takes both: remove the
faces joining arm and body below the armpit, and drop arm weights from torso vertices
(and torso weights from arm vertices). Check: chest close-ups of Block/Jab in Godot.

**6.21 A joint fitted from another body can sit inside a garment.** The auntie's
owner-fitted elbow was at 38 % of her arm while her sleeve ended at ~65 %: a bent arm broke
the sleeve into shards and painting a "clean hem" could not fix it. Measure where the
mesh's garment edges are and put the joint below them (elbow at 60 %), then re-weight
along the chain. Check: compare joint heights with garment hems before tuning paint.

**6.22 A generator's own download list can miss files.** Trellis2 (Modly extension) geometry
ran, then texturing failed on `shape_enc_...` not found: its pattern `encoders/**/*.safetensors`
needs a subfolder, the files sit directly in `encoders/`. Fetch `encoders/*` too. Check: run
both nodes (generate and texture) once before a batch, not only the first.

**6.23 Trellis2 texture colours drift because of a default, not the model.** The Modly
extension's texture guidance defaults to 1.0 (its README: 3.0): the blouse came out brown, the
print a rust smear. At 3.0 the sheet's colours return; a skin white balance against the sheet
fixes the remaining dark cast. Its multi-view sampler weighs "left"/"right" by the vertical axis
(use front/back only, model turned to face +X). Check: sample the raw albedo, not a render.

**6.24 A texture generator paints the reference's pose, not the mesh's.** The sheet's front
has a hand holding the strap on the chest; Trellis2 painted that hand onto our hanging-arm
model, and a two-sided towel from the 3/4 view. Colour rules in 3D chased it for hours; erasing
the hand from the input image fixed it. Also: r3 hands map every corner to one UV point, so a
bake never reaches them (paint the texel); the strap floats ~5 cm off the body, so measure
strap distance in the front view. Check: compare the input image with the mesh pose first.

**6.25 A near-white sheet background defeats background removal's framing.** The grandma's
views went to Trellis2 with the subject at 37 % of the frame (the light grey survived as
"foreground"), and her silver hair came out dark red-brown. `t2_texture.py` re-frames on the
non-white subject to 85 %. Measuring "sheet skin" over the top 30 % of the figure took the
rider's orange jacket; use the largest face-skin blob. Check: open `colours_in_front.png`.

**6.26 A dog is not a person to a front/back texture generator.** Front and back views only
see the head and the rear: the corgi's flanks were guessed. A second run with the side view
(mesh unturned, its left flank is +X) blended by normal fixes it. The face ellipse fitted on
human heads missed the dog's eyes (they sit a whole head half-width out): measure the eyes on
a close-up before trusting a mask, and check the mask by diffing old/new texels inside it.

**6.27 A pass that reads "the current texture" must not read its own output.** The Trellis2
configs pointed at the runtime GLBs; after installing, a re-run's "keep the drawn face / the
old bag print" kept the new texture (the bag's tone ratio came out 1.0, the giveaway). Pin the
source to the revision before the pass (`git:<rev>:<path>`). Check: print the tone gain of a
kept region; 1.0 means old and new are the same image.

**6.0 Retargeting third-party animation.** Transfer each bone's *world* rotation away from its own rest onto the target bone's rest — it survives different rest poses and bone rolls; copying local rotations does not. Bake per target model when sizes differ (one library per dog breed), otherwise hips heights float or sink. Scale hip travel by leg length and check the result at the biggest and smallest model (`dog_motion_test`: paws vs ground). Render a few frames of every clip before wiring it in — names lie ("Tired Hunched" is on all fours).

**6.1 Imported models bring their own animation.** A preview render showed the wrong pose because the glTF's action re-posed the armature at render time. Clear `animation_data.action` and remove imported actions before posing for a still.

**6.2 Codex may have Blender open.** Changing add-ons or preferences while another Blender runs can be overwritten when it quits. Check for a running Blender first (`Get-Process blender`); never close Codex's.

**6.3 Viewport-only add-ons don't load in `--background`** (PolyQuilt: "GPU functions … gpu module"). Enable them from a UI session; don't use them in batch scripts.

**6.4 `blender -c extension install` takes ids comma-separated, no spaces.**

**6.5 Bone frames match between Blender and Godot for this rig** (hand-local knuckle positions agree to the millimetre), so per-bone offsets measured in Blender can be used directly in Godot — but check once when a new rig arrives.

## 7. Working with art and the owner

**7.1 Publishing Codex's models.** Copy the candidate GLB over the runtime path (same import settings), delete the orphaned extracted textures, run `breed_models_test`, and record the publish in `SPRINT_STATUS.md` — `ART_STATUS.md` is Codex's and often holds their uncommitted edits, so don't commit it. Skip candidates with no record (work in progress).

**7.2 Read notes to the end.** A task was reported to the owner as blocked from an early note, when a later note in the same section had unblocked and merged it. Read the whole section before reporting status.

**7.3 Owner decisions that change approved design** (e.g. the dumbbell is training kit, not a weapon) are recorded as owner decisions in `SPRINT_STATUS.md` with the quote, and the tests that encoded the old design are changed to encode the new one.

## 8. Tooling

**8.3 Use the project's pinned Godot for art validation.** The shell `godot`
alias points at 4.7.1 here, while `tests/run_all.sh` specifies 4.6.3. The alias
reports a native `VirtualJoystick` class conflict. Use the test runner's binary;
do not modify gameplay classes to accommodate an accidental engine switch.

**8.4 Dense GLB keys require matching import sampling.** A 120 Hz dog contact
bake imported at 30 Hz loses the between-key correction. Keep dog library
`animation/fps=120`, then reimport and inspect. Ground checks must evaluate
actual skin between keys; r34 samples Run at 209 times and checks it still moves.

**8.1 Long Python edits through a shell heredoc break on quotes.** Write the patch script to a file (scratchpad) and run it.

**8.2 `str.replace` with an empty "old" text inserts everywhere.** When slicing a file by markers, assert the slice is non-empty before replacing.


### Dog skin / retarget correction, 2026-10-10 (CX-04)

- A texture-looking tear can be skin deformation or the body going below ground.
  Bone-marker tests missed both. Check the deformed mesh in Godot and measure
  skinned vertices through the clip; r33 adds `audit_dog_motion_skin.py`.
- Matching bone names does not mean matching anatomical pivots. The inherited
  breed front chains sat behind the visible forelegs. r33 keeps bind names and
  bakes virtual-pivot compensation into translation tracks; do not strip those.
- Imported Blender armatures can bring an unskinned Icosphere control object.
  Including all meshes gave a false -1 m ground level. Filter actual meshes by
  their Armature modifier's target before measuring the body's bounds.
- Abrupt four-weight transitions amplified fox motion into large skin stretch.
  r33 smooths the weights and retains both glTF influence sets (eight total).
  Preserve both on subsequent processing; review performance and deformation
  before reducing to four. Corrections and limits live in reproducible tools.


## 2026-10-12: bounded smoothing can reveal ear-tip spikes

Chihuahua r36 first trial smoothed the whole ear. Tiny irregular tip pieces did
not shrink with the surrounding bowl (including inversion-protected vertices),
so previously subtle spikes became conspicuous. Zero flipped faces is not a
visual acceptance criterion. Fade the smoothing mask out before fragile tips,
compare both profiles in Godot, and retain unresolved tips as explicit work.
Final r36 preserves z >= 0.337 m; max local movement 2.5 mm.


## Chihuahua r38 export and skin — 2026-10-14

- Set fake_user on every retained Blender Action before saving. Unassigned actions can disappear after reopening even when the current scene looks correct.
- Retarget scaled animals with joint translations as well as rotations; rotation-only adaptation left seated front feet floating. Check actual evaluated skin, not just joint coordinates.
- Recompute custom normals after skull edits, averaging coincident physical vertices across UV splits. Otherwise smooth shading can preserve old hard seams.
- Inspect rear and raised-chin poses before accepting a neck patch; a front-view repair can protrude as colored side panels.
- Appended Blender datablocks may retain a library reference to an old checkpoint. Save exports to a distinct filename rather than overwriting that referenced library.
