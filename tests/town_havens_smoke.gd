extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_town_havens_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var ui = game.get_node("UI")
	var grotto = game.get_node("EchoGrotto")
	var haven = game.get_node("EchoHaven")
	var haven_outskirts = game.get_node("EchoHavenOutskirts")
	var causeway = game.get_node("BrokenCauseway")
	var hearth = game.get_node("CinderHearth")
	var hearth_outskirts = game.get_node("CinderHearthOutskirts")
	_check(grotto.get_node("HavenDoor")._requirements_met(), "Echo haven entry should be open")
	_check(causeway.get_node("HearthDoor")._requirements_met(), "Ash hearth entry should be open")
	_check(get_first_node_in_group("echo_haven_entry") == haven.get_node("Entry"), "Echo haven entry is not in the world")
	_check(get_first_node_in_group("ash_hearth_entry") == hearth.get_node("Entry"), "Ash hearth entry is not in the world")
	_check(get_first_node_in_group("echo_haven_outskirts_entry") == haven_outskirts.get_node("Entry"), "Echo outskirts entry is not in the world")
	_check(get_first_node_in_group("ash_hearth_outskirts_entry") == hearth_outskirts.get_node("Entry"), "Ash outskirts entry is not in the world")
	_check(haven.get_node("ReturnDoor")._requirements_met() and hearth.get_node("ReturnDoor")._requirements_met(), "Town return doors must remain open")

	state.set_current_room("echo_grotto")
	await grotto.get_node("HavenDoor").activate(player)
	_check(state.current_room_id == "echo_haven_outskirts", "Echo approach transition failed")
	_check(player.global_position.distance_to(haven_outskirts.get_node("Entry").global_position) < 45.0, "Echo approach entry is wrong")
	_check("DANGER" in ui.objective_label.text and ui.zone_title_label.text == "WHISPERLIGHT APPROACH", "Echo approach is not marked dangerous")
	_check(game.get_node("AmbientSoundscape").current_track == "echo_haven_outskirts", "Echo approach ambience is missing")
	await haven_outskirts.get_node("GateDoor").activate(player)
	_check(state.current_room_id == "echo_haven", "Echo haven transition failed")
	_check(player.global_position.distance_to(haven.get_node("Entry").global_position) < 45.0, "Echo haven entry position is wrong")
	_check("SAFE HAVEN" in ui.objective_label.text and ui.zone_title_label.text == "WHISPERLIGHT HAVEN", "Echo haven title or safe status is missing")
	_check(game.get_node("AmbientSoundscape").current_track == "echo_haven", "Echo haven ambience is missing")

	var resident = haven.get_node("Neris")
	resident.interaction_requested.emit(resident)
	var first_line: String = ui.dialogue_text.text
	_check(ui.speaker_label.text == "NERIS" and not ui.dialogue_primary_button.visible, "Ambient resident uses quest dialogue")
	ui._close_dialogue()
	resident.interaction_requested.emit(resident)
	_check(ui.dialogue_text.text != first_line, "Resident dialogue does not rotate")
	ui._close_dialogue()

	var trader = haven.get_node("GlowmarketTrader")
	state.add_gold(200)
	trader.interaction_requested.emit(trader)
	_check(ui.shop_mode == "buy" and not ui.shop_forge_tab_button.visible, "Echo trader shows forge mode")
	ui.selected_shop_item_id = "healing_herb"
	ui._update_shop_item_details()
	_check(state.get_town_stock_remaining("echo_haven_shop", "healing_herb") == 3, "Initial Echo stock is wrong")
	ui._on_shop_buy_pressed()
	_check(state.get_town_stock_remaining("echo_haven_shop", "healing_herb") == 2, "Echo purchase did not reduce stock")
	_check(state.inventory.get("healing_herb", 0) == 1 and state.gold == 182, "Echo purchase did not exchange gold and item")
	_check(not state.purchase_town_item("echo_haven_shop", "healing_herb", 1, 1), "Town stock accepted an invalid price")
	ui._close_shop()

	var crystal_anvil = haven.get_node("CrystalAnvil")
	crystal_anvil.interaction_requested.emit(crystal_anvil)
	_check(ui.shop_mode == "forge" and not ui.shop_buy_tab_button.visible, "Echo anvil shows shop mode")
	_check(ui.shop_item_list.item_count >= 1, "Echo anvil cannot see the starting sword")
	ui._close_shop()

	var haven_lamp = haven.get_node("HavenLamp")
	player.global_position = haven_lamp.get_node("RespawnPoint").global_position
	_check(haven_lamp._save_progress(player), "Echo haven lamp did not save")
	_check(state.checkpoint_lamp_id == "echo_haven_lamp", "Echo haven lamp is not the respawn point")
	_check(state.get_discovered_lamps().has("echo_haven_lamp"), "Echo haven lamp is missing from fast travel")
	ui._open_shop(trader)
	ui.selected_shop_item_id = "healing_herb"
	ui._on_shop_buy_pressed()
	ui._on_shop_buy_pressed()
	_check(state.get_town_stock_remaining("echo_haven_shop", "healing_herb") == 0, "Echo stock cap was not enforced")
	ui.selected_shop_item_id = "healing_herb"
	ui._update_shop_item_details()
	_check(ui.shop_buy_button.disabled and ui.shop_buy_button.text == "Sold Out", "Sold-out Echo product is still buyable")
	ui._close_shop()
	_check(state.load_game(), "Town save did not load")
	_check(state.get_town_stock_remaining("echo_haven_shop", "healing_herb") == 2 and int(state.inventory.get("healing_herb", 0)) == 1, "Unsaved stock or inventory did not roll back")
	_check(state.current_room_id == "echo_haven", "Town save lost current room")

	await haven.get_node("ReturnDoor").activate(player)
	_check(state.current_room_id == "echo_haven_outskirts", "Echo haven gate return failed")
	_check(player.global_position.distance_to(haven_outskirts.get_node("GateReturn").global_position) < 45.0, "Echo gate return marker is wrong")
	await haven_outskirts.get_node("ReturnDoor").activate(player)
	_check(state.current_room_id == "echo_grotto", "Echo haven return failed")
	_check(player.global_position.distance_to(grotto.get_node("HavenReturn").global_position) < 45.0, "Echo haven return marker is wrong")

	state.set_current_room("ash_causeway")
	await causeway.get_node("HearthDoor").activate(player)
	_check(state.current_room_id == "ash_hearth_outskirts", "Ash approach transition failed")
	_check(player.global_position.distance_to(hearth_outskirts.get_node("Entry").global_position) < 45.0, "Ash approach entry is wrong")
	_check("DANGER" in ui.objective_label.text and ui.zone_title_label.text == "CINDER HEARTH APPROACH", "Ash approach is not marked dangerous")
	_check(game.get_node("AmbientSoundscape").current_track == "ash_hearth_outskirts", "Ash approach ambience is missing")
	await hearth_outskirts.get_node("GateDoor").activate(player)
	_check(state.current_room_id == "ash_hearth", "Cinder Hearth transition failed")
	_check(player.global_position.distance_to(hearth.get_node("Entry").global_position) < 45.0, "Cinder Hearth entry position is wrong")
	_check("SAFE HAVEN" in ui.objective_label.text and ui.zone_title_label.text == "CINDER HEARTH", "Cinder Hearth title or safe status is missing")
	_check(game.get_node("AmbientSoundscape").current_track == "ash_hearth", "Cinder Hearth ambience is missing")
	var hearth_trader = hearth.get_node("Quartermaster")
	hearth_trader.interaction_requested.emit(hearth_trader)
	_check(ui.shop_mode == "buy" and state.get_town_stock_remaining("ash_haven_shop", "iron_fragment") == 4, "Ash merchant stock is wrong")
	ui._close_shop()
	var hearth_anvil = hearth.get_node("Anvil")
	hearth_anvil.interaction_requested.emit(hearth_anvil)
	_check(ui.shop_mode == "forge", "Ash anvil does not open forge mode")
	ui._close_shop()
	var mira = hearth.get_node("Mira")
	mira.interaction_requested.emit(mira)
	_check(ui.speaker_label.text == "MIRA" and ui.dialogue_primary_button.visible, "Mira is not a quest giver")
	ui._on_dialogue_primary_pressed()
	_check(int(game.get_node("QuestManager").hearth_fan_state) == 1 and "Cool the Cinder Forge" in ui.quest_tracker_label.text, "Hearth side quest did not start or display")
	state.unlock_shortcut("ash_forge_fan")
	_check(int(game.get_node("QuestManager").hearth_fan_state) == 2, "Forge fan did not advance Hearth side quest")
	var reward_gold: int = state.gold
	ui._on_dialogue_primary_pressed()
	_check(int(game.get_node("QuestManager").hearth_fan_state) == 3 and state.gold == reward_gold + 50, "Hearth side quest did not pay once")
	ui._on_dialogue_primary_pressed()
	_check(state.gold == reward_gold + 50, "Hearth side quest paid twice")
	ui._close_dialogue()
	var tarin = hearth.get_node("Tarin")
	tarin.interaction_requested.emit(tarin)
	_check(ui.speaker_label.text == "TARIN" and ui.dialogue_primary_button.visible, "Gate watch is not a quest giver")
	ui._on_dialogue_primary_pressed()
	var quests = game.get_node("QuestManager")
	_check(int(quests.hearth_gate_state) == 1 and "Clear the Hearth Road" in ui.quest_tracker_label.text, "Gate road quest did not start")
	hearth_outskirts.get_node("GateFiend").die()
	_check(quests.get_hearth_gate_progress() == 1 and int(quests.hearth_gate_state) == 1, "First gate enemy was not recorded")
	hearth_outskirts.get_node("GateSentry").die()
	_check(quests.get_hearth_gate_progress() == 2 and int(quests.hearth_gate_state) == 2, "Gate road quest did not become ready")
	ui._close_dialogue()
	var hearth_lamp = hearth.get_node("HearthLamp")
	player.global_position = hearth_lamp.get_node("RespawnPoint").global_position
	_check(hearth_lamp._save_progress(player), "Hearth lamp did not save quest progress")
	game.get_node("QuestManager").hearth_fan_state = 1
	quests.hearth_gate_state = 1
	_check(state.load_game() and int(state.quest_state.get("hearth_fan_state", -1)) == 3, "Hearth quest state did not survive saving")
	state.apply_to_quest(game.get_node("QuestManager"))
	_check(int(game.get_node("QuestManager").hearth_fan_state) == 3, "Hearth quest state was not restored to QuestManager")
	_check(int(quests.hearth_gate_state) == 2 and quests.get_hearth_gate_progress() == 2, "Gate road quest did not survive saving")
	tarin.interaction_requested.emit(tarin)
	var gate_reward_gold: int = state.gold
	ui._on_dialogue_primary_pressed()
	_check(int(quests.hearth_gate_state) == 3 and state.gold == gate_reward_gold + 25, "Gate road quest reward failed")
	ui._on_dialogue_primary_pressed()
	_check(state.gold == gate_reward_gold + 25, "Gate road quest rewarded twice")
	ui._close_dialogue()
	await hearth.get_node("ReturnDoor").activate(player)
	_check(state.current_room_id == "ash_hearth_outskirts", "Cinder Hearth gate return failed")
	_check(player.global_position.distance_to(hearth_outskirts.get_node("GateReturn").global_position) < 45.0, "Ash gate return marker is wrong")
	await hearth_outskirts.get_node("ReturnDoor").activate(player)
	_check(state.current_room_id == "ash_causeway", "Cinder Hearth return failed")
	_check(player.global_position.distance_to(causeway.get_node("HearthReturn").global_position) < 45.0, "Cinder Hearth return marker is wrong")

	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("TOWN HAVENS TEST PASSED")
		quit(0)
	else:
		print("TOWN HAVENS TEST FAILED: ", failures)
		quit(1)
