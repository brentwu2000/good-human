class_name RunResult
extends RefCounted
## Outcome of one walk, built by RunManager and finalized by Game.

## DEFEATED = the human lost a fight (hospital).
enum Outcome { EXTRACTED, FAILED, DEFEATED }

var outcome: Outcome = Outcome.FAILED
var run_seed: int = 0
var elapsed_time: float = 0.0
var extraction_id: StringName = &""
## Opponent display name when DEFEATED.
var defeated_by: String = ""
## Items that go to the Home Stash.
var to_stash: Array[ItemStack] = []
## Items lost with the run (unprotected human inventory on failure).
var lost: Array[ItemStack] = []
## What the run taught the human (new perks filled in by Game).
var training: RunTrainingSummary
## Items that did not fit in the stash (filled in by Game).
var stash_overflow: Array[ItemStack] = []

## --- Run value (Sprint 05 P4-001) ---
## What came home safe in the dog's bag, and what the owner was carrying.
var safe_value: int = 0
var unbanked_value: int = 0
## What the walk actually took away (0 unless the owner's bag was lost).
var lost_value: int = 0
## When going home first became possible, -1 if it never did, and what the
## walk was worth at that moment.
var first_extraction_time: float = -1.0
var value_at_first_extraction: int = 0


## How long the player chose to stay on after they could have gone home.
func seconds_after_extraction() -> float:
	return 0.0 if first_extraction_time < 0.0 else maxf(elapsed_time - first_extraction_time, 0.0)


func is_success() -> bool:
	return outcome == Outcome.EXTRACTED
