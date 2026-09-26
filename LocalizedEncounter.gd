extends Area2D

signal encounter_started(encounter_id: String)
signal encounter_completed(encounter_id: String)

@export var encounter_id: String = "optional_ambush"
@export var zone_id: String = "sunken_shaft"
@export var enemy_scenes: Array[PackedScene] = []
@export var spawn_offsets: Array[Vector2] = []
@export var completion_event_id: String = ""
@export var minimum_zone_tier: int = 0
@export var encounter_title: String = ""
@export var required_event_ids: PackedStringArray = []
@export var locked_hint: String = "RESTORE THE MACHINERY FIRST"
@export var dormant_hint: String = "DORMANT - RETURN AFTER THE WARDEN"
@export var required_boss_id: String = ""
@export_range(0, 20, 1) var enemy_health_bonus: int = 0

var triggered: bool = false
var spawned_enemies: Array[Node2D] = []
var completed := false
var remaining_foes: Dictionary = {}
var status_label: Label


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var state := get_node_or_null("/root/GameState")
	if state != null:
		completed = not completion_event_id.is_empty() and bool(state.unlocked_shortcuts.get(completion_event_id, false))
		state.zone_tier_changed.connect(_on_tier_changed)
		state.shortcut_changed.connect(_on_shortcut_changed)
		state.boss_progress_changed.connect(_on_boss_changed)
	triggered = completed
	if not encounter_title.is_empty():
		status_label = Label.new()
		status_label.position = Vector2(-190, -166)
		status_label.size = Vector2(380, 55)
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_label.add_theme_font_size_override("font_size", 10)
		add_child(status_label)
	_refresh_status()


func _tier_available() -> bool:
	var state := get_node_or_null("/root/GameState")
	if not required_boss_id.is_empty() and (state == null or not bool(state.defeated_bosses.get(required_boss_id, false))):
		return false
	return minimum_zone_tier <= 0 or (state != null and state.get_zone_tier(zone_id) >= minimum_zone_tier)


func _on_boss_changed(boss_id: String) -> void:
	if boss_id == required_boss_id:
		_refresh_status()


func _requirements_met() -> bool:
	var state := get_node_or_null("/root/GameState")
	for event_id in required_event_ids:
		if state == null or not bool(state.unlocked_shortcuts.get(event_id, false)):
			return false
	return true


func _on_shortcut_changed(event_id: String) -> void:
	if required_event_ids.has(event_id):
		_refresh_status()


func _on_tier_changed(changed_zone: String, _tier: int) -> void:
	if changed_zone == zone_id:
		_refresh_status()


func _refresh_status() -> void:
	if status_label == null:
		return
	var detail := "ENTER TO INVESTIGATE"
	if completed:
		detail = "CLEARED - REWARD UNSEALED"
	elif not _tier_available():
		detail = dormant_hint
	elif not _requirements_met():
		detail = locked_hint
	elif triggered:
		detail = "GUARDIANS REMAINING: %d" % remaining_foes.size()
	status_label.text = encounter_title + "\n" + detail


func _on_body_entered(body: Node) -> void:
	if triggered or not body.is_in_group("player") or not _tier_available() or not _requirements_met():
		return
	triggered = true
	set_deferred("monitoring", false)
	call_deferred("_spawn_encounter")


func _spawn_encounter() -> void:
	var spawn_parent := get_parent() as Node2D
	if spawn_parent == null:
		return
	for index in range(enemy_scenes.size()):
		var scene: PackedScene = enemy_scenes[index]
		if scene == null:
			continue
		var enemy := scene.instantiate() as Node2D
		if enemy == null:
			continue
		enemy.name = "AmbushFoe%d" % index
		var offset := spawn_offsets[index] if index < spawn_offsets.size() else Vector2(float(index) * 90.0, -32.0)
		enemy.position = position + offset
		enemy.set("zone_id", zone_id)
		if enemy_health_bonus > 0 and enemy.get("max_health") != null:
			enemy.set("max_health", int(enemy.get("max_health")) + enemy_health_bonus)
		enemy.set_meta("localized_encounter_id", encounter_id)
		# Optional guardians never belong to the authored NestVeil objective.
		if enemy.is_in_group("nest_brood"):
			enemy.set("counts_for_nest", false)
		if enemy.has_signal("defeated"):
			remaining_foes[index] = true
			enemy.connect("defeated", Callable(self, "_on_foe_defeated").bind(index), CONNECT_ONE_SHOT)
		spawn_parent.add_child(enemy)
		spawned_enemies.append(enemy)
	_refresh_status()
	encounter_started.emit(encounter_id)


func _on_foe_defeated(index: int) -> void:
	remaining_foes.erase(index)
	if remaining_foes.is_empty() and not completed:
		completed = true
		var state := get_node_or_null("/root/GameState")
		if state != null and not completion_event_id.is_empty():
			state.unlock_shortcut(completion_event_id)
		encounter_completed.emit(encounter_id)
	_refresh_status()
