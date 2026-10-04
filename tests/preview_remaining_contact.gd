extends SceneTree
func _initialize() -> void:
	var names := ["shaft_cutting","shaft_hollow","drowned_crossing","flooded_gallery","warden_approach","warden_arena","echo_gallery","tide_well","echo_nest","crystal_causeway","undertow_vault","resonance_sanctum","echo_depths","ash_causeway","ember_barracks","slag_reservoir","ash_chapel","ash_coliseum","castellan_throne","emberspine","citadel_sky","training_aqueduct","echo_road","ash_road"]
	for page in range(8):
		var suffix := "close" if page < 4 else "wide"
		var sheet := Image.create(1440, 540, false, Image.FORMAT_RGB8)
		for slot in range(6):
			var picture := Image.load_from_file(ProjectSettings.globalize_path("res://art/characters/preview_remaining_%s_%s.png" % [names[(page % 4) * 6 + slot], suffix]))
			picture.resize(480, 270, Image.INTERPOLATE_LANCZOS)
			picture.convert(Image.FORMAT_RGB8)
			sheet.blit_rect(picture, Rect2i(0, 0, 480, 270), Vector2i((slot % 3) * 480, (slot / 3) * 270))
		sheet.save_png("res://art/characters/preview_remaining_contact_%d.png" % page)
	quit()
