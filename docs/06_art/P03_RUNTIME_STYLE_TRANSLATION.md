# P-03 Runtime Style Translation v0.1

Status: IN_PROGRESS

Owner decision: in-game presentation should approach the supplied P-03 storyboard style as closely as practical.

## Purpose

Translate cinematic reference images into achievable realtime 3D without reducing the direction to a filter. The target depends on character quality, motion, materials, lighting, camera and sound working together.

## Prototype-to-target gaps

| Area | Current prototype role | Runtime target | First production move |
|---|---|---|---|
| Player dog | warm low-poly silhouette | believable coat, face, ears, paws and harness at near-camera distance | replace body/head with authored realistic base; retain controller and anchors |
| Owner | modular low-poly body | natural anatomy, expressive face/hands, layered contemporary clothing | build one S-candidate owner before expanding modules |
| Opponent human | readable modular variant | same realism standard with ordinary appearance | reuse owner rig/proportions; author identity through face/clothes, not power coding |
| Dogs | breed/color primitives | believable fur mass, gaze and weight | one rival-dog S-candidate for P-03 |
| Combat motion | procedural pose offsets | authored anticipation/contact/recovery with grounded footwork | capture Punch/Kick/Block/Dodge/Hit/Down on production rig |
| Environment | unified low-poly kit | realistic nearby ground, vegetation, street furniture and façades | upgrade the P-03 combat pocket first, not the whole map |
| Materials | flat palette | physically coherent skin, fur, cotton, denim, rubber, metal and pavement | establish material value/roughness sheet under target lighting |
| Lighting | functional daylight | warm natural key, soft fill, contact shadows and restrained atmosphere | author one golden-hour P-03 lighting profile |
| FX | code-native rays/shapes | dust, cloth/fur response and restrained contact accents | keep graphic rays only if physical motion remains primary |
| Crowd reaction | minimal/absent | low-cost witnesses that look, stop or retreat | one nearby NPC plus one animal/environment reaction |

## Vertical-slice boundary

Do not attempt a full-game remaster before proving one encounter. P-03 needs:

- one production-quality player dog;
- one production-quality owner;
- one rival human and dog using the same standard;
- one upgraded park/street combat pocket;
- one golden-hour lighting and grading profile;
- complete tension, combat, crisis, affection and release motion set;
- mobile performance validation at the intended portrait resolution.

Assets outside the camera-visible P-03 pocket may remain prototype quality during this proof.

## Material targets

| Material | Required read | Avoid |
|---|---|---|
| Dog fur | directional clumps, soft rim, compressed contact areas | plastic shell, noisy strand carpet |
| Skin | natural roughness and warm subsurface response | wax, pore-heavy close-up noise |
| Cotton/hoodie | broad soft folds and worn edge response | uniform clay surface |
| Denim | structured folds, seam and restrained weave | bright blue flat fill |
| Shoe rubber | scuffed edge, grounded contact shadow | glossy toy sole |
| Leash webbing | woven roughness, stable teal identity, metal hardware | emissive laser line |
| Pavement | believable scale, grit and subtle variation | repeated tile pattern, mirror-wet surface |

## Lighting target

- Use the storyboard's low warm sun as the primary P-03 benchmark.
- Retain face readability with soft sky fill rather than front-facing game light.
- Contact shadows under shoes and paws are mandatory for weight.
- Rim light separates fur and clothing but cannot become a glowing outline.
- Exposure must hold sky, faces and pavement without aggressive HDR bloom.
- Motion blur is restrained and localized; mobile readability wins over cinematic smear.

## LOD and performance strategy

- Highest quality belongs within the dog-eye combat radius.
- Use simplified hair/fur cards or shell techniques at distance.
- Share human skeletons, skin shaders and clothing material families.
- Use trim sheets and atlases for street assets while preserving believable material scale.
- Background pedestrians use reduced rigs and materials but coherent color and light.
- Measure performance before reducing foreground character silhouette or animation quality.

## Acceptance ladder

### Gate A — still frame

Runtime capture approaches P03-D01 in camera height, human scale, lighting, material separation and leash ownership.

### Gate B — motion

The P03-D02 transition and core combat actions maintain physical weight without text or exaggerated FX.

### Gate C — emotion

CRITICAL, victory affection and defeat approach remain legible through body behavior at mobile size.

### Gate D — performance

The P-03 encounter sustains the project's target mobile frame rate and portrait readability without reverting foreground characters to prototype visuals.

## Status meaning

All existing low-poly 3D deliverables remain useful for gameplay integration but are visually provisional under this decision. They return to production review only when their runtime replacement or upgrade has been compared against the storyboard-derived gates above.
