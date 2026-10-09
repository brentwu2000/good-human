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

**2.5 Reactions must not move the head into the attacker.** HitHeavy folding forward and Block leaning in caused overlaps a clamp cannot fix (a constant pose cannot be "held earlier"). Author reactions that move away from the blow.

## 3. Tests that lie

**3.1 Check that the thing still happens, not only that nothing bad happens.** *Symptom:* `fight_body_contact_test` passed while every blow was frozen at the start of its clip. *Cause:* the clamp compared against −0.02 but the depth function never returns below 0, so every pose counted as "inside" and was clamped to t = 0 — no overlap, no fight. *Rule:* every "nothing overlaps / nothing breaks" test also asserts the behaviour is still there (blows are still thrown).

**3.2 Set thresholds from what the bug looks like, not from one good run.** A "blow reaches 0.5" check flaked because blows thrown up close rightly stop at 0.3–0.4. The bug it guards against is t = 0, so the bar is 0.25. Run a randomised test several times before trusting a threshold.

**3.3 Headless numbers can be wrong about the screen.** The headless viewport ignores `root.size`; framing judged from headless numbers was misleading. Judge framing from Movie Maker captures (`tests/capture/record.sh`, portrait 405×720), side views from the `inspect` case.

## 4. Camera and what is drawn over the game

**4.1 A fade rule can hide what the player should see.** The walking camera faded the owner whenever they were nearer than the dog — i.e. always. Fade only at the lens or when actually covering the subject on screen (`_owner_covers_dog`). *Check:* `walk_framing_test`.

**4.2 Portrait screens are narrow.** Horizontal FOV is about 40°; a sideways camera offset of 1 m pushed the owner off screen. Aim between subjects instead of offsetting far.

**4.3 Anything with `no_depth_test` is drawn through bodies.** Sniff-spot names, the desire card and the nose arrow were written across the fighters. In a fight, world labels and HUD hints step aside (`DesireHUD._in_fight`, `SearchPoint3D` label fade). Check captures for text over faces whenever a new label or hint is added.

## 5. Godot and the export

**5.1 Non-resource files are not exported.** `.json` (and other non-imported files) are left out of builds unless listed in each preset's `include_filter` (`export_presets.cfg`). Reading one with `FileAccess` works in the editor and fails in the exe.

**5.2 `pose_clip` at speed 0 never cross-fades** (a held clip's blend never advances). Clip changes are blended by `P04HumanVisual._start_blend` instead.

**5.3 Imported clips drop constant tracks.** A bone a clip does not key keeps whatever was written last; a layer that reads it back as the base accumulates (the pelvis drifted 90–160°). `apply_layers` remembers what it wrote.

## 6. Blender

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

**8.1 Long Python edits through a shell heredoc break on quotes.** Write the patch script to a file (scratchpad) and run it.

**8.2 `str.replace` with an empty "old" text inserts everywhere.** When slicing a file by markers, assert the slice is non-empty before replacing.
