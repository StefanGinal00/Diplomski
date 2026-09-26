extends Node

signal quest_updated
signal quest_item_collected(item_id: String, progress: int)
signal return_contract_completed(zone_id: String)

enum QuestState {
	NOT_STARTED,
	ACTIVE,
	READY_TO_TURN_IN,
	COMPLETED,
}

const QUEST_CLEAR_PASSAGE := 0
const QUEST_LOST_SIGIL := 1
const QUEST_AWAKENED_WARDEN := 2
const CLEAR_PASSAGE_TARGET := 3
const LOST_SIGIL_ID := "old_passage_sigil"
const ECHO_TRACE_IDS := ["echo_trace_gallery", "echo_trace_archive", "echo_trace_well"]
const STARFALL_REPORT_IDS := ["starfall_report_watch", "starfall_report_market", "starfall_report_garden"]
const STARFALL_COURIER_LAMPS := ["echo_haven_lamp", "ash_hearth_lamp"]
const DAWN_ARCHIVE_ECHOES := ["shaft", "echo", "ash"]
const RETURN_CONTRACTS := {
	"sunken_shaft": {"name": "Shaft Vigil", "kills": 3, "caches": ["shaft_rim", "shaft_depth", "hollow_resonance", "crossing_dregs", "gallery_afterglow", "cistern_echo", "approach_afterglow"], "cache_goal": 1, "xp": 2, "gold": 70, "item": "iron_fragment", "item_count": 2},
	"echo_grotto": {"name": "Resonance Sweep", "kills": 4, "caches": ["grotto_high", "gallery_step", "archive_shelf", "tide_depth", "nest_cocoon", "sanctum_heart", "causeway_afterglow", "vault_undertow"], "cache_goal": 2, "xp": 3, "gold": 100, "item": "ether_dust", "item_count": 2},
	"ashen_bastion": {"name": "Ember Reckoning", "kills": 4, "caches": ["causeway_embers", "forge_cinders", "barracks_embers", "arena_cinders", "reservoir_embers", "chapel_cinders"], "cache_goal": 2, "xp": 4, "gold": 130, "item": "iron_fragment", "item_count": 2},
}

var quest_index: int = QUEST_CLEAR_PASSAGE
var quest_state: QuestState = QuestState.NOT_STARTED
var quest_progress: int = 0
var defeated_enemies: int = 0
var lost_sigil_found: bool = false
var echo_survey_state: QuestState = QuestState.NOT_STARTED
var hearth_fan_state: QuestState = QuestState.NOT_STARTED
var hearth_gate_state: QuestState = QuestState.NOT_STARTED
var hearth_gate_defeated: Dictionary = {}
var starfall_route_state: QuestState = QuestState.NOT_STARTED
var starfall_reports: Dictionary = {}
var starfall_courier_state: QuestState = QuestState.NOT_STARTED
var starfall_courier_stops: Dictionary = {}
var dawn_archive_state: QuestState = QuestState.NOT_STARTED
var dawn_archive_records: Dictionary = {}
var echo_traces: Dictionary = {}
var return_contract_kills: Dictionary = {}
var return_contract_done: Dictionary = {}


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.apply_to_quest(self)
		game_state.boss_progress_changed.connect(_on_boss_progress_changed)
		game_state.zone_tier_changed.connect(_on_return_zone_tier_changed)
		game_state.cache_opened.connect(_on_return_cache_opened)
		game_state.shortcut_changed.connect(_on_hearth_shortcut_changed)
		game_state.checkpoint_resting.connect(_on_checkpoint_resting)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		_connect_return_enemy(enemy)
		_connect_hearth_gate_enemy(enemy)
	get_tree().node_added.connect(_connect_return_enemy)
	get_tree().node_added.connect(_connect_hearth_gate_enemy)


func _connect_return_enemy(node: Node) -> void:
	if not node.is_in_group("enemy") or node.is_in_group("boss") or not node.has_signal("defeated"):
		return
	if not RETURN_CONTRACTS.has(str(node.get("zone_id"))):
		return
	var callback := Callable(self, "_on_return_enemy_defeated").bind(node)
	if not node.is_connected("defeated", callback):
		node.connect("defeated", callback)


