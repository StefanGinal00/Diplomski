extends Node

signal gold_changed(current_gold: int)
signal inventory_changed
signal equipment_changed
signal weapon_upgraded(weapon_id: String, level: int)
signal item_acquired(item_id: String, amount: int)
signal zone_tier_changed(zone_id: String, tier: int)
signal cache_opened(cache_id: String)
signal room_changed(room_id: String)
signal mode_changed(mode: String)
signal save_completed
signal lamps_changed
signal save_recovered
signal merchant_changed
signal shortcut_changed(shortcut_id: String)
signal boss_progress_changed(boss_id: String)

const MODE_NORMAL := "normal"
const MODE_HARDCORE := "hardcore"
const STARTING_WEAPON := "worn_sword"
const MAX_WEAPON_UPGRADE := 5
const ENEMY_FAMILIES := ["spirit", "demon", "beast", "construct"]
const FORGE_RECIPES := {
	"worn_sword": [{"gold": 50, "iron_fragment": 2}, {"gold": 90, "iron_fragment": 3, "ether_dust": 1}, {"gold": 130, "iron_fragment": 4, "ether_dust": 2}, {"gold": 180, "iron_fragment": 4, "resonance_shard": 1}, {"gold": 260, "iron_fragment": 5, "resonance_shard": 2}],
	"spiritglass_blade": [{"gold": 65, "iron_fragment": 2, "ether_dust": 1}, {"gold": 110, "iron_fragment": 3, "ether_dust": 2}, {"gold": 155, "iron_fragment": 4, "ether_dust": 2}, {"gold": 210, "iron_fragment": 4, "resonance_shard": 1}, {"gold": 290, "iron_fragment": 5, "resonance_shard": 2}],
	"hunter_bow": [{"gold": 60, "iron_fragment": 2}, {"gold": 100, "iron_fragment": 3, "ether_dust": 1}, {"gold": 145, "iron_fragment": 4, "ether_dust": 2}, {"gold": 195, "iron_fragment": 4, "resonance_shard": 1}, {"gold": 275, "iron_fragment": 5, "resonance_shard": 2}],
	"thorn_bow": [{"gold": 70, "iron_fragment": 2, "ether_dust": 1}, {"gold": 115, "iron_fragment": 3, "ether_dust": 2}, {"gold": 160, "iron_fragment": 4, "ether_dust": 2}, {"gold": 215, "iron_fragment": 4, "resonance_shard": 1}, {"gold": 300, "iron_fragment": 5, "resonance_shard": 2}],
	"apprentice_staff": [{"gold": 65, "ether_dust": 2}, {"gold": 110, "ether_dust": 3, "iron_fragment": 1}, {"gold": 155, "ether_dust": 4, "iron_fragment": 2}, {"gold": 205, "ether_dust": 4, "resonance_shard": 1}, {"gold": 285, "ether_dust": 5, "resonance_shard": 2}],
	"sunder_staff": [{"gold": 80, "ether_dust": 2, "iron_fragment": 1}, {"gold": 125, "ether_dust": 3, "iron_fragment": 2}, {"gold": 170, "ether_dust": 4, "iron_fragment": 2}, {"gold": 225, "ether_dust": 4, "resonance_shard": 1}, {"gold": 310, "ether_dust": 5, "resonance_shard": 2}],
}
const ITEM_DEFINITIONS := {
	"worn_sword": {"name": "Basic Sword", "type": "weapon", "weapon_class": "sword", "preferred_slot": "primary_weapon", "damage": 1, "cooldown": 0.35, "range": 34, "description": "A balanced beginner blade. Reliable at close range and always available at the start of a journey.", "droppable": false, "base_price": 0},
	"spiritglass_blade": {"name": "Spiritglass Blade", "type": "weapon", "weapon_class": "sword", "preferred_slot": "primary_weapon", "damage": 1, "cooldown": 0.48, "range": 46, "bonus_family": "spirit", "bonus_damage": 1, "description": "Long reach, slower swing. Deals +1 damage to Spirits.", "droppable": true, "base_price": 155},
	"hunter_bow": {"name": "Hunter Bow", "type": "weapon", "weapon_class": "bow", "preferred_slot": "secondary_weapon", "damage": 1, "cooldown": 0.58, "range": 520, "description": "A light ranged weapon. Hold Up or Down while attacking to aim diagonally. Basic arrows are unlimited; special arrows are consumed.", "droppable": true, "base_price": 110},
	"thorn_bow": {"name": "Thorn Bow", "type": "weapon", "weapon_class": "bow", "preferred_slot": "secondary_weapon", "damage": 1, "cooldown": 0.46, "range": 420, "bonus_family": "beast", "bonus_damage": 1, "description": "Quick, short-ranged shots. Deals +1 damage to Beasts.", "droppable": true, "base_price": 170},
	"apprentice_staff": {"name": "Runed Staff", "type": "weapon", "weapon_class": "staff", "preferred_slot": "secondary_weapon", "damage": 2, "cooldown": 0.72, "range": 440, "description": "A focus for runic magic. Uses regenerating mana and can switch between every learned spell with [R].", "droppable": true, "base_price": 135},
	"sunder_staff": {"name": "Sunder Staff", "type": "weapon", "weapon_class": "staff", "preferred_slot": "secondary_weapon", "damage": 3, "cooldown": 0.95, "range": 350, "bonus_family": "construct", "bonus_damage": 1, "description": "Heavy, short-range spells. Deals +1 damage to Constructs.", "droppable": true, "base_price": 190},
	"guardian_band": {"name": "Guardian Band", "type": "defense", "preferred_slot": "defense", "description": "Heavy protection. Reduces each hit of 2 or more damage by 1, but every hit still deals at least 1 damage.", "droppable": true, "base_price": 90},
	"wind_cloak": {"name": "Wind Cloak", "type": "defense", "preferred_slot": "defense", "description": "Light protection. Reduces Dash cooldown by 25% once Dash is unlocked.", "droppable": true, "base_price": 110},
	"tideguard_mantle": {"name": "Tideguard Mantle", "type": "defense", "preferred_slot": "defense", "description": "Negates damage from tidal surges. Offers no protection against enemy attacks. Equipping it replaces your other defense gear.", "droppable": false, "base_price": 0},
	"ember_arrow": {"name": "Ember Arrow", "type": "ammo", "damage": 2, "description": "A special arrow that deals 2 damage and burns bright on impact. Select it with [R] while using a bow.", "droppable": true, "base_price": 8},
	"frost_rune": {"name": "Frost Rune", "type": "spell_tome", "spell_id": "frost_orb", "description": "Permanently teaches Frost Orb: a slower projectile that pierces two enemies for 2 mana.", "droppable": false, "base_price": 70},
	"healing_herb": {"name": "Healing Herb", "type": "consumable", "description": "Restores 2 HP when used.", "droppable": true, "base_price": 18},
	"life_bloom": {"name": "Life Bloom", "type": "consumable", "description": "Activates Second Breath. The next lethal hit revives you once with 20% HP. Only one can be active at a time.", "droppable": true, "base_price": 95},
	"iron_fragment": {"name": "Iron Fragment", "type": "material", "description": "A common forging material used for weapon upgrades.", "droppable": true, "base_price": 24},
	"ether_dust": {"name": "Ether Dust", "type": "material", "description": "Magical residue used for spells and staff upgrades.", "droppable": true, "base_price": 35},
	"resonance_shard": {"name": "Resonance Shard", "type": "material", "description": "A rare crystal from the awakened Echo Grotto. Required for forge ranks +4 and +5.", "droppable": true, "base_price": 140},
	"caretaker_charm": {"name": "Caretaker Charm", "type": "key_item", "description": "A token of the Caretaker's trust. It may open new dialogue and paths.", "droppable": false},
	"warden_seal": {"name": "Warden Seal", "type": "key_item", "description": "Taken from the Abyss Warden. Opens the sealed path into the Echo Grotto.", "droppable": false},
	"echo_charm": {"name": "Echo Charm", "type": "key_item", "description": "A relic awakened by both Grotto resonators. Permanently increases mana regeneration by 50% while carried.", "droppable": false},
	"gallery_prism": {"name": "Gallery Prism", "type": "key_item", "description": "A cut crystal from the Whispering Gallery. It unlocks the gallery's far passage and will be needed deeper in the Echo Grotto.", "droppable": false},
	"memory_sigil_echo": {"name": "Echo Memory Sigil", "type": "key_item", "description": "A memory awakened in the Prism Archive. One of the sigils needed to face the final boss.", "droppable": false},
	"tide_core": {"name": "Tide Core", "type": "key_item", "description": "A living core recovered from the Tide Well. It will be needed to reach the Echo Matriarch.", "droppable": false},
	"nest_crest": {"name": "Nest Crest", "type": "key_item", "description": "A crest revealed when the Echo Nest brood is cleared. It will open the path to the Echo Matriarch.", "droppable": false},
	"matriarch_seal": {"name": "Matriarch Seal", "type": "key_item", "description": "Taken from the Echo Matriarch. Together with her defeat, it opens the path into Ashen Bastion.", "droppable": false},
	"barracks_insignia": {"name": "Barracks Insignia", "type": "key_item", "description": "Proof of surviving the Ember Barracks trial. The Ashen Castellan's guard will recognize it.", "droppable": false},
	"marshal_emblem": {"name": "Marshal Emblem", "type": "key_item", "description": "Won in the Cinder Coliseum. One of the marks required to challenge the Ashen Castellan.", "droppable": false},
	"crucible_core": {"name": "Crucible Core", "type": "key_item", "description": "Recovered after balancing both Slag Reservoir coolant valves. It may power the path to the Ashen Castellan.", "droppable": false},
	"warden_heart": {"name": "Warden Heart", "type": "key_item", "description": "Earned by defeating the awakened Warden. Permanently grants +1 maximum HP.", "droppable": false},
	"matriarch_heart": {"name": "Matriarch Heart", "type": "key_item", "description": "Earned by defeating the awakened Matriarch. Permanently grants +1 maximum mana.", "droppable": false},
}

