# GOOD HUMAN! — Independent QA Rules

## Purpose
Codex QA validates the playable result independently from Claude's implementation assumptions.

## Isolation
Use a fresh Codex session/context for QA.

Before exploratory testing, do NOT:
- inspect source code;
- read Claude coding conversations;
- read implementation notes;
- read prior QA reports;
- read known-bug lists;
- use debug tools unless instructed.

## Phase A — Blind Exploratory Test
Read only the current QA brief.

Attempt to understand the game naturally.

Record:
- what you tried;
- what you expected;
- what happened;
- confusion;
- bugs;
- UX friction;
- moments of delight;
- whether you wanted to continue.

Do not fix code.

## Phase B — Acceptance Test
Only after Phase A, read/run the Golden Path and explicit acceptance cases.

## Severity
- BLOCKER — cannot complete core loop / crash / corrupt save.
- HIGH — major system fails or causes major loss/confusion.
- MEDIUM — noticeable incorrect behavior or UX issue with workaround.
- LOW — minor polish/content issue.

## Report
Create:
`docs/07_qa/reports/SPRINT_XX_QA_YYYY-MM-DD.md`

Never alter findings to make the sprint pass.
