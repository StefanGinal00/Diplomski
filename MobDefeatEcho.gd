extends Sprite2D
## Brief visual follow-through. Native enemy death/drops remain immediate.
const DURATION := 0.24
const MAX_ACTIVE := 16
const GROUP := "mob_defeat_echo"
var age := 0.0
var origin := Transform2D.IDENTITY
var airborne := false

static func hook(art: Sprite2D, identity: String) -> void:
	if Engine.is_editor_hint() or art.get_parent().is_in_group("neutral_creature"):
		return
	var callback := spawn.bind(art, identity)
	if not art.get_parent().defeated.is_connected(callback):
		art.get_parent().defeated.connect(callback)

static func spawn(art: Sprite2D, identity: String) -> Sprite2D:
	if not is_instance_valid(art) or not art.is_inside_tree() or not art.is_visible_in_tree():
		return null
	var actor := art.get_parent()
	if actor.is_in_group("neutral_creature"):
		return null
	var parent := actor.get_parent()
	if parent == null or parent.is_queued_for_deletion():
		return null
	var tree := art.get_tree()
	var transition := tree.root.get_node_or_null("RoomTransition")
	if transition != null and transition.is_transitioning:
		return null
	if tree.get_nodes_in_group(GROUP).size() >= MAX_ACTIVE or tree.get_nodes_in_group("boss_cosmetic_effect").size() >= 64:
		return null
	var echo := new()
	echo.texture = art.texture
	echo.texture_filter = art.texture_filter
	echo.hframes = art.hframes
	echo.vframes = art.vframes
	echo.frame = art.frame
	echo.offset = art.offset
	echo.flip_h = art.flip_h
	echo.flip_v = art.flip_v
	echo.centered = art.centered
	# Retain the warm Ash Sentry palette and any existing atlas mask.
	echo.material = art.material.duplicate() if art.material != null else null
	echo.modulate = art.modulate
	echo.airborne = identity in ["wisp", "shade"]
	echo.z_index = 1
	parent.add_child(echo)
	echo.global_transform = art.global_transform
	echo.origin = art.global_transform
	var materials = preload("res://EnemyAttackArt.gd")
	var frame_id: int = materials.CONTACTS.get(identity, materials.PROJECTILES.get(identity, 8))
	preload("res://BossBurst.gd").spawn(parent, actor.global_position, Color.WHITE, "impact", Vector2(10, 10), 0.16, frame_id)
	return echo

func _ready() -> void:
	add_to_group(GROUP)
	add_to_group("boss_cosmetic_effect")
	visibility_changed.connect(_on_visibility_changed)
	var state := get_node_or_null("/root/GameState")
	if state != null:
		state.room_changed.connect(_retire)
		state.checkpoint_resting.connect(_retire)
	var transition := get_node_or_null("/root/RoomTransition")
	if transition != null:
		transition.transition_started.connect(_retire)

func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		_retire()

func _retire(_unused: String = "") -> void:
	hide()
	queue_free()

func _process(delta: float) -> void:
	if is_queued_for_deletion():
		return
	age += delta
	if age >= DURATION:
		_retire()
		return
	var progress := age / DURATION
	self_modulate.a = 1.0 - progress
	# Registered sprite origins keep ground feet planted; only spectral/flying
	# bodies lift slightly. Never rotate a grounded corpse through its floor.
	var pose := origin
	pose.x *= 1.0 - progress * 0.06
	pose.y *= 1.0 - progress * (0.08 if airborne else 0.14)
	if airborne:
		pose.origin.y -= progress * 4
	global_transform = pose
