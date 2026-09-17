class_name HumanTraits
extends RefCounted
## Visible behaviour values derived from growth (see GrowthResolver.traits).
## Defaults are the untrained human.

## Seconds of being dragged fast before stumbling.
var stumble_after: float = 3.0
## Exertion per second while dragged fast (exhausted at 1.0).
var exertion_gain: float = 0.1
## Seconds catching breath when exhausted.
var recovery_time: float = 1.2
## Seconds hanging back when first nearing an unfamiliar pair.
var hesitation_time: float = 0.6
## Follow speed multiplier while the bag is heavy.
var heavy_bag_speed: float = 0.85
## Says hello to pairs instead of getting nervous.
var greets: bool = false
