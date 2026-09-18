# Sprint 05 — Risk HUD v0.1

Status: REVIEW
Deliverable: D5-05

## Selected direction

Use one quiet dog-tag-shaped line below the existing top bar. It appears only when the walk has something meaningful to say about risk.

- Before extraction: `主人帶著 $X · 倒下會失去` once unbanked value is notable.
- After extraction: `回家就安全 · 主人還帶著 $X`.
- Full bag: append `袋子已滿`, or show `主人的袋子裝滿了` when there is no other risk phrase.
- Heavy unbanked value warms the text from soft cream/green to amber.

The bag button remains the detailed inventory entry and continues to show owner-carried and dog-safe value.

## Visual rules

- Dark translucent tag with a narrow teal left edge; no red danger frame.
- Maximum two short lines at 720 px reference width.
- No risk percentage, loss meter, extraction-shooter bar, lethal-zone language or countdown.
- Empty-handed walks show nothing.
- The HUD states the consequence but never tells the player to leave.

## Runtime contract

Presentation reads `RunManager.value_changed`, `RunValue`, bag fullness and `is_past_first_extraction()`. It does not move loot, unlock exits, calculate loss or mutate run state.
