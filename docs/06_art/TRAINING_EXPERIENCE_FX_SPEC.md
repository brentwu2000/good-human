# GOOD HUMAN! — Training Experience Feedback FX Spec v0.1

Status: REVIEW  
Target: in-world walk HUD, 720 × 1280 portrait

## Purpose

Confirm that a meaningful shared moment happened without exposing TrainingTags, growth points, or a progress meter. The feedback reads as the dog noticing what the owner experienced.

## Presentation

- One charcoal memory card with a warm amber outline.
- A small `✦` moment mark, followed by `主人記住了：` and the event’s player-facing experience text.
- 0.22 second fade-in and gentle 14 px upward settle.
- 2.2 second readable hold, then a 0.28 second fade-out.
- Events queue rather than overlap, so simultaneous social/courage memories remain legible.

## Constraints

- Never display raw TrainingTag names, magnitude, accepted value, or total growth.
- Use one universal visual treatment instead of tag-coded colors.
- Do not interrupt movement, combat, interaction, owner speech, or normal loot toasts.
- Keep the card clear of the top status bar and bottom touch controls.

## Integration

The native Godot UI lives in `ui/hud/run_hud.tscn`. `RunHUD` listens only to the existing `TrainingTracker.event_recorded` presentation signal and does not change training acceptance, balance, or persistence.