var save_path: String = "user://savegame.json"
var music_enabled: bool = true
var session_started: bool = false
var game_mode: String = MODE_NORMAL
var gold: int = 0
var inventory: Dictionary = {STARTING_WEAPON: 1}
var equipped_items: Dictionary = {"primary_weapon": STARTING_WEAPON, "secondary_weapon": "", "defense": ""}
var weapon_upgrades: Dictionary = {}
var active_weapon_slot: String = "primary_weapon"
var selected_arrow_type: String = "basic_arrow"
var selected_spell: String = "arc_bolt"
var unlocked_spells: Array[String] = []
var zone_tiers: Dictionary = {"training_passage": 0}
var defeated_bosses: Dictionary = {}
var boss_rematches: Dictionary = {}
var unlocked_shortcuts: Dictionary = {}
var opened_caches: Dictionary = {}
var current_room_path: String = "res://Game.tscn"
var current_room_id: String = "training_passage"
var discovered_rooms: Dictionary = {"training_passage": true}
var target_entrance_id: String = "default"
var has_player_state: bool = false
var player_state: Dictionary = {}
var quest_state: Dictionary = {}
var has_checkpoint: bool = false
var checkpoint_position: Vector2 = Vector2.ZERO
var checkpoint_lamp_id: String = ""
var checkpoint_lamp_name: String = "Save Lamp"
var discovered_lamps: Dictionary = {}
var last_saved_unix_time: int = 0
var last_load_used_backup: bool = false
var merchant_quest_state: int = 0
var merchant_discount_unlocked: bool = false


