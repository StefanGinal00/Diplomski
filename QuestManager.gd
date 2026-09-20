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
const RETURN_CONTRACTS := {
	"sunken_shaft": {"name": "Shaft Vigil", "kills": 3, "caches": ["shaft_rim", "shaft_depth", "hollow_resonance", "crossing_dregs", "gallery_afterglow", "cistern_echo", "approach_afterglow"], "cache_goal": 1, "xp": 2, "gold": 70, "item": "iron_fragment", "item_count": 2},
	"echo_grotto": {"name": "Resonance Sweep", "kills": 4, "caches": ["grotto_high", "gallery_step", "archive_shelf", "tide_depth", "nest_cocoon", "sanctum_heart", "causeway_afterglow", "vault_undertow"], "cache_goal": 2, "xp": 3, "gold": 100, "item": "ether_dust", "item_count": 2},
}

var quest_index: int = QUEST_CLEAR_PASSAGE
var quest_state: QuestState = QuestState.NOT_STARTED
var quest_progress: int = 0
var defeated_enemies: int = 0
var lost_sigil_found: bool = false
var echo_survey_state: QuestState = QuestState.NOT_STARTED
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
	for enemy in get_tree().get_nodes_in_group("enemy"):
		_connect_return_enemy(enemy)
	get_tree().node_added.connect(_connect_return_enemy)


func _connect_return_enemy(node: Node) -> void:
	if not node.is_in_group("enemy") or node.is_in_group("boss") or not node.has_signal("defeated"):
		return
	if not RETURN_CONTRACTS.has(str(node.get("zone_id"))):
		return
	var callback := Callable(self, "_on_return_enemy_defeated").bind(node)
	if not node.is_connected("defeated", callback):
		node.connect("defeated", callback)


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
	for zone_id in ["sunken_shaft", "echo_grotto"]:
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
	return bool(echo_traces.get(item_id, false)) if ECHO_TRACE_IDS.has(item_id) else false


func start_echo_survey() -> bool:
	if echo_survey_state != QuestState.NOT_STARTED:
		return false
	echo_survey_state = QuestState.READY_TO_TURN_IN if get_echo_survey_progress() == ECHO_TRACE_IDS.size() else QuestState.ACTIVE
	quest_updated.emit()
	return true


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
	echo_traces = Dictionary(data.get("echo_traces", {})).duplicate(true)
	return_contract_kills = Dictionary(data.get("return_contract_kills", {})).duplicate(true)
	return_contract_done = Dictionary(data.get("return_contract_done", {})).duplicate(true)
	quest_updated.emit()
