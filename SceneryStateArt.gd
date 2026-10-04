extends Sprite2D
## Native event colors remain authoritative; no polling or independent timer.
var source: Polygon2D
func bind_source(node: Polygon2D) -> void:
	source=node
	set_process(false)
	var state:=get_node("/root/GameState")
	for event in ["shortcut_changed","cache_opened","boss_progress_changed","zone_tier_changed","room_changed"]:
		state.connect(event,_schedule_refresh)
	var parent:=node.get_parent()
	while parent!=null:
		if parent.has_signal("sequence_changed"): parent.connect("sequence_changed",_schedule_refresh)
		parent=parent.get_parent()
	refresh()
func _schedule_refresh(_a: Variant=null,_b: Variant=null) -> void:
	call_deferred("refresh")
func refresh() -> void:
	if not is_instance_valid(source): return
	var value:=clampf(source.color.v*1.3,0.62,1.15)
	var tint:=Color.WHITE.lerp(Color(source.color,1),0.32)
	modulate=Color(tint.r*value,tint.g*value,tint.b*value,1)
