extends Area2D

signal activated
signal rest_blocked(message: String)
signal travel_requested(checkpoint)
signal player_left(checkpoint)

@export var lamp_id: String = "passage_lamp"
@export var lamp_name: String = "Passage Lamp"
@export var room_id: String = "training_passage"
@export_range(32.0, 500.0, 8.0) var enemy_block_radius: float = 150.0

var is_active: bool = false
var is_resting: bool = false
var player_in_range: Player

@onready var core: Polygon2D = $Core
@onready var glow: Polygon2D = $Glow
@onready var status_label: Label = $StatusLabel
@onready var interaction_prompt: Label = $InteractionPrompt
@onready var respawn_point: Marker2D = $RespawnPoint
@onready var save_chime: AudioStreamPlayer2D = $SaveChime


func _ready() -> void:
	interaction_prompt.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	save_chime.stream = _create_save_chime()
	call_deferred("_restore_saved_lamp_state")


func _process(delta: float) -> void:
	if not is_active:
		return
	glow.rotation += delta * 0.8
	glow.modulate.a = 0.55 + sin(Time.get_ticks_msec() * 0.004) * 0.2


func _unhandled_input(event: InputEvent) -> void:
	if player_in_range == null or is_resting or event.is_echo():
		return
	if event.is_action_pressed("fast_travel") and is_active:
		var game_state := get_node_or_null("/root/GameState")
		if game_state != null and game_state.get_discovered_lamps().size() >= 2:
			travel_requested.emit(self)
		else:
			rest_blocked.emit("Discover and activate another Save Lamp first.")
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact"):
		if _has_nearby_threat():
			interaction_prompt.text = "UNSAFE  •  ENEMIES NEARBY"
			rest_blocked.emit("Cannot rest while enemies are nearby.")
			get_viewport().set_input_as_handled()
			return
		_begin_rest(player_in_range)
		get_viewport().set_input_as_handled()


func _begin_rest(player: Player) -> void:
	if is_resting or player == null or player.is_dead:
		return
	is_resting = true
	player.begin_safe_rest()
	interaction_prompt.text = "RESTING..."
	var rest_tween := create_tween()
	rest_tween.set_parallel(true)
	rest_tween.tween_property(glow, "scale", Vector2(1.35, 1.35), 0.65).set_trans(Tween.TRANS_SINE)
	rest_tween.tween_property(core, "modulate", Color(1.5, 1.5, 1.2, 1.0), 0.65)
	await rest_tween.finished
	var settle_tween := create_tween()
	settle_tween.set_parallel(true)
	settle_tween.tween_property(glow, "scale", Vector2.ONE, 0.65).set_trans(Tween.TRANS_SINE)
	settle_tween.tween_property(core, "modulate", Color.WHITE, 0.65)
	await settle_tween.finished
	var saved := _save_progress(player)
	player.end_safe_rest()
	is_resting = false
	_update_interaction_prompt()
	if not saved:
		rest_blocked.emit("Save failed. Your previous save is still protected.")


func _save_progress(player: Player) -> bool:
	if player == null or player.is_dead:
		return false
	var game_state := get_node_or_null("/root/GameState")
	var quest_manager := get_tree().get_first_node_in_group("quest_manager")
	if game_state == null:
		return false
	player.set_checkpoint(respawn_point.global_position)
	if not game_state.save_at_checkpoint(player, quest_manager, respawn_point.global_position, lamp_id, lamp_name, room_id):
		return false
	is_active = true
	_set_active_visuals()
	save_chime.play()
	_update_interaction_prompt()
	activated.emit()
	return true


func _restore_saved_lamp_state() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or not game_state.has_checkpoint:
		return
	var was_discovered: bool = game_state.get_discovered_lamps().has(lamp_id)
	var is_legacy_checkpoint: bool = game_state.checkpoint_lamp_id == lamp_id or respawn_point.global_position.distance_to(game_state.checkpoint_position) <= 1.0
	if not was_discovered and not is_legacy_checkpoint:
		return
	is_active = true
	_set_active_visuals()
	_update_interaction_prompt()


func activate_from_travel() -> void:
	is_active = true
	_set_active_visuals()
	_update_interaction_prompt()


func _set_active_visuals() -> void:
	core.color = Color(0.2, 1.0, 0.72, 1.0)
	glow.color = Color(0.3, 1.0, 0.8, 0.35)
	status_label.text = "LAMP ACTIVE"


func _on_body_entered(body: Node) -> void:
	if body is Player:
		player_in_range = body
		_update_interaction_prompt()
		interaction_prompt.show()


func _on_body_exited(body: Node) -> void:
	if body != player_in_range:
		return
	player_in_range = null
	interaction_prompt.hide()
	player_left.emit(self)


func _update_interaction_prompt() -> void:
	if _has_nearby_threat():
		interaction_prompt.text = "[E] Unsafe  •  Enemies nearby"
		return
	var game_state := get_node_or_null("/root/GameState")
	var can_travel: bool = is_active and game_state != null and game_state.get_discovered_lamps().size() >= 2
	if can_travel:
		interaction_prompt.text = "[E] Rest & Save   [T] Travel"
	elif is_active:
		interaction_prompt.text = "[E] Save Again"
	else:
		interaction_prompt.text = "[E] Rest and Save"


func _has_nearby_threat() -> bool:
	for group_name in ["enemy", "boss"]:
		for threat in get_tree().get_nodes_in_group(group_name):
			if not threat is Node2D or not is_instance_valid(threat):
				continue
			if bool(threat.get("is_dead")):
				continue
			if global_position.distance_to(threat.global_position) <= enemy_block_radius:
				return true
	return false


func _create_save_chime() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.42
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in range(sample_count):
		var time := float(index) / sample_rate
		var envelope := pow(1.0 - time / duration, 2.0)
		var sample := (sin(TAU * 659.25 * time) * 0.55 + sin(TAU * 987.77 * time) * 0.25) * envelope
		data.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream
