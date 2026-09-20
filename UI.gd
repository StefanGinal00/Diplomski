extends CanvasLayer

const SHOP_ORDER: Array[String] = ["spiritglass_blade", "hunter_bow", "thorn_bow", "apprentice_staff", "sunder_staff", "guardian_band", "wind_cloak", "frost_rune", "healing_herb", "life_bloom", "ember_arrow", "iron_fragment", "ether_dust", "resonance_shard"]
const FORGE_ORDER: Array[String] = ["worn_sword", "spiritglass_blade", "hunter_bow", "thorn_bow", "apprentice_staff", "sunder_staff"]
const SHOP_QUANTITIES := {"spiritglass_blade": 1, "hunter_bow": 1, "thorn_bow": 1, "apprentice_staff": 1, "sunder_staff": 1, "guardian_band": 1, "wind_cloak": 1, "frost_rune": 1, "healing_herb": 1, "life_bloom": 1, "ember_arrow": 3, "iron_fragment": 1, "ether_dust": 1, "resonance_shard": 1}
const FORGE_EFFECTS: Array[String] = ["+1 damage", "Attack delay -12%", "+1 damage", "Attack delay -18% total", "+1 damage; radiant glow"]

@export var player_path: NodePath = NodePath("../Player")
@export var exit_path: NodePath = NodePath("../ExitPortal")
@export var quest_manager_path: NodePath = NodePath("../QuestManager")

@onready var player: Player = get_node_or_null(player_path) as Player
@onready var level_exit: Area2D = get_node_or_null(exit_path) as Area2D
@onready var quest_manager: Node = get_node_or_null(quest_manager_path)
@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/HealthLabel
@onready var revive_status_label: Label = $ReviveStatusLabel
@onready var xp_bar: ProgressBar = $XPBar
@onready var xp_label: Label = $XPBar/XPLabel
@onready var dash_status_panel: Panel = $DashStatusPanel
@onready var dash_cooldown_bar: ProgressBar = $DashStatusPanel/DashCooldownBar
@onready var dash_status_label: Label = $DashStatusPanel/DashCooldownBar/DashStatusLabel
@onready var skill_points_label: Label = $SkillPointsLabel
@onready var gold_label: Label = $GoldLabel
@onready var mode_label: Label = $ModeLabel
@onready var skill_panel: Panel = $SkillPanel
@onready var quest_panel: Panel = $QuestPanel
@onready var hud_panel: Panel = $HUDPanel
@onready var objective_panel: Panel = $ObjectivePanel
@onready var menu_bar_panel: Panel = $MenuBarPanel
@onready var skills_menu_button: Button = $MenuBarPanel/SkillsButton
@onready var quests_menu_button: Button = $MenuBarPanel/QuestsButton
@onready var bag_menu_button: Button = $MenuBarPanel/BagButton
@onready var map_menu_button: Button = $MenuBarPanel/MapButton
@onready var double_jump_button: Button = $SkillPanel/DoubleJumpButton
@onready var dash_button: Button = $SkillPanel/DashButton
@onready var sword_mastery_button: Button = $SkillPanel/SwordMasteryButton
@onready var sword_reach_button: Button = $SkillPanel/SwordReachButton
@onready var bow_mastery_button: Button = $SkillPanel/BowMasteryButton
@onready var bow_piercing_button: Button = $SkillPanel/BowPiercingButton
@onready var staff_mastery_button: Button = $SkillPanel/StaffMasteryButton
@onready var staff_flow_button: Button = $SkillPanel/StaffFlowButton
@onready var skill_info_label: Label = $SkillPanel/SkillInfoLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var game_over_label: Label = $GameOverPanel/GameOverLabel
@onready var restart_button: Button = $GameOverPanel/RestartButton
@onready var switch_mode_button: Button = $GameOverPanel/SwitchModeButton
@onready var objective_label: Label = $ObjectivePanel/ObjectiveLabel
@onready var notification_label: Label = $NotificationLabel
@onready var boss_health_panel: Panel = $BossHealthPanel
@onready var boss_health_bar: ProgressBar = $BossHealthPanel/BossHealthBar
@onready var boss_health_label: Label = $BossHealthPanel/BossHealthBar/BossHealthLabel
@onready var level_complete_panel: Panel = $LevelCompletePanel
@onready var play_again_button: Button = $LevelCompletePanel/PlayAgainButton
@onready var quest_tracker_label: Label = $QuestPanel/QuestScroll/QuestTrackerLabel
@onready var dialogue_panel: Panel = $DialoguePanel
@onready var speaker_label: Label = $DialoguePanel/SpeakerLabel
@onready var dialogue_text: Label = $DialoguePanel/DialogueText
@onready var dialogue_primary_button: Button = $DialoguePanel/PrimaryButton
@onready var dialogue_close_button: Button = $DialoguePanel/CloseButton
@onready var pause_panel: Panel = $PausePanel
@onready var resume_button: Button = $PausePanel/ResumeButton
@onready var restart_level_button: Button = $PausePanel/RestartLevelButton
@onready var music_button: Button = $PausePanel/MusicButton
@onready var soundscape: Node = get_node_or_null("../AmbientSoundscape")
@onready var inventory_panel: Panel = $InventoryPanel
@onready var inventory_item_list: ItemList = $InventoryPanel/ItemList
@onready var item_name_label: Label = $InventoryPanel/ItemNameLabel
@onready var item_description_label: Label = $InventoryPanel/ItemDescriptionLabel
@onready var item_action_button: Button = $InventoryPanel/ActionButton
@onready var item_drop_button: Button = $InventoryPanel/DropButton
@onready var inventory_gold_label: Label = $InventoryPanel/GoldLabel
@onready var close_inventory_button: Button = $InventoryPanel/CloseButton
@onready var main_menu_panel: Panel = $MainMenuPanel
@onready var main_menu_backdrop: ColorRect = $MainMenuBackdrop
@onready var zone_title_panel: Panel = $ZoneTitlePanel
@onready var zone_title_label: Label = $ZoneTitlePanel/ZoneTitleLabel
@onready var zone_subtitle_label: Label = $ZoneTitlePanel/ZoneSubtitleLabel
@onready var continue_button: Button = $MainMenuPanel/ContinueButton
@onready var continue_info_label: Label = $MainMenuPanel/ContinueInfoLabel
@onready var normal_mode_button: Button = $MainMenuPanel/NormalModeButton
@onready var hardcore_mode_button: Button = $MainMenuPanel/HardcoreModeButton
@onready var map_hint_label: Label = $MapHintLabel
@onready var world_map_panel: Panel = $WorldMapPanel
@onready var map_lamp_list: ItemList = $WorldMapPanel/LampList
@onready var map_details_label: Label = $WorldMapPanel/DetailsLabel
@onready var map_route_label: Label = $WorldMapPanel/RouteScroll/RouteLabel
@onready var map_travel_button: Button = $WorldMapPanel/TravelButton
@onready var map_close_button: Button = $WorldMapPanel/CloseButton
@onready var weapon_status_label: Label = $WeaponStatusPanel/WeaponLabel
@onready var ammo_status_label: Label = $WeaponStatusPanel/AmmoLabel
@onready var shop_panel: Panel = $ShopPanel
@onready var shop_dimmer: ColorRect = get_node_or_null("ShopDimmer") as ColorRect
@onready var shop_title_label: Label = $ShopPanel/TitleLabel
@onready var shop_gold_label: Label = $ShopPanel/GoldLabel
@onready var shop_item_list: ItemList = $ShopPanel/ItemList
@onready var shop_buy_tab_button: Button = $ShopPanel/BuyTabButton
@onready var shop_forge_tab_button: Button = $ShopPanel/ForgeTabButton
@onready var shop_item_name_label: Label = $ShopPanel/ItemNameLabel
@onready var shop_item_description_label: Label = $ShopPanel/ItemDescriptionLabel
@onready var shop_buy_button: Button = $ShopPanel/BuyButton
@onready var shop_quest_label: Label = $ShopPanel/QuestLabel
@onready var shop_quest_button: Button = $ShopPanel/QuestButton
@onready var shop_close_button: Button = $ShopPanel/CloseButton
@onready var game_state: Node = get_node_or_null("/root/GameState")