func _connect_hearth_gate_enemy(node: Node) -> void:
	if not node.is_in_group("hearth_gate_target") or not node.has_signal("defeated"):
		return
	var callback := Callable(self, "_on_hearth_gate_target_defeated").bind(node)
	if not node.is_connected("defeated", callback):
		node.connect("defeated", callback)


func _on_hearth_gate_target_defeated(enemy: Node) -> void:
	var target_id := str(enemy.name)
	if bool(hearth_gate_defeated.get(target_id, false)):
		return
	hearth_gate_defeated[target_id] = true
	if hearth_gate_state == QuestState.ACTIVE and get_hearth_gate_progress() >= 2:
		hearth_gate_state = QuestState.READY_TO_TURN_IN
	quest_updated.emit()


func _on_return_enemy_defeated(enemy: Node) -> void:
	var zone_id := str(enemy.get("zone_id"))
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or not RETURN_CONTRACTS.has(zone_id) or game_state.get_zone_tier(zone_id) < 1 or bool(return_contract_done.get(zone_id, false)):
		return
	var contract: Dictionary = RETURN_CONTRACTS[zone_id]
	return_contract_kills[zone_id] = mini(int(return_contract_kills.get(zone_id, 0)) + 1, int(contract["kills"]))
	_check_return_contract_completed(zone_id)
	quest_updated.emit()


func _on_return_zone_tier_changed(zone_id: String, tier: int) -> void:
	if RETURN_CONTRACTS.has(zone_id) and tier >= 1:
		quest_updated.emit()


func _on_return_cache_opened(cache_id: String) -> void:
	for zone_id in RETURN_CONTRACTS:
		var contract: Dictionary = RETURN_CONTRACTS[zone_id]
		if not contract["caches"].has(cache_id):
			continue
		_check_return_contract_completed(str(zone_id))
		quest_updated.emit()
		return


func _get_return_cache_count(zone_id: String) -> int:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or not RETURN_CONTRACTS.has(zone_id):
		return 0
	var count := 0
	var contract: Dictionary = RETURN_CONTRACTS[zone_id]
	for cache_id in contract["caches"]:
		if bool(game_state.opened_caches.get(cache_id, false)):
			count += 1
	return count


func _check_return_contract_completed(zone_id: String) -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or game_state.get_zone_tier(zone_id) < 1 or bool(return_contract_done.get(zone_id, false)):
		return
	var contract: Dictionary = RETURN_CONTRACTS[zone_id]
	if int(return_contract_kills.get(zone_id, 0)) < int(contract["kills"]) or _get_return_cache_count(zone_id) < int(contract["cache_goal"]):
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not player.has_method("add_xp"):
		return
	return_contract_done[zone_id] = true
	player.add_xp(int(contract["xp"]))
	game_state.add_gold(int(contract["gold"]))
	game_state.add_item(str(contract["item"]), int(contract["item_count"]))
	return_contract_completed.emit(zone_id)


func get_return_contract_tracker_text() -> String:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return ""
	var lines: Array[String] = []
	for zone_id in ["sunken_shaft", "echo_grotto", "ashen_bastion"]:
		if game_state.get_zone_tier(zone_id) < 1 or bool(return_contract_done.get(zone_id, false)):
			continue
		var contract: Dictionary = RETURN_CONTRACTS[zone_id]
		var item_name := str(game_state.get_item_definition(str(contract["item"])).get("name", contract["item"]))
		lines.append("RETURN: %s  %d/%d foes • %d/%d caches\nREWARD: %d XP, %dG, %s x%d" % [
			str(contract["name"]), int(return_contract_kills.get(zone_id, 0)), int(contract["kills"]),
			mini(_get_return_cache_count(zone_id), int(contract["cache_goal"])), int(contract["cache_goal"]),
			int(contract["xp"]), int(contract["gold"]), item_name, int(contract["item_count"]),
		])
	return "\n\n".join(lines)


