extends CanvasLayer

@export var player_path: NodePath = NodePath("../Player")
@export var exit_path: NodePath = NodePath("../ExitPortal")
@export var quest_manager_path: NodePath = NodePath("../QuestManager")

@onready var player: Player = get_node_or_null(player_path) as Player
@onready var level_exit: Area2D = get_node_or_null(exit_path) as Area2D
@onready var quest_manager: Node = get_node_or_null(quest_manager_path)
@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/HealthLabel
@onready var xp_bar: ProgressBar = $XPBar
@onready var xp_label: Label = $XPBar/XPLabel
@onready var skill_points_label: Label = $SkillPointsLabel
@onready var skill_panel: Panel = $SkillPanel
@onready var double_jump_button: Button = $SkillPanel/DoubleJumpButton
@onready var dash_button: Button = $SkillPanel/DashButton
@onready var skill_info_label: Label = $SkillPanel/SkillInfoLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var restart_button: Button = $GameOverPanel/RestartButton
@onready var objective_label: Label = $ObjectivePanel/ObjectiveLabel
@onready var notification_label: Label = $NotificationLabel
@onready var level_complete_panel: Panel = $LevelCompletePanel
@onready var play_again_button: Button = $LevelCompletePanel/PlayAgainButton
@onready var quest_tracker_label: Label = $QuestTrackerLabel
@onready var dialogue_panel: Panel = $DialoguePanel
@onready var speaker_label: Label = $DialoguePanel/SpeakerLabel
@onready var dialogue_text: Label = $DialoguePanel/DialogueText
@onready var dialogue_primary_button: Button = $DialoguePanel/PrimaryButton
@onready var dialogue_close_button: Button = $DialoguePanel/CloseButton

var total_enemies: int = 0
var defeated_enemies: int = 0
var notification_tween: Tween
var resume_player_after_dialogue: bool = false


