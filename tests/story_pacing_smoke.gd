extends "res://tests/story_scenes_smoke.gd"

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_story_pacing.json"
	state.start_new_game("normal")
	state.music_enabled = true
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var cinema: Node = game.get_node("UI").story_player
	var music := game.get_node("AmbientSoundscape")
	music.set_enabled(true)
	music._play_track("echo_haven")
	await create_timer(1.3).timeout
	var voice: AudioStreamPlayer = music.players[music.active_player_index]
	var original_stream: AudioStream = voice.stream
	_check(is_equal_approx(voice.volume_db, music.AMBIENT_DB), "Ambient baseline incorrect")
	cinema.play("opening")
	await create_timer(0.55).timeout
	_check(paused and music.story_reading, "Reading mix did not engage with modal")
	_check(is_equal_approx(voice.volume_db, music.AMBIENT_DB + music.STORY_DUCK_DB), "Reading mix failed while paused")
	_check(voice.playing and voice.stream == original_stream, "Reading restarted/replaced current music")
	# A track crossfade must keep both voices within the same reading mix.
	music._play_track("echo_grotto")
	await create_timer(0.2).timeout
	for index in range(2):
		_check(is_equal_approx(music.players[index].volume_db, maxf(music.SILENT_DB, music.voice_levels[index] + music.STORY_DUCK_DB)), "Crossfade fought reading gain")
	await create_timer(1.2).timeout
	_check(music.players[1 - music.active_player_index].stream == null, "Reading retained outgoing track")
	cinema.cancel()
	await create_timer(0.55).timeout
	_check(not music.story_reading and is_zero_approx(music.reading_gain_db) and not paused, "Cancel retained reading gain or pause")
	# Fast closing/reopening cannot let an old restore tween win.
	cinema.play("opening")
	await create_timer(0.1).timeout
	cinema.cancel()
	cinema.open_library()
	await create_timer(0.55).timeout
	_check(music.story_reading and is_equal_approx(music.reading_gain_db, music.STORY_DUCK_DB), "Rapid replay lost reading gain")
	music.set_enabled(false)
	await create_timer(0.4).timeout
	for channel in music.players:
		_check(not channel.playing and channel.stream == null, "Muted story kept an audio stream")
	music.set_enabled(true)
	await create_timer(1.3).timeout
	_check(is_equal_approx(music.players[music.active_player_index].volume_db, music.AMBIENT_DB + music.STORY_DUCK_DB), "Unmute ignored active reading mix")
	cinema.finish()
	await create_timer(0.55).timeout
	_check(is_zero_approx(music.reading_gain_db), "Library close failed to restore audio")
	# Context depends on actual memories, not quest reward claims or stage prefix.
	state.defeated_bosses["starfall_guardian"] = true
	var default_guardian: Array = Scenes.SCENES.guardian.pages.duplicate()
	_check(Scenes.pages_for(state, "guardian") == default_guardian, "Missing memories got already-collected text")
	for item in ["memory_sigil_shaft", "memory_sigil_echo", "memory_sigil_ash"]: state.inventory[item] = 1
	var adapted: Array = Scenes.pages_for(state, "guardian")
	_check("already with you" in adapted[2] and Scenes.SCENES.guardian.pages == default_guardian, "Route text missing or mutated shared catalog")
	cinema.play("guardian")
	state.inventory.erase("memory_sigil_echo")
	_check(cinema.narration_pages == adapted, "Narration snapshot changed during playback")
	cinema.cancel()
	state.inventory["memory_sigil_echo"] = 1
	_complete(state, 6)
	_check("watch has ended" in Scenes.pages_for(state, "memories")[2], "Late memory scene ignored Guardian progress")
	# Long contextual variants must fit at every currently supported desktop size.
	for resolution in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		await process_frame
		for id in ["guardian", "memories"]:
			cinema.play(id)
			cinema.page = 2
			cinema._show_page()
			cinema.advance()
			await process_frame
			_check(cinema.text_label.get_minimum_size().y <= cinema.text_label.size.y, "Contextual narration clipped: " + id)
			_check(cinema.text_label.get_global_rect().end.y <= cinema.next_button.get_global_rect().position.y, "Contextual narration overlaps controls")
			cinema.cancel()
	# Closing from a paused journal keeps its pause, but not a stale reading mix.
	paused = true
	cinema.open_library()
	cinema.finish()
	await create_timer(0.55).timeout
	_check(paused and not music.story_reading and is_zero_approx(music.reading_gain_db), "Nested pause/audio ownership mismatch")
	paused = false
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("STORY PACING TEST PASSED: paused music duck/restore, crossfade, mute, rapid replay, route-aware snapshot and three-size layout")
		quit(0)
	else: quit(1)