func start_new_game(mode: String = MODE_NORMAL) -> void:
	game_mode = mode if mode == MODE_HARDCORE else MODE_NORMAL
	session_started = true
	gold = 0
	inventory = {STARTING_WEAPON: 1}
	equipped_items = {"primary_weapon": STARTING_WEAPON, "secondary_weapon": "", "defense": ""}
	weapon_upgrades.clear()
	active_weapon_slot = "primary_weapon"
	selected_arrow_type = "basic_arrow"
	selected_spell = "arc_bolt"
	unlocked_spells.clear()
	zone_tiers = {"training_passage": 0}
	defeated_bosses.clear()
	boss_rematches.clear()
	unlocked_shortcuts.clear()
	opened_caches.clear()
	current_room_path = "res://Game.tscn"
	current_room_id = "training_passage"
	discovered_rooms = {"training_passage": true}
	target_entrance_id = "default"
	has_player_state = false
	player_state.clear()
	quest_state.clear()
	has_checkpoint = false
	checkpoint_position = Vector2.ZERO
	checkpoint_lamp_id = ""
	checkpoint_lamp_name = "Save Lamp"
	discovered_lamps.clear()
	last_saved_unix_time = 0
	last_load_used_backup = false
	merchant_quest_state = 0
	merchant_discount_unlocked = false
	delete_save()
	_emit_full_state()
	mode_changed.emit(game_mode)


func reset_to_main_menu() -> void:
	start_new_game(MODE_NORMAL)
	session_started = false


func add_gold(amount: int) -> bool:
	if amount <= 0:
		return false
	gold += amount
	gold_changed.emit(gold)
	return true


func can_afford(amount: int) -> bool:
	return amount >= 0 and gold >= amount


func spend_gold(amount: int) -> bool:
	if amount <= 0 or not can_afford(amount):
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true


func add_item(item_id: String, amount: int = 1) -> bool:
	if item_id.is_empty() or amount <= 0:
		return false
	inventory[item_id] = int(inventory.get(item_id, 0)) + amount
	inventory_changed.emit()
	item_acquired.emit(item_id, amount)
	return true


func has_item(item_id: String, amount: int = 1) -> bool:
	return amount > 0 and int(inventory.get(item_id, 0)) >= amount


func has_weapon_class(weapon_class: String) -> bool:
	for item_id in inventory.keys():
		if has_item(str(item_id)) and str(get_item_definition(str(item_id)).get("weapon_class", "")) == weapon_class:
			return true
	return false


func remove_item(item_id: String, amount: int = 1) -> bool:
	if not has_item(item_id, amount):
		return false
	var remaining := int(inventory[item_id]) - amount
	if remaining <= 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = remaining
	inventory_changed.emit()
	if item_id == "ember_arrow" and not has_item("ember_arrow") and selected_arrow_type == "ember_arrow":
		selected_arrow_type = "basic_arrow"
		equipment_changed.emit()
	return true


func equip_item(item_id: String, slot: String = "") -> bool:
	var definition := get_item_definition(item_id)
	if slot.is_empty():
		slot = str(definition.get("preferred_slot", "primary_weapon"))
	if not has_item(item_id):
		return false
	var item_type := str(definition.get("type", ""))
	if not ((item_type == "weapon" and slot in ["primary_weapon", "secondary_weapon"]) or (item_type == "defense" and slot == "defense")):
		return false
	equipped_items[slot] = item_id
	inventory_changed.emit()
	equipment_changed.emit()
	return true


func unequip_defense() -> bool:
	if str(equipped_items.get("defense", "")).is_empty():
		return false
	equipped_items["defense"] = ""
	inventory_changed.emit()
	equipment_changed.emit()
	return true


func get_equipped_defense_id() -> String:
	var defense_id := str(equipped_items.get("defense", ""))
	return defense_id if has_item(defense_id) else ""


func get_active_weapon_id() -> String:
	var weapon_id := str(equipped_items.get(active_weapon_slot, ""))
	if weapon_id.is_empty() or not has_item(weapon_id):
		active_weapon_slot = "primary_weapon"
		weapon_id = str(equipped_items.get(active_weapon_slot, STARTING_WEAPON))
	return weapon_id


func cycle_weapon() -> bool:
	var other_slot := "secondary_weapon" if active_weapon_slot == "primary_weapon" else "primary_weapon"
	var other_weapon := str(equipped_items.get(other_slot, ""))
	if other_weapon.is_empty() or not has_item(other_weapon):
		return false
	active_weapon_slot = other_slot
	equipment_changed.emit()
	return true


func toggle_arrow_type() -> String:
	if selected_arrow_type == "basic_arrow" and has_item("ember_arrow"):
		selected_arrow_type = "ember_arrow"
	else:
		selected_arrow_type = "basic_arrow"
	equipment_changed.emit()
	return selected_arrow_type


func select_arrow_type(arrow_type: String) -> bool:
	if arrow_type == "ember_arrow" and not has_item("ember_arrow"):
		return false
	selected_arrow_type = arrow_type if arrow_type == "ember_arrow" else "basic_arrow"
	equipment_changed.emit()
	return true


func unlock_spell(spell_id: String) -> bool:
	if spell_id.is_empty() or unlocked_spells.has(spell_id):
		return false
	unlocked_spells.append(spell_id)
	if unlocked_spells.size() == 1:
		selected_spell = spell_id
	inventory_changed.emit()
	equipment_changed.emit()
	return true


func cycle_spell() -> bool:
	if unlocked_spells.size() <= 1:
		return false
	var current_index := unlocked_spells.find(selected_spell)
	selected_spell = unlocked_spells[(current_index + 1) % unlocked_spells.size()]
	equipment_changed.emit()
	return true