func start_quest() -> bool:
	if quest_state != QuestState.NOT_STARTED:
		return false

	quest_state = QuestState.ACTIVE
	if quest_index == QUEST_CLEAR_PASSAGE:
		quest_progress = mini(defeated_enemies, CLEAR_PASSAGE_TARGET)
	elif quest_index == QUEST_LOST_SIGIL:
		quest_progress = 1 if lost_sigil_found else 0
	else:
		var game_state := get_node_or_null("/root/GameState")
		quest_progress = 1 if game_state != null and bool(game_state.boss_rematches.get("abyss_warden", false)) else 0
	_update_ready_state()
	quest_updated.emit()
	return true


func report_enemy_defeated() -> void:
	defeated_enemies += 1
	if quest_index != QUEST_CLEAR_PASSAGE or quest_state != QuestState.ACTIVE:
		return

	quest_progress = mini(defeated_enemies, CLEAR_PASSAGE_TARGET)
	_update_ready_state()
	quest_updated.emit()


func report_item_collected(item_id: String) -> void:
	if STARFALL_REPORT_IDS.has(item_id):
		if bool(starfall_reports.get(item_id, false)):
			return
		starfall_reports[item_id] = true
		if starfall_route_state == QuestState.ACTIVE and get_starfall_route_progress() == STARFALL_REPORT_IDS.size():
			starfall_route_state = QuestState.READY_TO_TURN_IN
		quest_updated.emit()
		quest_item_collected.emit(item_id, get_starfall_route_progress())
		return
	if ECHO_TRACE_IDS.has(item_id):
		if bool(echo_traces.get(item_id, false)):
			return
		echo_traces[item_id] = true
		if echo_survey_state == QuestState.ACTIVE and get_echo_survey_progress() == ECHO_TRACE_IDS.size():
			echo_survey_state = QuestState.READY_TO_TURN_IN
		quest_updated.emit()
		quest_item_collected.emit(item_id, get_echo_survey_progress())
		return
	if item_id != LOST_SIGIL_ID or lost_sigil_found:
		return

	lost_sigil_found = true
	if quest_index == QUEST_LOST_SIGIL and quest_state == QuestState.ACTIVE:
		quest_progress = 1
		_update_ready_state()
	quest_updated.emit()
	quest_item_collected.emit(item_id, 1)


func has_collected_quest_item(item_id: String) -> bool:
	if item_id == LOST_SIGIL_ID:
		return lost_sigil_found
	if STARFALL_REPORT_IDS.has(item_id):
		return bool(starfall_reports.get(item_id, false))
	return bool(echo_traces.get(item_id, false)) if ECHO_TRACE_IDS.has(item_id) else false


func get_starfall_route_progress() -> int:
	var count := 0
	for report_id in STARFALL_REPORT_IDS:
		count += int(bool(starfall_reports.get(report_id, false)))
	return count


func start_starfall_route() -> bool:
	if starfall_route_state != QuestState.NOT_STARTED:
		return false
	starfall_route_state = QuestState.READY_TO_TURN_IN if get_starfall_route_progress() == STARFALL_REPORT_IDS.size() else QuestState.ACTIVE
	quest_updated.emit()
	return true


func turn_in_starfall_route(player: Node) -> bool:
	if starfall_route_state != QuestState.READY_TO_TURN_IN or player == null or not player.has_method("add_skill_points") or not player.has_method("add_xp"):
		return false
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return false
	starfall_route_state = QuestState.COMPLETED
	player.add_skill_points(1)
	player.add_xp(4)
	game_state.add_gold(100)
	game_state.add_item("ether_dust", 2)
	quest_updated.emit()
	return true


func get_starfall_route_tracker_text() -> String:
	match starfall_route_state:
		QuestState.ACTIVE:
			return "SIDE: Lantern Route %d/3\nWatch %d/1  -  Market %d/1  -  Garden %d/1\nREWARD: 1 SP, 4 XP, 100G, Ether Dust x2" % [get_starfall_route_progress(), int(bool(starfall_reports.get(STARFALL_REPORT_IDS[0], false))), int(bool(starfall_reports.get(STARFALL_REPORT_IDS[1], false))), int(bool(starfall_reports.get(STARFALL_REPORT_IDS[2], false)))]
		QuestState.READY_TO_TURN_IN:
			return "SIDE: Return the three reports to Rook\nREWARD: 1 SP, 4 XP, 100G, Ether Dust x2"
		_:
			return ""


