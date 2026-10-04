extends Node
signal interrupted
## Shared interruption boundary; normal attack timing remains in native boss AI.
const ROOMS := {
	"void_sentinel": "training_passage", "abyss_warden": "sunken_shaft",
	"echo_matriarch": "echo_sanctum", "ash_castellan": "ash_throne",
	"starfall_guardian": "starfall_empty_court", "hollow_sovereign": "starfall_hollow_throne",
	"ember_marshal": "ash_arena",
}
const TIMERS := ["windup_remaining", "charge_windup", "volley_windup", "pulse_windup", "eruption_windup", "charge_remaining", "recovery_remaining", "turn_remaining", "eruption_flash", "pulse_flash", "impact_flash"]
const COOLDOWNS := ["shot_cooldown", "volley_cooldown", "charge_cooldown", "pulse_cooldown", "eruption_cooldown", "attack_delay"]
var properties := {}
var cancelled := false

func _ready() -> void:
	var boss := get_parent()
	for entry in boss.get_property_list():
		properties[String(entry.name)] = true
	boss.visibility_changed.connect(_on_visibility_changed)
	boss.defeated.connect(_abort)
	var state := get_node_or_null("/root/GameState")
	if state != null:
		state.room_changed.connect(_on_room_changed)
		state.checkpoint_resting.connect(_abort)
	var transition := get_node_or_null("/root/RoomTransition")
	if transition != null:
		transition.transition_started.connect(_abort)

func should_suspend() -> bool:
	var boss := get_parent()
	var state := get_node_or_null("/root/GameState")
	var transition := get_node_or_null("/root/RoomTransition")
	var target: Node = boss.target_player if is_instance_valid(boss.target_player) else null
	var suspended: bool = not boss.is_visible_in_tree() or (state != null and state.current_room_id != ROOMS[boss.boss_id]) or (transition != null and transition.is_transitioning) or (target != null and target.is_dead)
	if suspended:
		if not cancelled:
			_abort()
	else:
		cancelled = false
	return suspended

func _on_room_changed(room_id: String) -> void:
	if room_id != ROOMS[get_parent().boss_id]:
		_abort()

func _on_visibility_changed() -> void:
	if not get_parent().is_visible_in_tree():
		_abort()

func _abort(_unused: String = "") -> void:
	var boss := get_parent()
	# Defeat has its own music handoff (including the final victory theme).
	if not boss.is_dead:
		interrupted.emit()
	cancelled = true
	for key in TIMERS:
		if properties.has(key): boss.set(key, 0.0)
	for key in COOLDOWNS:
		if properties.has(key): boss.set(key, maxf(float(boss.get(key)), 1.0))
	if properties.has("active"): boss.active = false
	if properties.has("combat_state"): boss.combat_state = "approach"
	if properties.has("closing_distance"): boss.closing_distance = false
	boss.velocity = Vector2.ZERO
	for method in ["_hide_warnings", "_hide_floor_marks", "_hide_eruption_marks"]:
		if boss.has_method(method): boss.call(method)
	for child in boss.get_children():
		if child is Line2D:
			child.hide()
	for bolt in get_tree().get_nodes_in_group("enemy_projectile"):
		if bolt.get("source") == boss:
			bolt._retire()
	var effects := boss.get_node_or_null("CombatPresentation")
	if effects != null: effects._reset_transients()
	var art := boss.get_node_or_null("PaintedAppearance")
	if art != null:
		art._reset_transients()
		art._apply_pose(0)
