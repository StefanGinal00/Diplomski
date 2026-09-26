extends Node2D

# These sites use the existing walkable side chambers. Their completed events
# and rewards belong to the ordinary lamp snapshot, including death rollback.
const RESIDENT := preload("res://TownResident.tscn")
const CACHE := preload("res://ResonanceCache.tscn")
const ENCOUNTER := preload("res://LocalizedEncounter.tscn")
const CRAWLER := preload("res://ShaftCrawler.tscn")
const WISP := preload("res://ShaftWisp.tscn")
const SENTRY := preload("res://ShaftSentry.tscn")
const ORE_SURVEY := preload("res://HollowOreSurvey.gd")
const SITES := {
	"hollow": {
		"resident": "Deren, Ore Surveyor", "camp": "SURVEYOR'S SHELTER",
		"lines": ["The timber frames mark unstable ceilings. Watch for falling stone before crossing beneath them.", "Climb into the high ore alcove deeper in the Hollow. Its supply chest unseals when its two guardians fall.", "The lowest side cutting has gone quiet. If the Warden falls, return there: something is still stirring beneath the ore."],
		"trial": "THE STIRRING ORE FACE", "reward": "Recovered Ore Reserve", "item": "iron_fragment", "foes": [CRAWLER, CRAWLER],
	},
	"crossing": {
		"resident": "Nera, Water Scout", "camp": "DRY AQUEDUCT CAMP",
		"lines": ["The raised ledges keep you above the current. Find the sluice valve and the main crossing will become calmer.", "There is a guarded supply alcove above the deeper channel. Clear its guardians before opening the chest.", "After the Warden falls, inspect the lowest side channel again. The old sediment attracts restless lights."],
		"trial": "LIGHTS IN THE SEDIMENT", "reward": "Aqueduct Salvage", "item": "ether_dust", "foes": [WISP, WISP],
	},
	"gallery": {
		"resident": "Pell, Pipe Tender", "camp": "PIPE TENDER'S REST",
		"lines": ["The lower and upper controls quiet different pressure jets. Turn both to open the way toward the Warden.", "Take the climb to the hidden supply alcove. Its seal is tied to the guardians waiting there.", "The lowest maintenance branch holds a dormant inspection crew. Check it again after the Warden falls."],
		"trial": "THE LAST INSPECTION", "reward": "Maintenance Reserve", "item": "healing_herb", "foes": [SENTRY, CRAWLER],
	},
	"cistern": {
		"resident": "Sela, Gauge Keeper", "camp": "GAUGE KEEPER'S REFUGE",
		"lines": ["The pump remembers the order: near, high, then far. An incorrect dial only resets the unfinished sequence.", "A supply cache waits in the high side alcove. Defeat both guardians there to release its seal.", "Return to the lowest overflow branch after the Warden falls. The pressure cells are not the only things that can wake."],
		"trial": "OVERFLOW WATCH", "reward": "Pressure Cell Reserve", "item": "ether_dust", "foes": [WISP, SENTRY],
	},
	"approach": {
		"resident": "Bram, Retired Watchman", "camp": "WATCHMAN'S SHELTER",
		"lines": ["Use the low cover against sentries. The far counterweight lowers a bridge for your return.", "Before the arena, climb into the guarded supply alcove. Its chest opens once both guardians are defeated.", "The lowest watch branch will stir after the Warden falls. Its remaining sentries guard a separate reserve."],
		"trial": "THE SILENT WATCH", "reward": "Watch Reserve", "item": "iron_fragment", "foes": [SENTRY, SENTRY],
	},
}

var expansion: Node2D


