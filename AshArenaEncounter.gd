extends Node2D

signal encounter_changed

const CLEAR_EVENT := "ash_arena_cleared"
const FIEND_SCENE: PackedScene = preload("res://AshFiend.tscn")
const SENTRY_SCENE: PackedScene = preload("res://AshSentry.tscn")
const MARSHAL_SCENE: PackedScene = preload("res://EmberMarshal.tscn")
const TOTAL_WAVES := 4

var active: bool = false
var completed: bool = false
var intermission: bool = false
var wave: int = 0
var enemies_remaining: int = 0
var participant: Player
var marshal: Node2D
var encounter_generation: int = 0

@onready var bell: Area2D = $ArenaBell
@onready var combatants: Node2D = $Combatants
@onready var status_label: Label = $ArenaStatus


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		completed = bool(game_state.unlocked_shortcuts.get(CLEAR_EVENT, false))
		game_state.room_changed.connect(_on_room_changed)
	_update_display()


func _process(_delta: float) -> void:
	if active and (not is_instance_valid(participant) or participant.is_dead):
		_reset_encounter()


func start_trial(player: Player) -> bool:
	if player == null or player.is_dead or active or completed:
		return false
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or game_state.current_room_id != "ash_arena" or not bool(game_state.unlocked_shortcuts.get("ash_barracks_cleared", false)):
		return false
	encounter_generation += 1
	active = true
	participant = player
	wave = 1
	_spawn_wave()
	_update_display()
	return true


func _spawn_wave() -> void:
	var layouts := [
		[[FIEND_SCENE, Vector2(575, 397)], [FIEND_SCENE, Vector2(940, 397)]],
		[[FIEND_SCENE, Vector2(555, 397)], [SENTRY_SCENE, Vector2(850, 293)], [FIEND_SCENE, Vector2(1015, 397)]],
		[[SENTRY_SCENE, Vector2(610, 397)], [FIEND_SCENE, Vector2(760, 397)], [SENTRY_SCENE, Vector2(930, 293)]],
		[[FIEND_SCENE, Vector2(560, 397)], [MARSHAL_SCENE, Vector2(885, 391)], [FIEND_SCENE, Vector2(1100, 397)]],
	]
	var layout: Array = layouts[wave - 1]
	var offset: float = [-36.0, 0.0, 36.0].pick_random()
	enemies_remaining = layout.size()
	for index in range(layout.size()):
		var enemy: Node2D = layout[index][0].instantiate()
		enemy.name = "Wave%d_Enemy%d" % [wave, index + 1]
		enemy.position = layout[index][1] + Vector2(offset, 0.0)
		if wave < TOTAL_WAVES or not enemy.is_in_group("mini_boss"):
			enemy.set("xp_orb_scene", null)
			enemy.set("gold_pickup_scene", null)
		combatants.add_child(enemy)
		enemy.defeated.connect(_on_enemy_defeated)
		if enemy.is_in_group("mini_boss"):
			marshal = enemy
			enemy.health_changed.connect(_on_marshal_health_changed)
			enemy.phase_changed.connect(_on_marshal_phase_changed)


func _on_enemy_defeated() -> void:
	if not active:
		return
	enemies_remaining = maxi(enemies_remaining - 1, 0)
	_update_display()
	if enemies_remaining == 0 and not intermission:
		intermission = true
		_advance_after_pause()


func _advance_after_pause() -> void:
	var generation := encounter_generation
	_update_display()
	await get_tree().create_timer(1.6).timeout
	if generation != encounter_generation or not active or not is_instance_valid(participant) or participant.is_dead:
		return
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or game_state.current_room_id != "ash_arena":
		return
	intermission = false
	if wave < TOTAL_WAVES:
		wave += 1
		_spawn_wave()
		_update_display()
	else:
		_complete_encounter(game_state)


func _complete_encounter(game_state: Node) -> void:
	active = false
	for node in combatants.get_children():
		if node.is_in_group("enemy_projectile"):
			node.queue_free()
	completed = game_state.unlock_shortcut(CLEAR_EVENT)
	if completed:
		game_state.add_item("marshal_emblem")
		game_state.add_gold(100)
		participant.add_xp(7)
	participant = null
	marshal = null
	_update_display()


func _on_room_changed(room_id: String) -> void:
	if room_id != "ash_arena" and active:
		_reset_encounter()


func _reset_encounter() -> void:
	encounter_generation += 1
	active = false
	intermission = false
	wave = 0
	enemies_remaining = 0
	participant = null
	marshal = null
	for node in combatants.get_children():
		node.queue_free()
	_update_display()


func _on_marshal_health_changed(_health: int, _maximum: int) -> void:
	_update_display()


func _on_marshal_phase_changed(_phase: int) -> void:
	_update_display()


func _update_display() -> void:
	if status_label == null:
		return
	if completed:
		status_label.text = "ARENA CLEARED  •  MARSHAL EMBLEM CLAIMED"
	elif intermission:
		status_label.text = "WAVE %d/%d CLEARED  •  PREPARE FOR THE NEXT" % [wave, TOTAL_WAVES]
	elif active and wave == TOTAL_WAVES and is_instance_valid(marshal) and not marshal.is_dead:
		status_label.text = "EMBER MARSHAL  %d/%d HP  •  %d FOES LEFT" % [marshal.current_health, marshal.max_health, enemies_remaining]
	elif active:
		status_label.text = "ARENA WAVE %d/%d  •  %d FOES LEFT" % [wave, TOTAL_WAVES, enemies_remaining]
	else:
		status_label.text = "FOUR WAVES  •  MARSHAL + GUARDS AT THE END"
	if bell != null:
		bell.refresh()
	encounter_changed.emit()