var total_enemies: int = 0
var defeated_enemies: int = 0
var notification_tween: Tween
var resume_player_after_dialogue: bool = false
var active_dialogue_npc: Area2D
var selected_item_id: String = ""
var selected_lamp_id: String = ""
var travel_source_checkpoint: Node
var map_allows_travel: bool = false
var selected_shop_item_id: String = ""
var shop_mode: String = "buy"
var active_merchant: Node
var zone_title_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_panel.hide()
	level_complete_panel.hide()
	dialogue_panel.hide()
	pause_panel.hide()
	inventory_panel.hide()
	main_menu_panel.hide()
	main_menu_backdrop.hide()
	zone_title_panel.hide()
	world_map_panel.hide()
	shop_panel.hide()
	_set_shop_dimmer_visible(false)
	skill_panel.hide()
	quest_panel.hide()
	notification_label.modulate.a = 0.0
	boss_health_panel.hide()
	double_jump_button.pressed.connect(_on_double_jump_button_pressed)
	dash_button.pressed.connect(_on_dash_button_pressed)
	sword_mastery_button.pressed.connect(_on_sword_mastery_pressed)
	sword_reach_button.pressed.connect(_on_sword_reach_pressed)
	bow_mastery_button.pressed.connect(_on_bow_mastery_pressed)
	bow_piercing_button.pressed.connect(_on_bow_piercing_pressed)
	staff_mastery_button.pressed.connect(_on_staff_mastery_pressed)
	staff_flow_button.pressed.connect(_on_staff_flow_pressed)
	skills_menu_button.pressed.connect(_toggle_skills)
	quests_menu_button.pressed.connect(_toggle_quests)
	bag_menu_button.pressed.connect(_toggle_inventory)
	map_menu_button.pressed.connect(_toggle_map_button)
	$SkillPanel/CloseButton.pressed.connect(_toggle_skills)
	$QuestPanel/CloseButton.pressed.connect(_toggle_quests)
	restart_button.pressed.connect(_on_respawn_button_pressed)
	switch_mode_button.pressed.connect(_switch_to_normal_mode)
	play_again_button.pressed.connect(_restart_journey)
	dialogue_primary_button.pressed.connect(_on_dialogue_primary_pressed)
	dialogue_close_button.pressed.connect(_close_dialogue)
	resume_button.pressed.connect(_resume_game)
	restart_level_button.pressed.connect(_restart_from_pause)
	music_button.pressed.connect(_on_music_button_pressed)
	inventory_item_list.item_selected.connect(_on_inventory_item_selected)
	item_action_button.pressed.connect(_on_inventory_action_pressed)
	item_drop_button.pressed.connect(_on_inventory_drop_pressed)
	close_inventory_button.pressed.connect(_close_inventory)
	map_lamp_list.item_selected.connect(_on_map_lamp_selected)
	map_travel_button.pressed.connect(_on_map_travel_pressed)
	map_close_button.pressed.connect(_close_world_map)
	shop_item_list.item_selected.connect(_on_shop_item_selected)
	shop_buy_tab_button.pressed.connect(_on_shop_buy_tab_pressed)
	shop_forge_tab_button.pressed.connect(_on_shop_forge_tab_pressed)
	shop_buy_button.pressed.connect(_on_shop_buy_pressed)
	shop_quest_button.pressed.connect(_on_shop_quest_pressed)
	shop_close_button.pressed.connect(_close_shop)
	continue_button.pressed.connect(_continue_saved_game)
	normal_mode_button.pressed.connect(_start_normal_mode)
	hardcore_mode_button.pressed.connect(_start_hardcore_mode)
	_setup_enemy_objective()
	_setup_friendly_npcs()
	_setup_checkpoints()
	_setup_life_pickups()
	_setup_shortcuts_and_doors()
	_setup_archive()
	_setup_nest()
	_setup_boss()
	var cistern := get_parent().get_node_or_null("BlackwaterCistern")
	if cistern != null:
		cistern.sequence_changed.connect(_update_objective_label)
	var barracks := get_parent().get_node_or_null("EmberBarracks")
	if barracks != null:
		barracks.trial_changed.connect(_update_objective_label)
	if game_state != null:
		if not game_state.gold_changed.is_connected(_on_gold_changed):
			game_state.gold_changed.connect(_on_gold_changed)
		if not game_state.item_acquired.is_connected(_on_item_acquired):
			game_state.item_acquired.connect(_on_item_acquired)
		if not game_state.room_changed.is_connected(_on_room_changed):
			game_state.room_changed.connect(_on_room_changed)
		if not game_state.zone_tier_changed.is_connected(_on_zone_tier_changed):
			game_state.zone_tier_changed.connect(_on_zone_tier_changed)
		if not game_state.inventory_changed.is_connected(_on_inventory_changed):
			game_state.inventory_changed.connect(_on_inventory_changed)
		if not game_state.mode_changed.is_connected(_on_mode_changed):
			game_state.mode_changed.connect(_on_mode_changed)
		if not game_state.lamps_changed.is_connected(_on_lamps_changed):
			game_state.lamps_changed.connect(_on_lamps_changed)
		if not game_state.equipment_changed.is_connected(_update_weapon_status):
			game_state.equipment_changed.connect(_update_weapon_status)
		if not game_state.merchant_changed.is_connected(_on_merchant_changed):
			game_state.merchant_changed.connect(_on_merchant_changed)
		if not game_state.boss_progress_changed.is_connected(_on_boss_progress_changed):
			game_state.boss_progress_changed.connect(_on_boss_progress_changed)
		if not game_state.shortcut_changed.is_connected(_on_world_progress_changed):
			game_state.shortcut_changed.connect(_on_world_progress_changed)
		_on_gold_changed(game_state.gold)
		_on_mode_changed(game_state.game_mode)
		_on_lamps_changed()
		_update_weapon_status()
		_update_inventory_panel()
		if not game_state.session_started:
			_show_main_menu()
		else:
			_set_hud_visible(true)
			call_deferred("_show_zone_title", game_state.current_room_id)
			if game_state.last_load_used_backup:
				game_state.last_load_used_backup = false
				call_deferred("_show_notification", "SAVE RECOVERED FROM BACKUP")

	if level_exit != null:
		level_exit.unlocked.connect(_on_exit_unlocked)
		level_exit.level_completed.connect(_on_level_completed)
	if quest_manager != null:
		quest_manager.quest_updated.connect(_on_quest_updated)
		quest_manager.quest_item_collected.connect(_on_quest_item_collected)
		quest_manager.return_contract_completed.connect(_on_return_contract_completed)
		_on_quest_updated()

	if player == null:
		push_error("UI could not find the Player node at: " + str(player_path))
		double_jump_button.disabled = true
		dash_button.disabled = true
		return

	player.health_changed.connect(_on_health_changed)
	player.mana_changed.connect(_on_mana_changed)
	player.combat_message.connect(_show_notification)
	player.second_breath_changed.connect(_on_second_breath_changed)
	player.second_breath_triggered.connect(_on_second_breath_triggered)
	player.progression_changed.connect(_on_progression_changed)
	player.double_jump_state_changed.connect(_on_double_jump_state_changed)
	player.dash_state_changed.connect(_on_dash_state_changed)
	player.weapon_changed.connect(_on_player_weapon_changed)
	player.died.connect(_on_player_died)

	_on_health_changed(player.current_health, player.max_health)
	_on_mana_changed(player.current_mana, player.max_mana)
	_on_second_breath_changed(player.second_breath_active)
	_on_progression_changed(player.xp, player.xp_per_level, player.skill_points)
	_on_double_jump_state_changed(player.double_jump_unlocked)
	_on_dash_state_changed(player.dash_unlocked)
	_update_dash_status()


func _process(_delta: float) -> void:
	_update_dash_status()


func _input(event: InputEvent) -> void:
	if not shop_panel.visible or not event is InputEventKey or not event.pressed or event.is_echo():
		return
	if get_viewport().gui_get_focus_owner() != shop_item_list or shop_item_list.item_count == 0:
		return
	var selected := shop_item_list.get_selected_items()
	if selected.is_empty():
		return
	var next_index := -1
	if event.is_action_pressed("ui_down") and selected[0] == shop_item_list.item_count - 1:
		next_index = 0
	elif event.is_action_pressed("ui_up") and selected[0] == 0:
		next_index = shop_item_list.item_count - 1
	if next_index >= 0:
		shop_item_list.select(next_index)
		_on_shop_item_selected(next_index)
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if main_menu_panel.visible:
		return
	if event.is_action_pressed("skills_menu"):
		get_viewport().set_input_as_handled()
		_toggle_skills()
		return
	if event.is_action_pressed("quest_log"):
		get_viewport().set_input_as_handled()
		_toggle_quests()
		return
	if event.is_action_pressed("world_map"):
		get_viewport().set_input_as_handled()
		_toggle_map_button()
		return
	if event.is_action_pressed("inventory"):
		get_viewport().set_input_as_handled()
		if not _hud_menu_blocked():
			_toggle_inventory()
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if shop_panel.visible:
		_close_shop()
	elif world_map_panel.visible:
		_close_world_map()
	elif inventory_panel.visible:
		_close_inventory()
	elif skill_panel.visible or quest_panel.visible:
		_close_side_panels()
	elif get_tree().paused:
		_resume_game()
	elif not game_over_panel.visible and not level_complete_panel.visible:
		_pause_game()


func _pause_game() -> void:
	_close_side_panels()
	inventory_panel.hide()
	get_tree().paused = true
	_update_music_button()
	pause_panel.show()
	resume_button.grab_focus()


func _resume_game() -> void:
	pause_panel.hide()
	get_tree().paused = false


func _hud_menu_blocked() -> bool:
	return main_menu_panel.visible or game_over_panel.visible or level_complete_panel.visible \
		or dialogue_panel.visible or shop_panel.visible or pause_panel.visible


func _close_side_panels() -> void:
	skill_panel.hide()
	quest_panel.hide()
	get_tree().paused = false


func _toggle_skills() -> void:
	if skill_panel.visible:
		_close_side_panels()
		return
	if _hud_menu_blocked() or inventory_panel.visible or world_map_panel.visible:
		return
	quest_panel.hide()
	_update_skill_buttons()
	skill_panel.show()
	get_tree().paused = true
	$SkillPanel/CloseButton.grab_focus()


func _toggle_quests() -> void:
	if quest_panel.visible:
		_close_side_panels()
		return
	if _hud_menu_blocked() or inventory_panel.visible or world_map_panel.visible:
		return
	skill_panel.hide()
	_on_quest_updated()
	quest_panel.show()
	get_tree().paused = true
	$QuestPanel/CloseButton.grab_focus()


func _toggle_map_button() -> void:
	if world_map_panel.visible:
		_close_world_map()
		return
	if _hud_menu_blocked() or inventory_panel.visible:
		return
	_close_side_panels()
	_open_world_map(false)


func _set_hud_visible(show_hud: bool) -> void:
	for control in [hud_panel, health_bar, xp_bar, skill_points_label, gold_label, mode_label,
		objective_panel, notification_label, menu_bar_panel, weapon_status_label.get_parent()]:
		control.visible = show_hud
	map_hint_label.hide()
	$ControlsLabel.hide()
	revive_status_label.visible = show_hud and player != null and player.second_breath_active
	if not show_hud:
		boss_health_panel.hide()
		$DashStatusPanel.hide()


func _restart_from_pause() -> void:
	_restart_journey()


func _update_music_button() -> void:
	music_button.disabled = soundscape == null
	music_button.text = "Ambient Music: On" if soundscape != null and bool(soundscape.get("enabled")) else "Ambient Music: Off"


func _on_music_button_pressed() -> void:
	if soundscape == null or not soundscape.has_method("set_enabled"):
		return
	soundscape.set_enabled(not bool(soundscape.get("enabled")))
	_update_music_button()


func _show_main_menu() -> void:
	_set_hud_visible(false)
	main_menu_backdrop.show()
	main_menu_panel.show()
	continue_button.disabled = game_state == null or not game_state.has_save_file()
	_update_continue_summary()
	get_tree().paused = true
	if not continue_button.disabled:
		continue_button.grab_focus()
	else:
		normal_mode_button.grab_focus()


func _start_normal_mode() -> void:
	_start_new_mode("normal")


func _start_hardcore_mode() -> void:
	_start_new_mode("hardcore")


func _start_new_mode(mode: String) -> void:
	if game_state == null:
		return
	game_state.start_new_game(mode)
	main_menu_panel.hide()
	main_menu_backdrop.hide()
	game_over_panel.hide()
	_set_hud_visible(true)
	get_tree().paused = false
	_on_gold_changed(game_state.gold)
	_update_inventory_panel()
	_show_zone_title("training_passage")


func _show_zone_title(room_id: String) -> void:
	if main_menu_panel.visible:
		return
	var titles := {
		"training_passage": ["THE TRAINING PASSAGE", "A journey begins"],
		"sunken_shaft": ["THE SUNKEN SHAFT", "Beneath the forgotten passage"],
		"shaft_hollow": ["WISP HOLLOW", "A hidden path through the Shaft"],
		"shaft_crossing": ["DROWNED CROSSING", "Drain the old aqueduct to quiet the current"],
		"shaft_gallery": ["FLOODED GALLERY", "Two old controls feed the Warden passage"],
		"shaft_cistern": ["BLACKWATER CISTERN", "Restore the pump to open a second passage"],
		"shaft_approach": ["WARDEN APPROACH", "Climb the gantry before the arena"],
		"echo_grotto": ["THE ECHO GROTTO", "Beyond the Warden's seal"],
		"echo_gallery": ["WHISPERING GALLERY", "The cave remembers every footstep"],
		"echo_archive": ["THE PRISM ARCHIVE", "The mirrors hold a buried memory"],
		"echo_tide_well": ["THE TIDE WELL", "Follow the current into the deep"],
		"echo_nest": ["THE ECHO NEST", "The brood guards what lies beyond"],
		"echo_sanctum": ["RESONANCE SANCTUM", "The Echo Matriarch waits"],
		"echo_causeway": ["CRYSTAL CAUSEWAY", "The bridge fades beneath each footstep"],
		"echo_vault": ["UNDERTOW VAULT", "Two seals protect a forgotten mantle"],
		"ash_causeway": ["BROKEN CAUSEWAY", "Ashen Bastion begins beyond the Matriarch"],
		"ash_forge": ["CINDER FORGE", "Restore airflow to quiet the vents"],
		"ash_barracks": ["EMBER BARRACKS", "Two waves guard a route back to the Causeway"],
	}
	var entry: Array = titles.get(room_id, [room_id.replace("_", " ").to_upper(), "An unfamiliar place"])
	var subtitle: String = str(entry[1])
	var zone_id := "echo_grotto" if room_id.begins_with("echo_") else ("sunken_shaft" if room_id.begins_with("shaft_") else ("ashen_bastion" if room_id.begins_with("ash_") else room_id))
	if game_state != null and game_state.get_zone_tier(zone_id) >= 1:
		subtitle = "AWAKENED  •  STRONGER ENEMIES" if zone_id == "ashen_bastion" else "AWAKENED  •  STRONGER ENEMIES  •  RETURN QUEST [J]"
	_show_zone_banner(str(entry[0]), subtitle)


