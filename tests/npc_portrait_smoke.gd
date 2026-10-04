extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _separate(art: Control, controls: Array) -> void:
	for control in controls:
		if control.visible:
			_check(not art.get_global_rect().intersects(control.get_global_rect()), "Portrait overlaps " + str(control.name))


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_npc_portrait_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var ui := game.get_node("UI")
	var neris := game.get_node("EchoHaven/Neris")
	var calen := game.get_node("EchoHaven/Calen")
	var orin := game.get_node("WayfarerMerchant")
	var vendor := game.get_node("EchoHaven/GlowmarketTrader")
	var forge := game.get_node("EchoHaven/CrystalAnvil")
	_check(neris.get_portrait_texture().resource_path.ends_with("neris_portrait_v1.png"), "Neris portrait not assigned")
	_check(orin.get_portrait_texture().resource_path.ends_with("orin_portrait_v1.png"), "Orin portrait not assigned")
	_check(calen.get_portrait_texture() == null, "Unrelated resident inherited Neris portrait")
	for actor in [neris, orin]:
		var texture: Texture2D = actor.get_portrait_texture()
		_check(texture.get_width() == 256 and texture.get_height() == 256, "Portrait import exceeds its UI texture budget")
	var neris_shape: RID = neris.get_node("CollisionShape2D").shape.get_rid()
	var orin_shape: RID = orin.get_node("CollisionShape2D").shape.get_rid()
	for resolution in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		await process_frame
		ui._on_npc_interaction_requested(neris)
		await process_frame
		_check(ui.dialogue_portrait.visible and ui.dialogue_portrait.texture == neris.portrait_texture, "Dialogue portrait missing")
		_check(ui.dialogue_portrait.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Portrait steals dialogue input")
		_separate(ui.dialogue_portrait, [ui.speaker_label, ui.dialogue_text, ui.dialogue_primary_button, ui.dialogue_close_button])
		var viewport_bounds := Rect2(Vector2.ZERO, Vector2(root.size))
		_check(viewport_bounds.encloses(ui.dialogue_panel.get_global_rect()), "Dialogue panel outside viewport")
		# Cover every authored line, including the longest timeline/victory lines.
		var lines: PackedStringArray = neris.dialogue_lines + neris.timeline_dialogue_lines + neris.victory_dialogue_lines
		for line in lines:
			ui.active_town_line = line
			ui._update_dialogue_content()
			await process_frame
			_check(ui.dialogue_text.text == line, "Portrait changed dialogue text")
			_check(ui.dialogue_text.get_minimum_size().y <= ui.dialogue_text.size.y, "Dialogue line overflowed its portrait layout")
			_check(ui.dialogue_text.get_global_rect().end.y < ui.dialogue_close_button.get_global_rect().position.y, "Dialogue text overlaps close button")
		ui._close_dialogue()
		_check(ui.dialogue_portrait.texture == null and not ui.dialogue_portrait.visible and ui.dialogue_text.offset_left == 20, "Closing dialogue retained portrait layout")
		ui._on_npc_interaction_requested(calen)
		_check(ui.speaker_label.text == "CALEN" and ui.dialogue_portrait.texture == null and not ui.dialogue_portrait.visible, "Neris portrait leaked into Calen dialogue")
		ui._close_dialogue()
		state.merchant_discount_unlocked = true
		ui._open_shop(orin)
		await process_frame
		_check(ui.shop_portrait.visible and ui.shop_portrait.texture == orin.portrait_texture and paused, "Merchant portrait/shop pause missing")
		_check(ui.shop_portrait.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Portrait steals shop input")
		_check(ui.shop_item_list.has_focus(), "Shop lost list focus")
		_check(viewport_bounds.encloses(ui.shop_panel.get_global_rect()), "Shop panel outside viewport")
		_separate(ui.shop_portrait, [ui.shop_title_label, ui.shop_gold_label, ui.shop_item_list, ui.shop_buy_tab_button, ui.shop_forge_tab_button])
		_check(ui.shop_title_label.get_minimum_size().x <= ui.shop_title_label.size.x, "Discount title does not fit beside portrait")
		_check(ui.shop_title_label.get_global_rect().end.x <= ui.shop_panel.get_global_rect().end.x - 12, "Discount title escapes shop panel")
		for item_id in ui.SHOP_ORDER:
			ui.selected_shop_item_id = item_id
			ui._update_shop_item_details()
			await process_frame
			await process_frame
			var scroll: ScrollContainer = ui.shop_item_description_scroll
			_check(scroll.clip_contents and not scroll.get_global_rect().intersects(ui.shop_buy_button.get_global_rect()), "Description can cover the purchase button")
			_check(scroll.scroll_vertical == 0, "New item retained previous description scroll")
			_check(ui.shop_item_description_label.text.contains("PRICE:"), "Item description lost price")
			if ui.shop_item_description_label.size.y > scroll.size.y:
				_check(scroll.get_v_scroll_bar().visible, "Long item description cannot be scrolled")
				scroll.scroll_vertical = 10000
				await process_frame
				_check(ui.shop_item_description_label.get_global_rect().end.y <= scroll.get_global_rect().end.y + 2, "Bottom of long description is unreachable")
		ui._on_shop_forge_tab_pressed()
		_check(ui.shop_portrait.texture == orin.portrait_texture, "Forge tab lost Orin portrait")
		ui._close_shop()
		_check(not paused and not ui.shop_portrait.visible and ui.shop_portrait.texture == null, "Shop close retained portrait/pause")
		for service in [vendor, forge]:
			ui._open_shop(service)
			_check(ui.shop_portrait.texture == service.get_portrait_texture(), "Wrong service portrait")
			if service == forge:
				_check(not ui.shop_portrait.visible and ui.shop_title_label.offset_left == 24, "Orin portrait leaked into unnamed forge")
			ui._close_shop()
	_check(neris.get_node("CollisionShape2D").shape.get_rid() == neris_shape and orin.get_node("CollisionShape2D").shape.get_rid() == orin_shape, "Portrait changed NPC colliders")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("NPC PORTRAIT TEST PASSED: identity, texture budget, dialogue/shop/forge, fallback, long lines, 3 viewport sizes, input and collider invariants")
		quit(0)
	else:
		quit(1)
