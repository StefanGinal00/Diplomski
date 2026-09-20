extends Node

const CACHE_SCENE := preload("res://ResonanceCache.tscn")
const WISP_SCENE := preload("res://ShaftWisp.tscn")
const SHADE_SCENE := preload("res://EchoShade.tscn")
const BROOD_SCENE := preload("res://EchoBroodling.tscn")
const WARDEN_SCENE := preload("res://AbyssWarden.tscn")
const MATRIARCH_SCENE := preload("res://EchoMatriarch.tscn")

const CACHES := [
	["Game", "training_passage", "passage_return", Vector2(945, 371), 24, "iron_fragment"],
	["VerticalChamber", "sunken_shaft", "shaft_rim", Vector2(281, 48), 26, "healing_herb"],
	["VerticalChamber", "sunken_shaft", "shaft_depth", Vector2(365, 629), 34, "ether_dust"],
	["ShaftHollow", "sunken_shaft", "hollow_resonance", Vector2(615, 300), 32, "iron_fragment"],
	["DrownedCrossing", "sunken_shaft", "crossing_dregs", Vector2(634, 216), 34, "ether_dust"],
	["FloodedGallery", "sunken_shaft", "gallery_afterglow", Vector2(455, 174), 36, "iron_fragment"],
	["BlackwaterCistern", "sunken_shaft", "cistern_echo", Vector2(280, 243), 36, "iron_fragment"],
	["WardenApproach", "sunken_shaft", "approach_afterglow", Vector2(455, 227), 38, "ether_dust"],
	["EchoGrotto", "echo_grotto", "grotto_high", Vector2(875, -105), 28, "resonance_shard"],
	["EchoGallery", "echo_grotto", "gallery_step", Vector2(515, -49), 30, "ember_arrow"],
	["PrismArchive", "echo_grotto", "archive_shelf", Vector2(505, 1), 32, "resonance_shard"],
	["TideWell", "echo_grotto", "tide_depth", Vector2(340, 535), 36, "healing_herb"],
	["EchoNest", "echo_grotto", "nest_cocoon", Vector2(508, 0), 38, "iron_fragment"],
	["ResonanceSanctum", "echo_grotto", "sanctum_heart", Vector2(695, 61), 50, "life_bloom"],
	["CrystalCauseway", "echo_grotto", "causeway_afterglow", Vector2(390, 251), 38, "resonance_shard"],
	["UndertowVault", "echo_grotto", "vault_undertow", Vector2(265, 251), 40, "resonance_shard"],
]

const REINFORCEMENTS := [
	["VerticalChamber", "sunken_shaft", "shaft_echo_wisp", "sunken_shaft", Vector2(90, 420), Vector2(235, 435)],
	["ShaftHollow", "sunken_shaft", "hollow_echo_wisp", "shaft_hollow", Vector2(352, 175), Vector2(426, 185)],
	["DrownedCrossing", "sunken_shaft", "crossing_echo_wisp", "shaft_crossing", Vector2(370, 205), Vector2(555, 205)],
	["FloodedGallery", "sunken_shaft", "gallery_echo_wisp", "shaft_gallery", Vector2(355, 145), Vector2(675, 146)],
	["BlackwaterCistern", "sunken_shaft", "cistern_echo_wisp", "shaft_cistern", Vector2(605, 130), Vector2(735, 175)],
	["WardenApproach", "sunken_shaft", "approach_echo_wisp", "shaft_approach", Vector2(470, 160), Vector2(755, 180)],
	["EchoGrotto", "echo_grotto", "grotto_echo_wisp", "echo_grotto", Vector2(790, 28), Vector2(860, 45)],
	["EchoGallery", "echo_grotto", "gallery_echo_shade", "echo_gallery", Vector2(630, 135), Vector2(690, 135)],
	["PrismArchive", "echo_grotto", "archive_echo_shade", "echo_archive", Vector2(520, 135), Vector2(565, 135)],
	["TideWell", "echo_grotto", "tide_echo_wisp", "echo_tide_well", Vector2(170, 510), Vector2(300, 522)],
	["EchoNest", "echo_grotto", "nest_echo_brood", "echo_nest", Vector2(365, 145), Vector2(530, 145)],
	["CrystalCauseway", "echo_grotto", "causeway_echo_wisp", "echo_causeway", Vector2(338, 196), Vector2(560, 197)],
	["UndertowVault", "echo_grotto", "vault_echo_wisp", "echo_vault", Vector2(580, 203), Vector2(737, 203)],
]