func _show_zone_banner(title: String, subtitle: String, duration: float = 1.55) -> void:
	zone_title_label.text = title
	zone_subtitle_label.text = subtitle
	if zone_title_tween != null and zone_title_tween.is_valid():
		zone_title_tween.kill()
	zone_title_panel.modulate.a = 0.0
	zone_title_panel.show()
	zone_title_tween = create_tween()
	zone_title_tween.tween_property(zone_title_panel, "modulate:a", 1.0, 0.25)
	zone_title_tween.tween_interval(duration)
	zone_title_tween.tween_property(zone_title_panel, "modulate:a", 0.0, 0.4)
	zone_title_tween.tween_callback(zone_title_panel.hide)


func _on_zone_tier_changed(zone_id: String, tier: int) -> void:
	if tier < 1 or main_menu_panel.visible:
		return
	if zone_id == "sunken_shaft":
		_show_zone_banner("SUNKEN SHAFT AWAKENED", "ENEMIES GROW STRONGER  •  NEW RETURN QUEST [J]", 2.8)
	elif zone_id == "echo_grotto":
		_show_zone_banner("ECHO GROTTO AWAKENED", "ENEMIES GROW STRONGER  •  NEW RETURN QUEST [J]", 2.8)


func _on_return_contract_completed(zone_id: String) -> void:
	var quest_name := "SHAFT VIGIL" if zone_id == "sunken_shaft" else "RESONANCE SWEEP"
	call_deferred("_show_notification", "RETURN QUEST COMPLETE  •  " + quest_name)


func _on_quest_item_collected(item_id: String, progress: int) -> void:
	if item_id == "old_passage_sigil":
		_show_notification("LOST SIGIL FOUND  •  CHECK QUEST LOG [J]")
	elif item_id.begins_with("echo_trace_"):
		if progress >= 3 and quest_manager != null and int(quest_manager.echo_survey_state) == 2:
			_show_notification("ECHO TRACES 3/3  •  RETURN TO LYRA")
		else:
			_show_notification("ECHO TRACE FOUND  •  %d/3" % progress)


func _continue_saved_game() -> void:
	if game_state == null or not game_state.load_game():
		continue_info_label.text = "Save could not be loaded. No valid backup was found."
		return
	get_tree().paused = false
	get_tree().reload_current_scene()


func _update_continue_summary() -> void:
	if game_state == null:
		continue_info_label.text = "Save system unavailable"
		return
	var summary: Dictionary = game_state.get_save_summary()
	if summary.is_empty():
		continue_info_label.text = "No Save Lamp data found"
		return
	var mode := str(summary.get("mode", "normal")).to_upper()
	var location := str(summary.get("lamp_name", "Save Lamp"))
	var saved_at := int(summary.get("saved_at", 0))
	var time_text := "Unknown time"
	if saved_at > 0:
		var date := Time.get_datetime_dict_from_unix_time(saved_at)
		time_text = "%02d.%02d.%04d  %02d:%02d" % [date.day, date.month, date.year, date.hour, date.minute]
	continue_button.text = "Continue  •  " + mode
	continue_info_label.text = "%s  •  %s" % [location, time_text]


func _open_world_map(allow_travel: bool, checkpoint: Node = null) -> void:
	if game_state == null:
		return
	_close_side_panels()
	map_allows_travel = allow_travel
	travel_source_checkpoint = checkpoint
	pause_panel.hide()
	_populate_world_map()
	world_map_panel.show()
	get_tree().paused = true
	if map_lamp_list.item_count > 0:
		map_lamp_list.grab_focus()
	else:
		map_close_button.grab_focus()


func _close_world_map() -> void:
	world_map_panel.hide()
	map_allows_travel = false
	travel_source_checkpoint = null
	get_tree().paused = false


func _populate_world_map() -> void:
	map_lamp_list.clear()
	selected_lamp_id = ""
	_update_route_summary()
	var lamps: Dictionary = game_state.get_discovered_lamps()
	var lamp_ids: Array = lamps.keys()
	lamp_ids.sort_custom(func(a, b): return str(lamps[a].get("name", a)) < str(lamps[b].get("name", b)))
	for lamp_id in lamp_ids:
		var lamp_data: Dictionary = lamps[lamp_id]
		var current_mark := "  ◀ CURRENT SAVE" if str(lamp_id) == game_state.checkpoint_lamp_id else ""
		var index := map_lamp_list.add_item("◉  %s%s" % [str(lamp_data.get("name", lamp_id)), current_mark])
		map_lamp_list.set_item_metadata(index, str(lamp_id))
	if map_lamp_list.item_count == 0:
		map_details_label.text = "No Save Lamps discovered yet.\n\nExplore the world and rest at a lamp to mark it on the map."
		map_travel_button.visible = map_allows_travel
		map_travel_button.disabled = true
		map_travel_button.text = "Travel Unavailable"
		return
	map_lamp_list.select(0)
	selected_lamp_id = str(map_lamp_list.get_item_metadata(0))
	_update_map_details()


func _on_map_lamp_selected(index: int) -> void:
	selected_lamp_id = str(map_lamp_list.get_item_metadata(index))
	_update_map_details()


func _update_map_details() -> void:
	var lamps: Dictionary = game_state.get_discovered_lamps()
	var lamp_data: Dictionary = lamps.get(selected_lamp_id, {})
	if lamp_data.is_empty():
		map_details_label.text = "Select a discovered lamp."
		map_travel_button.disabled = true
		return
	var area_name := str(lamp_data.get("room_id", "unknown_area")).replace("_", " ").capitalize()
	var is_current: bool = selected_lamp_id == game_state.checkpoint_lamp_id
	map_details_label.text = "LOCATION: %s\nAREA: %s\n\n%s" % [
		str(lamp_data.get("name", selected_lamp_id)),
		area_name,
		"This is your current respawn lamp." if is_current else "A safe route has been recorded.",
	]
	map_travel_button.visible = map_allows_travel
	map_travel_button.disabled = not map_allows_travel or is_current or lamps.size() < 2
	map_travel_button.text = "Current Lamp" if is_current else "Travel to Lamp"


func _update_route_summary() -> void:
	var echo_rooms := [
		["echo_grotto", "Grotto"], ["echo_gallery", "Gallery"],
		["echo_archive", "Archive"], ["echo_tide_well", "Tide Well"],
		["echo_nest", "Nest"], ["echo_sanctum", "Sanctum"],
		["echo_causeway", "Causeway"], ["echo_vault", "Vault"],
	]
	var visited := 0
	var room_lines: Array[String] = []
	for index in range(0, echo_rooms.size(), 2):
		var left: Array = echo_rooms[index]
		var left_seen: bool = bool(game_state.discovered_rooms.get(left[0], false))
		visited += int(left_seen)
		if index + 1 < echo_rooms.size():
			var right: Array = echo_rooms[index + 1]
			var right_seen: bool = bool(game_state.discovered_rooms.get(right[0], false))
			visited += int(right_seen)
			room_lines.append("  %s %-10s %s %s" % ["[+]" if left_seen else "[ ]", left[1], "[+]" if right_seen else "[ ]", right[1]])
		else:
			room_lines.append("  %s %s" % ["[+]" if left_seen else "[ ]", left[1]])
	var echo_caches := ["grotto_high", "gallery_step", "archive_shelf", "tide_depth", "nest_cocoon", "sanctum_heart", "causeway_supply", "causeway_afterglow", "vault_mantle", "vault_undertow"]
	var found_caches := 0
	for cache_id in echo_caches:
		found_caches += int(bool(game_state.opened_caches.get(cache_id, false)))
	var echo_boss := "UNDEFEATED"
	if bool(game_state.boss_rematches.get("echo_matriarch", false)):
		echo_boss = "REMATCH CLEARED"
	elif bool(game_state.defeated_bosses.get("echo_matriarch", false)):
		echo_boss = "REMATCH READY"
	var shaft_boss := "UNDEFEATED"
	if bool(game_state.boss_rematches.get("abyss_warden", false)):
		shaft_boss = "REMATCH CLEARED"
	elif bool(game_state.defeated_bosses.get("abyss_warden", false)):
		shaft_boss = "REMATCH READY"
	var shaft_caches := 0
	for cache_id in ["shaft_rim", "shaft_depth", "hollow_resonance", "crossing_supply", "crossing_dregs", "gallery_supply", "gallery_afterglow", "cistern_supply", "cistern_echo", "approach_supply", "approach_afterglow"]:
		shaft_caches += int(bool(game_state.opened_caches.get(cache_id, false)))
	var shaft_rooms := 0
	for room_id in ["sunken_shaft", "shaft_hollow", "shaft_crossing", "shaft_gallery", "shaft_cistern", "shaft_approach"]:
		shaft_rooms += int(bool(game_state.discovered_rooms.get(room_id, false)))
	var ash_rooms := int(bool(game_state.discovered_rooms.get("ash_causeway", false))) + int(bool(game_state.discovered_rooms.get("ash_forge", false))) + int(bool(game_state.discovered_rooms.get("ash_barracks", false)))
	var ash_caches := int(bool(game_state.opened_caches.get("ash_causeway_supply", false))) + int(bool(game_state.opened_caches.get("ash_forge_supply", false))) + int(bool(game_state.opened_caches.get("ash_barracks_supply", false)))
	var fan_status := "ON" if bool(game_state.unlocked_shortcuts.get("ash_forge_fan", false)) else "OFF"
	var trial_status := "CLEARED" if bool(game_state.unlocked_shortcuts.get("ash_barracks_cleared", false)) else "OPEN"
	map_route_label.text = "ECHO GROTTO  %d/8 PLAYABLE ROOMS\n%s\nCACHES %d/10  •  %s\n\nSUNKEN SHAFT  %d/6 PLAYABLE ROOMS\nCACHES %d/11  •  %s\n\nASHEN BASTION  %d/3 OPENING ROOMS\nCACHES %d/3  •  FAN %s  •  TRIAL %s" % [
		visited, "\n".join(room_lines), found_caches, echo_boss, shaft_rooms, shaft_caches, shaft_boss, ash_rooms, ash_caches, fan_status, trial_status,
	]


func _on_map_travel_pressed() -> void:
	if not map_allows_travel or selected_lamp_id.is_empty() or player == null:
		return
	var lamps: Dictionary = game_state.get_discovered_lamps()
	var lamp_data: Dictionary = lamps.get(selected_lamp_id, {})
	if lamp_data.is_empty():
		return
	var target_position: Vector2 = game_state.get_lamp_position(selected_lamp_id)
	var target_room_id := str(lamp_data.get("room_id", "training_passage"))
	var target_name := str(lamp_data.get("name", "Save Lamp"))
	world_map_panel.hide()
	get_tree().paused = false
	var transition_manager := get_node_or_null("/root/RoomTransition")
	if transition_manager != null:
		await transition_manager.transition_player(player, target_position, target_room_id)
	else:
		player.global_position = target_position
		game_state.set_current_room(target_room_id)
	var destination := _find_checkpoint_by_id(selected_lamp_id)
	if destination != null and destination.has_method("activate_from_travel"):
		destination.activate_from_travel()
	player.set_checkpoint(target_position)
	game_state.save_at_checkpoint(player, quest_manager, target_position, selected_lamp_id, target_name, target_room_id)
	map_allows_travel = false
	travel_source_checkpoint = destination
	_show_notification("FAST TRAVEL  •  " + target_name.to_upper())


