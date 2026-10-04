extends SceneTree

var failures: Array[String] = []
var room: Node2D
var first: Area2D
var second: Area2D


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _resident(actor_name: String, at: Vector2) -> Area2D:
	var marker := Marker2D.new()
	marker.name = actor_name + "Stop"
	marker.position = at
	marker.add_to_group("town_social_spot")
	room.add_child(marker)
	var actor: Area2D = load("res://TownResident.tscn").instantiate()
	actor.name = actor_name
	actor.position = at
	actor.route_marker_names = PackedStringArray([marker.name])
	actor.social_lines = PackedStringArray(["The market is open."])
	room.add_child(actor)
	actor.set_process(false)
	actor.get_node("ResidentMotion").set_process(false)
	actor.current_stop_marker = marker
	return actor


func _begin() -> void:
	first._end_social_exchange(true)
	first.social_cooldown = 0
	second.social_cooldown = 0
	first._try_social_exchange()
	_check(first.social_partner == second and second.social_partner == first, "Exchange did not establish reciprocal partners")
	_check(first.social_remaining > 0 and second.social_remaining > 0, "Exchange did not start for both residents")


func _ended(context: String) -> void:
	_check(first.social_remaining == 0 and second.social_remaining == 0, context + ": conversation remained active")
	_check(first.social_partner == null and second.social_partner == null, context + ": partner references survived")
	_check(not first.social_bubble.visible and not second.social_bubble.visible, context + ": speech bubbles survived")


func _player() -> Player:
	var template: Node = load("res://Game.tscn").instantiate()
	var actor := template.get_node("Player") as Player
	template.remove_child(actor)
	template.free()
	root.add_child(actor)
	actor.process_mode = Node.PROCESS_MODE_DISABLED
	actor.collision_layer = 0
	actor.collision_mask = 0
	actor.get_node("Camera2D").enabled = false
	return actor


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_resident_conversation_save.json"
	state.start_new_game("normal")
	room = Node2D.new()
	root.add_child(room)
	first = _resident("First", Vector2(0, 0))
	second = _resident("Second", Vector2(80, 0))
	first.talk_partner = NodePath("../Second")
	second.talk_partner = NodePath("../First")
	var first_motion := first.get_node("ResidentMotion")
	var second_motion := second.get_node("ResidentMotion")
	var collider := first.get_node("CollisionShape2D")
	var shape_before: RID = collider.shape.get_rid()
	var collision_before: Transform2D = collider.transform
	var label_before: Vector2 = first.name_label.position

	_begin()
	first_motion._process(0.1)
	second_motion._process(0.1)
	_check(first_motion.facing > 0 and second_motion.facing < 0, "Stationary partners did not face one another")
	_check(first_motion._is_speaking() and not second_motion._is_speaking(), "Listener gestured during the opening line")
	var line_index: int = first.social_line_index
	second._try_social_exchange()
	_check(first.social_line_index == line_index and first.social_initiator, "Receiver restarted an active exchange")
	first._update_social(1.8)
	second._update_social(1.8)
	_check(not first_motion._is_speaking() and second_motion._is_speaking(), "Gestures did not follow the reply bubble")
	first._update_social(1.7)
	_ended("Natural completion")
	first.social_cooldown = 0
	first._try_social_exchange()
	_check(first.social_remaining == 0, "Partner cooldown was ignored")
	second.social_cooldown = 0
	second.set_player_dialogue_active(true)
	first._try_social_exchange()
	_check(first.social_remaining == 0, "Resident interrupted a partner's player dialogue")
	second.set_player_dialogue_active(false)
	second.hide()
	first._try_social_exchange()
	_check(first.social_remaining == 0, "Hidden partner accepted a conversation")
	second.show()
	first.talk_partner = NodePath(".")
	first._try_social_exchange()
	_check(first.social_remaining == 0, "Resident started a conversation with itself")
	first.talk_partner = NodePath("../Second")

	_begin()
	var third := _resident("Third", Vector2(40, 0))
	# Simulate a stale one-sided link after the receiver acquired a new partner.
	second.social_partner = third
	third.social_partner = second
	third.social_remaining = 1
	first._update_social(0.1)
	_check(first.social_partner == null and second.social_partner == third and third.social_remaining > 0, "Stale exchange canceled an unrelated conversation")
	second._end_social_exchange(true)
	third.free()

	_begin()
	second.position.x = 300
	first._update_social(0.1)
	_ended("Partner out of range")
	second.position.x = 80
	_begin()
	second.hide()
	_ended("Partner hidden")
	second.show()
	_begin()
	room.hide()
	room.process_mode = Node.PROCESS_MODE_DISABLED
	_ended("Inactive room")
	_check(first_motion.stride == 0 and first_motion.phase == 0, "Room hiding retained stale stride")
	room.show()
	room.process_mode = Node.PROCESS_MODE_INHERIT

	_begin()
	var hero := _player()
	hero.position = Vector2(-20, 0)
	first._on_body_entered(hero)
	_ended("Player arrival")
	_check(first.prompt.visible and first.get_attention_target() == hero, "Nearby player did not receive attention/prompt")
	first.set_player_dialogue_active(true)
	first_motion._process(0.1)
	_check(first_motion.facing < 0 and first_motion._is_speaking() and not first.prompt.visible, "Player conversation pose/prompt incorrect")
	first.indoor_state = "entering"
	first.indoor_timer = 0.2
	first._process(1.0)
	_check(first.indoor_timer == 0.2 and first.visible, "Resident entered a house during player dialogue")
	first.indoor_state = ""
	first.set_player_dialogue_active(false)
	_check(first.prompt.visible, "Talk prompt did not return on dialogue close")
	first.set_player_dialogue_active(true)
	hero.free()
	first._process(0.1)
	_check(first.player_in_range == null and not first.player_dialogue_active and not first.prompt.visible, "Freed player left the NPC locked in dialogue")

	hero = _player()
	for unavailable in ["dead", "hidden", "queued"]:
		first._on_body_entered(hero)
		first.set_player_dialogue_active(true)
		match unavailable:
			"dead": hero.is_dead = true
			"hidden": hero.hide()
			"queued": hero.queue_free()
		first._process(0.1)
		_check(first.get_attention_target() == null and not first.player_dialogue_active and not first.prompt.visible, unavailable + " player retained attention")
		hero.is_dead = false
		hero.show()
	await process_frame

	_begin()
	second.queue_free()
	first._update_social(0.1)
	_check(first.social_partner == null and first.social_remaining == 0, "Queued partner retained conversation")
	await process_frame
	second = _resident("Second", Vector2(80, 0))
	_begin()
	second.free()
	_check(first.social_partner == null and first.social_remaining == 0, "Freed partner retained conversation")
	# A manually paused fixture without a player must still honor its pause.
	first.set_player_dialogue_active(true)
	var position_before: Vector2 = first.position
	first._process(0.5)
	_check(first.position == position_before and first.player_dialogue_active, "Explicit dialogue pause was discarded")
	first.set_player_dialogue_active(false)
	first.route_markers[0].position.x = 40
	first.pause_remaining = 0
	first._process(0.2)
	_check(first.position.x > position_before.x, "Resident failed to resume its route after interruption")
	_check(collider.shape.get_rid() == shape_before and collider.transform == collision_before and first.name_label.position == label_before, "Conversation presentation altered collider/UI")
	room.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("RESIDENT CONVERSATION TEST PASSED: handshake, turns, facing, player priority, interior pause, lifecycle, route continuation, collider/UI invariants")
		quit(0)
	else:
		quit(1)
