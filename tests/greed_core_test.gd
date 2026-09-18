extends "res://tests/test_case.gd"
## Sprint 05 P4-003 / P4-004: reasons to stay out after going home became
## possible. Checks the data templates and the director's rules without a world
## scene; `golden_path_test` covers the HUD wording in the real walk.

const EXTRACTION_SCENE: PackedScene = preload("res://world/extraction/extraction_point.tscn")
const SEED: int = 4321

var run: RunManager
var director: TemptationDirector
var offers: Array[TemptationData] = []
var expiries: Array[TemptationData] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_templates()
	await _build()
	await _test_nothing_before_going_home_is_possible()
	await _test_offer_needs_something_at_stake()
	await _test_offers_are_not_guaranteed()
	await _test_offer_expires_and_waits()
	_test_cooldown_and_conditions()
	finish()


## P4-004: the five templates the sprint asks for, each answerable by the world.
func _test_templates() -> void:
	var templates := DataRegistry.temptations
	check_eq(templates.size(), 5, "five temptation templates")
	var ids: Array[StringName] = []
	for template in templates:
		ids.append(template.id)
		check(not template.dog_text.is_empty(), "%s speaks in the dog's voice" % template.id)
		check(template.weight > 0.0, "%s can be picked" % template.id)
		check(template.expiry > 0.0, "%s stops standing eventually" % template.id)
		check(template.cooldown >= template.expiry, "%s does not repeat while still standing" % template.id)
	for expected: StringName in [&"banyan_opportunity", &"one_more_search", &"rare_scent_after_extract", &"rival_after_extract", &"special_event_nearby"]:
		check(ids.has(expected), "template %s exists" % expected)


func _build() -> void:
	var point := EXTRACTION_SCENE.instantiate() as ExtractionPoint
	point.extraction_id = &"bus_stop"
	point.unlock_time = 60.0
	add_child(point)
	run = RunManager.new()
	run.auto_start = false
	run.report_to_game = false
	add_child(run)
	director = TemptationDirector.new()
	director.run_manager = run
	# One template that the world can always honour, so the rules are what is
	# under test rather than the scenery.
	director.catalog = [_template(&"always", TemptationData.Needs.NOTHING, 40)]
	add_child(director)
	director.offered.connect(func(t: TemptationData) -> void: offers.append(t))
	director.expired.connect(func(t: TemptationData) -> void: expiries.append(t))
	run.start_run(SEED)
	await _physics(2)


func _test_nothing_before_going_home_is_possible() -> void:
	run.debug_give_item(&"boxing_gloves", 1)
	# Plenty is at stake and the walk is long, but home is still out of reach.
	run.debug_set_time(59.0)
	await _physics(30)
	check(not run.is_past_first_extraction(), "going home is not possible yet")
	check(offers.is_empty(), "nothing is offered before the player could have left")

	# And not the instant it becomes possible either: the choice comes first.
	run.debug_set_time(60.0)
	await _physics(4)
	check(run.is_past_first_extraction(), "going home is possible now")
	check(offers.is_empty(), "no nudge the moment home opens up")


func _test_offer_needs_something_at_stake() -> void:
	# Going home is possible, but the owner is carrying nothing worth staying for.
	run.start_run(SEED)
	run.debug_unlock_all_extractions()
	await _physics(2)
	run.debug_set_time(run.first_extraction_time + TemptationDirector.FIRST_OFFER_DELAY + 1.0)
	await _physics(30)
	check(offers.is_empty(), "an empty-handed walk is not tempted (%d offers)" % offers.size())


func _test_offers_are_not_guaranteed() -> void:
	var tempted := 0
	for i in 20:
		offers.clear()
		run.start_run(SEED + i)
		run.debug_give_item(&"boxing_gloves", 1)
		run.debug_unlock_all_extractions()
		await _physics(2)
		run.debug_set_time(run.first_extraction_time + TemptationDirector.FIRST_OFFER_DELAY + 1.0)
		await _physics(4)
		if not offers.is_empty():
			tempted += 1
	check(tempted > 0, "a walk worth protecting sometimes gets tempted (%d of 20)" % tempted)
	check(tempted < 20, "temptation is not guaranteed every walk (%d of 20)" % tempted)


func _test_offer_expires_and_waits() -> void:
	# Force an offer, then let it stand too long.
	offers.clear()
	expiries.clear()
	var found := false
	for i in 40:
		run.start_run(SEED + 100 + i)
		run.debug_give_item(&"boxing_gloves", 1)
		run.debug_unlock_all_extractions()
		await _physics(2)
		run.debug_set_time(run.first_extraction_time + TemptationDirector.FIRST_OFFER_DELAY + 1.0)
		await _physics(4)
		if not offers.is_empty():
			found = true
			break
	check(found, "an offer can be produced")
	check(director.has_offer(), "the offer stands")
	var standing := offers[-1]
	run.debug_add_time(standing.expiry + 1.0)
	await _physics(4)
	check_eq(expiries.size(), 1, "an ignored offer stops standing")
	check(not director.has_offer(), "and the walk goes quiet again")
	var quiet := offers.size()
	await _physics(4)
	check_eq(offers.size(), quiet, "it does not immediately ask again")


## P4-004: value, flag and world conditions all gate a template.
func _test_cooldown_and_conditions() -> void:
	var rich := _template(&"rich", TemptationData.Needs.NOTHING, 500)
	check(not rich.is_allowed(100, {}), "a template can ask for a real stake")
	check(rich.is_allowed(500, {}), "and allows it once carried")

	var gated := _template(&"gated", TemptationData.Needs.NOTHING, 0)
	gated.requires_flags = [&"rival_revealed"]
	check(not gated.is_allowed(0, {}), "a template can wait for a flag")
	check(gated.is_allowed(0, {&"rival_revealed": true}), "and appears once it is set")

	var retired := _template(&"retired", TemptationData.Needs.NOTHING, 0)
	retired.blocked_by_flags = [&"banyan_owned"]
	check(retired.is_allowed(0, {}), "a template runs until it is done with")
	check(not retired.is_allowed(0, {&"banyan_owned": true}), "and then retires")

	# Territory has no world behind it until P4-005, so it can never be offered.
	var territory := _template(&"territory", TemptationData.Needs.TERRITORY, 0)
	director.catalog = [territory]
	check(not director._world_offers(TemptationData.Needs.TERRITORY, run.run_value()), "territory offers nothing before it exists")


func _template(id: StringName, needs: TemptationData.Needs, min_value: int) -> TemptationData:
	var template := TemptationData.new()
	template.id = id
	template.dog_text = "……"
	template.needs = needs
	template.weight = 1.0
	template.cooldown = 90.0
	template.expiry = 20.0
	template.min_unbanked_value = min_value
	return template


func _physics(frames: int) -> void:
	for i in frames:
		await get_tree().physics_frame