func start_merchant_quest() -> bool:
	if merchant_quest_state != 0:
		return false
	merchant_quest_state = 1
	merchant_changed.emit()
	return true


func complete_merchant_quest() -> bool:
	if merchant_quest_state != 1 or not has_item("iron_fragment"):
		return false
	remove_item("iron_fragment", 1)
	merchant_quest_state = 2
	merchant_discount_unlocked = true
	add_item("ember_arrow", 3)
	merchant_changed.emit()
	return true


func get_shop_price(base_price: int) -> int:
	if merchant_discount_unlocked:
		return maxi(int(ceil(base_price * 0.8)), 1)
	return maxi(base_price, 0)


func get_weapon_upgrade_level(weapon_id: String) -> int:
	return clampi(int(weapon_upgrades.get(weapon_id, 0)), 0, MAX_WEAPON_UPGRADE)


func get_weapon_upgrade_cost(weapon_id: String) -> Dictionary:
	if not FORGE_RECIPES.has(weapon_id):
		return {}
	var level := get_weapon_upgrade_level(weapon_id)
	if level >= MAX_WEAPON_UPGRADE:
		return {}
	var recipe: Dictionary = FORGE_RECIPES[weapon_id][level]
	var cost := recipe.duplicate()
	cost["gold"] = get_shop_price(int(cost.get("gold", 0)))
	return cost


func can_upgrade_weapon(weapon_id: String) -> bool:
	if not has_item(weapon_id):
		return false
	var cost := get_weapon_upgrade_cost(weapon_id)
	if cost.is_empty() or not can_afford(int(cost.get("gold", 0))):
		return false
	for material_id in cost.keys():
		if material_id != "gold" and not has_item(str(material_id), int(cost[material_id])):
			return false
	return true


func upgrade_weapon(weapon_id: String) -> bool:
	if not can_upgrade_weapon(weapon_id):
		return false
	var cost := get_weapon_upgrade_cost(weapon_id)
	gold -= int(cost["gold"])
	for material_id in cost.keys():
		if material_id == "gold":
			continue
		var remaining := int(inventory.get(material_id, 0)) - int(cost[material_id])
		if remaining <= 0:
			inventory.erase(material_id)
		else:
			inventory[material_id] = remaining
	var new_level := get_weapon_upgrade_level(weapon_id) + 1
	weapon_upgrades[weapon_id] = new_level
	gold_changed.emit(gold)
	inventory_changed.emit()
	equipment_changed.emit()
	weapon_upgraded.emit(weapon_id, new_level)
	return true


func get_weapon_damage_bonus(weapon_id: String) -> int:
	var level := get_weapon_upgrade_level(weapon_id)
	return int(level >= 1) + int(level >= 3) + int(level >= 5)


func get_weapon_cooldown_multiplier(weapon_id: String) -> float:
	var level := get_weapon_upgrade_level(weapon_id)
	return 0.82 if level >= 4 else (0.88 if level >= 2 else 1.0)


func get_enemy_family(target: Node) -> String:
	if target == null or not target.is_in_group("enemy"):
		return ""
	for family in ENEMY_FAMILIES:
		if target.is_in_group("family_" + family):
			return family
	return ""


func get_weapon_target_bonus(weapon_id: String, target: Node) -> int:
	if target == null or not target.is_in_group("enemy"):
		return 0
	var definition := get_item_definition(weapon_id)
	var bonus := 0
	var bonus_family := str(definition.get("bonus_family", ""))
	if not bonus_family.is_empty() and bonus_family == get_enemy_family(target):
		bonus += int(definition.get("bonus_damage", 0))
	if target.is_in_group("boss"):
		bonus += int(definition.get("bonus_boss_damage", 0))
	return bonus


func get_item_definition(item_id: String) -> Dictionary:
	if ITEM_DEFINITIONS.has(item_id):
		return ITEM_DEFINITIONS[item_id]
	return {"name": item_id.replace("_", " ").capitalize(), "type": "material", "description": "An unidentified item.", "droppable": true}


func set_zone_tier(zone_id: String, tier: int) -> void:
	if zone_id.is_empty():
		return
	var safe_tier := maxi(tier, 0)
	if int(zone_tiers.get(zone_id, 0)) == safe_tier:
		return
	zone_tiers[zone_id] = safe_tier
	zone_tier_changed.emit(zone_id, safe_tier)


