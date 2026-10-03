# Complete puppy eye source — 2026-10-03

Author: Codex-directed built-in OpenAI imagegen output for GOOD HUMAN!.
Reference: owner's `good_human_stylized_factory/references/dogs/chihuahua_front.png`.
Selected asset: `puppy_eye_rgba.png`, original generated RGBA output preserved.
No purchased or third-party eye image was used. The source follows the existing
owner-generated character-sheet output-rights convention. The inherited model
and rig licence restrictions remain unchanged.

Intended use: local surface-space UV baking into the seven preview dog atlases.
The source is not rendered as an independent eye mesh. `complete_eye.png` is an
unused earlier iris experiment; only `puppy_eye_rgba.png` is consumed.

Built-in generation prompt:

> Create a single puppy EYE TEXTURE based very closely on the complete left eye of this reference chihuahua. One eye only, centered square image, eye takes 70 percent width. Match its extremely large glossy BLACK pupil, only a very narrow dark caramel crescent visible along the lower edge, thin off-white lower outer rim, subtle black eyelid outline, gentle slightly pear-shaped puppy eye outline. Almost the entire visible eye is black. No large brown iris ring. Tiny soft white catchlight upper left. Eye fully visible and unoccluded; no face, nose, cream muzzle, eyebrow or fur. Uniform neutral tan background around the complete eye. Preserve the appealing stylized reference expression; avoid a perfectly circular staring human iris. Texture viewed straight-on for 3D UV mapping.

Final built-in edit prompt (`transparent_background=true`):

> Remove ONLY the beige background outside the eye, making it fully transparent. Preserve the complete eye exactly: dark upper eyelid outline, white lower sclera rim, iris, pupil, highlights, shape and position. Keep the white crescent INSIDE the eye opaque. Clean antialiased outer edge. Do not redraw or change proportions.

The generated edit changed its framing slightly; the bake measures the final
image at centre (628,617), half-width 523, half-height 462, and uses its alpha.
Projector coordinates are determined on each mesh with ray casts. Original
reference sheets and factory `basecolor.png` files remain untouched.
