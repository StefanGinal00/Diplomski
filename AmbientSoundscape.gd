extends Node

const SAMPLE_RATE := 22050
const LOOP_SECONDS := 8.0
const SILENT_DB := -60.0
const AMBIENT_DB := -24.0
const BOSS_DB := -20.0

var enabled: bool = true
var boss_active: bool = false
var boss_track_id: String = "boss"
var finale_active: bool = false
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
			call_deferred("_play_track", _track_for_room(str(game_state.current_room_id)))
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
		register_boss(boss)


func register_boss(boss: Node) -> void:
	if boss == null or bool(boss.get("is_dead")):
		return
	if boss.has_signal("battle_started"):
		var start_callback := _on_boss_started.bind(boss)
		if not boss.battle_started.is_connected(start_callback):
			boss.battle_started.connect(start_callback)
	if boss.has_signal("defeated"):
		var defeat_callback := _on_boss_defeated.bind(boss)
		if not boss.defeated.is_connected(defeat_callback):
			boss.defeated.connect(defeat_callback)


func _on_mode_changed(_mode: String) -> void:
	if game_state != null and game_state.session_started:
		_play_track(_track_for_room(str(game_state.current_room_id)))


func _on_room_changed(room_id: String) -> void:
	boss_active = false
	boss_track_id = "boss"
	finale_active = false
	_play_track(_track_for_room(room_id))


func _on_boss_started(boss: Node) -> void:
	boss_active = true
	finale_active = false
	boss_track_id = "hollow_boss" if str(boss.get("boss_id")) == "hollow_sovereign" else "boss"
	_play_track(boss_track_id)


func _on_boss_defeated(boss: Node) -> void:
	boss_active = false
	if game_state != null:
		finale_active = str(boss.get("boss_id")) == "hollow_sovereign"
		_play_track("finale" if finale_active else _track_for_room(str(game_state.current_room_id)))


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
		_play_track(boss_track_id if boss_active else ("finale" if finale_active else _track_for_room(str(game_state.current_room_id))))


func _track_for_room(room_id: String) -> String:
	if room_id == "starfall_citadel" and game_state != null and bool(game_state.defeated_bosses.get("hollow_sovereign", false)):
		return "starfall_citadel_dawn"
	return room_id


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
	var target_db := BOSS_DB if track_id in ["boss", "hollow_boss"] else AMBIENT_DB
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
		"shaft_drift":
			frequencies = [65.4, 98.1, 130.8, 196.2]
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
		"echo_haven_outskirts":
			frequencies = [92.5, 138.8, 185.0, 277.5]
		"echo_haven":
			frequencies = [130.8, 164.8, 196.0, 261.6]
		"echo_gallery":
			frequencies = [87.3, 130.8, 174.6, 261.6]
		"echo_depths":
			frequencies = [77.8, 116.7, 155.6, 233.4]
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
		"ash_emberspine":
			frequencies = [58.3, 87.45, 116.6, 174.9]
		"ash_hearth_outskirts":
			frequencies = [73.4, 110.1, 146.8, 220.2]
		"ash_hearth":
			frequencies = [110.0, 146.8, 174.6, 220.0]
		"ash_forge":
			frequencies = [58.3, 87.45, 116.6, 174.9]
		"ash_barracks":
			frequencies = [69.3, 103.95, 138.6, 207.9]
		"ash_arena":
			frequencies = [55.0, 82.5, 110.0, 220.0]
		"ash_reservoir":
			frequencies = [77.8, 116.7, 155.6, 233.4]
		"ash_chapel":
			frequencies = [65.4, 98.1, 164.8, 261.6]
		"ash_throne":
			frequencies = [55.0, 82.4, 123.5, 196.0]
		"starfall_gate":
			frequencies = [123.5, 185.25, 246.9, 370.4]
		"starfall_ward":
			frequencies = [130.8, 196.2, 261.6, 392.4]
		"starfall_citadel":
			frequencies = [130.8, 164.8, 196.0, 329.6]
		"starfall_citadel_dawn":
			frequencies = [146.8, 220.0, 293.7, 440.0]
		"starfall_outskirts":
			frequencies = [73.4, 110.0, 164.8, 246.9]
		"starfall_ramparts":
			frequencies = [69.3, 103.9, 138.6, 207.8]
		"starfall_silent_gate":
			frequencies = [65.4, 98.1, 130.8, 196.2]
		"starfall_memory_vault":
			frequencies = [82.4, 123.5, 164.8, 247.0]
		"starfall_rooted_hall":
			frequencies = [69.3, 103.9, 138.6, 207.8]
		"starfall_empty_court":
			frequencies = [61.7, 92.6, 138.7, 246.9]
		"starfall_soul_crucible":
			frequencies = [69.3, 103.9, 155.6, 233.1]
		"starfall_sunless_passage":
			frequencies = [58.3, 87.3, 130.8, 196.2]
		"starfall_hollow_throne":
			frequencies = [55.0, 82.5, 110.0, 165.0]
		"boss":
			frequencies = [82.5, 123.75, 165.0, 330.0]
		"hollow_boss":
			frequencies = [55.0, 82.5, 138.6, 220.0]
		"finale":
			frequencies = [110.0, 164.8, 220.0, 329.6]
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
		elif track_id == "hollow_boss":
			pulse = 0.54 + 0.16 * sin(TAU * time * 1.5) + 0.1 * sin(TAU * time * 3.0)
		elif track_id == "finale":
			pulse = 0.72 + 0.12 * sin(TAU * time * 0.5)
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