func _find_checkpoint_by_id(lamp_id: String) -> Node:
	for checkpoint in get_tree().get_nodes_in_group("checkpoint"):
		if str(checkpoint.get("lamp_id")) == lamp_id:
			return checkpoint
	return null


func _toggle_inventory() -> void:
	if inventory_panel.visible:
		_close_inventory()
		return
	if _hud_menu_blocked() or world_map_panel.visible:
		return
	_close_side_panels()
	pause_panel.hide()
	_update_inventory_panel()
	inventory_panel.show()
	get_tree().paused = true
	close_inventory_button.grab_focus()


func _close_inventory() -> void:
	inventory_panel.hide()
	get_tree().paused = false


func _update_inventory_panel() -> void:
	if game_state == null:
		item_description_label.text = "Inventory unavailable"
		return
	var previous_selection := selected_item_id
	inventory_item_list.clear()
	var item_ids: Array = game_state.inventory.keys()
	item_ids.sort()
	for item_id in item_ids:
		var definition: Dictionary = game_state.get_item_definition(str(item_id))
		var equipped_mark := "  [EQUIPPED]" if game_state.equipped_items.values().has(item_id) else ""
		var upgrade_mark := " +%d" % game_state.get_weapon_upgrade_level(str(item_id)) if str(definition.get("type", "")) == "weapon" and game_state.get_weapon_upgrade_level(str(item_id)) > 0 else ""
		var index := inventory_item_list.add_item("◆ %s%s  x%d%s" % [str(definition.get("name", item_id)), upgrade_mark, int(game_state.inventory[item_id]), equipped_mark])
		inventory_item_list.set_item_metadata(index, str(item_id))
	if inventory_item_list.item_count == 0:
		selected_item_id = ""
		_update_item_details()
		return
	var selected_index := 0
	for index in range(inventory_item_list.item_count):
		if str(inventory_item_list.get_item_metadata(index)) == previous_selection:
			selected_index = index
			break
	inventory_item_list.select(selected_index)
	selected_item_id = str(inventory_item_list.get_item_metadata(selected_index))
	_update_item_details()


func _format_item_name(item_id: String) -> String:
	if item_id.is_empty() or item_id == "None":
		return "None"
	return item_id.replace("_", " ").capitalize()


func _on_inventory_item_selected(index: int) -> void:
	selected_item_id = str(inventory_item_list.get_item_metadata(index))
	_update_item_details()


func _update_item_details() -> void:
	if game_state == null or selected_item_id.is_empty() or not game_state.has_item(selected_item_id):
		item_name_label.text = "Select an item"
		item_description_label.text = "Choose an item to see its description and available actions."
		item_action_button.text = "No Action"
		item_action_button.disabled = true
		item_drop_button.disabled = true
		return
	var definition: Dictionary = game_state.get_item_definition(selected_item_id)
	var item_type := str(definition.get("type", "material"))
	var rank_text := " +%d" % game_state.get_weapon_upgrade_level(selected_item_id) if item_type == "weapon" and game_state.get_weapon_upgrade_level(selected_item_id) > 0 else ""
	item_name_label.text = "%s%s  x%d" % [str(definition.get("name", selected_item_id)), rank_text, int(game_state.inventory[selected_item_id])]
	item_description_label.text = "TYPE: %s\n\n%s" % [item_type.replace("_", " ").to_upper(), str(definition.get("description", ""))]
	if item_type == "weapon":
		var weapon_class := str(definition.get("weapon_class", ""))
		var mastery_bonus := 0
		if player != null:
			match weapon_class:
				"sword": mastery_bonus = 1 if player.sword_mastery_unlocked else 0
				"bow": mastery_bonus = 1 if player.bow_mastery_unlocked else 0
				"staff": mastery_bonus = 1 if player.staff_mastery_unlocked else 0
		var shown_range: int = int(definition.get("range", 0)) + (16 if player != null and player.sword_reach_unlocked and weapon_class == "sword" else 0)
		item_description_label.text += "\n\nDAMAGE: %d  •  ATTACK TIME: %.2fs\nRANGE: %d" % [
			int(definition.get("damage", 1)) + game_state.get_weapon_damage_bonus(selected_item_id) + mastery_bonus,
			float(definition.get("cooldown", 0.5)) * game_state.get_weapon_cooldown_multiplier(selected_item_id),
			shown_range,
		]
	elif item_type == "ammo":
		item_description_label.text += "\n\nDAMAGE: %d  •  OWNED: %d" % [int(definition.get("damage", 1)), int(game_state.inventory[selected_item_id])]
	var is_equipped: bool = game_state.equipped_items.values().has(selected_item_id)
	item_action_button.disabled = false
	match item_type:
		"weapon":
			item_action_button.text = "Equipped" if is_equipped else "Equip"
			item_action_button.disabled = is_equipped
		"defense":
			item_action_button.text = "Unequip" if is_equipped else "Equip"
		"consumable":
			if selected_item_id == "healing_herb":
				item_action_button.text = "Use (+2 HP)"
				item_action_button.disabled = player == null or player.current_health >= player.max_health
			elif selected_item_id == "life_bloom":
				item_action_button.text = "Activate Second Breath"
				item_action_button.disabled = player == null or player.second_breath_active
			else:
				item_action_button.text = "Use"
		"ammo":
			item_action_button.text = "Selected" if game_state.selected_arrow_type == selected_item_id else "Select for Bow"
			var secondary_definition: Dictionary = game_state.get_item_definition(str(game_state.equipped_items.get("secondary_weapon", "")))
			item_action_button.disabled = game_state.selected_arrow_type == selected_item_id or str(secondary_definition.get("weapon_class", "")) != "bow"
		"material", "key_item", "spell_tome":
			item_action_button.text = "No Action"
			item_action_button.disabled = true
	item_drop_button.disabled = not bool(definition.get("droppable", true)) or is_equipped


func _on_inventory_action_pressed() -> void:
	if game_state == null or player == null or selected_item_id.is_empty():
		return
	var definition: Dictionary = game_state.get_item_definition(selected_item_id)
	match str(definition.get("type", "")):
		"weapon":
			if game_state.equip_item(selected_item_id):
				_show_notification("EQUIPPED  •  " + str(definition.get("name", selected_item_id)))
		"defense":
			if game_state.get_equipped_defense_id() == selected_item_id:
				if game_state.unequip_defense():
					_show_notification("DEFENSE UNEQUIPPED")
			elif game_state.equip_item(selected_item_id):
				_show_notification("EQUIPPED  •  " + str(definition.get("name", selected_item_id)))
		"consumable":
			if selected_item_id == "healing_herb" and player.current_health < player.max_health:
				if game_state.remove_item(selected_item_id, 1):
					player.heal(2)
					_show_notification("USED HEALING HERB  •  HP RESTORED")
			elif selected_item_id == "life_bloom" and player.activate_second_breath():
				game_state.remove_item(selected_item_id, 1)
				_show_notification("SECOND BREATH ACTIVATED")
		"ammo":
			if game_state.select_arrow_type(selected_item_id):
				_show_notification("SPECIAL AMMO SELECTED  •  " + str(definition.get("name", selected_item_id)).to_upper())
	_update_inventory_panel()


func _on_inventory_drop_pressed() -> void:
	if game_state == null or player == null or selected_item_id.is_empty():
		return
	var definition: Dictionary = game_state.get_item_definition(selected_item_id)
	if not bool(definition.get("droppable", true)) or game_state.equipped_items.values().has(selected_item_id):
		return
	var dropped_item_id := selected_item_id
	if not game_state.remove_item(dropped_item_id, 1):
		return
	var pickup_scene := load("res://ItemPickup.tscn") as PackedScene
	var pickup := pickup_scene.instantiate() as Area2D
	get_tree().current_scene.add_child(pickup)
	pickup.configure(dropped_item_id, str(definition.get("name", dropped_item_id)))
	pickup.global_position = player.global_position + Vector2(24.0 * player.facing_direction, -6.0)
	_show_notification("DROPPED  •  " + str(definition.get("name", dropped_item_id)))
	selected_item_id = ""
	_update_inventory_panel()


func _open_shop(merchant: Node) -> void:
	if game_state == null or player == null or player.is_dead:
		return
	_close_side_panels()
	active_merchant = merchant
	shop_mode = "buy"
	dialogue_panel.hide()
	inventory_panel.hide()
	world_map_panel.hide()
	if zone_title_tween != null and zone_title_tween.is_valid():
		zone_title_tween.kill()
	zone_title_panel.hide()
	_populate_shop()
	_set_shop_dimmer_visible(true)
	shop_panel.show()
	get_tree().paused = true
	shop_item_list.grab_focus()


func _close_shop() -> void:
	shop_panel.hide()
	_set_shop_dimmer_visible(false)
	active_merchant = null
	selected_shop_item_id = ""
	get_tree().paused = false


func _set_shop_dimmer_visible(should_show: bool) -> void:
	if not is_instance_valid(shop_dimmer):
		shop_dimmer = get_node_or_null("ShopDimmer") as ColorRect
	if shop_dimmer != null:
		shop_dimmer.visible = should_show


func _populate_shop() -> void:
	if game_state == null:
		return
	var previous_selection := selected_shop_item_id
	shop_item_list.clear()
	shop_buy_tab_button.disabled = shop_mode == "buy"
	shop_forge_tab_button.disabled = shop_mode == "forge"
	if shop_mode == "forge":
		for item_id in FORGE_ORDER:
			if not game_state.has_item(item_id):
				continue
			var definition: Dictionary = game_state.get_item_definition(item_id)
			var level: int = game_state.get_weapon_upgrade_level(item_id)
			var index := shop_item_list.add_item("%s  +%d%s" % [str(definition.get("name", item_id)), level, "  [MAX]" if level >= game_state.MAX_WEAPON_UPGRADE else ""])
			shop_item_list.set_item_metadata(index, item_id)
		shop_title_label.text = "ORIN'S FORGE  •  20% DISCOUNT" if game_state.merchant_discount_unlocked else "ORIN'S FORGE"
		shop_quest_label.text = "FORGE: Damage at +1/+3/+5, speed at +2/+4. +5 glows. Save at a lamp."
		shop_quest_button.hide()
	else:
		for item_id in SHOP_ORDER:
			if item_id in ["spiritglass_blade", "thorn_bow", "sunder_staff"] and not bool(game_state.defeated_bosses.get("abyss_warden", false)):
				continue
			if item_id == "resonance_shard" and game_state.get_zone_tier("echo_grotto") < 1:
				continue
			var definition: Dictionary = game_state.get_item_definition(item_id)
			var quantity := int(SHOP_QUANTITIES.get(item_id, 1))
			var base_price := int(definition.get("base_price", 0)) * quantity
			var price: int = game_state.get_shop_price(base_price)
			var one_time_owned: bool = (str(definition.get("type", "")) in ["weapon", "defense"] and game_state.has_item(item_id)) or (str(definition.get("type", "")) == "spell_tome" and game_state.unlocked_spells.has(str(definition.get("spell_id", ""))))
			var owned_mark := "  [OWNED]" if one_time_owned else ""
			var quantity_text := " x%d" % quantity if quantity > 1 else ""
			var index := shop_item_list.add_item("%s%s  •  %dG%s" % [str(definition.get("name", item_id)), quantity_text, price, owned_mark])
			shop_item_list.set_item_metadata(index, item_id)
		shop_title_label.text = "ORIN'S WAYFARER SHOP  •  20% DISCOUNT" if game_state.merchant_discount_unlocked else "ORIN'S WAYFARER SHOP"
		shop_quest_button.show()
		_update_merchant_quest_ui()
	shop_gold_label.text = "GOLD: %d" % game_state.gold
	if shop_item_list.item_count == 0:
		selected_shop_item_id = ""
		_update_shop_item_details()
		return
	var selected_index := 0
	for index in range(shop_item_list.item_count):
		if str(shop_item_list.get_item_metadata(index)) == previous_selection:
			selected_index = index
			break
	shop_item_list.select(selected_index)
	selected_shop_item_id = str(shop_item_list.get_item_metadata(selected_index))
	_update_shop_item_details()


func _on_shop_buy_tab_pressed() -> void:
	shop_mode = "buy"
	selected_shop_item_id = ""
	_populate_shop()
	shop_item_list.grab_focus()


func _on_shop_forge_tab_pressed() -> void:
	shop_mode = "forge"
	selected_shop_item_id = ""
	_populate_shop()
	shop_item_list.grab_focus()


func _on_shop_item_selected(index: int) -> void:
	selected_shop_item_id = str(shop_item_list.get_item_metadata(index))
	_update_shop_item_details()


func _update_shop_item_details() -> void:
	if game_state == null or selected_shop_item_id.is_empty():
		shop_item_name_label.text = "No weapon available"
		shop_item_description_label.text = "Acquire a weapon to forge it."
		shop_buy_button.text = "Forge Unavailable"
		shop_buy_button.disabled = true
		return
	var definition: Dictionary = game_state.get_item_definition(selected_shop_item_id)
	if shop_mode == "forge":
		var level: int = game_state.get_weapon_upgrade_level(selected_shop_item_id)
		var cost: Dictionary = game_state.get_weapon_upgrade_cost(selected_shop_item_id)
		shop_item_name_label.text = "%s  +%d" % [str(definition.get("name", selected_shop_item_id)), level]
		if cost.is_empty():
			shop_item_description_label.text = "FULLY FORGED\n+3 damage; 18% shorter attack delay.\nRadiant glow while equipped."
			shop_buy_button.text = "Maximum Rank"
			shop_buy_button.disabled = true
			return
		var effect: String = FORGE_EFFECTS[level]
		var materials: Array[String] = []
		for material_id in ["iron_fragment", "ether_dust", "resonance_shard"]:
			if cost.has(material_id):
				materials.append("%s: %d/%d" % [str(game_state.get_item_definition(material_id).get("name", material_id)), int(game_state.inventory.get(material_id, 0)), int(cost[material_id])])
		shop_item_description_label.text = "NEXT: %s\nCOST: %d GOLD\n%s" % [effect, int(cost["gold"]), "\n".join(materials)]
		shop_buy_button.text = "Forge Rank %d" % (level + 1) if game_state.can_upgrade_weapon(selected_shop_item_id) else "Need Gold / Materials"
		shop_buy_button.disabled = not game_state.can_upgrade_weapon(selected_shop_item_id)
		return
	var quantity := int(SHOP_QUANTITIES.get(selected_shop_item_id, 1))
	var price: int = game_state.get_shop_price(int(definition.get("base_price", 0)) * quantity)
	var item_type := str(definition.get("type", ""))
	var already_owned: bool = (item_type in ["weapon", "defense"] and game_state.has_item(selected_shop_item_id)) or (item_type == "spell_tome" and game_state.unlocked_spells.has(str(definition.get("spell_id", ""))))
	var requires_staff: bool = item_type == "spell_tome" and not game_state.has_weapon_class("staff")
	shop_item_name_label.text = str(definition.get("name", selected_shop_item_id))
	shop_item_description_label.text = "%s\n\nPRICE: %d GOLD" % [str(definition.get("description", "")), price]
	if str(definition.get("type", "")) == "weapon":
		shop_item_description_label.text += "\nDAMAGE: %d  •  RANGE: %d  •  ATTACK: %.2fs" % [int(definition.get("damage", 1)), int(definition.get("range", 0)), float(definition.get("cooldown", 0.5))]
	shop_buy_button.text = "Requires Runed Staff" if requires_staff else ("Already Owned" if already_owned else "Buy for %d Gold" % price)
	shop_buy_button.disabled = already_owned or requires_staff or not game_state.can_afford(price)


func _on_shop_buy_pressed() -> void:
	if game_state == null or selected_shop_item_id.is_empty():
		return
	if shop_mode == "forge":
		if game_state.upgrade_weapon(selected_shop_item_id):
			var weapon_name := str(game_state.get_item_definition(selected_shop_item_id).get("name", selected_shop_item_id)).to_upper()
			_show_notification("FORGED  •  %s +%d" % [weapon_name, game_state.get_weapon_upgrade_level(selected_shop_item_id)])
		_populate_shop()
		return
	if selected_shop_item_id == "resonance_shard" and game_state.get_zone_tier("echo_grotto") < 1:
		return
	if selected_shop_item_id in ["spiritglass_blade", "thorn_bow", "sunder_staff"] and not bool(game_state.defeated_bosses.get("abyss_warden", false)):
		return
	var definition: Dictionary = game_state.get_item_definition(selected_shop_item_id)
	var quantity := int(SHOP_QUANTITIES.get(selected_shop_item_id, 1))
	var price: int = game_state.get_shop_price(int(definition.get("base_price", 0)) * quantity)
	var item_type := str(definition.get("type", ""))
	var spell_id := str(definition.get("spell_id", ""))
	if (item_type in ["weapon", "defense"] and game_state.has_item(selected_shop_item_id)) or (item_type == "spell_tome" and game_state.unlocked_spells.has(spell_id)):
		return
	if item_type == "spell_tome" and not game_state.has_weapon_class("staff"):
		return
	if not game_state.spend_gold(price):
		_show_notification("NOT ENOUGH GOLD")
		return
	game_state.add_item(selected_shop_item_id, quantity)
	if item_type in ["weapon", "defense"]:
		game_state.equip_item(selected_shop_item_id)
		if str(definition.get("weapon_class", "")) == "staff":
			game_state.unlock_spell("arc_bolt")
	elif item_type == "spell_tome":
		game_state.unlock_spell(spell_id)
	_show_notification("PURCHASED  •  %s x%d" % [str(definition.get("name", selected_shop_item_id)).to_upper(), quantity])
	_populate_shop()


func _update_merchant_quest_ui() -> void:
	if game_state == null:
		return
	match int(game_state.merchant_quest_state):
		0:
			shop_quest_label.text = "SIDE TASK  •  A FAIR PRICE\nOrin offers a permanent discount if you bring him one Iron Fragment."
			shop_quest_button.text = "Accept Side Task"
			shop_quest_button.disabled = false
		1:
			var has_fragment: bool = game_state.has_item("iron_fragment")
			shop_quest_label.text = "SIDE TASK  •  A FAIR PRICE\nBring Iron Fragment: %d/1\nREWARD: 20%% shop discount + Ember Arrows x3" % (1 if has_fragment else 0)
			shop_quest_button.text = "Deliver Iron Fragment" if has_fragment else "Iron Fragment Required"
			shop_quest_button.disabled = not has_fragment
		2:
			shop_quest_label.text = "A FAIR PRICE  •  COMPLETE\nPermanent 20% discount active."
			shop_quest_button.text = "Reward Claimed"
			shop_quest_button.disabled = true


func _on_shop_quest_pressed() -> void:
	if game_state == null:
		return
	if game_state.merchant_quest_state == 0 and game_state.start_merchant_quest():
		_show_notification("NEW SIDE TASK  •  A FAIR PRICE")
	elif game_state.merchant_quest_state == 1 and game_state.complete_merchant_quest():
		_show_notification("SIDE TASK COMPLETE  •  SHOP DISCOUNT UNLOCKED")
	_populate_shop()
	_on_quest_updated()


func _update_dash_status() -> void:
	if player == null:
		dash_status_panel.hide()
		return
	dash_status_panel.visible = player.dash_unlocked and not main_menu_panel.visible
	var effective_cooldown: float = player.get_effective_dash_cooldown()
	dash_cooldown_bar.max_value = effective_cooldown
	if not player.dash_unlocked:
		dash_cooldown_bar.value = 0.0
		dash_status_label.text = "DASH  •  LOCKED"
	elif player.is_dashing:
		dash_cooldown_bar.value = 0.0
		dash_status_label.text = "DASH  •  ACTIVE"
	elif player.dash_cooldown_remaining > 0.0:
		dash_cooldown_bar.value = effective_cooldown - player.dash_cooldown_remaining
		dash_status_label.text = "DASH  •  %.1fs" % player.dash_cooldown_remaining
	else:
		dash_cooldown_bar.value = effective_cooldown
		dash_status_label.text = "DASH  •  READY"


func _setup_friendly_npcs() -> void:
	for npc in get_tree().get_nodes_in_group("friendly_npc"):
		var callback := Callable(self, "_on_npc_interaction_requested")
		if npc.has_signal("interaction_requested") and not npc.is_connected("interaction_requested", callback):
			npc.connect("interaction_requested", callback)


func _setup_checkpoints() -> void:
	for checkpoint in get_tree().get_nodes_in_group("checkpoint"):
		var callback := Callable(self, "_on_checkpoint_activated")
		if checkpoint.has_signal("activated") and not checkpoint.is_connected("activated", callback):
			checkpoint.connect("activated", callback)
		var blocked_callback := Callable(self, "_on_checkpoint_rest_blocked")
		if checkpoint.has_signal("rest_blocked") and not checkpoint.is_connected("rest_blocked", blocked_callback):
			checkpoint.connect("rest_blocked", blocked_callback)
		var travel_callback := Callable(self, "_on_checkpoint_travel_requested")
		if checkpoint.has_signal("travel_requested") and not checkpoint.is_connected("travel_requested", travel_callback):
			checkpoint.connect("travel_requested", travel_callback)
		var left_callback := Callable(self, "_on_checkpoint_player_left")
		if checkpoint.has_signal("player_left") and not checkpoint.is_connected("player_left", left_callback):
			checkpoint.connect("player_left", left_callback)


func _setup_life_pickups() -> void:
	for pickup in get_tree().get_nodes_in_group("life_pickup"):
		var callback := Callable(self, "_on_life_pickup_collected")
		if pickup.has_signal("collected") and not pickup.is_connected("collected", callback):
			pickup.connect("collected", callback)


func _setup_shortcuts_and_doors() -> void:
	for lift in get_tree().get_nodes_in_group("shaft_lift"):
		if lift.has_signal("shortcut_activated"):
			lift.shortcut_activated.connect(_on_shortcut_activated)
		if lift.has_signal("lift_blocked"):
			lift.lift_blocked.connect(_on_access_denied)
	for door in get_tree().get_nodes_in_group("room_door"):
		if door.has_signal("access_denied"):
			door.access_denied.connect(_on_access_denied)
	for relay in get_tree().get_nodes_in_group("shaft_relay"):
		if relay.has_signal("relay_blocked"):
			relay.relay_blocked.connect(_on_access_denied)


func _setup_archive() -> void:
	for archive in get_tree().get_nodes_in_group("prism_archive"):
		if archive.has_signal("puzzle_progress_changed"):
			archive.puzzle_progress_changed.connect(_on_archive_progress_changed)


func _setup_nest() -> void:
	for brood in get_tree().get_nodes_in_group("nest_brood"):
		if brood.has_signal("defeated") and not brood.defeated.is_connected(_on_nest_brood_defeated):
			brood.defeated.connect(_on_nest_brood_defeated)


func _on_nest_brood_defeated() -> void:
	_update_objective_label()


func _on_archive_progress_changed(_step: int, message: String) -> void:
	_update_objective_label()
	_show_notification(message)


func _on_shortcut_activated(shortcut_id: String) -> void:
	var lift_name := "TIDE LIFT" if shortcut_id == "tide_lift" else "SHAFT LIFT"
	_show_notification("SHORTCUT OPEN  •  %s ACTIVE" % lift_name)


func _on_world_progress_changed(progress_id: String) -> void:
	if progress_id == "shaft_hollow_relay":
		_update_objective_label()
		_show_notification("HOLLOW RELAY ACTIVE  •  LOWER PASSAGE OPEN")
	elif progress_id == "shaft_sluice_valve":
		_update_objective_label()
		_show_notification("SLUICE DRAINED  •  CROSSING SAFE")
	elif progress_id.begins_with("shaft_gallery_"):
		_update_objective_label()
		var controls := int(bool(game_state.unlocked_shortcuts.get("shaft_gallery_lower", false))) + int(bool(game_state.unlocked_shortcuts.get("shaft_gallery_upper", false)))
		_show_notification("WARDEN SHORTCUT OPEN" if controls == 2 else "GALLERY CONTROL TURNED  •  1/2")
	elif progress_id == "shaft_cistern_pump":
		_update_objective_label()
		_show_notification("CISTERN PUMP ACTIVE  •  GALLERY LOOP OPEN")
	elif progress_id == "shaft_approach_bridge":
		_update_objective_label()
		_show_notification("COUNTERWEIGHT LOWERED  •  RETURN BRIDGE OPEN")
	elif progress_id == "ash_forge_fan":
		_update_objective_label()
		_show_notification("FORGE AIRFLOW RESTORED  •  VENTS QUIET")
	elif progress_id == "ash_barracks_cleared":
		_update_objective_label()
		_show_notification("BARRACKS CLEARED  •  CAUSEWAY LOOP OPEN")
	elif progress_id.begins_with("echo_resonator_"):
		_update_objective_label()
		_show_notification("RESONATOR ATTUNED  •  THE GROTTO RESPONDS")
	elif progress_id == "echo_causeway_anchor":
		_update_objective_label()
		_show_notification("CAUSEWAY ANCHORED  •  TIDE LOOP OPEN")
	elif progress_id.begins_with("echo_vault_"):
		_update_objective_label()
		var seals := int(bool(game_state.unlocked_shortcuts.get("echo_vault_upper", false))) + int(bool(game_state.unlocked_shortcuts.get("echo_vault_far", false)))
		_show_notification("VAULT RELIQUARY OPEN" if seals == 2 else "VAULT SEAL ATTUNED  •  1/2")
	elif progress_id == "tide_lift":
		_update_objective_label()
	elif progress_id == "echo_nest_cleared":
		_update_objective_label()
		_show_notification("NEST CLEARED  •  THE VEIL FADES")


func _on_access_denied(message: String) -> void:
	_show_notification(message.to_upper())


func _on_boss_progress_changed(_boss_id: String) -> void:
	_update_objective_label()


func _on_life_pickup_collected() -> void:
	_show_notification("LIFE BLOOM STORED  •  OPEN INVENTORY [I]")


func _on_gold_changed(current_gold: int) -> void:
	gold_label.text = "GOLD: %d" % current_gold
	inventory_gold_label.text = "GOLD: %d" % current_gold
	if shop_panel.visible:
		_populate_shop()


func _on_mode_changed(mode: String) -> void:
	mode_label.text = "MODE: " + mode.to_upper()
	mode_label.modulate = Color(1.0, 0.42, 0.42, 1.0) if mode == "hardcore" else Color(0.45, 0.9, 1.0, 1.0)


func _on_item_acquired(item_id: String, amount: int) -> void:
	var item_name := item_id.replace("_", " ").capitalize()
	if item_id == "barracks_insignia":
		_show_notification("BARRACKS CLEARED  •  INSIGNIA + 45 GOLD + 4 XP  •  LOOP OPEN")
	else:
		_show_notification("TIDEGUARD MANTLE FOUND  •  EQUIP IN INVENTORY [I]" if item_id == "tideguard_mantle" else "ITEM ACQUIRED  •  %s x%d" % [item_name, amount])
	if item_id == "echo_charm" or item_id == "gallery_prism" or item_id == "memory_sigil_echo" or item_id == "tide_core" or item_id == "nest_crest" or item_id == "matriarch_seal" or item_id == "tideguard_mantle":
		_update_objective_label()
	if shop_panel.visible:
		_populate_shop()


func _on_inventory_changed() -> void:
	_update_inventory_panel()
	_update_weapon_status()
	_update_skill_buttons()
	_on_quest_updated()
	if shop_panel.visible:
		_populate_shop()


func _on_merchant_changed() -> void:
	if shop_panel.visible:
		_populate_shop()
	_on_quest_updated()


func _on_player_weapon_changed(_weapon_id: String, _arrow_type: String) -> void:
	_update_weapon_status()


func _update_weapon_status() -> void:
	if game_state == null:
		return
	var weapon_id: String = game_state.get_active_weapon_id()
	var definition: Dictionary = game_state.get_item_definition(weapon_id)
	var rank: int = game_state.get_weapon_upgrade_level(weapon_id)
	weapon_status_label.text = "WEAPON [Q]  •  " + str(definition.get("name", weapon_id)).to_upper() + (" +%d" % rank if rank > 0 else "")
	var weapon_class := str(definition.get("weapon_class", "sword"))
	if weapon_class == "bow":
		var ember_count := int(game_state.inventory.get("ember_arrow", 0))
		if game_state.selected_arrow_type == "ember_arrow" and ember_count > 0:
			ammo_status_label.text = "AMMO [R]  •  EMBER x%d" % ember_count
			ammo_status_label.modulate = Color(1.0, 0.48, 0.2, 1.0)
		else:
			ammo_status_label.text = "AMMO [R]  •  BASIC ∞" + ("  •  PIERCE 2" if player != null and player.bow_piercing_unlocked else "")
			ammo_status_label.modulate = Color(0.7, 0.88, 1.0, 1.0)
	elif weapon_class == "staff":
		var spell_name := "FROST ORB" if game_state.selected_spell == "frost_orb" else "ARC BOLT"
		ammo_status_label.text = "SPELL [R]  •  %s  |  MANA %d/%d" % [spell_name, player.current_mana if player != null else 0, player.max_mana if player != null else 0]
		ammo_status_label.modulate = Color(0.72, 0.48, 1.0, 1.0)
	else:
		ammo_status_label.text = "SECONDARY  •  %s" % ("NONE" if str(game_state.equipped_items.get("secondary_weapon", "")).is_empty() else "PRESS Q TO SWITCH")
		ammo_status_label.modulate = Color(0.62, 0.68, 0.78, 1.0)


func _on_room_changed(room_id: String) -> void:
	var room_name := room_id.replace("_", " ").capitalize()
	_show_notification("AREA DISCOVERED  •  " + room_name)
	_show_zone_title(room_id)
	_update_objective_label()


func _setup_boss() -> void:
	for boss in get_tree().get_nodes_in_group("boss"):
		register_boss(boss)


func register_boss(boss: Node) -> void:
	if boss == null or bool(boss.get("is_dead")):
		return
	boss.battle_started.connect(_on_boss_battle_started.bind(boss))
	boss.health_changed.connect(_on_boss_health_changed.bind(boss))
	boss.phase_changed.connect(_on_boss_phase_changed.bind(boss))
	boss.defeated.connect(_on_boss_defeated.bind(boss))


func _boss_display_name(boss: Node) -> String:
	return str(boss.get("boss_name")).to_upper()


func _on_boss_battle_started(boss: Node) -> void:
	boss_health_panel.show()
	_on_boss_health_changed(boss.current_health, boss.max_health, boss)
	_show_notification("BOSS ENCOUNTER  •  " + _boss_display_name(boss))


func _on_boss_health_changed(current_health: int, maximum_health: int, boss: Node) -> void:
	boss_health_bar.max_value = maximum_health
	boss_health_bar.value = current_health
	boss_health_label.text = "%s  %d/%d" % [_boss_display_name(boss), current_health, maximum_health]


func _on_boss_phase_changed(new_phase: int, boss: Node) -> void:
	_show_notification(_boss_display_name(boss) + "  •  PHASE %d" % new_phase)


func _on_boss_defeated(boss: Node) -> void:
	boss_health_panel.hide()
	var suffix := "  •  PATH OPEN" if boss.get("is_rematch") != true and (str(boss.get("boss_id")) == "abyss_warden" or str(boss.get("boss_id")) == "echo_matriarch") else ""
	_show_notification(_boss_display_name(boss) + " DEFEATED" + suffix)
	_update_objective_label()


func _on_checkpoint_activated() -> void:
	_show_notification("PROGRESS SAVED  •  SAVE LAMP ACTIVATED")
	_on_lamps_changed()


func _on_checkpoint_rest_blocked(message: String) -> void:
	_show_notification(message.to_upper())


func _on_checkpoint_travel_requested(checkpoint: Node) -> void:
	_open_world_map(true, checkpoint)


func _on_checkpoint_player_left(checkpoint: Node) -> void:
	if checkpoint == travel_source_checkpoint and not world_map_panel.visible:
		travel_source_checkpoint = null


func _on_lamps_changed() -> void:
	if game_state == null:
		return
	var count: int = game_state.get_discovered_lamps().size()
	map_hint_label.text = "MAP [M]  •  LAMPS %d" % count
	for checkpoint in get_tree().get_nodes_in_group("checkpoint"):
		if checkpoint.has_method("_update_interaction_prompt"):
			checkpoint._update_interaction_prompt()


func _on_npc_interaction_requested(_npc: Area2D) -> void:
	if player == null or player.is_dead or level_complete_panel.visible:
		return
	if _npc.is_in_group("merchant_npc"):
		_open_shop(_npc)
		return

	active_dialogue_npc = _npc
	resume_player_after_dialogue = player.is_physics_processing()
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	dialogue_panel.show()
	_update_dialogue_content()
	dialogue_close_button.grab_focus()


func _update_dialogue_content() -> void:
	if quest_manager == null:
		return
	if active_dialogue_npc != null and active_dialogue_npc.is_in_group("surveyor_npc"):
		_update_surveyor_dialogue()
		return

	speaker_label.text = "ELDRIC"
	var quest_index := int(quest_manager.get("quest_index"))
	var state := int(quest_manager.get("quest_state"))
	if quest_index == 0:
		match state:
			0:
				dialogue_text.text = "Defeat all three creatures and return. Reward: 1 Skill Point, 2 XP and 30 Gold."
				dialogue_primary_button.text = "Accept Mission"
				dialogue_primary_button.show()
			1:
				dialogue_text.text = "The passage is still dangerous. Enemies defeated: %d/3." % int(quest_manager.get("quest_progress"))
				dialogue_primary_button.hide()
			2:
				dialogue_text.text = "The passage is safe. Your reward: 1 skill point, 2 XP and 30 gold."
				dialogue_primary_button.text = "Claim Reward"
				dialogue_primary_button.show()
	elif quest_index == 1:
		match state:
			0:
				dialogue_text.text = "Find the violet sigil. Reward: 1 Max HP, 2 XP, 45 Gold and a Caretaker Charm."
				dialogue_primary_button.text = "Accept Mission"
				dialogue_primary_button.show()
			1:
				dialogue_text.text = "The sigil should be resting somewhere above the old passage."
				dialogue_primary_button.hide()
			2:
				dialogue_text.text = "You found it. Take 1 Max HP, 2 XP, 45 gold and my charm."
				dialogue_primary_button.text = "Return Sigil"
				dialogue_primary_button.show()
	else:
		match state:
			0:
				dialogue_text.text = "One last trial: return to the Sunken Shaft and defeat the Awakened Warden. Reward: 1 Skill Point, 4 XP and 65 Gold."
				dialogue_primary_button.text = "Accept Trial"
				dialogue_primary_button.show()
			1:
				dialogue_text.text = "The Warden returns stronger after his first defeat. The Echo path remains open; this trial is your choice."
				dialogue_primary_button.hide()
			2:
				dialogue_text.text = "You mastered the awakened guardian. Claim 1 Skill Point, 4 XP and 65 Gold."
				dialogue_primary_button.text = "Claim Reward"
				dialogue_primary_button.show()
			3:
				dialogue_text.text = "You have outgrown my lessons, Wayfarer. The deeper echoes are yours to explore."
				dialogue_primary_button.hide()


