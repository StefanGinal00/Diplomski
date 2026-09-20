extends Node

const SAMPLE_RATE := 22050
const LOOP_SECONDS := 8.0
const SILENT_DB := -60.0
const AMBIENT_DB := -24.0
const BOSS_DB := -20.0

var enabled: bool = true
var boss_active: bool = false
var current_track: String = ""
var active_player_index: int = 0
var players: Array[AudioStreamPlayer] = []
var streams: Dictionary = {}
var fade_tween: Tween
var game_state: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index in range(2):
		var player := AudioStreamPlayer.new()
		player.name = "AmbientTrack%d" % index
		player.volume_db = SILENT_DB
		add_child(player)
		players.append(player)
	game_state = get_node_or_null("/root/GameState")
	if game_state != null:
		enabled = bool(game_state.music_enabled)
		game_state.room_changed.connect(_on_room_changed)
		game_state.mode_changed.connect(_on_mode_changed)
		if game_state.session_started:
			call_deferred("_play_track", str(game_state.current_room_id))
	call_deferred("_connect_bosses")


func _exit_tree() -> void:
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	for player in players:
		player.stop()
		player.stream = null
	streams.clear()


func _connect_bosses() -> void:
	for boss in get_tree().get_nodes_in_group("boss"):
		if bool(boss.get("is_dead")):
			continue
		if boss.has_signal("battle_started"):
			boss.battle_started.connect(_on_boss_started)
		if boss.has_signal("defeated"):
			boss.defeated.connect(_on_boss_defeated)


func _on_mode_changed(_mode: String) -> void:
	if game_state != null and game_state.session_started:
		_play_track(str(game_state.current_room_id))


func _on_room_changed(room_id: String) -> void:
	boss_active = false
	_play_track(room_id)


func _on_boss_started() -> void:
	boss_active = true
	_play_track("boss")


func _on_boss_defeated() -> void:
	boss_active = false
	if game_state != null:
		_play_track(str(game_state.current_room_id))


func set_enabled(should_enable: bool) -> void:
	if enabled == should_enable:
		return
	enabled = should_enable
	if game_state != null:
		game_state.music_enabled = enabled
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	if not enabled:
		current_track = ""
		fade_tween = create_tween()
		fade_tween.set_parallel(true)
		for player in players:
			fade_tween.tween_property(player, "volume_db", SILENT_DB, 0.35)
		fade_tween.set_parallel(false)
		fade_tween.tween_callback(_stop_all)
	elif game_state != null and game_state.session_started:
		_stop_all()
		_play_track("boss" if boss_active else str(game_state.current_room_id))


func _stop_all() -> void:
	for player in players:
		player.stop()
		player.volume_db = SILENT_DB


func _play_track(track_id: String) -> void:
	if not enabled or track_id == current_track or players.size() < 2:
		return
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	var previous := players[active_player_index]
	var next_index := 1 - active_player_index
	var incoming := players[next_index]
	incoming.stop()
	incoming.stream = _get_stream(track_id)
	incoming.volume_db = SILENT_DB
	incoming.play()
	var target_db := BOSS_DB if track_id == "boss" else AMBIENT_DB
	fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(incoming, "volume_db", target_db, 1.2)
	fade_tween.tween_property(previous, "volume_db", SILENT_DB, 1.2)
	fade_tween.set_parallel(false)
	fade_tween.tween_callback(previous.stop)
	active_player_index = next_index
	current_track = track_id


func _get_stream(track_id: String) -> AudioStreamWAV:
	if streams.has(track_id):
		return streams[track_id]
	var frequencies: Array[float]
	match track_id:
		"sunken_shaft":
			frequencies = [73.5, 110.25, 147.0, 220.5]
		"shaft_hollow":
			frequencies = [82.4, 123.6, 164.8, 246.9]
		"shaft_crossing":
			frequencies = [69.3, 103.95, 138.6, 207.9]
		"shaft_gallery":
			frequencies = [77.8, 116.7, 155.6, 233.4]
		"shaft_cistern":
			frequencies = [61.7, 92.55, 123.4, 185.1]
		"shaft_approach":
			frequencies = [55.0, 82.5, 110.0, 165.0]
		"echo_grotto":
			frequencies = [98.0, 147.0, 196.0, 294.0]
		"echo_gallery":
			frequencies = [87.3, 130.8, 174.6, 261.6]
		"echo_causeway":
			frequencies = [103.8, 155.7, 207.6, 311.4]
		"echo_vault":
			frequencies = [61.7, 92.5, 123.4, 185.1]
		"echo_archive":
			frequencies = [116.5, 155.6, 233.1, 311.1]
		"echo_tide_well":
			frequencies = [65.4, 98.0, 130.8, 196.0]
		"echo_nest":
			frequencies = [82.4, 123.5, 164.8, 247.0]
		"echo_sanctum":
			frequencies = [73.4, 110.1, 146.8, 220.2]
		"ash_causeway":
			frequencies = [65.4, 98.1, 130.8, 196.2]
		"ash_forge":
			frequencies = [58.3, 87.45, 116.6, 174.9]
		"ash_barracks":
			frequencies = [69.3, 103.95, 138.6, 207.9]
		"ash_arena":
			frequencies = [55.0, 82.5, 110.0, 220.0]
		"ash_reservoir":
			frequencies = [77.8, 116.7, 155.6, 233.4]
		"boss":
			frequencies = [82.5, 123.75, 165.0, 330.0]
		_:
			frequencies = [110.0, 165.0, 220.0, 330.0]
	var sample_count := int(SAMPLE_RATE * LOOP_SECONDS)
	var data := PackedByteArray()
	data.resize(sample_count * 4)
	for index in range(sample_count):
		var time := float(index) / SAMPLE_RATE
		var slow_wave := sin(TAU * time / LOOP_SECONDS)
		var pulse := 0.66 + 0.18 * slow_wave
		if track_id == "boss":
			pulse = 0.56 + 0.25 * sin(TAU * time * 2.0)
		var base := sin(TAU * frequencies[0] * time) * 0.34
		var middle := sin(TAU * frequencies[1] * time + 0.4) * 0.18
		var upper := sin(TAU * frequencies[2] * time + 1.1) * 0.11
		var shimmer := sin(TAU * frequencies[3] * time + slow_wave * 0.22) * 0.045
		var left := clampf((base + middle + upper + shimmer) * pulse, -1.0, 1.0)
		var right := clampf((base + middle * 0.86 + upper * 1.08 - shimmer) * pulse, -1.0, 1.0)
		data.encode_s16(index * 4, int(left * 32767.0))
		data.encode_s16(index * 4 + 2, int(right * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = true
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	stream.data = data
	streams[track_id] = stream
	return stream