func get_zone_tier(zone_id: String) -> int:
	return int(zone_tiers.get(zone_id, 0))


func unlock_shortcut(shortcut_id: String) -> bool:
	if shortcut_id.is_empty() or bool(unlocked_shortcuts.get(shortcut_id, false)):
		return false
	unlocked_shortcuts[shortcut_id] = true
	shortcut_changed.emit(shortcut_id)
	return true


func mark_boss_defeated(boss_id: String) -> bool:
	if boss_id.is_empty() or bool(defeated_bosses.get(boss_id, false)):
		return false
	defeated_bosses[boss_id] = true
	boss_progress_changed.emit(boss_id)
	return true


func mark_boss_rematch_cleared(boss_id: String) -> bool:
	if boss_id.is_empty() or not bool(defeated_bosses.get(boss_id, false)) or bool(boss_rematches.get(boss_id, false)):
		return false
	boss_rematches[boss_id] = true
	boss_progress_changed.emit(boss_id)
	return true


func open_cache(cache_id: String) -> bool:
	if cache_id.is_empty() or bool(opened_caches.get(cache_id, false)):
		return false
	opened_caches[cache_id] = true
	cache_opened.emit(cache_id)
	return true


func set_current_room(room_id: String) -> void:
	if room_id.is_empty():
		return
	discovered_rooms[room_id] = true
	if current_room_id == room_id:
		return
	current_room_id = room_id
	room_changed.emit(room_id)


func capture_player(player) -> void:
	if player == null:
		return
	player_state = {
		"max_health": player.max_health,
		"current_health": player.current_health,
		"max_mana": player.max_mana,
		"current_mana": player.current_mana,
		"xp": player.xp,
		"skill_points": player.skill_points,
		"double_jump_unlocked": player.double_jump_unlocked,
		"dash_unlocked": player.dash_unlocked,
		"second_breath_active": player.second_breath_active,
		"sword_mastery_unlocked": player.sword_mastery_unlocked,
		"bow_mastery_unlocked": player.bow_mastery_unlocked,
		"staff_mastery_unlocked": player.staff_mastery_unlocked,
		"sword_reach_unlocked": player.sword_reach_unlocked,
		"bow_piercing_unlocked": player.bow_piercing_unlocked,
		"staff_flow_unlocked": player.staff_flow_unlocked,
	}
	has_player_state = true


func apply_to_player(player) -> void:
	if player == null or not has_player_state:
		return
	player.max_health = int(player_state.get("max_health", player.max_health))
	player.current_health = clampi(int(player_state.get("current_health", player.max_health)), 1, player.max_health)
	player.max_mana = int(player_state.get("max_mana", player.max_mana))
	player.current_mana = clampi(int(player_state.get("current_mana", player.max_mana)), 0, player.max_mana)
	player.xp = int(player_state.get("xp", player.xp))
	player.skill_points = int(player_state.get("skill_points", player.skill_points))
	player.double_jump_unlocked = bool(player_state.get("double_jump_unlocked", false))
	player.dash_unlocked = bool(player_state.get("dash_unlocked", false))
	player.second_breath_active = bool(player_state.get("second_breath_active", false))
	player.sword_mastery_unlocked = bool(player_state.get("sword_mastery_unlocked", false))
	player.bow_mastery_unlocked = bool(player_state.get("bow_mastery_unlocked", false))
	player.staff_mastery_unlocked = bool(player_state.get("staff_mastery_unlocked", false))
	player.sword_reach_unlocked = bool(player_state.get("sword_reach_unlocked", false))
	player.bow_piercing_unlocked = bool(player_state.get("bow_piercing_unlocked", false))
	player.staff_flow_unlocked = bool(player_state.get("staff_flow_unlocked", false))
	if has_checkpoint:
		player.global_position = checkpoint_position
		player.respawn_position = checkpoint_position


func capture_quest(quest_manager) -> void:
	if quest_manager != null and quest_manager.has_method("get_save_state"):
		quest_state = quest_manager.get_save_state()


func apply_to_quest(quest_manager) -> void:
	if quest_manager != null and not quest_state.is_empty() and quest_manager.has_method("apply_save_state"):
		quest_manager.apply_save_state(quest_state)


