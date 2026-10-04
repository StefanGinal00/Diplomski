extends "res://tests/boss_combat_presentation_smoke.gd"

const Music = preload("res://BossMusic.gd")
const Safety = preload("res://BossEncounterSafety.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_boss_music.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var music := game.get_node("AmbientSoundscape")
	var player := game.get_node("Player")
	music.process_mode = Node.PROCESS_MODE_ALWAYS
	var paths := {}
	for track_id in Music.TRACKS:
		var stream: AudioStream = Music.load_track(track_id)
		_check(stream != null and stream.get_length() > 30.0, "Missing/truncated boss track: " + track_id)
		_check(not paths.has(stream.resource_path), "Two bosses share a music file")
		paths[stream.resource_path] = true
		if stream is AudioStreamWAV:
			_check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and stream.loop_end > 0, "WAV loop missing")
		else:
			_check(stream is AudioStreamOggVorbis and stream.loop, "OGG loop missing")
		print("MUSIC_ASSET ", track_id, " seconds=", stream.get_length())
	var bosses: Array[Node] = []
	for boss in get_nodes_in_group("boss"): bosses.append(boss)
	var marshal: Node = load("res://EmberMarshal.tscn").instantiate()
	game.get_node("AshArena/Combatants").add_child(marshal)
	bosses.append(marshal)
	_check(bosses.size() == 7, "Expected six bosses and one miniboss")
	for boss in bosses:
		state.set_current_room(Safety.ROOMS[boss.boss_id])
		music.register_boss(boss)
		music.register_boss(boss) # Idempotent rematch wiring.
		boss.battle_started.emit()
		var expected := Music.track_for(boss.boss_id)
		_check(music.current_track == expected and music.boss_active, "Wrong encounter theme")
		_check(music.players[music.active_player_index].stream.resource_path == Music.TRACKS[expected], "Theme selected but asset not playing")
		music.set_enabled(false)
		await create_timer(0.4).timeout
		for voice in music.players:
			_check(not voice.playing and voice.stream == null, "Muted music retained voice/resource")
		music.set_enabled(true)
		_check(music.current_track == expected, "Unmute lost encounter identity")
		# Exercise the native death cancellation condition, without changing saves.
		player.is_dead = true
		boss.target_player = player
		boss.get_node("EncounterSafety").cancelled = false
		boss.get_node("EncounterSafety").should_suspend()
		_check(not music.boss_active and music.current_track == state.current_room_id, "Death left boss music active")
		player.is_dead = false
		boss.battle_started.emit()
		boss.is_dead = true
		boss.defeated.emit()
		_check(music.current_track == ("finale" if boss.boss_id == "hollow_sovereign" else state.current_room_id), "Defeat handoff lost ambience/finale")
		boss.is_dead = false
		state.set_current_room("training_passage")
		_check(not music.boss_active and music.current_track == "training_passage", "Room change retained battle/finale")
	await create_timer(1.3).timeout
	_check(music.players[1 - music.active_player_index].stream == null, "Outgoing fade retained music resource")
	for key in Music.TRACKS:
		_check(not music.streams.has(key), "Music cached all encounters in memory")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("BOSS MUSIC TEST PASSED: seven distinct looped assets, signals, mute, death, victory, room exit and resource release")
		quit(0)
	else: quit(1)
