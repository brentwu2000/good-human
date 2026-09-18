# D4-12 — Combat Snap Storyboard v0.1

Status: REVIEW

Visual board: `assets/_source/design/dog_agency/combat_snap_storyboard_01.svg`

## Intent

Combat begins as a change in the relationship already moving through the Run World. It is not announced by a card, teleport, control lock or hard camera cut. The snap is a readable 1.0–1.4 second escalation from walking to first contact while the dog remains controllable.

## Six-beat sequence

| Beat | Target time | Camera | Dog / leash | Humans | Sound / FX handoff |
|---|---:|---|---|---|---|
| 1. Walk | 0.00 s | Explore framing follows dog | Dog leads; leash has a soft sag | Owner follows; opponent pair remains environmental | Normal ambience |
| 2. Notice | 0.18 s | Enter TENSION; no zoom jump | Dog ears/head orient first; leash begins to lift | Owner looks across; opponent squares up | Optional short dog-local attention cue |
| 3. Tension | 0.40 s | Soft focus weight moves toward owner | Dog may still steer; leash curve shallows | Owner plants the trailing foot; opponent closes one step | Ambience may duck subtly; no title card |
| 4. Tighten | 0.62 s | Push inward begins, preserving feet | Leash becomes near-straight; teal line is the relationship axis | Owner torso turns; guard is incomplete, not a posed idle | Clothing/foot shuffle carries anticipation |
| 5. Commit | 0.88 s | ACTIVE composition settles before impact | Dog stays foreground/edge; leash avoids impact point | Striker commits; defender braces or starts response | Attack motion cue begins; no hit FX early |
| 6. Contact | 1.08 s | Frame already contains both torsos | Dog and leash remain readable | First landed strike reaches its strongest contact silhouette | Hitstop, graded shake, knockback and coral hit rays begin on contact |

Times are presentation targets. Combat simulation remains authoritative for when an engagement and hit occur.

## Continuous-control rule

- Dog movement input remains live through every beat.
- The camera interpolates toward the combat framing; it never captures or steers the dog.
- If the dog pulls away during beats 2–5, preserve the tension composition only while the encounter remains valid. Disengagement wins over completing the storyboard.
- Bark or Pull may alter human/dog reaction after the engagement begins, but cannot delay the first simulated action solely to complete a visual pose.

## Silhouette progression

The sequence must read without text or color:

1. three independent vertical masses;
2. dog head turns and two human sightlines connect;
3. owner weight shifts backward;
4. leash straightens into a diagonal and owner rotates;
5. human silhouettes overlap along one striking limb;
6. contact pose forms a clear compression point, followed by separation.

The first strike must not start from two neutral puppets sliding together. Feet plant before torso rotation; shoulder/hip lead the striking limb; the receiver compresses at contact before knockback.

## Camera and screen-space rules

- The owner reaches the D4-11 focus region by beat 5, before hitstop can expose poor framing.
- Total push-in is modest: approximately 5–10% tighter than Explore, distributed across beats 2–5.
- Use soft focus/dead-zone. Dog strafing produces composition drift, not immediate camera reversal.
- Preserve both human feet through beat 6 so balance, recoil and knockback are legible.
- Opponent dog moves to the outer middle edge by beat 4 and reacts after notice; it cannot cross the player leash side.
- Nearby props remain visible enough to confirm the Run World continues, but lose contrast behind the contact point.

## Leash choreography

| Beat | Shape | Meaning |
|---|---|---|
| Walk | broad sag | ordinary follow |
| Notice | sag lifts near owner hand | attention changes |
| Tension | shallow curve | owner slows while dog still leads |
| Tighten | near-straight diagonal | relationship pressure becomes visible |
| Commit | stable diagonal outside torso overlap | dog remains causal and controllable |
| Contact | brief vibration/recoil only if existing owner motion drives it | impact happened to the connected human |

Do not animate an independent leash shockwave. The line responds to its anchors and the owner's physical reaction.

## Impact handoff

Beat 6 is the bridge to the landed-hit presentation already implemented:

- hitstop begins only after the contact silhouette is formed;
- shake begins with the hit, not during the approach;
- knockback magnitude differentiates light and heavy attacks after compression;
- coral hit rays originate at torso contact and expand once;
- a miss or dodge passes through beat 5 into separation without hitstop or coral rays.

## Abort and edge cases

- **Dog circles behind opponent:** hold a wider TENSION frame, cross the angular dead-zone, then settle; never whip-pan to finish on schedule.
- **Wall occlusion:** fade/reframe geometry before increasing push-in.
- **Owner already close to opponent:** compress beats 2–4 in time but retain Notice and Commit silhouettes.
- **First action is a block:** contact uses teal block rays and reduced shake; sequence timing remains.
- **Dog disengages before contact:** blend back to Explore and relax the leash; no false hit cue.
- **Simultaneous interactable:** keep its world cue, but combat focus cannot place a modal prompt over the owner.

## Mobile acceptance

At 405×720:

- the transition reads as escalation without text;
- the dog remains visible in all six frames;
- the leash change from sag to near-straight is visible before contact;
- both human feet and the striking limb remain readable at beat 6;
- no HUD control covers the dog's head, owner torso or contact point;
- no frame resembles a loading transition, battle arena or cinematic cutscene.

## Runtime review markers

D4-17 captures should measure these checkpoints:

- TENSION context starts by the first mutual human reaction;
- owner enters the focus region before the first landed hit;
- ACTIVE does not hard-snap on context change;
- the leash is visible in at least four of the six equivalent moments;
- first-hit FX do not begin before physical contact;
- an early disengage returns cleanly to Explore without completing the snap.