func register_lamp(lamp_id: String, lamp_name: String, room_id: String, position: Vector2) -> bool:
	if lamp_id.is_empty():
		return false
	var lamp_data := {
		"name": lamp_name,
		"room_id": room_id,
		"room_path": current_room_path,
		"position": [position.x, position.y],
	}
	var was_new := not discovered_lamps.has(lamp_id)
	discovered_lamps[lamp_id] = lamp_data
	if was_new:
		lamps_changed.emit()
	return was_new


func get_discovered_lamps() -> Dictionary:
	return discovered_lamps.duplicate(true)


func get_lamp_position(lamp_id: String) -> Vector2:
	var lamp_data: Dictionary = discovered_lamps.get(lamp_id, {})
	var saved_position: Array = lamp_data.get("position", [0.0, 0.0])
	if saved_position.size() < 2:
		return Vector2.ZERO
	return Vector2(float(saved_position[0]), float(saved_position[1]))


func save_at_checkpoint(player, quest_manager, position: Vector2, lamp_id: String = "", lamp_name: String = "Save Lamp", room_id: String = "") -> bool:
	capture_player(player)
	capture_quest(quest_manager)
	has_checkpoint = true
	checkpoint_position = position
	checkpoint_lamp_id = lamp_id
	checkpoint_lamp_name = lamp_name
	if not lamp_id.is_empty():
		register_lamp(lamp_id, lamp_name, room_id if not room_id.is_empty() else current_room_id, position)
	last_saved_unix_time = int(Time.get_unix_time_from_system())
	var temporary_path := save_path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open temporary save file: " + temporary_path)
		return false
	file.store_string(JSON.stringify(_build_save_data(), "  "))
	file.close()
	if has_save_file() and _read_save_file(save_path) is Dictionary:
		_copy_save_file(save_path, _get_backup_path())
	var primary_absolute := ProjectSettings.globalize_path(save_path)
	var temporary_absolute := ProjectSettings.globalize_path(temporary_path)
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(primary_absolute)
	if DirAccess.rename_absolute(temporary_absolute, primary_absolute) != OK:
		if FileAccess.file_exists(_get_backup_path()):
			_copy_save_file(_get_backup_path(), save_path)
		push_error("Could not finalize save file: " + save_path)
		return false
	if not FileAccess.file_exists(_get_backup_path()):
		_copy_save_file(save_path, _get_backup_path())
	save_completed.emit()
	return true


func has_save_file() -> bool:
	return FileAccess.file_exists(save_path) or FileAccess.file_exists(_get_backup_path())


func load_game() -> bool:
	last_load_used_backup = false
	var parsed = _read_save_file(save_path)
	if not parsed is Dictionary:
		parsed = _read_save_file(_get_backup_path())
		if not parsed is Dictionary:
			return false
		last_load_used_backup = true
		_copy_save_file(_get_backup_path(), save_path)
	_apply_save_data(parsed)
	session_started = true
	_emit_full_state()
	mode_changed.emit(game_mode)
	if last_load_used_backup:
		save_recovered.emit()
	return true


func get_save_summary() -> Dictionary:
	var data = _read_save_file(save_path)
	if not data is Dictionary:
		data = _read_save_file(_get_backup_path())
	if not data is Dictionary:
		return {}
	return {
		"mode": str(data.get("game_mode", MODE_NORMAL)),
		"lamp_name": str(data.get("checkpoint_lamp_name", "Save Lamp")),
		"room_id": str(data.get("current_room_id", "unknown_area")),
		"saved_at": int(data.get("last_saved_unix_time", 0)),
	}


