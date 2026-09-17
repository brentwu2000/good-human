# GOOD HUMAN! — Dog Desire Visual Spec v0.1

Status: REVIEW  
Target: 720 × 1280 portrait gameplay

## Intent

Desires are a glimpse of what catches the dog’s attention. They are optional, emotional, and incomplete—not orders from a quest system.

## Language

- Header wording: `狗狗現在想……`, never `任務`, `目標清單`, or `進度`.
- Main text is first-person dog desire copy supplied by goal data.
- A secondary hint may name a smell, place, object, or remembered encounter.
- No checkbox, completion counter, XP bar, rarity frame, or reward preview.
- Persistent threads use the same card; continuity comes from copy and icon, not a larger “epic quest” frame.

## Palette

- Thought surface: charcoal teal `#182323`.
- Curiosity: warm amber `#F2B456`.
- Scent trail: mint `#72C7AF`.
- Memory/thread: dusty violet `#A999CC`.
- Text: warm white `#F5F0DF`.

## Icon grammar

Icons use a 64 × 64 viewBox, rounded strokes, no text, and one dominant symbol. Amber denotes attention; mint denotes a trail or discoverable direction. Icons remain readable at 32 px.

## Runtime components

- `ui/desire/desire_card.tscn`: top-area primary desire card with icon, dog-thought label, main desire, and optional hint.
- `ui/desire/world_scent_cue.tscn`: non-interactive in-world scent marker with a looping breathe animation.
- Category icons live in `assets/ui/desires/` and import natively as SVG textures.
- `ui/goals/desire_hud.tscn` now mounts `DesireCard` for the active dog thought; its legacy text label stays hidden as a compatibility/debug mirror.

## Safe-area rules

- Desire card sits below the timer/bag bar and above existing toast space.
- Expanded copy should wrap within 520 px and stay under three lines.
- World cues must never resemble interaction buttons or combat targeting markers.
