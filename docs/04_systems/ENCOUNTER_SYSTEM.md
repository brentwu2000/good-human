# Encounter System v0.1

## Encounter Unit
An encounter is a dog + human pair.

The dog is the social/territorial identity. The human is the autonomous fighter.

## Sprint 02 Choices
- PROVOKE
- LEAVE

Future:
- sniff/social
- intimidate
- flee
- territory-specific interaction

## Opponent Tiers
- Tier 1: ordinary pair
- Tier 2: recognizable combat tendency
- Tier X: early overpowered pair

Sprint 02 content:
- 3 ordinary pairs
- 1 Tier X pair

## Tier X Design
Use a visually misleading pair:
- small/unthreatening dog;
- frail or ordinary-looking older human;
- unexpectedly strong combat behavior.

Do not show a numeric power score that reveals the trick.

The purpose is to teach:
Appearance != Combat Strength.

## Rewards
Victory may award:
- one loot roll;
- small run reward;
- later: reputation/territory/intel.

Keep Sprint 02 rewards simple.

## Architecture
Encounter starts from world interaction but combat should be separable from map logic.

Suggested flow:
World Encounter Trigger
→ Encounter Decision
→ Combat Context
→ Combat Result
→ World/Run Result Handling