func _ready() -> void:
	var id := String(expansion.plan["id"])
	var data: Dictionary = SITES[id]
	var route: Node2D = expansion.generated
	var camp := route.get_node("Branch1_Chamber") as Node2D
	var camp_at := to_local(camp.global_position)
	for index in range(2):
		var stop := Marker2D.new()
		stop.name = "CampStop%d" % index
		stop.position = camp_at + Vector2(-55 + index * 65, -26)
		add_child(stop)
	var resident := RESIDENT.instantiate() as Area2D
	resident.name = "FieldResident"
	resident.position = get_node("CampStop0").position
	resident.set("resident_name", data["resident"])
	resident.set("dialogue_lines", PackedStringArray(data["lines"]))
	resident.set("route_marker_names", PackedStringArray(["CampStop0", "CampStop1"]))
	resident.set("coat_color", expansion.plan["tone"])
	add_child(resident)
	resident.get_node("NameLabel").position.x = -130.0
	resident.get_node("NameLabel").size.x = 260.0
	var sign := Label.new()
	sign.name = "CampSign"
	sign.position = camp_at + Vector2(-190, -125)
	sign.size.x = 380
	sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign.text = data["camp"]
	sign.add_theme_font_size_override("font_size", 11)
	add_child(sign)
	# The generic branch label occupies the same line as this camp's name.
	# Keep one readable heading instead of drawing both over each other.
	route.get_node("Branch1_Label").hide()
	# A small tent and warm lamp make the quiet detour recognizable at a glance.
	var tent := Polygon2D.new()
	tent.name = "SurveyTent"
	tent.position = camp_at + Vector2(-30, -9)
	tent.z_index = -1
	tent.color = Color(0.22, 0.37, 0.37)
	tent.polygon = PackedVector2Array([Vector2(-65, 0), Vector2(-5, -86), Vector2(70, 0), Vector2(30, 0), Vector2(0, -43), Vector2(-23, 0)])
	add_child(tent)
	var lantern := Polygon2D.new()
	lantern.position = camp_at + Vector2(72, -28)
	lantern.color = Color(1.0, 0.77, 0.35)
	lantern.polygon = PackedVector2Array([Vector2(-5, -8), Vector2(5, -8), Vector2(5, 8), Vector2(-5, 8)])
	add_child(lantern)
	var return_branch := route.get_node("Branch5_Chamber") as Node2D
	var trial := ENCOUNTER.instantiate() as Area2D
	trial.name = "AwakenedTrial"
	trial.position = to_local(return_branch.global_position)
	trial.set("encounter_id", "shaft_%s_return_trial" % id)
	trial.set("completion_event_id", "shaft_%s_return_trial_cleared" % id)
	trial.set("minimum_zone_tier", 1)
	trial.set("encounter_title", data["trial"])
	var foes: Array = data["foes"]
	for index in range(foes.size()):
		trial.get("enemy_scenes").append(foes[index])
		trial.get("spawn_offsets").append(Vector2(-70 + index * 160, -95 if foes[index] == WISP else -31))
	add_child(trial)
	var reward := CACHE.instantiate() as Area2D
	reward.name = "AwakenedTrialReward"
	reward.position = trial.position + Vector2(-155, -36)
	reward.set("cache_id", "shaft_%s_trial_reserve" % id)
	reward.set("cache_name", data["reward"])
	reward.set("gold_reward", 15)
	reward.set("reward_item_id", data["item"])
	reward.set("required_event_ids", PackedStringArray([trial.get("completion_event_id")]))
	add_child(reward)
	if id == "hollow":
		var survey := Node2D.new()
		survey.name = "OreSurvey"
		survey.set_script(ORE_SURVEY)
		survey.set("expansion", expansion)
		add_child(survey)
	var state := get_node_or_null("/root/GameState")
	if state != null:
		state.zone_tier_changed.connect(_on_zone_tier_changed)
		state.shortcut_changed.connect(_on_progress_changed)
		state.cache_opened.connect(_on_cache_opened)
	if id == "cistern":
		expansion.get_parent().sequence_changed.connect(_refresh_dialogue)
	_refresh_dialogue()


func _on_zone_tier_changed(zone: String, _tier: int) -> void:
	if zone == "sunken_shaft":
		_refresh_dialogue()


func _on_progress_changed(event_id: String) -> void:
	var id := String(expansion.plan["id"])
	if event_id.begins_with("shaft_%s_" % id) or (id == "crossing" and event_id == "shaft_sluice_valve"):
		_refresh_dialogue()


func _on_cache_opened(cache_id: String) -> void:
	var id := String(expansion.plan["id"])
	if cache_id in ["shaft_%s_depth_cache" % id, "shaft_%s_trial_reserve" % id]:
		_refresh_site_labels()


