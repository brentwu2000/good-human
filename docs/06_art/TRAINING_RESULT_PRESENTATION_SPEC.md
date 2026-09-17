# GOOD HUMAN! — Training Result Presentation Spec v0.1

Status: REVIEW  
Target: 720 × 1280 portrait result screen

## Intent

The result screen should feel like the dog remembering a walk, not a character-stat report. Training remains behavior-led: player-facing copy names lived experiences and newly noticed habits, never raw TrainingTags or numeric growth values.

## Visual hierarchy

1. **Journey outcome** — the strongest type, with elapsed time and outcome context.
2. **Today’s experiences** — warm amber edge; short memories with repeat counts.
3. **New behavior** — gold card shown only when a perk is newly unlocked.
4. **Carried items** — cool blue edge; returned and lost items remain secondary.
5. **Return home** — a large green thumb-zone action.

## Art language

- Background: charcoal blue `#0E1114`.
- Home/safety accent: muted mint `#52A18C`.
- Experience accent: warm amber `#F0B052`.
- New behavior accent: soft gold `#FFD16B`.
- Inventory accent: quiet blue `#78BAE8`.
- Cards use 18–24 px rounded corners and generous internal padding.
- No progress bars, stat arrows, skill-tree nodes, or combat-power color coding.

## Runtime behavior

- Experience card hides when no meaningful training event occurred.
- New behavior card hides unless a perk was newly unlocked.
- Defeat wording communicates partial learning in humane language.
- Long content scrolls while outcome and return-home controls remain stable.

## Integration

- Godot-native `Control` and `StyleBoxFlat` resources live in `ui/run_result/run_result.tscn`.
- Existing `TitleLabel`, `SummaryLabel`, `ItemsLabel`, and `HomeButton` names remain available.
- `ItemsLabel` retains aggregate legacy content invisibly for compatibility; visible content is split into training, perk, and loot labels.
