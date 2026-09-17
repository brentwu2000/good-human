class_name HumanTraits
extends RefCounted
## Visible behaviour values derived from growth (see GrowthResolver.traits).
## Defaults are the untrained human.

## Seconds of being dragged fast before stumbling.
var stumble_after: float = 2.5
## Exertion per second while dragged fast (exhausted at 1.0).
var exertion_gain: float = 0.14
## Seconds catching breath when exhausted.
var recovery_time: float = 2.6
## Seconds hanging back when first nearing an unfamiliar pair.
var hesitation_time: float = 1.4
## Follow speed multiplier while the bag is heavy.
var heavy_bag_speed: float = 0.75
## Says hello to pairs instead of getting nervous.
var greets: bool = false
