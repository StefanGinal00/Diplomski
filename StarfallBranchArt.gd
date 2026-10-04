@tool
extends Node2D
## Static edge dressing on existing side floors; no geometry or task changes.

const BOTANY := preload("res://StarfallBotany.gd")
var pockets: Array[Rect2] = []
var retired: Array[Label] = []
var theme := ""
var built := false


func _ready() -> void:
	z_index = -2
	set_process(false)
	call_deferred("_build")


func _build() -> void:
	if built:
		return
	theme = String(get_parent().get_parent().get_parent().name)
	for named in ["Branch1_Chamber", "Branch3_Chamber", "Branch5_Chamber", "Niche1_Crest", "Niche4_Crest"]:
		var floor_node := get_parent().get_node_or_null(NodePath(named)) as StaticBody2D
		# The schematic editor may omit gameplay branch floors. Never invent a
		# different editor-only position; draw only where the authored floor exists.
		if floor_node == null:
			continue
		var collision := floor_node.get_node("CollisionShape2D") as CollisionShape2D
		var size: Vector2 = collision.shape.size
		var top_left := to_local(collision.to_global(-size * 0.5))
		var height := 36.0 if String(named).begins_with("Niche") else 135.0
		pockets.append(Rect2(top_left - Vector2(0, height), Vector2(size.x, height)))
		var label_name: String = named.replace("_Chamber", "_Label").replace("_Crest", "_Label")
		var label := get_parent().get_node_or_null(NodePath(label_name)) as Label
		if label != null and label.visible:
			label.hide()
			retired.append(label)
	built = true
	queue_redraw()


func _draw() -> void:
	var atlas := preload("res://StarfallTaskAtlas.gd")
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var tint := Color("a4b3aa") if theme=="StarfallRootedHall" else Color("b0abbf")
	for rect in pockets:
		for side in 2:
			var at := Vector2(rect.position.x+9 if side==0 else rect.end.x-9,rect.end.y)
			atlas.draw_at(self,"post_moss" if side==0 else "post_carved",at,16,24,tint)
		if rect.size.y<70: continue
		var at := Vector2(rect.position.x+48,rect.end.y)
		match theme:
			"StarfallOutskirts": atlas.draw_at(self,"barricade",at,44,29,tint)
			"StarfallSilentGate": atlas.draw_at(self,"post_carved",at,19,32,tint)
			"StarfallMemoryVault": atlas.draw_at(self,"books",at,38,24,tint)
			"StarfallRootedHall": atlas.draw_at(self,"growth_done",at,42,28,tint)
			"StarfallSoulCrucible": atlas.draw_at(self,"post_carved",at,22,29,Color("9f96b3"))
			"StarfallSunlessPassage": atlas.draw_at(self,"lantern",at,16,26,tint)