func _update_surveyor_dialogue() -> void:
	speaker_label.text = "LYRA"
	var state := int(quest_manager.get("echo_survey_state"))
	match state:
		0:
			dialogue_text.text = "Find three echo traces: Gallery, Archive, Tide Well. Reward: 1 SP, 3 XP, 80 Gold, 2 Ether Dust."
			dialogue_primary_button.text = "Accept Survey"
			dialogue_primary_button.show()
		1:
			dialogue_text.text = "Traces recovered: %d/3. Search the Gallery, Archive and Tide Well." % quest_manager.get_echo_survey_progress()
			dialogue_primary_button.hide()
		2:
			dialogue_text.text = "You found all three traces. Claim 1 SP, 3 XP, 80 Gold and 2 Ether Dust."
			dialogue_primary_button.text = "Claim Reward"
			dialogue_primary_button.show()
		_:
			dialogue_text.text = "The survey is complete. There is more to find beyond the Grotto."
			dialogue_primary_button.hide()


func _on_dialogue_primary_pressed() -> void:
	if quest_manager == null:
		return
	if active_dialogue_npc != null and active_dialogue_npc.is_in_group("surveyor_npc"):
		var survey_state := int(quest_manager.get("echo_survey_state"))
		if survey_state == 0 and quest_manager.start_echo_survey():
			_show_notification("NEW SIDE QUEST: ECHO SURVEY")
		elif survey_state == 2 and quest_manager.turn_in_echo_survey(player):
			_show_notification("ECHO SURVEY COMPLETE  •  SP +1  •  XP +3  •  GOLD +80")
		_update_dialogue_content()
		return

	var state := int(quest_manager.get("quest_state"))
	if state == 0 and quest_manager.start_quest():
		var quest_name: String = ["CLEAR THE PASSAGE", "FIND THE LOST SIGIL", "AWAKENED WARDEN"][clampi(int(quest_manager.get("quest_index")), 0, 2)]
		_show_notification("NEW QUEST: " + quest_name)
	elif state == 2:
		var completed_quest := int(quest_manager.get("quest_index"))
		if quest_manager.turn_in_quest(player):
			if completed_quest == 0:
				_show_notification("QUEST COMPLETE  •  SP +1  •  XP +2  •  GOLD +30")
			elif completed_quest == 1:
				_show_notification("QUEST COMPLETE  •  MAX HP +1  •  CARETAKER CHARM")
			else:
				_show_notification("QUEST COMPLETE  •  SP +1  •  XP +4  •  GOLD +65")
	_update_dialogue_content()


func _close_dialogue() -> void:
	dialogue_panel.hide()
	if resume_player_after_dialogue and player != null and not player.is_dead and not level_complete_panel.visible:
		player.set_physics_process(true)
	resume_player_after_dialogue = false
	active_dialogue_npc = null


func _on_quest_updated() -> void:
	if quest_manager == null:
		quest_tracker_label.text = "QUEST SYSTEM UNAVAILABLE"
		return

	quest_tracker_label.text = "%s\nREWARD: %s" % [quest_manager.get_tracker_text(), quest_manager.get_reward_text()]
	if game_state != null and game_state.merchant_quest_state == 1:
		var fragment_count := mini(int(game_state.inventory.get("iron_fragment", 0)), 1)
		quest_tracker_label.text += "\nSIDE: A Fair Price  •  Iron Fragment %d/1" % fragment_count
	var survey_text: String = quest_manager.get_echo_survey_tracker_text()
	if not survey_text.is_empty():
		quest_tracker_label.text += "\n\n" + survey_text
	var return_text: String = quest_manager.get_return_contract_tracker_text()
	if not return_text.is_empty():
		quest_tracker_label.text += "\n\n" + return_text
	if dialogue_panel.visible:
		_update_dialogue_content()


func _setup_enemy_objective() -> void:
	var enemy_group: StringName = level_exit.required_enemy_group if level_exit != null else &"enemy"
	var enemies := get_tree().get_nodes_in_group(enemy_group)
	total_enemies = enemies.size()
	for enemy in enemies:
		if enemy.has_signal("defeated") and not enemy.defeated.is_connected(_on_enemy_defeated):
			enemy.defeated.connect(_on_enemy_defeated)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if str(enemy.get("zone_id")) == "sunken_shaft":
			var callback := Callable(self, "_on_zone_enemy_defeated")
			if enemy.has_signal("defeated") and not enemy.is_connected("defeated", callback):
				enemy.connect("defeated", callback)
	_update_objective_label()


func _on_enemy_defeated() -> void:
	defeated_enemies += 1
	_update_objective_label()
	_show_notification("ENEMY DEFEATED  •  XP DROPPED")


func _on_zone_enemy_defeated() -> void:
	_update_objective_label()
	_show_notification("SHAFT ENEMY DEFEATED  •  LOOT DROPPED")


func _update_objective_label() -> void:
	if game_state != null and game_state.current_room_id == "echo_sanctum":
		if bool(game_state.boss_rematches.get("echo_matriarch", false)):
			objective_label.text = "ASHEN GATE OPEN  •  MATRIARCH DEFEATED"
		elif bool(game_state.defeated_bosses.get("echo_matriarch", false)):
			objective_label.text = "ASHEN GATE OPEN  •  AWAKENED MATRIARCH OPTIONAL"
		else:
			objective_label.text = "DEFEAT ECHO MATRIARCH"
		return
	if game_state != null and game_state.current_room_id == "echo_nest":
		if bool(game_state.defeated_bosses.get("echo_matriarch", false)):
			objective_label.text = "MATRIARCH DEFEATED"
		elif game_state.has_item("nest_crest"):
			objective_label.text = "ENTER SANCTUM"
		elif bool(game_state.unlocked_shortcuts.get("echo_nest_cleared", false)):
			objective_label.text = "CLAIM NEST CREST"
		else:
			var brood_left := 0
			for brood in get_tree().get_nodes_in_group("nest_brood"):
				if not bool(brood.get("is_dead")):
					brood_left += 1
			objective_label.text = "CLEAR BROOD  %d LEFT" % brood_left
		return
	if game_state != null and game_state.current_room_id == "echo_tide_well":
		if not game_state.has_item("tide_core"):
			objective_label.text = "DESCEND FOR TIDE CORE"
		elif not game_state.has_item("nest_crest"):
			objective_label.text = "ENTER ECHO NEST"
		elif not bool(game_state.unlocked_shortcuts.get("tide_lift", false)):
			objective_label.text = "ACTIVATE LOWER LIFT"
		else:
			objective_label.text = "RETURN TO GROTTO"
		return
	if game_state != null and game_state.current_room_id == "echo_causeway":
		objective_label.text = "TIDE LOOP OPEN" if bool(game_state.unlocked_shortcuts.get("echo_causeway_anchor", false)) else "CROSS THE PHASE BRIDGE  •  STABILIZE ANCHOR [E]"
		return
	if game_state != null and game_state.current_room_id == "echo_vault":
		var seals := int(bool(game_state.unlocked_shortcuts.get("echo_vault_upper", false))) + int(bool(game_state.unlocked_shortcuts.get("echo_vault_far", false)))
		objective_label.text = "TIDEGUARD MANTLE CLAIMED" if bool(game_state.opened_caches.get("vault_mantle", false)) else ("CLAIM THE RELIQUARY" if seals == 2 else "ATTUNE VAULT SEALS  %d/2" % seals)
		return
	if game_state != null and game_state.current_room_id == "echo_archive":
		if game_state.has_item("memory_sigil_echo"):
			objective_label.text = "RETURN TO GROTTO"
		else:
			var archive := get_tree().get_first_node_in_group("prism_archive")
			objective_label.text = "ALIGN MIRRORS %d/3" % (int(archive.step) if archive != null else 0)
		return
	if game_state != null and game_state.current_room_id == "echo_gallery":
		if game_state.has_item("memory_sigil_echo"):
			objective_label.text = "ARCHIVE CLEARED"
		elif game_state.has_item("gallery_prism"):
			objective_label.text = "ENTER THE ARCHIVE"
		else:
			objective_label.text = "FIND THE GALLERY PRISM"
		return
	if game_state != null and game_state.current_room_id == "echo_grotto":
		if bool(game_state.defeated_bosses.get("echo_matriarch", false)):
			objective_label.text = "ASHEN BASTION OPEN" if game_state.has_item("memory_sigil_echo") else "SEEK ECHO MEMORY SIGIL"
		elif game_state.has_item("memory_sigil_echo") and game_state.has_item("nest_crest"):
			objective_label.text = "ECHO RELICS GATHERED"
		elif game_state.has_item("memory_sigil_echo") and game_state.has_item("tide_core"):
			objective_label.text = "CLEAR ECHO NEST"
		elif game_state.has_item("memory_sigil_echo"):
			objective_label.text = "SEEK TIDE CORE"
		elif game_state.has_item("tide_core"):
			objective_label.text = "SEEK ECHO SIGIL"
		elif game_state.has_item("gallery_prism"):
			objective_label.text = "GALLERY  →  ARCHIVE"
		elif game_state.has_item("echo_charm"):
			objective_label.text = "ENTER THE GALLERY  →"
		else:
			var resonators := int(bool(game_state.unlocked_shortcuts.get("echo_resonator_lower", false))) + int(bool(game_state.unlocked_shortcuts.get("echo_resonator_upper", false)))
			objective_label.text = "RESONATORS %d/2  •  CLIMB" % resonators
		return
	if game_state != null and game_state.current_room_id == "shaft_hollow":
		if bool(game_state.unlocked_shortcuts.get("shaft_hollow_relay", false)):
			objective_label.text = "RELAY ACTIVE  •  LOWER SHAFT OPEN"
		else:
			var guardians_left := 0
			for guardian in get_tree().get_nodes_in_group("hollow_guardian"):
				if not bool(guardian.get("is_dead")):
					guardians_left += 1
			objective_label.text = "CLEAR HOLLOW WISPS  %d LEFT" % guardians_left if guardians_left > 0 else "ACTIVATE THE HOLLOW RELAY [E]"
		return
	if game_state != null and game_state.current_room_id == "shaft_crossing":
		if not bool(game_state.unlocked_shortcuts.get("shaft_sluice_valve", false)):
			objective_label.text = "CROSS THE SURGE  •  DRAIN THE VALVE [E]"
		elif not bool(game_state.unlocked_shortcuts.get("shaft_hollow_relay", false)):
			objective_label.text = "CROSSING SAFE  •  HOLLOW RELAY SEALED"
		else:
			objective_label.text = "CROSSING SAFE  •  HOLLOW LOOP OPEN"
		return
	if game_state != null and game_state.current_room_id == "shaft_gallery":
		var controls := int(bool(game_state.unlocked_shortcuts.get("shaft_gallery_lower", false))) + int(bool(game_state.unlocked_shortcuts.get("shaft_gallery_upper", false)))
		objective_label.text = "WARDEN SHORTCUT OPEN" if controls == 2 else "TURN GALLERY CONTROLS  %d/2" % controls
		return
	if game_state != null and game_state.current_room_id == "shaft_cistern":
		if bool(game_state.unlocked_shortcuts.get("shaft_cistern_pump", false)):
			objective_label.text = "PUMP ACTIVE  •  GALLERY LOOP OPEN"
		else:
			var cistern := get_parent().get_node_or_null("BlackwaterCistern")
			var progress := int(cistern.puzzle_progress) if cistern != null else 0
			objective_label.text = "DIALS %d/3  •  NEAR > HIGH > FAR" % progress
		return
	if game_state != null and game_state.current_room_id == "shaft_approach":
		objective_label.text = "BRIDGE LOWERED  •  WARDEN AHEAD" if bool(game_state.unlocked_shortcuts.get("shaft_approach_bridge", false)) else "CLIMB THE GANTRY  •  LOWER THE BRIDGE"
		return
	if game_state != null and game_state.current_room_id == "ash_causeway":
		objective_label.text = "VENTS QUIET  •  FORGE OPEN" if bool(game_state.unlocked_shortcuts.get("ash_forge_fan", false)) else "CROSS THE VENTS  •  FIND THE FORGE"
		return
	if game_state != null and game_state.current_room_id == "ash_forge":
		objective_label.text = "FORGE AIRFLOW RESTORED  •  BARRACKS OPEN →" if bool(game_state.unlocked_shortcuts.get("ash_forge_fan", false)) else "CLIMB TO THE COOLING FAN [E]"
		return
	if game_state != null and game_state.current_room_id == "ash_barracks":
		var barracks := get_parent().get_node_or_null("EmberBarracks")
		if bool(game_state.unlocked_shortcuts.get("ash_barracks_cleared", false)):
			objective_label.text = "TRIAL CLEARED  •  CAUSEWAY LOOP OPEN"
		elif barracks != null and barracks.active:
			objective_label.text = "TRIAL WAVE %d/2  •  %d LEFT" % [barracks.wave, barracks.enemies_remaining]
		else:
			objective_label.text = "ACTIVATE THE BARRACKS SIGNAL [E]"
		return
	if game_state != null and game_state.current_room_id == "sunken_shaft":
		if bool(game_state.defeated_bosses.get("abyss_warden", false)):
			objective_label.text = "WARDEN HEART CLAIMED  •  ECHO OPEN" if bool(game_state.boss_rematches.get("abyss_warden", false)) else "ECHO OPEN  •  AWAKENED WARDEN OPTIONAL"
			return
		var remaining_threats := 0
		var shaft_room := get_parent().get_node_or_null("VerticalChamber")
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if shaft_room != null and shaft_room.is_ancestor_of(enemy) and not bool(enemy.get("is_dead")):
				remaining_threats += 1
		objective_label.text = "SUNKEN SHAFT  •  THREATS REMAINING %d" % remaining_threats
		return
	if level_exit != null and level_exit.is_unlocked:
		objective_label.text = "AREA CLEAR  •  Reach the exit"
	elif total_enemies <= 0:
		objective_label.text = "Explore the training ground"
	elif defeated_enemies >= total_enemies:
		objective_label.text = "AREA CLEAR  •  Reach the exit"
	else:
		objective_label.text = "DEFEAT ENEMIES  %d/%d" % [defeated_enemies, total_enemies]


