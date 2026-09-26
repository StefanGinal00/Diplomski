extends Node2D

const RESIDENT := preload("res://TownResident.tscn")
const ROUTES := {
	"starfall_outskirts": ["Outskirts", "Repair the two caravan winches in the first and middle side branches. Each raises road cover; neither replaces the original route."],
	"starfall_ramparts": ["Broken Ramparts", "Clear the west and east side-watch guards, recover both signal plates, then restore the desk in the high archive branch. The signal quiets both root lanes; the deepest branch guard protects the Rim Cache."],
	"starfall_silent_gate": ["Silent Gate", "Power the original high and low relays, then inspect their terminals in the first and last side branches. The main exit only needs the original relays."],
	"starfall_memory_vault": ["Memory Vault", "Break the three marked record cases in the three side branches. Their records always count, even if a case drops no ordinary loot. They are not the three memory sigils."],
	"starfall_rooted_hall": ["Rooted Hall", "Open the original root channel, then restore the seedbeds in the first and last side branches. Leave peaceful grazers alone; they are not part of the task."],
	"starfall_soul_crucible": ["Soul Crucible", "Each original channel enables one containment fight: high in the first side branch, low in the last. Clear both and stabilize the original channels."],
	"starfall_sunless_passage": ["Sunless Passage", "Light First, Middle, then Last in the three side branches. Each beacon quiets two void lanes. Only the original Dawn Anchor stabilizes the bridges."],
}

var state: Node
var rows: Dictionary = {}
var table: GridContainer
var summary: Label
var keeper: Area2D
var courier: Area2D
var backing: Polygon2D


func _ready() -> void:
	state = get_node("/root/GameState")
	backing = Polygon2D.new()
	backing.name = "BoardBacking"
	backing.z_index = -1
	backing.color = Color(0.08, 0.09, 0.16, 0.98)
	backing.polygon = PackedVector2Array([Vector2(-255, -234), Vector2(255, -234), Vector2(255, -62), Vector2(-255, -62)])
	add_child(backing)
	var title := _label("CITADEL FIELD OFFICE - %d EXPANDED ROUTES" % ROUTES.size(), 0)
	title.position = Vector2(-244, -292)
	title.add_theme_font_size_override("font_size", 12)
	add_child(title)
	table = GridContainer.new()
	table.name = "RouteTable"
	table.position = Vector2(-244, -269)
	table.columns = 5
	table.mouse_filter = Control.MOUSE_FILTER_IGNORE
	table.add_theme_constant_override("h_separation", 5)
	table.add_theme_constant_override("v_separation", 2)
	add_child(table)
	for index in range(5):
		table.add_child(_label(["ROUTE", "TASK", "GUARD", "CACHE", "RETURN"][index], index))
	for id in ROUTES:
		var cells: Array[Label] = []
		for index in range(5):
			var cell := _label(String(ROUTES[id][0]) if index == 0 else "-", index)
			table.add_child(cell)
			cells.append(cell)
		rows[id] = cells
	summary = _label("", 0)
	summary.position = Vector2(-244, -92)
	summary.size = Vector2(488, 36)
	add_child(summary)
	for index in range(4):
		var stop := Marker2D.new()
		stop.name = "OfficeStop%d" % index
		stop.position = Vector2([-65, -20, 65, 110][index], -33)
		stop.add_to_group("town_social_spot")
		add_child(stop)
	keeper = _resident("Senna", "Senna, Field Archivist", 0, "../Tarin")
	courier = _resident("Tarin", "Tarin, Route Courier", 2, "../Senna")
	state.shortcut_changed.connect(_on_progress)
	state.cache_opened.connect(_on_progress)
	state.boss_progress_changed.connect(_on_boss)
	_refresh()


func _label(text: String, column: int) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = [120, 43, 48, 65, 107][column]
	label.add_theme_font_size_override("font_size", 11)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _resident(node_name: String, title: String, first_stop: int, partner: String) -> Area2D:
	var npc := RESIDENT.instantiate() as Area2D
	npc.name = node_name
	npc.position = get_node("OfficeStop%d" % first_stop).position
	npc.set("resident_name", title)
	npc.set("route_marker_names", PackedStringArray(["OfficeStop%d" % first_stop, "OfficeStop%d" % (first_stop + 1)]))
	npc.set("talk_partner", NodePath(partner))
	npc.set("pause_seconds", 2.5)
	npc.set("coat_color", Color(0.43, 0.4, 0.59) if first_stop == 0 else Color(0.34, 0.48, 0.52))
	add_child(npc)
	npc.get_node("NameLabel").text = node_name
	return npc


func _on_progress(event_id: String) -> void:
	if event_id.begins_with("starfall_"):
		_refresh()


func _on_boss(boss_id: String) -> void:
	if boss_id == "hollow_sovereign":
		_refresh()


func _done(event_id: String) -> bool:
	return bool(state.unlocked_shortcuts.get(event_id, false))


func _claimed(cache_id: String) -> bool:
	return bool(state.opened_caches.get(cache_id, false))


