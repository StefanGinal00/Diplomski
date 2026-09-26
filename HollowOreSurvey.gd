extends Node2D

# Optional first-visit exploration, using existing interactions and lamp-save
# flags. It never replaces the relay, guardian cache or awakened trial.
const MARKER := preload("res://SluiceValve.tscn")
const CACHE := preload("res://ResonanceCache.tscn")
const EVENTS := ["shaft_hollow_survey_ore", "shaft_hollow_survey_haul", "shaft_hollow_survey_seep"]
const REWARD_ID := "shaft_hollow_survey_reserve"
const TITLES := ["HIGH ORE SAMPLE", "OLD HAULAGE SAMPLE", "LOWER SEEP SAMPLE"]
var expansion: Node2D
var board: Label


func _ready() -> void:
	var route: Node2D = expansion.generated
	var points := [
		route.get_node("Niche1_Crest").position + Vector2(60, -34),
		route.get_node("Branch3_Chamber").position + Vector2(150, -34),
		expansion._floor_point(6, 3000, 34),
	]
	for index in range(3):
		var marker := MARKER.instantiate() as Area2D
		marker.name = "Sample%d" % index
		marker.position = to_local(route.to_global(points[index]))
		marker.set("shortcut_id", EVENTS[index])
		marker.set("inactive_label", TITLES[index])
		marker.set("active_label", TITLES[index] + " - RECORDED")
		marker.set("inactive_prompt", "[E] RECORD ORE SAMPLE")
		marker.set("active_prompt", "SAMPLE RECORDED")
		add_child(marker)
		marker.get_node("Core").polygon = PackedVector2Array([Vector2(0, -20), Vector2(13, -6), Vector2(7, 14), Vector2(-7, 14), Vector2(-13, -6)])
		for label_name in ["StatusLabel", "InteractionPrompt"]:
			var label := marker.get_node(label_name) as Label
			label.position.x = -160
			label.size.x = 320
	var camp_at := to_local(route.get_node("Branch1_Chamber").global_position)
	var reward := CACHE.instantiate() as Area2D
	reward.name = "SurveyReward"
	reward.position = camp_at + Vector2(165, -36)
	reward.set("cache_id", REWARD_ID)
	reward.set("cache_name", "Surveyor's Supplies")
	reward.set("gold_reward", 18)
	reward.set("reward_item_id", "iron_fragment")
	reward.set("required_event_ids", PackedStringArray(EVENTS))
	add_child(reward)
	# Keep the chest prompt below the survey board, including the font's
	# minimum line height (which can exceed the requested Label height).
	reward.get_node("Prompt").position.y = -30
	board = Label.new()
	board.name = "SurveyBoard"
	board.position = camp_at + Vector2(-180, -98)
	board.size = Vector2(350, 18)
	board.add_theme_font_size_override("font_size", 10)
	board.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06))
	board.add_theme_constant_override("outline_size", 3)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(board)
	var state := get_node("/root/GameState")
	state.shortcut_changed.connect(_on_event)
	state.cache_opened.connect(_on_cache)
	_refresh()


func recorded_count() -> int:
	var state := get_node("/root/GameState")
	var count := 0
	for event_id in EVENTS:
		count += int(bool(state.unlocked_shortcuts.get(event_id, false)))
	return count


func get_guide_line() -> String:
	var state := get_node("/root/GameState")
	if state.opened_caches.get(REWARD_ID, false):
		return "Your ore survey is recorded and the supplies are yours. Save at a lamp to keep the findings."
	if recorded_count() == 3:
		return "All three samples are recorded. Collect the survey supplies beside my shelter; the return lift shortens the way back."
	var missing: Array[String] = []
	var places := ["the upper ore alcove", "the side haulage chamber", "the lowest seep gallery"]
	for index in range(3):
		if not state.unlocked_shortcuts.get(EVENTS[index], false):
			missing.append(places[index])
	return "Ore survey %d/3: record samples in %s. My supply chest opens when all three are recorded; this is separate from the relay." % [recorded_count(), ", ".join(missing)]


func _on_event(event_id: String) -> void:
	if EVENTS.has(event_id):
		_refresh()


func _on_cache(cache_id: String) -> void:
	if cache_id == REWARD_ID:
		_refresh()
		get_parent()._refresh_dialogue()


func _refresh() -> void:
	var state := get_node("/root/GameState")
	board.text = "ORE SURVEY - SUPPLIES CLAIMED" if state.opened_caches.get(REWARD_ID, false) else ("ORE SURVEY 3/3 - SUPPLIES READY" if recorded_count() == 3 else "OPTIONAL ORE SURVEY %d/3" % recorded_count())