var spawned_reinforcements: Dictionary = {}


func _ready() -> void:
	call_deferred("_initialize")


func _initialize() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return
	game_state.zone_tier_changed.connect(_on_zone_tier_changed)
	game_state.room_changed.connect(_on_room_changed)
	game_state.boss_progress_changed.connect(_on_boss_progress_changed)
	_sync_contents(false)


func _on_zone_tier_changed(_zone_id: String, _tier: int) -> void:
	_sync_contents(true)


func _on_room_changed(room_id: String) -> void:
	_sync_contents(false)
	_respawn_boss_rematch(room_id)


func _on_boss_progress_changed(_boss_id: String) -> void:
	_sync_contents(true)


func _sync_contents(skip_current_room: bool) -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return
	for entry in CACHES:
		if game_state.get_zone_tier(str(entry[1])) < 1:
			continue
		if str(entry[2]) == "sanctum_heart" and not bool(game_state.boss_rematches.get("echo_matriarch", false)):
			continue
		var room := _get_room(str(entry[0]))
		var node_name := "Cache_" + str(entry[2])
		if room == null or room.has_node(node_name):
			continue
		var cache := CACHE_SCENE.instantiate() as Area2D
		cache.name = node_name
		cache.position = entry[3]
		cache.cache_id = str(entry[2])
		cache.cache_name = str(entry[2]).replace("_", " ").capitalize()
		cache.gold_reward = int(entry[4])
		cache.reward_item_id = str(entry[5])
		room.add_child(cache)
	for entry in REINFORCEMENTS:
		var encounter_id := str(entry[2])
		if spawned_reinforcements.has(encounter_id) or game_state.get_zone_tier(str(entry[1])) < 1:
			continue
		if skip_current_room and game_state.current_room_id == str(entry[3]):
			continue
		var room := _get_room(str(entry[0]))
		if room == null:
			continue
		var enemy: CharacterBody2D
		if "brood" in encounter_id:
			enemy = BROOD_SCENE.instantiate()
		elif "shade" in encounter_id:
			enemy = SHADE_SCENE.instantiate()
		else:
			enemy = WISP_SCENE.instantiate()
		enemy.name = encounter_id
		enemy.position = entry[4] if randi_range(0, 1) == 0 else entry[5]
		enemy.set("zone_id", str(entry[1]))
		room.add_child(enemy)
		if enemy.is_in_group("nest_brood"):
			enemy.remove_from_group("nest_brood")
		spawned_reinforcements[encounter_id] = true


func _respawn_boss_rematch(room_id: String) -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return
	var room: Node2D
	var boss: CharacterBody2D
	var boss_id := ""
	if room_id == "sunken_shaft":
		room = _get_room("VerticalChamber")
		boss_id = "abyss_warden"
		if room != null and not room.has_node("AbyssWarden"):
			boss = WARDEN_SCENE.instantiate()
			boss.name = "AbyssWarden"
			boss.position = Vector2(585, 630)
	elif room_id == "echo_sanctum":
		room = _get_room("ResonanceSanctum")
		boss_id = "echo_matriarch"
		if room != null and not room.has_node("EchoMatriarch"):
			boss = MATRIARCH_SCENE.instantiate()
			boss.name = "EchoMatriarch"
			boss.position = Vector2(500, 34)
	if boss == null or not bool(game_state.defeated_bosses.get(boss_id, false)) or bool(game_state.boss_rematches.get(boss_id, false)):
		return
	room.add_child(boss)
	var ui := get_parent().get_node_or_null("UI")
	if ui != null:
		ui.register_boss(boss)


func _get_room(room_name: String) -> Node2D:
	if room_name == "Game":
		return get_parent() as Node2D
	return get_parent().get_node_or_null(room_name) as Node2D
