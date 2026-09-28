# Human Combat Motion v0.1
An attack is an event, not a forward-lean pose.

Every attack uses WINDUP → STRIKE → CONTACT_WINDOW → FOLLOW_THROUGH → RECOVERY.

JAB: fast, compact, short recovery.
HEAVY_HOOK: visible shoulder/hip rotation, readable windup, meaningful defender rotation/displacement.
KICK: longer commitment/range, leg visibly lifts/extends, stronger recovery.
BLOCK: visible guard plus contact response.
DODGE: actual spatial/body displacement must clear the strike.
REACTIONS: HIT_LIGHT, HIT_HEAVY, STUMBLE, DOWN.

Footwork has higher priority than adding moves: approach, circle, sidestep, backstep, re-engage.

Prototype animation may be simple/procedural, but silhouette must read at mobile size and gameplay collision must agree with motion.

Future hook only: combat_style = UNTRAINED / SCRAPPER / CALM.

## Carried over from P-03 (still in force)
Merged on install of Update 006 Patch 03. Hit presentation and hit-stop ranges now live in `COMBAT_SPACING_CONTACT_IMPACT.md`.

### Why motion matters
Damage events without physical motion cannot validate combat camera, dog intervention or atmosphere.

### Spacing
Humans must not stand fixed and exchange HP. Combat AI cycles through approach, angle/circle, attack/defense, reaction and spacing reset.

### Dog Agency Dependency
Heavy/meaningful attacks need readable windup so the dog can react with Bark or Leash Pull. If the player cannot visually anticipate an attack, intervention design fails.

### Timings
Exact timings are data-driven (`docs/05_data/P04_COMBAT_TUNING_SCHEMA.md`). Attacks must telegraph clearly on a mobile-sized screen.

### Debug
Combat log is debug-only. Normal prototype must remain understandable with combat text hidden.
