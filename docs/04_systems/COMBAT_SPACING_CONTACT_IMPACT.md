# Combat Spacing, Contact & Impact

Each fighter tracks target, desired range, minimum separation, lateral preference, obstacles and dog proximity.

too_far → approach
too_close → backstep/separate
ideal → attack/circle

Dog entering a movement path must not be walked through; adjust path or produce minor contact response without allowing permanent dog body-blocking.

Damage requires: active CONTACT_WINDOW + target hurt volume in reach + attack has not already hit target + defense permits it.

A convincing hit combines attacker follow-through, defender reaction, short hit stop, controlled displacement, impact audio and restrained optional FX/camera impulse.

Prototype hit-stop ranges:
Light ~0.04–0.07s
Heavy ~0.06–0.10s
Tuning only, not locked.

A miss continues through follow-through/recovery and creates an intervention/counter opportunity.