func delete_save() -> void:
	for path in [save_path, _get_backup_path(), save_path + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func handle_hardcore_death() -> void:
	if game_mode == MODE_HARDCORE:
		delete_save()


func prepare_room_transition(room_path: String, entrance_id: String, player) -> void:
	capture_player(player)
	current_room_path = room_path
	target_entrance_id = entrance_id


func _build_save_data() -> Dictionary:
	return {
		"version": 7, "game_mode": game_mode, "gold": gold, "inventory": inventory,
		"equipped_items": equipped_items, "weapon_upgrades": weapon_upgrades, "active_weapon_slot": active_weapon_slot,
		"selected_arrow_type": selected_arrow_type, "selected_spell": selected_spell, "unlocked_spells": unlocked_spells,
		"zone_tiers": zone_tiers, "defeated_bosses": defeated_bosses, "boss_rematches": boss_rematches,
		"unlocked_shortcuts": unlocked_shortcuts, "opened_caches": opened_caches, "current_room_path": current_room_path,
		"current_room_id": current_room_id, "target_entrance_id": target_entrance_id,
		"discovered_rooms": discovered_rooms,
		"player_state": player_state, "quest_state": quest_state,
		"has_checkpoint": has_checkpoint, "checkpoint_position": [checkpoint_position.x, checkpoint_position.y],
		"checkpoint_lamp_id": checkpoint_lamp_id, "checkpoint_lamp_name": checkpoint_lamp_name,
		"discovered_lamps": discovered_lamps, "last_saved_unix_time": last_saved_unix_time,
		"merchant_quest_state": merchant_quest_state, "merchant_discount_unlocked": merchant_discount_unlocked,
	}


func _apply_save_data(data: Dictionary) -> void:
	game_mode = str(data.get("game_mode", MODE_NORMAL))
	gold = int(data.get("gold", 0))
	inventory = Dictionary(data.get("inventory", {STARTING_WEAPON: 1})).duplicate(true)
	equipped_items = Dictionary(data.get("equipped_items", {"primary_weapon": STARTING_WEAPON, "secondary_weapon": "", "defense": ""})).duplicate(true)
	weapon_upgrades = Dictionary(data.get("weapon_upgrades", {})).duplicate(true)
	active_weapon_slot = str(data.get("active_weapon_slot", "primary_weapon"))
	selected_arrow_type = str(data.get("selected_arrow_type", "basic_arrow"))
	selected_spell = str(data.get("selected_spell", "arc_bolt"))
	unlocked_spells.assign(data.get("unlocked_spells", []))
	zone_tiers = Dictionary(data.get("zone_tiers", {"training_passage": 0})).duplicate(true)
	defeated_bosses = Dictionary(data.get("defeated_bosses", {})).duplicate(true)
	boss_rematches = Dictionary(data.get("boss_rematches", {})).duplicate(true)
	unlocked_shortcuts = Dictionary(data.get("unlocked_shortcuts", {})).duplicate(true)
	opened_caches = Dictionary(data.get("opened_caches", {})).duplicate(true)
	current_room_path = str(data.get("current_room_path", "res://Game.tscn"))
	current_room_id = str(data.get("current_room_id", "training_passage"))
	discovered_rooms = Dictionary(data.get("discovered_rooms", {"training_passage": true})).duplicate(true)
	discovered_rooms["training_passage"] = true
	discovered_rooms[current_room_id] = true
	target_entrance_id = str(data.get("target_entrance_id", "default"))
	player_state = Dictionary(data.get("player_state", {})).duplicate(true)
	quest_state = Dictionary(data.get("quest_state", {})).duplicate(true)
	has_player_state = not player_state.is_empty()
	has_checkpoint = bool(data.get("has_checkpoint", false))
	checkpoint_lamp_id = str(data.get("checkpoint_lamp_id", ""))
	checkpoint_lamp_name = str(data.get("checkpoint_lamp_name", "Save Lamp"))
	discovered_lamps = Dictionary(data.get("discovered_lamps", {})).duplicate(true)
	for lamp_data in discovered_lamps.values():
		if lamp_data is Dictionary:
			var lamp_room := str(lamp_data.get("room_id", ""))
			if not lamp_room.is_empty():
				discovered_rooms[lamp_room] = true
	last_saved_unix_time = int(data.get("last_saved_unix_time", 0))
	merchant_quest_state = int(data.get("merchant_quest_state", 0))
	merchant_discount_unlocked = bool(data.get("merchant_discount_unlocked", false))
	var saved_position: Array = data.get("checkpoint_position", [0.0, 0.0])
	if saved_position.size() >= 2:
		checkpoint_position = Vector2(float(saved_position[0]), float(saved_position[1]))


func _emit_full_state() -> void:
	gold_changed.emit(gold)
	inventory_changed.emit()
	equipment_changed.emit()
	lamps_changed.emit()
	merchant_changed.emit()


func _get_backup_path() -> String:
	return save_path + ".backup"


func _read_save_file(path: String):
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		return null
	return json.data


func _copy_save_file(source_path: String, destination_path: String) -> bool:
	if not FileAccess.file_exists(source_path):
		return false
	if FileAccess.file_exists(destination_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(destination_path))
	return DirAccess.copy_absolute(
		ProjectSettings.globalize_path(source_path),
		ProjectSettings.globalize_path(destination_path)
	) == OK
