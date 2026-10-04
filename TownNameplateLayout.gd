extends Node2D
## Screen-space name decluttering. Does not choose interaction targets.

const LANE_STEP := 17.0
const REFRESH_SECONDS := 0.1
var entries: Array[Dictionary] = []
var refresh_clock := 0.0
var registry_clock := 0.5
var visible_rects: Array[Rect2] = []


func _ready() -> void:
	call_deferred("refresh_layout")


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	refresh_clock += delta
	registry_clock += delta
	if refresh_clock >= REFRESH_SECONDS:
		refresh_clock = 0.0
		refresh_layout()


func _rescan() -> void:
	entries = entries.filter(func(entry: Dictionary) -> bool: return is_instance_valid(entry.actor) and is_instance_valid(entry.label) and get_parent().is_ancestor_of(entry.actor))
	for actor in get_tree().get_nodes_in_group("friendly_npc"):
		if not get_parent().is_ancestor_of(actor):
			continue
		var label := actor.get_node_or_null("NameLabel") as Label
		if label == null:
			continue
		var found := false
		for entry in entries:
			if entry.actor == actor:
				found = true
				break
		if found:
			continue
		entries.append({"actor": actor, "label": label, "base": label.position})
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_outline_color", Color(0.025, 0.045, 0.06, 0.95))
		label.add_theme_constant_override("outline_size", 2)
	registry_clock = 0.0


func _priority(actor: Node) -> int:
	if actor.get("player_dialogue_active") == true:
		return 0
	if is_instance_valid(actor.get("player_in_range")):
		return 1
	if actor.is_in_group("town_service"):
		return 2
	for group in ["hearth_quest_npc", "hearth_gate_quest_npc", "surveyor_npc", "starfall_route_npc", "dawn_archive_npc"]:
		if actor.is_in_group(group):
			return 3
	return 4


func text_screen_rect(label: Label) -> Rect2:
	var text_size := label.get_minimum_size()
	var local_rect := Rect2(Vector2((label.size.x - text_size.x) * 0.5, 0), text_size)
	return (label.get_global_transform_with_canvas() * local_rect).grow(3.0)


func refresh_layout() -> void:
	if not is_visible_in_tree():
		return
	if registry_clock >= 0.5:
		_rescan()
	visible_rects.clear()
	var viewport_bounds := get_viewport_rect().grow(-4)
	var occupied: Array[Rect2] = []
	var candidates: Array[Dictionary] = []
	var player := get_tree().get_first_node_in_group("player") as Node2D
	for entry in entries:
		var actor: Node2D = entry.actor
		var label: Label = entry.label
		if not is_instance_valid(actor) or not is_instance_valid(label):
			continue
		label.position = entry.base
		label.hide()
		if not actor.is_visible_in_tree() or actor.modulate.a < 0.5:
			continue
		for named in ["SocialBubble", "InteractionPrompt"]:
			var other := actor.get_node_or_null(named) as Control
			if other != null and other.is_visible_in_tree():
				occupied.append(other.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, other.size))
		var rect := text_screen_rect(label)
		if not viewport_bounds.intersects(rect):
			continue
		entry["priority"] = _priority(actor)
		entry["distance"] = actor.global_position.distance_squared_to(player.global_position) if player != null else 0.0
		candidates.append(entry)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.priority != b.priority:
			return a.priority < b.priority
		if not is_equal_approx(a.distance, b.distance):
			return a.distance < b.distance
		return a.actor.get_instance_id() < b.actor.get_instance_id()
	)
	for entry in candidates:
		var label: Label = entry.label
		for lane in range(3):
			label.position = entry.base - Vector2(0, LANE_STEP * lane)
			var rect := text_screen_rect(label)
			if not viewport_bounds.encloses(rect):
				continue
			var blocked := false
			for other in occupied:
				if rect.intersects(other):
					blocked = true
					break
			if not blocked:
				label.show()
				occupied.append(rect)
				visible_rects.append(rect)
				break
