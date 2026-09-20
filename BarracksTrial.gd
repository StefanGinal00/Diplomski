extends Node2D

signal trial_changed

const CLEAR_EVENT := "ash_barracks_cleared"
const FIEND_SCENE: PackedScene = preload("res://AshFiend.tscn")
const SENTRY_SCENE: PackedScene = preload("res://AshSentry.tscn")

var active: bool = false
var wave: int = 0
var enemies_remaining: int = 0
var completed: bool = false
var participant: Player

@onready var beacon: Area2D = $BarracksBeacon
@onready var wave_enemies: Node2D = $WaveEnemies
@onready var challenge_label: Label = $ChallengeLabel


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		completed = bool(game_state.unlocked_shortcuts.get(CLEAR_EVENT, false))
		game_state.room_changed.connect(_on_room_changed)
	_update_display()


func start_trial(player: Player) -> bool:
	if player == null or player.is_dead or active or completed:
		return false
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or game_state.current_room_id != "ash_barracks":
		return false
	active = true
	participant = player
	wave = 1
	_spawn_wave()
	_update_display()
	return true


func _spawn_wave() -> void:
	var layouts := [
		[[FIEND_SCENE, Vector2(390, 387)], [FIEND_SCENE, Vector2(710, 387)]],
		[[FIEND_SCENE, Vector2(445, 387)], [SENTRY_SCENE, Vector2(820, 387)]],
	]
	var layout: Array = layouts[wave - 1]
	var offset: float = [-38.0, 0.0, 38.0].pick_random()
	enemies_remaining = layout.size()
	for index in range(layout.size()):
		var enemy: Node2D = layout[index][0].instantiate()
		enemy.name = "Wave%d_Enemy%d" % [wave, index + 1]
		enemy.position = layout[index][1] + Vector2(offset, 0)
		enemy.set("xp_orb_scene", null)
		enemy.set("gold_pickup_scene", null)
		wave_enemies.add_child(enemy)
		enemy.defeated.connect(_on_enemy_defeated)


func _on_enemy_defeated() -> void:
	if not active:
		return
	enemies_remaining = maxi(enemies_remaining - 1, 0)
	_update_display()
	if enemies_remaining == 0:
		call_deferred("_advance_wave")


func _advance_wave() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if not active or enemies_remaining != 0 or game_state == null or game_state.current_room_id != "ash_barracks":
		return
	if not is_instance_valid(participant) or participant.is_dead:
		_reset_trial()
		return
	if wave == 1:
		wave = 2
		_spawn_wave()
		_update_display()
		return
	active = false
	completed = game_state.unlock_shortcut(CLEAR_EVENT)
	if completed:
		game_state.add_item("barracks_insignia")
		game_state.add_gold(45)
		participant.add_xp(4)
	participant = null
	_update_display()


func _on_room_changed(room_id: String) -> void:
	if room_id == "ash_barracks" or not active:
		return
	_reset_trial()


func _reset_trial() -> void:
	active = false
	participant = null
	wave = 0
	enemies_remaining = 0
	for enemy in wave_enemies.get_children():
		enemy.queue_free()
	_update_display()


func _update_display() -> void:
	if challenge_label == null:
		return
	if completed:
		challenge_label.text = "TRIAL CLEARED  •  CAUSEWAY LOOP OPEN"
	elif active:
		challenge_label.text = "BARRACKS TRIAL  •  WAVE %d/2  •  %d LEFT" % [wave, enemies_remaining]
	else:
		challenge_label.text = "TWO WAVES  •  INSIGNIA + 45 GOLD + 4 XP"
	if beacon != null:
		beacon.refresh()
	trial_changed.emit()