func start_starfall_courier() -> bool:
	if starfall_route_state != QuestState.COMPLETED or starfall_courier_state != QuestState.NOT_STARTED:
		return false
	starfall_courier_state = QuestState.ACTIVE
	quest_updated.emit()
	return true


func _on_checkpoint_resting(lamp_id: String) -> void:
	if starfall_courier_state != QuestState.ACTIVE or not STARFALL_COURIER_LAMPS.has(lamp_id) or bool(starfall_courier_stops.get(lamp_id, false)):
		return
	starfall_courier_stops[lamp_id] = true
	if get_starfall_courier_progress() == STARFALL_COURIER_LAMPS.size():
		starfall_courier_state = QuestState.READY_TO_TURN_IN
	quest_updated.emit()


func get_starfall_courier_progress() -> int:
	var count := 0
	for lamp_id in STARFALL_COURIER_LAMPS:
		count += int(bool(starfall_courier_stops.get(lamp_id, false)))
	return count


func turn_in_starfall_courier(player: Node) -> bool:
	if starfall_courier_state != QuestState.READY_TO_TURN_IN or player == null or not player.has_method("add_xp"):
		return false
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return false
	starfall_courier_state = QuestState.COMPLETED
	player.add_xp(3)
	game_state.add_gold(75)
	game_state.add_item("resonance_shard")
	quest_updated.emit()
	return true


func get_starfall_courier_tracker_text() -> String:
	match starfall_courier_state:
		QuestState.ACTIVE:
			return "SIDE: Courier Circuit %d/2\nRest at Whisperlight and Cinder Hearth lamps\nREWARD: 3 XP, 75G, Resonance Shard" % get_starfall_courier_progress()
		QuestState.READY_TO_TURN_IN:
			return "SIDE: Return to Rook with both replies\nREWARD: 3 XP, 75G, Resonance Shard"
		_:
			return ""


func get_dawn_archive_progress() -> int:
	var count := 0
	for echo_id in DAWN_ARCHIVE_ECHOES:
		count += int(bool(dawn_archive_records.get(echo_id, false)))
	return count


func is_dawn_echo_recorded(echo_id: String) -> bool:
	return bool(dawn_archive_records.get(echo_id, false))


func start_dawn_archive() -> bool:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or not bool(game_state.defeated_bosses.get("hollow_sovereign", false)) or dawn_archive_state != QuestState.NOT_STARTED:
		return false
	dawn_archive_state = QuestState.READY_TO_TURN_IN if get_dawn_archive_progress() == DAWN_ARCHIVE_ECHOES.size() else QuestState.ACTIVE
	quest_updated.emit()
	return true


func record_dawn_echo(echo_id: String) -> bool:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or not bool(game_state.defeated_bosses.get("hollow_sovereign", false)) or not DAWN_ARCHIVE_ECHOES.has(echo_id) or is_dawn_echo_recorded(echo_id):
		return false
	dawn_archive_records[echo_id] = true
	var progress := get_dawn_archive_progress()
	if dawn_archive_state == QuestState.ACTIVE and progress == DAWN_ARCHIVE_ECHOES.size():
		dawn_archive_state = QuestState.READY_TO_TURN_IN
	quest_updated.emit()
	quest_item_collected.emit("dawn_echo_" + echo_id, progress)
	return true


func turn_in_dawn_archive(player: Node) -> bool:
	if dawn_archive_state != QuestState.READY_TO_TURN_IN or player == null or not player.has_method("add_skill_points") or not player.has_method("add_xp"):
		return false
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or not bool(game_state.defeated_bosses.get("hollow_sovereign", false)):
		return false
	dawn_archive_state = QuestState.COMPLETED
	player.add_skill_points(1)
	player.add_xp(4)
	game_state.add_gold(120)
	game_state.add_item("dawn_chronicle")
	quest_updated.emit()
	return true