func _show_notification(message: String) -> void:
	if notification_tween != null and notification_tween.is_valid():
		notification_tween.kill()

	notification_label.text = message
	notification_label.modulate.a = 1.0
	notification_tween = create_tween()
	notification_tween.tween_interval(1.1)
	notification_tween.tween_property(notification_label, "modulate:a", 0.0, 0.35)


func _on_exit_unlocked() -> void:
	_show_notification("EXIT UNLOCKED")
	_update_objective_label()


func _on_level_completed() -> void:
	if player == null or player.is_dead:
		return

	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	dialogue_panel.hide()
	resume_player_after_dialogue = false
	_close_side_panels()
	menu_bar_panel.hide()
	objective_label.text = "LEVEL COMPLETE"
	level_complete_panel.show()
	play_again_button.grab_focus()


func _on_health_changed(current_health: int, maximum_health: int) -> void:
	health_bar.max_value = maximum_health
	health_bar.value = current_health
	health_label.text = "HP: %d/%d" % [current_health, maximum_health]
	if inventory_panel.visible:
		_update_inventory_panel()


func _on_mana_changed(_current_mana: int, _maximum_mana: int) -> void:
	_update_weapon_status()


func _on_second_breath_changed(is_active: bool) -> void:
	revive_status_label.text = "BREATH READY"
	revive_status_label.modulate = Color(0.45, 1.0, 0.72, 1.0)
	revive_status_label.visible = is_active and not main_menu_panel.visible
	if inventory_panel.visible:
		_update_inventory_panel()


func _on_second_breath_triggered() -> void:
	_show_notification("SECOND BREATH  •  REVIVED AT 20% HP")


func _on_progression_changed(current_xp: int, required_xp: int, points: int) -> void:
	xp_bar.max_value = required_xp
	xp_bar.value = current_xp
	xp_label.text = "XP: %d/%d" % [current_xp, required_xp]
	skill_points_label.text = "SP: %d" % points
	_update_skill_buttons()


func _on_double_jump_state_changed(_is_unlocked: bool) -> void:
	_update_skill_buttons()


func _on_dash_state_changed(_is_unlocked: bool) -> void:
	_update_skill_buttons()


func _update_skill_buttons() -> void:
	if player == null:
		return

	if player.double_jump_unlocked:
		double_jump_button.text = "Double Jump - Unlocked"
		double_jump_button.disabled = true
	else:
		double_jump_button.text = "Unlock Double Jump - %d SP" % player.double_jump_cost
		double_jump_button.disabled = not player.can_unlock_double_jump()

	if player.dash_unlocked:
		dash_button.text = "Dash - Unlocked"
		dash_button.disabled = true
	else:
		dash_button.text = "Unlock Dash - %d SP" % player.dash_cost
		dash_button.disabled = not player.can_unlock_dash()

	sword_mastery_button.text = "Sword Mastery: +1 Damage  •  UNLOCKED" if player.sword_mastery_unlocked else "Sword Mastery: +1 Damage  •  1 SP"
	sword_mastery_button.disabled = player.sword_mastery_unlocked or not player.can_unlock_weapon_mastery("sword")
	sword_reach_button.text = "Long Reach: +16 Range  •  UNLOCKED" if player.sword_reach_unlocked else ("Long Reach: +16 Range  •  1 SP" if player.sword_mastery_unlocked else "Long Reach  •  Requires Sword Mastery")
	sword_reach_button.disabled = not player.can_unlock_advanced_mastery("sword")
	if player.bow_mastery_unlocked:
		bow_mastery_button.text = "Bow Mastery: +1 Damage  •  UNLOCKED"
	elif game_state == null or not game_state.has_weapon_class("bow"):
		bow_mastery_button.text = "Bow Mastery  •  Requires a Bow"
	else:
		bow_mastery_button.text = "Bow Mastery: +1 Damage  •  1 SP"
	bow_mastery_button.disabled = player.bow_mastery_unlocked or not player.can_unlock_weapon_mastery("bow")
	bow_piercing_button.text = "Piercing Shot: 2 Targets  •  UNLOCKED" if player.bow_piercing_unlocked else ("Piercing Shot: 2 Targets  •  1 SP" if player.bow_mastery_unlocked else "Piercing Shot  •  Requires Bow Mastery")
	bow_piercing_button.disabled = not player.can_unlock_advanced_mastery("bow")
	if player.staff_mastery_unlocked:
		staff_mastery_button.text = "Runic Mastery: +1 Damage  •  UNLOCKED"
	elif game_state == null or not game_state.has_weapon_class("staff"):
		staff_mastery_button.text = "Runic Mastery  •  Requires a Staff"
	else:
		staff_mastery_button.text = "Runic Mastery: +1 Damage  •  1 SP"
	staff_mastery_button.disabled = player.staff_mastery_unlocked or not player.can_unlock_weapon_mastery("staff")
	staff_flow_button.text = "Mana Flow: +50% Regen  •  UNLOCKED" if player.staff_flow_unlocked else ("Mana Flow: +50% Regen  •  1 SP" if player.staff_mastery_unlocked else "Mana Flow  •  Requires Runic Mastery")
	staff_flow_button.disabled = not player.can_unlock_advanced_mastery("staff")
	skill_info_label.text = "Each weapon's second skill needs its Mastery. Skills persist at Save Lamps."


func _on_double_jump_button_pressed() -> void:
	if player != null:
		player.try_unlock_double_jump()


func _on_dash_button_pressed() -> void:
	if player != null:
		player.try_unlock_dash()


func _on_sword_mastery_pressed() -> void:
	if player != null and player.try_unlock_weapon_mastery("sword"):
		_show_notification("SWORD MASTERY UNLOCKED  •  +1 DAMAGE")


func _on_sword_reach_pressed() -> void:
	if player != null and player.try_unlock_advanced_mastery("sword"):
		_show_notification("LONG REACH UNLOCKED  •  +16 MELEE RANGE")


func _on_bow_mastery_pressed() -> void:
	if player != null and player.try_unlock_weapon_mastery("bow"):
		_show_notification("BOW MASTERY UNLOCKED  •  +1 DAMAGE")


func _on_bow_piercing_pressed() -> void:
	if player != null and player.try_unlock_advanced_mastery("bow"):
		_show_notification("PIERCING SHOT UNLOCKED  •  BASIC ARROWS HIT TWO")
		_update_weapon_status()


func _on_staff_mastery_pressed() -> void:
	if player != null and player.try_unlock_weapon_mastery("staff"):
		_show_notification("RUNIC MASTERY UNLOCKED  •  +1 DAMAGE")


func _on_staff_flow_pressed() -> void:
	if player != null and player.try_unlock_advanced_mastery("staff"):
		_show_notification("MANA FLOW UNLOCKED  •  FASTER STAFF REGEN")


func _on_player_died() -> void:
	if get_tree().paused:
		_resume_game()
	dialogue_panel.hide()
	resume_player_after_dialogue = false
	_close_side_panels()
	menu_bar_panel.hide()
	level_complete_panel.hide()
	if game_state != null and game_state.game_mode == "hardcore":
		game_over_label.text = "HARDCORE RUN ENDED\nAll progress has been lost"
		restart_button.text = "Start Hardcore Again"
		switch_mode_button.show()
	else:
		game_over_label.text = "YOU FELL\nReturn to the last Save Lamp"
		restart_button.text = "Return to Lamp"
		switch_mode_button.hide()
	game_over_panel.show()
	restart_button.grab_focus()


func _on_respawn_button_pressed() -> void:
	if player == null or game_state == null:
		return
	if game_state.game_mode == "hardcore":
		game_state.start_new_game("hardcore")
		get_tree().reload_current_scene()
		return
	if game_state.load_game():
		get_tree().reload_current_scene()
	else:
		game_state.start_new_game("normal")
		get_tree().reload_current_scene()


func _switch_to_normal_mode() -> void:
	if game_state == null:
		return
	game_state.start_new_game("normal")
	get_tree().paused = false
	get_tree().reload_current_scene()


func _reload_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _restart_journey() -> void:
	get_tree().paused = false
	if game_state != null:
		game_state.reset_to_main_menu()
	get_tree().reload_current_scene()
