extends Node

signal quest_updated

enum QuestState {
	NOT_STARTED,
	ACTIVE,
	READY_TO_TURN_IN,
	COMPLETED,
}

const QUEST_CLEAR_PASSAGE := 0
const QUEST_LOST_SIGIL := 1
const CLEAR_PASSAGE_TARGET := 2
const LOST_SIGIL_ID := "old_passage_sigil"

var quest_index: int = QUEST_CLEAR_PASSAGE
var quest_state: QuestState = QuestState.NOT_STARTED
var quest_progress: int = 0
var defeated_enemies: int = 0
var lost_sigil_found: bool = false


func start_quest() -> bool:
	if quest_state != QuestState.NOT_STARTED:
		return false

	quest_state = QuestState.ACTIVE
	if quest_index == QUEST_CLEAR_PASSAGE:
		quest_progress = mini(defeated_enemies, CLEAR_PASSAGE_TARGET)
	else:
		quest_progress = 1 if lost_sigil_found else 0
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
	if item_id != LOST_SIGIL_ID or lost_sigil_found:
		return

	lost_sigil_found = true
	if quest_index == QUEST_LOST_SIGIL and quest_state == QuestState.ACTIVE:
		quest_progress = 1
		_update_ready_state()
	quest_updated.emit()


func turn_in_quest(player: Node) -> bool:
	if quest_state != QuestState.READY_TO_TURN_IN or player == null:
		return false

	if quest_index == QUEST_CLEAR_PASSAGE:
		if not player.has_method("add_skill_points"):
			return false
		player.add_skill_points(1)
		quest_index = QUEST_LOST_SIGIL
		quest_state = QuestState.NOT_STARTED
		quest_progress = 0
	else:
		if not player.has_method("increase_max_health"):
			return false
		player.increase_max_health(1)
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
	else:
		match quest_state:
			QuestState.NOT_STARTED:
				return "QUEST: The Caretaker has another task"
			QuestState.ACTIVE:
				return "QUEST: Find the Lost Sigil  %d/1" % quest_progress
			QuestState.READY_TO_TURN_IN:
				return "QUEST: Return the sigil to the Caretaker"
			QuestState.COMPLETED:
				return "ALL QUESTS COMPLETE"
	return ""