func _ready() -> void:
	game_over_panel.hide()
	level_complete_panel.hide()
	dialogue_panel.hide()
	notification_label.modulate.a = 0.0
	double_jump_button.pressed.connect(_on_double_jump_button_pressed)
	dash_button.pressed.connect(_on_dash_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	play_again_button.pressed.connect(_on_restart_button_pressed)
	dialogue_primary_button.pressed.connect(_on_dialogue_primary_pressed)
	dialogue_close_button.pressed.connect(_close_dialogue)
	_setup_enemy_objective()
	_setup_friendly_npcs()

	if level_exit != null:
		level_exit.unlocked.connect(_on_exit_unlocked)
		level_exit.level_completed.connect(_on_level_completed)
	if quest_manager != null:
		quest_manager.quest_updated.connect(_on_quest_updated)
		_on_quest_updated()

	if player == null:
		push_error("UI could not find the Player node at: " + str(player_path))
		double_jump_button.disabled = true
		dash_button.disabled = true
		return

	player.health_changed.connect(_on_health_changed)
	player.progression_changed.connect(_on_progression_changed)
	player.double_jump_state_changed.connect(_on_double_jump_state_changed)
	player.dash_state_changed.connect(_on_dash_state_changed)
	player.died.connect(_on_player_died)

	_on_health_changed(player.current_health, player.max_health)
	_on_progression_changed(player.xp, player.xp_per_level, player.skill_points)
	_on_double_jump_state_changed(player.double_jump_unlocked)
	_on_dash_state_changed(player.dash_unlocked)


func _setup_friendly_npcs() -> void:
	for npc in get_tree().get_nodes_in_group("friendly_npc"):
		var callback := Callable(self, "_on_npc_interaction_requested")
		if npc.has_signal("interaction_requested") and not npc.is_connected("interaction_requested", callback):
			npc.connect("interaction_requested", callback)


func _on_npc_interaction_requested(_npc: Area2D) -> void:
	if player == null or player.is_dead or level_complete_panel.visible:
		return

	resume_player_after_dialogue = player.is_physics_processing()
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	dialogue_panel.show()
	_update_dialogue_content()
	dialogue_close_button.grab_focus()


func _update_dialogue_content() -> void:
	if quest_manager == null:
		return

	speaker_label.text = "CARETAKER"
	var quest_index := int(quest_manager.get("quest_index"))
	var state := int(quest_manager.get("quest_state"))
	if quest_index == 0:
		match state:
			0:
				dialogue_text.text = "Creatures have overrun the old passage. Defeat both of them and return to me."
				dialogue_primary_button.text = "Accept Mission"
				dialogue_primary_button.show()
			1:
				dialogue_text.text = "The passage is still dangerous. Enemies defeated: %d/2." % int(quest_manager.get("quest_progress"))
				dialogue_primary_button.hide()
			2:
				dialogue_text.text = "The passage is safe again. You have earned this skill point."
				dialogue_primary_button.text = "Claim Reward"
				dialogue_primary_button.show()
	else:
		match state:
			0:
				dialogue_text.text = "One task remains. Find the violet sigil hidden on the upper path and bring it back."
				dialogue_primary_button.text = "Accept Mission"
				dialogue_primary_button.show()
			1:
				dialogue_text.text = "The sigil should be resting somewhere above the old passage."
				dialogue_primary_button.hide()
			2:
				dialogue_text.text = "You found it. Its energy will strengthen your life force."
				dialogue_primary_button.text = "Return Sigil"
				dialogue_primary_button.show()
			3:
				dialogue_text.text = "The passage and its relic are safe. You have my gratitude."
				dialogue_primary_button.hide()


func _on_dialogue_primary_pressed() -> void:
	if quest_manager == null:
		return

	var state := int(quest_manager.get("quest_state"))
	if state == 0 and quest_manager.start_quest():
		var quest_name := "CLEAR THE PASSAGE" if int(quest_manager.get("quest_index")) == 0 else "FIND THE LOST SIGIL"
		_show_notification("NEW QUEST: " + quest_name)
	elif state == 2:
		var completed_quest := int(quest_manager.get("quest_index"))
		if quest_manager.turn_in_quest(player):
			if completed_quest == 0:
				_show_notification("QUEST COMPLETE  •  +1 SKILL POINT")
			else:
				_show_notification("QUEST COMPLETE  •  MAX HP +1")
	_update_dialogue_content()


func _close_dialogue() -> void:
	dialogue_panel.hide()
	if resume_player_after_dialogue and player != null and not player.is_dead and not level_complete_panel.visible:
		player.set_physics_process(true)
	resume_player_after_dialogue = false


func _on_quest_updated() -> void:
	if quest_manager == null:
		quest_tracker_label.text = "QUEST SYSTEM UNAVAILABLE"
		return

	quest_tracker_label.text = quest_manager.get_tracker_text()
	if dialogue_panel.visible:
		_update_dialogue_content()


func _setup_enemy_objective() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	total_enemies = enemies.size()
	for enemy in enemies:
		if enemy.has_signal("defeated") and not enemy.defeated.is_connected(_on_enemy_defeated):
			enemy.defeated.connect(_on_enemy_defeated)
	_update_objective_label()


func _on_enemy_defeated() -> void:
	defeated_enemies += 1
	_update_objective_label()
	_show_notification("ENEMY DEFEATED  •  XP DROPPED")


func _update_objective_label() -> void:
	if total_enemies <= 0:
		objective_label.text = "Explore the training ground"
	elif defeated_enemies >= total_enemies:
		objective_label.text = "AREA CLEAR  •  Reach the exit"
	else:
		objective_label.text = "DEFEAT ENEMIES  %d/%d" % [defeated_enemies, total_enemies]


func _show_notification(message: String) -> void:
	if notification_tween != null and notification_tween.is_valid():
		notification_tween.kill()

	notification_label.text = message
	notification_label.modulate.a = 1.0
	notification_tween = create_tween()
	notification_tween.tween_interval(1.1)
	notification_tween.tween_property(notification_label, "modulate:a", 0.0, 0.35)


func _on_exit_unlocked() -> void:
	_show_notification("EXIT UNLOCKED")


func _on_level_completed() -> void:
	if player == null or player.is_dead:
		return

	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	dialogue_panel.hide()
	resume_player_after_dialogue = false
	skill_panel.hide()
	objective_label.text = "LEVEL COMPLETE"
	level_complete_panel.show()
	play_again_button.grab_focus()


func _on_health_changed(current_health: int, maximum_health: int) -> void:
	health_bar.max_value = maximum_health
	health_bar.value = current_health
	health_label.text = "HP: %d/%d" % [current_health, maximum_health]


func _on_progression_changed(current_xp: int, required_xp: int, points: int) -> void:
	xp_bar.max_value = required_xp
	xp_bar.value = current_xp
	xp_label.text = "XP: %d/%d" % [current_xp, required_xp]
	skill_points_label.text = "SKILL POINTS: %d" % points
	_update_skill_buttons()


func _on_double_jump_state_changed(_is_unlocked: bool) -> void:
	_update_skill_buttons()


func _on_dash_state_changed(_is_unlocked: bool) -> void:
	_update_skill_buttons()


func _update_skill_buttons() -> void:
	if player == null:
		return

	if player.double_jump_unlocked:
		double_jump_button.text = "Double Jump - Unlocked"
		double_jump_button.disabled = true
	else:
		double_jump_button.text = "Unlock Double Jump - %d SP" % player.double_jump_cost
		double_jump_button.disabled = not player.can_unlock_double_jump()

	if player.dash_unlocked:
		dash_button.text = "Dash - Unlocked"
		dash_button.disabled = true
	else:
		dash_button.text = "Unlock Dash - %d SP" % player.dash_cost
		dash_button.disabled = not player.can_unlock_dash()

	if player.double_jump_unlocked and player.dash_unlocked:
		skill_info_label.text = "All available skills unlocked."
	elif player.can_unlock_double_jump() or player.can_unlock_dash():
		skill_info_label.text = "Choose an ability to unlock."
	else:
		skill_info_label.text = "Collect XP to earn a skill point."


func _on_double_jump_button_pressed() -> void:
	if player != null:
		player.try_unlock_double_jump()


func _on_dash_button_pressed() -> void:
	if player != null:
		player.try_unlock_dash()


func _on_player_died() -> void:
	dialogue_panel.hide()
	resume_player_after_dialogue = false
	skill_panel.hide()
	level_complete_panel.hide()
	game_over_panel.show()
	restart_button.grab_focus()


func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
