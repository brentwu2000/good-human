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


func is_success() -> bool:
	return outcome == Outcome.EXTRACTED