func _refresh() -> void:
	var sovereign_down := bool(state.defeated_bosses.get("hollow_sovereign", false))
	var tasks := 0
	var reserves := 0
	var suggestions := PackedStringArray()
	for id in ROUTES:
		var task := _done(id + "_field_complete")
		var guarded := _done(id + "_niche_cleared")
		var cache := _claimed(id + ("_rim" if id == "starfall_ramparts" else "_hidden_depth"))
		var returned := _done(id + "_field_return_complete")
		var reserve := _claimed(id + "_field_return_reserve")
		tasks += int(task)
		reserves += int(reserve)
		var cells: Array = rows[id]
		cells[1].text = "YES" if task else "-"
		cells[2].text = "YES" if guarded else "-"
		cells[3].text = "TAKEN" if cache else ("READY" if task and guarded else "LOCKED")
		cells[4].text = "TAKEN" if reserve else ("REWARD" if returned else ("AFTER BOSS" if not sovereign_down else ("READY" if task and guarded else "TASK/GUARD")))
		for index in range(1, 5):
			cells[index].modulate = Color(0.55, 0.95, 0.77) if cells[index].text in ["YES", "TAKEN"] else (Color(1.0, 0.83, 0.48) if cells[index].text in ["READY", "REWARD"] else Color(0.7, 0.72, 0.82))
		var room_title := String(ROUTES[id][0])
		var reserve_location := "deepest side branch" if id == "starfall_ramparts" else "upper hidden alcove"
		var return_location := "Western Gate chamber" if id == "starfall_ramparts" else "final gallery"
		if sovereign_down and returned and not reserve:
			suggestions.append(room_title + ": your return patrol is defeated, but its reserve in the " + return_location + " has not been collected.")
		elif not task:
			suggestions.append(room_title + ": " + String(ROUTES[id][1]))
		elif not guarded:
			suggestions.append(room_title + ": the field task is done. Visit the " + reserve_location + " and defeat its reserve guardians.")
		elif not cache:
			suggestions.append(room_title + ": the reserve is unsealed. Return to the " + reserve_location + " to collect it.")
		elif sovereign_down and not returned:
			suggestions.append(room_title + ": a stronger return patrol is ready in the " + return_location + ". Its reward is separate from the discovery reserve.")
	summary.text = "TASKS %d/%d   RETURN RESERVES TAKEN %d/%d\nOptional routes; save progress at a lamp." % [tasks, ROUTES.size(), reserves, ROUTES.size()]
	var guidance := suggestions.duplicate()
	if guidance.is_empty():
		guidance.append("All route reports are complete. The return patrols wait until the Hollow Sovereign falls." if not sovereign_down else "All listed routes and their return reserves are recorded. The city remains safe; there is no extra payout for this board.")
	guidance.append("TASK and GUARD are separate. CACHE READY means the discovery reserve can be opened; TAKEN means collected. RETURN REWARD means the patrol is dead but its reserve is still waiting.")
	guidance.append("These discoveries never replace Rook's courier reports, Atley's archive, the three memory sigils or the final gate. The Ramparts row tracks its deep Rim Cache, not the separate MidCache in the archive branch.")
	keeper.set("dialogue_lines", guidance)
	keeper.set("next_line_index", 0)
	courier.set("dialogue_lines", PackedStringArray([
		"The Sovereign has fallen. Stronger patrols now wait in the final galleries, but each still needs its local field task and reserve guardians cleared." if sovereign_down else "The RETURN column stays AFTER BOSS until the Hollow Sovereign falls. Completing these optional tasks does not raise the entire zone's difficulty.",
		"Take the east city gate to Outskirts, cross Broken Ramparts to Silent Gate, then continue through Memory Vault and Rooted Hall. The upper spur from Empty Court leads to Soul Crucible and Sunless Passage.",
		"All listed field tasks are done. Check CACHE and RETURN before leaving a room; a won fight is not yet a collected reward." if tasks == ROUTES.size() else "Look in the side branches, not just at the exit. Watch plates, archive records, seedbeds and procession lights give those detours a purpose.",
		"This office only records discoveries. It does not spend materials, refill shops, award duplicate loot or open a gate.",
	]))
	courier.set("next_line_index", 0)
	keeper.set("social_lines", PackedStringArray(["A cleared patrol is not a collected reserve, Tarin. Keep both marks."]))
	courier.set("social_lines", PackedStringArray(["The final galleries have changed since the Sovereign fell." if sovereign_down else "I will carry the next report through the east gate."]))
	call_deferred("_fit_board")


func _fit_board() -> void:
	# Theme font metrics, not guessed line heights, determine the backing.
	summary.position.y = table.position.y + table.get_combined_minimum_size().y + 8
	var bottom := summary.position.y + summary.get_combined_minimum_size().y + 8
	backing.polygon = PackedVector2Array([Vector2(-255, -300), Vector2(255, -300), Vector2(255, bottom), Vector2(-255, bottom)])
