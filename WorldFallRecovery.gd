extends Node
## Last supported position, per room. A fail-safe, not an invisible catch floor.
## Does not heal, change checkpoints, grant progress, or write a save.
const Layout := preload("res://WorldLayout.gd")
const Hurt := preload("res://CombatHurtbox.gd")
var player: Player
var state: Node
var room_id := ""
var bounds := Rect2()
var safe_positions := {}
var surfaces: Array[Rect2] = []
var grace := 0.0
var sample_clock := 0.0
var recoveries := 0

func _ready() -> void:
	player = get_parent().get_node_or_null("Player")
	state = get_node("/root/GameState")
	state.room_changed.connect(_room_changed)
	call_deferred("_room_changed", state.current_room_id)

func _room_changed(id: String) -> void:
	room_id = id
	grace = 0.75
	call_deferred("refresh_room")

func refresh_room() -> void:
	var room: Node2D = get_parent() if room_id=="training_passage" else get_parent().get_node_or_null(str(Layout.ROOM_NODES.get(room_id,"Missing")))
	if room == null: bounds=Rect2(); return
	var finish := get_parent().get_node("WorldPresentationFinish")
	var nodes: Array[Node] = finish._members(room)
	surfaces = preload("res://WorldSupport.gd").floors(nodes)
	bounds = Rect2()
	for rect in surfaces:
		bounds = rect if not bounds.has_area() else bounds.merge(rect)
	# Use the whole room's vertical range, never the currently visible floor.
	bounds = bounds.grow_individual(160, 400, 160, 280)

func _physics_process(delta: float) -> void:
	if player==null or player.is_dead or not state.session_started: return
	var transition := get_node_or_null("/root/RoomTransition")
	if transition!=null and transition.is_transitioning: grace=0.75; return
	grace = maxf(0, grace-delta)
	if grace>0 or not bounds.has_area(): return
	if OS.is_debug_build() and player.test_flight: return
	if not bounds.has_point(player.global_position):
		recover()
		return
	sample_clock += delta
	if sample_clock<0.15 or not player.is_on_floor(): return
	sample_clock=0
	if is_safe(player.global_position): safe_positions[room_id] = player.global_position

func is_safe(at: Vector2) -> bool:
	if not bounds.has_point(at): return false
	var space := player.get_world_2d().direct_space_state
	var shape := RectangleShape2D.new()
	shape.size = player.player_collision.shape.size - Vector2(1, 1)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape=shape
	query.transform=Transform2D(0,at)
	query.exclude=[player.get_rid()]
	# Walking deliberately ignores damage-only receivers, but a recovery point
	# inside a painted boss torso/head is still dangerous. Query that layer only
	# for this safety check; never change the player's navigation collision mask.
	query.collision_mask=player.collision_mask | Hurt.LAYER
	query.collide_with_areas=true
	for hit in space.intersect_shape(query,32):
		var body: Node = hit.collider
		if body is PhysicsBody2D: return false
		if Hurt.actor(body).is_in_group("enemy"): return false
		var script_path: String = body.get_script().resource_path if body.get_script()!=null else ""
		if "Hazard" in script_path or "Spike" in script_path or "Vent" in script_path or body.is_in_group("enemy"): return false
	var feet: float = player.player_collision.shape.size.y*0.5
	var ray := PhysicsRayQueryParameters2D.create(at+Vector2(0,feet-1),at+Vector2(0,feet+5),player.collision_mask,[player.get_rid()])
	var support := space.intersect_ray(ray)
	return not support.is_empty() and support.collider is StaticBody2D and not support.collider.is_in_group("breakable")

func recover() -> bool:
	if player==null or player.is_dead: return false
	var destination: Vector2 = safe_positions.get(room_id,Vector2.INF)
	if not destination.is_finite() or not is_safe(destination):
		destination=Vector2.INF
		var nearest := INF
		for floor_rect in surfaces:
			if floor_rect.size.x<48: continue
			for fraction in [0.5,0.25,0.75]:
				var candidate := Vector2(lerpf(floor_rect.position.x+18,floor_rect.end.x-18,fraction),floor_rect.position.y-player.player_collision.shape.size.y*0.5-0.1)
				var distance := candidate.distance_squared_to(player.global_position)
				if distance<nearest and is_safe(candidate): destination=candidate; nearest=distance
	if not destination.is_finite(): return false
	player._clear_drop_through()
	player.global_position=destination
	player.velocity=Vector2.ZERO
	player.is_dashing=false
	player.dash_visual.hide()
	player.jump_buffer_remaining=0
	player.is_invulnerable=true
	player.invulnerability_timer.start(1.0)
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera!=null: camera.reset_smoothing(); camera.force_update_scroll()
	grace=0.4
	recoveries+=1
	player.combat_message.emit("Returned to safe ground")
	return true
