extends SceneTree

const CASES := [
	["Boss", "VOID SENTINEL"],
	["AbyssWarden", "ABYSS WARDEN"],
	["EchoMatriarch", "ECHO MATRIARCH"],
	["AshCastellan", "ASH CASTELLAN"],
	["HollowSovereign", "HOLLOW SOVEREIGN"],
	["StarfallGuardian", "STARFALL GUARDIAN"],
	["EmberMarshal", "EMBER MARSHAL"],
]


func _initialize() -> void:
	call_deferred("_render")


func _render() -> void:
	root.size = Vector2i(1400, 700)
	root.content_scale_size = Vector2i(1400, 700)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_boss_appearance_preview.json"
	state.start_new_game("normal")
	var gallery := Node2D.new()
	root.add_child(gallery)
	var backdrop := Polygon2D.new()
	backdrop.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1400, 0), Vector2(1400, 700), Vector2(0, 700)])
	backdrop.color = Color("151c2b")
	backdrop.z_index = -2
	gallery.add_child(backdrop)
	var title := Label.new()
	title.text = "BOSS SHEETS  /  LIVE ART SCALE  /  IDLE + RECOVERY"
	title.position = Vector2(36, 18)
	title.add_theme_font_size_override("font_size", 22)
	gallery.add_child(title)
	for i in range(CASES.size()):
		var x := 90.0 + i * 195
		var boss: CharacterBody2D = load("res://%s.tscn" % CASES[i][0]).instantiate()
		boss.set_physics_process(false)
		gallery.add_child(boss)
		boss.set_physics_process(false)
		boss.set_process(false)
		var art := boss.get_node("PaintedAppearance") as Sprite2D
		boss.get_node("CombatPresentation").hide()
		art.set_process(false)
		boss.position = Vector2(x, 324.0 - art.position.y)
		var clone := Sprite2D.new()
		clone.texture = art.texture
		clone.hframes = art.hframes
		clone.vframes = art.vframes
		clone.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		clone.scale = art.scale
		art._apply_pose(3)
		clone.frame = art.frame
		clone.offset = art.offset
		clone.material = art.material.duplicate()
		clone.flip_h = art.flip_h
		clone.position = Vector2(x, 583.0)
		art._apply_pose(0)
		gallery.add_child(clone)
		var label := Label.new()
		label.text = CASES[i][1]
		label.position = Vector2(x - 92, 602)
		label.size = Vector2(184, 28)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		gallery.add_child(label)
	for y in [324.0, 583.0]:
		var ground := Line2D.new()
		ground.points = PackedVector2Array([Vector2(32, y), Vector2(1368, y)])
		ground.width = 2
		ground.default_color = Color("596575")
		ground.z_index = -1
		gallery.add_child(ground)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/characters/preview_boss_appearances.png")
	gallery.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
