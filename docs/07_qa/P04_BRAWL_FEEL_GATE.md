# P-04 Brawl Feel Gate

Fresh blind QA. Hide HP, damage numbers, combat log, state labels, hitboxes and AI debug. Watch/test a 30–60 second encounter.

Without explanation, identify:
who attacked; hit/miss; light/heavy impact; block/dodge; who is pressured; loss of balance; whether Bark/Pull changed the exchange.

Control:
Dog POV navigable; dog can circle/approach/retreat; no body penetration; auto-framing remains stable.

Critical Fail:
- obvious primary-character penetration
- damage before visible/valid contact
- repeated stationary attack trading
- dodge succeeds without spatial avoidance
- dog permanently jams fighter AI
- camera makes fight unreadable
- combat only understandable with text/debug

PASS → Sprint 05 engineering may proceed.
PASS WITH CHANGES → fix named P0 issues first.
FAIL → continue P-04; do not mask with HUD.