func get_dawn_archive_tracker_text() -> String:
	match dawn_archive_state:
		QuestState.ACTIVE:
			return "SIDE: Dawn Archive %d/3\nBlackwater %d/1  -  Prism %d/1  -  Chapel %d/1\nClear nearby foes; stay close while listening.\nREWARD: 1 SP, 4 XP, 120G, Dawn Chronicle" % [get_dawn_archive_progress(), int(is_dawn_echo_recorded("shaft")), int(is_dawn_echo_recorded("echo")), int(is_dawn_echo_recorded("ash"))]
		QuestState.READY_TO_TURN_IN:
			return "SIDE: Return the three echoes to Atley in Starfall's library\nREWARD: 1 SP, 4 XP, 120G, Dawn Chronicle"
		_:
			return ""


func start_echo_survey() -> bool:
	if echo_survey_state != QuestState.NOT_STARTED:
		return false
	echo_survey_state = QuestState.READY_TO_TURN_IN if get_echo_survey_progress() == ECHO_TRACE_IDS.size() else QuestState.ACTIVE
	quest_updated.emit()
	return true


func _on_hearth_shortcut_changed(shortcut_id: String) -> void:
	if shortcut_id != "ash_forge_fan" or hearth_fan_state != QuestState.ACTIVE:
		return
	hearth_fan_state = QuestState.READY_TO_TURN_IN
	quest_updated.emit()


func start_hearth_fan_quest() -> bool:
	if hearth_fan_state != QuestState.NOT_STARTED:
		return false
	var game_state := get_node_or_null("/root/GameState")
	hearth_fan_state = QuestState.READY_TO_TURN_IN if game_state != null and bool(game_state.unlocked_shortcuts.get("ash_forge_fan", false)) else QuestState.ACTIVE
	quest_updated.emit()
	return true


func turn_in_hearth_fan_quest(player: Node) -> bool:
	if hearth_fan_state != QuestState.READY_TO_TURN_IN or player == null or not player.has_method("add_xp"):
		return false
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return false
	hearth_fan_state = QuestState.COMPLETED
	player.add_xp(2)
	game_state.add_gold(50)
	game_state.add_item("iron_fragment", 2)
	quest_updated.emit()
	return true


func get_hearth_fan_tracker_text() -> String:
	match hearth_fan_state:
		QuestState.ACTIVE:
			return "SIDE: Cool the Cinder Forge  0/1\nREWARD: 2 XP, 50G, Iron Fragment x2"
		QuestState.READY_TO_TURN_IN:
			return "SIDE: Return to Mira in Cinder Hearth\nREWARD: 2 XP, 50G, Iron Fragment x2"
		_:
			return ""


func get_hearth_gate_progress() -> int:
	return mini(hearth_gate_defeated.size(), 2)


func start_hearth_gate_quest() -> bool:
	if hearth_gate_state != QuestState.NOT_STARTED:
		return false
	hearth_gate_state = QuestState.READY_TO_TURN_IN if get_hearth_gate_progress() >= 2 else QuestState.ACTIVE
	quest_updated.emit()
	return true


func turn_in_hearth_gate_quest(player: Node) -> bool:
	if hearth_gate_state != QuestState.READY_TO_TURN_IN or player == null or not player.has_method("add_xp"):
		return false
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return false
	hearth_gate_state = QuestState.COMPLETED
	player.add_xp(1)
	game_state.add_gold(25)
	game_state.add_item("iron_fragment", 1)
	quest_updated.emit()
	return true


func get_hearth_gate_tracker_text() -> String:
	match hearth_gate_state:
		QuestState.ACTIVE:
			return "SIDE: Clear the Hearth Road  %d/2\nREWARD: 1 XP, 25G, Iron Fragment" % get_hearth_gate_progress()
		QuestState.READY_TO_TURN_IN:
			return "SIDE: Return to Tarin in Cinder Hearth\nREWARD: 1 XP, 25G, Iron Fragment"
		_:
			return ""


