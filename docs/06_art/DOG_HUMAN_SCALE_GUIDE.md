# GOOD HUMAN! — Dog/Human Scale Guide v0.1

Status: `REVIEW`  
Applies to: exploration and encounter staging in the 720×1280 portrait viewport

## Baseline Gameplay Scale

Measurements use the visible character silhouette from the top of the head/ears to the lowest grounded paw/foot. They do not include shadows, selection rings, or overhead markers.

| Element | Baseline height | Allowed exploration range | Notes |
|---|---:|---:|---|
| Human | 210 px | 180–230 px | Owner and ordinary opponent share the same truthful scale range. |
| Player dog | 112 px | 96–124 px | Approximately 53% of the owner's visible height. |
| Small opponent dog | 88 px | 76–100 px | Do not reduce below the mobile readability floor. |
| Large opponent dog | 132 px | 116–146 px | Still visually subordinate to the human silhouette. |

The player dog may receive a 4–6% presentation bias over an equivalent non-player dog. Use outline, contrast, harness color, and animation timing before increasing physical size further.

## 3/4 Top-Down Construction

- Human head-to-body target: about 1:5.5 in the gameplay sprite, with the head slightly enlarged for expression readability.
- Dog head should occupy roughly 30–34% of its visible silhouette height.
- Keep feet and paws visible. Do not let the torso hide all four dog paws in the neutral gameplay angle.
- Ground contact is the authoritative world position: midpoint between human feet; center between the dog's load-bearing paws.
- Character shadows are flattened ellipses, offset no more than 6 px at baseline scale.

## Leash

- Baseline visible width: 6 px at 720×1280; never render below 4 px.
- Use a dark 2 px edge plus a colored inner stroke where the scene is visually busy.
- The leash attaches at the dog's upper-back harness ring and the owner's lowered hand.
- Preferred relaxed screen-space span: 95–175 px. At more than 210 px, communicate tension with a straightened line and character pose before allowing further stretch.
- Preserve a readable curve in relaxed motion. Avoid routing the leash across either character's face.
- The leash is a relationship cue, not a precision simulation; visual continuity has priority over physically exact hand switching.

## Camera and Safe Staging

- Base viewport: 720×1280 portrait.
- Reserve the top 170 px for status/navigation UI and the bottom 190 px for primary actions.
- Keep character faces inside the central action-safe region: x = 64–656 px, y = 190–1030 px.
- Exploration staging target: dog ground point near 62% of viewport height; owner trails 120–190 px behind along the movement axis.
- Maintain at least 48 px between a character silhouette and the left/right screen edge during normal play.
- During encounters, show both dog/human pairs without shrinking the owner below 180 px. Favor diagonal staging and a slight camera pullback.

## Collision and Selection Assumptions

- Collision shapes follow ground footprint, not the full painted silhouette.
- Human navigation footprint: approximately 38×22 px ellipse at baseline scale.
- Dog navigation footprint: approximately 44×24 px ellipse at baseline scale.
- Tap/selection target may expand to at least 64×64 px without changing collision.
- Player identification should remain readable without a selection ring. If a ring is used, place it beneath the shadow and keep it secondary to the teal harness.
- Props may overlap legs below the knee/hock, but must not obscure the player dog's head, teal harness, or owner face during required interactions.

## Readability Checks

Review each production sprite at 100%, 50%, and 33% of the 720×1280 reference frame.

At 33% preview size, testers should still distinguish:

1. player dog versus opponent dog;
2. dog facing direction;
3. owner versus opponent human;
4. relaxed versus taut leash;
5. interactable versus background prop.

The companion visual board is `assets/characters/guides/dog_human_scale_guide_01.svg`.