func _refresh_site_labels() -> void:
	var state := get_node_or_null("/root/GameState")
	if state == null:
		return
	var id := String(expansion.plan["id"])
	var route: Node2D = expansion.generated
	for return_site in [false, true]:
		var label := route.get_node("Branch5_Label" if return_site else "Niche4_Label") as Label
		var floor_node := route.get_node("Branch5_Chamber" if return_site else "Niche4_Crest") as Node2D
		var event_id := "shaft_%s_%s" % [id, "return_trial_cleared" if return_site else "hidden_depth_cleared"]
		var cache_id := "shaft_%s_%s" % [id, "trial_reserve" if return_site else "depth_cache"]
		var collected := bool(state.opened_caches.get(cache_id, false))
		var cleared := bool(state.unlocked_shortcuts.get(event_id, false))
		var dormant: bool = return_site and state.get_zone_tier("sunken_shaft") < 1
		var status := "CLAIMED" if collected else ("CACHE UNSEALED" if cleared else ("RETURN AFTER THE WARDEN" if dormant else "DEFEAT BOTH GUARDIANS"))
		# The encounter already owns the title/remaining-enemy count above.
		# This single status line fits below it and above the cache prompt.
		label.text = status
		label.position = floor_node.position + Vector2(-170, -109)
		label.size = Vector2(340, 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.z_index = 3
		label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 1))
		label.add_theme_constant_override("outline_size", 3)
		label.add_theme_color_override("font_color", Color(0.58, 0.73, 0.74) if collected or dormant else (Color(0.55, 1.0, 0.73) if cleared else Color(1.0, 0.8, 0.45)))


func _refresh_dialogue() -> void:
	var state := get_node_or_null("/root/GameState")
	if state == null:
		return
	_refresh_site_labels()
	var data: Dictionary = SITES[String(expansion.plan["id"])]
	var lines := PackedStringArray(data["lines"])
	var trial := get_node("AwakenedTrial")
	if bool(state.unlocked_shortcuts.get(trial.get("completion_event_id"), false)):
		lines = PackedStringArray(["The lowest branch is quiet again. The reserve is yours. Rest at a lamp to keep what you recovered.", String(data["lines"][0])])
	elif state.get_zone_tier("sunken_shaft") >= 1:
		lines = PackedStringArray(["The Warden has fallen, and the lowest side branch has awakened. Defeat its two guardians to unseal the reserve.", String(data["lines"][0]), "The return lift can shorten the journey once you activate it from below."])
	var id := String(expansion.plan["id"])
	if id in ["hollow", "crossing", "gallery", "cistern", "approach"]:
		var main_done := bool(state.unlocked_shortcuts.get("shaft_hollow_relay" if id == "hollow" else "shaft_sluice_valve", false))
		var main_advice := ("The Hollow relay is active: its lower room links are open." if main_done else "Defeat the two original Hollow guardian wisps, then activate the relay to open the lower links.") if id == "hollow" else ("The sluice is drained. Its currents are calmed, but enemies and other hazards still remain." if main_done else "The sluice valve calms the aqueduct currents. Raised bypasses let you cross before draining it.")
		if id == "gallery":
			var lower := bool(state.unlocked_shortcuts.get("shaft_gallery_lower", false))
			var upper := bool(state.unlocked_shortcuts.get("shaft_gallery_upper", false))
			main_advice = "Both pressure banks are calmed. The Warden shortcut is open." if lower and upper else ("The lower bank is calmed. Find the upper control to open the Warden shortcut." if lower else ("The upper bank is calmed. Find the lower control to open the Warden shortcut." if upper else "Two controls quiet different pressure banks. Turn both to open the Warden shortcut."))
		elif id == "cistern":
			var pump := bool(state.unlocked_shortcuts.get("shaft_cistern_pump", false))
			var progress: int = expansion.get_parent().puzzle_progress
			main_advice = "The pump is running: pressure cells are calmed and the Gallery passage is open." if pump else "Pump order: near, high, far. You have set %d/3 dials; an unfinished sequence is not kept when loading a save." % progress
		elif id == "approach":
			main_advice = "The original return bridge is lowered. Sentries and the Warden are still separate dangers." if state.unlocked_shortcuts.get("shaft_approach_bridge", false) else "Climb the gantry and find the far counterweight crank. It lowers the original return bridge, not the Warden's defences."
		# Preserve awakened/cleared-trial advice, while also explaining the
		# independent main mechanism and the first-clear guardian reserve.
		if state.get_zone_tier("sunken_shaft") == 0:
			lines[0] = main_advice
			if state.unlocked_shortcuts.get("shaft_%s_hidden_depth_cleared" % id, false):
				lines[1] = "Both high-niche guardians are defeated. Their separate cache is unsealed; it does not replace the room's main mechanism."
		else:
			lines[1] = main_advice
	var resident := get_node("FieldResident")
	if id == "hollow" and has_node("OreSurvey"):
		lines.append(get_node("OreSurvey").get_guide_line())
	resident.set("dialogue_lines", lines)
	resident.set("next_line_index", 0)