func get_echo_survey_progress() -> int:
	var count := 0
	for trace_id in ECHO_TRACE_IDS:
		if bool(echo_traces.get(trace_id, false)):
			count += 1
	return count


func get_echo_survey_tracker_text() -> String:
	if echo_survey_state == QuestState.NOT_STARTED:
		return ""
	if echo_survey_state == QuestState.COMPLETED:
		return "SIDE: Echo Survey complete"
	var locations: Array[String] = []
	for index in range(ECHO_TRACE_IDS.size()):
		var room_name: String = ["Gallery", "Archive", "Tide Well"][index]
		locations.append("%s %d/1" % [room_name, int(bool(echo_traces.get(ECHO_TRACE_IDS[index], false)))])
	var heading := "SIDE: Return to Lyra" if echo_survey_state == QuestState.READY_TO_TURN_IN else "SIDE: Echo Survey %d/3" % get_echo_survey_progress()
	return "%s\n%s\nREWARD: 1 SP, 3 XP, 80G, Ether Dust x2" % [heading, " • ".join(locations)]


func turn_in_echo_survey(player: Node) -> bool:
	if echo_survey_state != QuestState.READY_TO_TURN_IN or player == null or not player.has_method("add_skill_points") or not player.has_method("add_xp"):
		return false
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return false
	echo_survey_state = QuestState.COMPLETED
	player.add_skill_points(1)
	player.add_xp(3)
	game_state.add_gold(80)
	game_state.add_item("ether_dust", 2)
	quest_updated.emit()
	return true


func turn_in_quest(player: Node) -> bool:
	if quest_state != QuestState.READY_TO_TURN_IN or player == null:
		return false

	if quest_index == QUEST_CLEAR_PASSAGE:
		if not player.has_method("add_skill_points"):
			return false
		player.add_skill_points(1)
		player.add_xp(2)
		var game_state := get_node_or_null("/root/GameState")
		if game_state != null:
			game_state.add_gold(30)
		quest_index = QUEST_LOST_SIGIL
		quest_state = QuestState.NOT_STARTED
		quest_progress = 0
	elif quest_index == QUEST_LOST_SIGIL:
		if not player.has_method("increase_max_health"):
			return false
		player.increase_max_health(1)
		player.add_xp(2)
		var game_state := get_node_or_null("/root/GameState")
		if game_state != null:
			game_state.add_gold(45)
			game_state.add_item("caretaker_charm", 1)
		quest_index = QUEST_AWAKENED_WARDEN
		quest_state = QuestState.NOT_STARTED
		quest_progress = 0
	else:
		player.add_skill_points(1)
		player.add_xp(4)
		var game_state := get_node_or_null("/root/GameState")
		if game_state != null:
			game_state.add_gold(65)
		quest_state = QuestState.COMPLETED
		quest_progress = 1

	quest_updated.emit()
	return true


func _update_ready_state() -> void:
	if quest_state != QuestState.ACTIVE:
		return

	var target := CLEAR_PASSAGE_TARGET if quest_index == QUEST_CLEAR_PASSAGE else 1
	if quest_progress >= target:
		quest_state = QuestState.READY_TO_TURN_IN


func get_tracker_text() -> String:
	if quest_index == QUEST_CLEAR_PASSAGE:
		match quest_state:
			QuestState.NOT_STARTED:
				return "QUEST: Talk to the Caretaker"
			QuestState.ACTIVE:
				return "QUEST: Clear the Passage  %d/%d" % [quest_progress, CLEAR_PASSAGE_TARGET]
			QuestState.READY_TO_TURN_IN:
				return "QUEST: Return to the Caretaker"
	elif quest_index == QUEST_LOST_SIGIL:
		match quest_state:
			QuestState.NOT_STARTED:
				return "QUEST: The Caretaker has another task"
			QuestState.ACTIVE:
				return "QUEST: Find the Lost Sigil  %d/1" % quest_progress
			QuestState.READY_TO_TURN_IN:
				return "QUEST: Return the sigil to the Caretaker"
	else:
		match quest_state:
			QuestState.NOT_STARTED:
				return "QUEST: Eldric has a final challenge"
			QuestState.ACTIVE:
				return "QUEST: Defeat the Awakened Warden  %d/1" % quest_progress
			QuestState.READY_TO_TURN_IN:
				return "QUEST: Report to Eldric"
			QuestState.COMPLETED:
				return "ELDRIC'S QUESTS COMPLETE"
	return ""


