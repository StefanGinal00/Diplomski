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
var wave_started := false
var suspended := false
var live_foes: Dictionary = {}
var foe_snapshots: Dictionary = {}


func _room_active() -> bool:
	var state := get_node_or_null("/root/GameState")
	if state == null: return true
	var ancestor := get_parent()
	while ancestor != null:
		for room_id in preload("res://WorldLayout.gd").ROOM_NODES:
			if str(ancestor.name) == preload("res://WorldLayout.gd").ROOM_NODES[room_id]:
				return state.current_room_id == room_id
		ancestor = ancestor.get_parent()
	return true # Standalone encounters and isolated fixtures have no room owner.


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var state := get_node_or_null("/root/GameState")
	if state != null:
		completed = not completion_event_id.is_empty() and bool(state.unlocked_shortcuts.get(completion_event_id, false))
		state.zone_tier_changed.connect(_on_tier_changed)
		state.shortcut_changed.connect(_on_shortcut_changed)
		state.boss_progress_changed.connect(_on_boss_changed)
		state.cache_opened.connect(_on_cache_opened)
	triggered = completed
	if not encounter_title.is_empty():
		status_label = Label.new()
		status_label.position = Vector2(-190, -166)
		status_label.size = Vector2(380, 55)
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_label.add_theme_font_size_override("font_size", 10)
		add_child(status_label)
	_refresh_status()
	call_deferred("_refresh_status") # Sibling rewards may be added after the trigger.


func _on_cache_opened(_cache_id: String) -> void:
	if completed:
		_refresh_status()


func _all_rewards_claimed() -> bool:
	if completion_event_id.is_empty():
		return false
	var state := get_node_or_null("/root/GameState")
	if state == null: return false
	var found := false
	for sibling in get_parent().get_children():
		if sibling.get_script() != preload("res://ResonanceCache.gd"):
			continue
		if not sibling.required_event_ids.has(completion_event_id):
			continue
		found = true
		if not bool(state.opened_caches.get(sibling.cache_id, false)): return false
	return found


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
		detail = "CLEARED - REWARD CLAIMED" if _all_rewards_claimed() else "CLEARED - REWARD UNSEALED"
	elif not _tier_available():
		detail = dormant_hint
	elif not _requirements_met():
		detail = locked_hint
	elif triggered:
		detail = "GUARDIANS REMAINING: %d" % remaining_foes.size()
	status_label.text = encounter_title + "\n" + detail


func _on_body_entered(body: Node) -> void:
	if triggered or not body.is_in_group("player") or body.get("is_dead") == true or not _room_active() or not _tier_available() or not _requirements_met():
		return
	triggered = true
	set_deferred("monitoring", false)
	call_deferred("_spawn_encounter")


func _spawn_encounter() -> void:
	if completed or wave_started or not triggered: return
	if not _room_active():
		# The player can cross a door before this deferred callback executes.
		triggered = false
		set_deferred("monitoring", true)
		return
	wave_started = true
	_spawn_remaining_foes(false)
	_refresh_status()
	encounter_started.emit(encounter_id)


func _spawn_remaining_foes(restoring: bool) -> void:
	var spawn_parent := get_parent() as Node2D
	if spawn_parent == null:
		return
	var state := get_node_or_null("/root/GameState")
	var encounter_key: String = state.world_actor_key(self) if state != null else ""
	for index in range(enemy_scenes.size()):
		if restoring and not remaining_foes.has(index): continue
		# Siblings from different ambushes share generated node names. Use the
		# stable trigger path plus authored slot, never an auto-renamed foe path.
		var foe_key := "encounter:%s/foe:%d" % [encounter_key, index]
		if not encounter_key.is_empty() and bool(state.defeated_enemies.get(foe_key, false)):
			continue
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
		if not encounter_key.is_empty(): enemy.set_meta("checkpoint_enemy_key", foe_key)
		# Optional guardians never belong to the authored NestVeil objective.
		if enemy.is_in_group("nest_brood"):
			enemy.set("counts_for_nest", false)
		if enemy.has_signal("defeated"):
			remaining_foes[index] = true
			enemy.connect("defeated", Callable(self, "_on_foe_defeated").bind(index), CONNECT_ONE_SHOT)
		spawn_parent.add_child(enemy)
		spawned_enemies.append(enemy)
		live_foes[index] = enemy
		if restoring and foe_snapshots.has(index):
			var snapshot: Dictionary = foe_snapshots[index]
			enemy.position = snapshot.position
			enemy.set("current_health", mini(int(snapshot.health), int(enemy.get("max_health"))))
			var bar := enemy.get_node_or_null("HealthBar") as ProgressBar
			if bar != null: bar.value = int(enemy.get("current_health"))
			for key in snapshot.anchors: enemy.set(key, snapshot.anchors[key])
	foe_snapshots.clear()


func suspend_encounter_population() -> void:
	if not wave_started or completed or suspended: return
	foe_snapshots.clear()
	for index in live_foes:
		var enemy: Node2D = live_foes[index]
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or enemy.get("is_dead") == true: continue
		var anchors := {}
		for key in ["start_x", "anchor_x", "anchor_position", "left_limit", "right_limit", "direction", "patrol_direction", "facing"]:
			if enemy.get(key) != null: anchors[key] = enemy.get(key)
		foe_snapshots[index] = {"position": enemy.position, "health": int(enemy.get("current_health")), "anchors": anchors}
		var callback := Callable(self, "_on_foe_defeated").bind(index)
		if enemy.has_signal("defeated") and enemy.is_connected("defeated", callback): enemy.disconnect("defeated", callback)
		for projectile in get_tree().get_nodes_in_group("enemy_projectile"):
			if projectile.get("source") == enemy: projectile.queue_free()
		# Stop this instance immediately, even if the room is reentered this frame.
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		enemy.hide()
		enemy.queue_free()
	live_foes.clear()
	spawned_enemies.clear()
	suspended = true


func activate_room_population() -> void:
	if not suspended or completed or not _room_active(): return
	suspended = false
	_spawn_remaining_foes(true)
	_refresh_status()


func _on_foe_defeated(index: int) -> void:
	if not triggered or completed or not remaining_foes.has(index): return
	remaining_foes.erase(index)
	live_foes.erase(index)
	if remaining_foes.is_empty() and not completed:
		completed = true
		var state := get_node_or_null("/root/GameState")
		if state != null and not completion_event_id.is_empty():
			state.unlock_shortcut(completion_event_id)
		encounter_completed.emit(encounter_id)
	_refresh_status()