func get_reward_text() -> String:
	if quest_index == QUEST_CLEAR_PASSAGE:
		return "1 Skill Point  •  2 XP  •  30 Gold"
	if quest_index == QUEST_AWAKENED_WARDEN:
		return "All rewards claimed" if quest_state == QuestState.COMPLETED else "1 Skill Point  •  4 XP  •  65 Gold"
	if quest_state == QuestState.COMPLETED:
		return "All rewards claimed"
	return "1 Max HP  •  2 XP  •  45 Gold  •  Caretaker Charm"


func _on_boss_progress_changed(boss_id: String) -> void:
	if boss_id != "abyss_warden" or quest_index != QUEST_AWAKENED_WARDEN or quest_state != QuestState.ACTIVE:
		return
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and bool(game_state.boss_rematches.get("abyss_warden", false)):
		quest_progress = 1
		_update_ready_state()
		quest_updated.emit()


func get_save_state() -> Dictionary:
	return {
		"quest_index": quest_index,
		"quest_state": int(quest_state),
		"quest_progress": quest_progress,
		"defeated_enemies": defeated_enemies,
		"lost_sigil_found": lost_sigil_found,
		"echo_survey_state": int(echo_survey_state),
		"hearth_fan_state": int(hearth_fan_state),
		"hearth_gate_state": int(hearth_gate_state),
		"hearth_gate_defeated": hearth_gate_defeated.duplicate(true),
		"starfall_route_state": int(starfall_route_state),
		"starfall_reports": starfall_reports.duplicate(true),
		"starfall_courier_state": int(starfall_courier_state),
		"starfall_courier_stops": starfall_courier_stops.duplicate(true),
		"dawn_archive_state": int(dawn_archive_state),
		"dawn_archive_records": dawn_archive_records.duplicate(true),
		"echo_traces": echo_traces.duplicate(true),
		"return_contract_kills": return_contract_kills.duplicate(true),
		"return_contract_done": return_contract_done.duplicate(true),
	}


func apply_save_state(data: Dictionary) -> void:
	quest_index = int(data.get("quest_index", QUEST_CLEAR_PASSAGE))
	quest_state = int(data.get("quest_state", QuestState.NOT_STARTED)) as QuestState
	quest_progress = int(data.get("quest_progress", 0))
	defeated_enemies = int(data.get("defeated_enemies", 0))
	lost_sigil_found = bool(data.get("lost_sigil_found", false))
	echo_survey_state = int(data.get("echo_survey_state", QuestState.NOT_STARTED)) as QuestState
	hearth_fan_state = int(data.get("hearth_fan_state", QuestState.NOT_STARTED)) as QuestState
	hearth_gate_state = int(data.get("hearth_gate_state", QuestState.NOT_STARTED)) as QuestState
	hearth_gate_defeated = Dictionary(data.get("hearth_gate_defeated", {})).duplicate(true)
	starfall_route_state = int(data.get("starfall_route_state", QuestState.NOT_STARTED)) as QuestState
	starfall_reports = Dictionary(data.get("starfall_reports", {})).duplicate(true)
	starfall_courier_state = int(data.get("starfall_courier_state", QuestState.NOT_STARTED)) as QuestState
	starfall_courier_stops = Dictionary(data.get("starfall_courier_stops", {})).duplicate(true)
	dawn_archive_state = int(data.get("dawn_archive_state", QuestState.NOT_STARTED)) as QuestState
	dawn_archive_records = Dictionary(data.get("dawn_archive_records", {})).duplicate(true)
	echo_traces = Dictionary(data.get("echo_traces", {})).duplicate(true)
	return_contract_kills = Dictionary(data.get("return_contract_kills", {})).duplicate(true)
	return_contract_done = Dictionary(data.get("return_contract_done", {})).duplicate(true)
	quest_updated.emit()
