extends Node2D

const RESIDENT := preload("res://TownResident.tscn")
const ROOMS := {"causeway": "Causeway", "forge": "Forge", "barracks": "Barracks", "reservoir": "Reservoir", "chapel": "Chapel", "outskirts": "Outskirts", "emberspine": "Emberspine"}
var state: Node
var board: Label
var keeper: Area2D
var courier: Area2D


func _ready() -> void:
	state = get_node("/root/GameState")
	var backing := Polygon2D.new()
	backing.name = "BoardBacking"
	backing.z_index = -1
	backing.polygon = PackedVector2Array([Vector2(-225, -245), Vector2(225, -245), Vector2(225, -65), Vector2(-225, -65)])
	backing.color = Color(0.12, 0.08, 0.10, 0.97)
	add_child(backing)
	board = Label.new()
	board.name = "WorkOrders"
	board.position = Vector2(-215, -235)
	board.size = Vector2(430, 160)
	board.add_theme_font_size_override("font_size", 11)
	add_child(board)
	for index in range(4):
		var stop := Marker2D.new()
		stop.name = "BoardStop%d" % index
		stop.position = Vector2([-85, -25, 55, 100][index], -33)
		stop.add_to_group("town_social_spot")
		add_child(stop)
	keeper = _resident("Oren", "Oren, Road Keeper", Vector2(-85, -33), ["BoardStop0", "BoardStop1"], "../Mira")
	courier = _resident("Mira", "Mira, Hearth Courier", Vector2(55, -33), ["BoardStop2", "BoardStop3"], "../Oren")
	state.shortcut_changed.connect(_on_event)
	state.zone_tier_changed.connect(_on_tier)
	_refresh()


func _resident(node_name: String, title: String, at: Vector2, stops: Array, partner: String) -> Area2D:
	var resident := RESIDENT.instantiate() as Area2D
	resident.name = node_name
	resident.position = at
	resident.set("resident_name", title)
	resident.set("route_marker_names", PackedStringArray(stops))
	resident.set("talk_partner", NodePath(partner))
	resident.set("pause_seconds", 2.5)
	resident.set("coat_color", Color(0.46, 0.3, 0.24) if node_name == "Oren" else Color(0.34, 0.29, 0.44))
	add_child(resident)
	# Short overhead names stay readable when the two residents meet; dialogue
	# still uses the full role/name stored in resident_name.
	resident.get_node("NameLabel").text = node_name
	return resident


func _on_event(event_id: String) -> void:
	if event_id.begins_with("ash_"):
		_refresh()


func _on_tier(zone_id: String, _tier: int) -> void:
	if zone_id == "ashen_bastion":
		_refresh()


func _refresh() -> void:
	var lines := PackedStringArray(["HEARTH ROAD & FIELD OFFICE", "Task / Niche / Return    (+ complete, - pending)"])
	var entries := PackedStringArray()
	var tasks := 0
	var victories := 0
	for id in ROOMS:
		var done := bool(state.unlocked_shortcuts.get("ash_%s_field_complete" % id, false))
		var guarded := bool(state.unlocked_shortcuts.get("ash_%s_guarded_niche_cleared" % id, false))
		var returned := bool(state.unlocked_shortcuts.get("ash_%s_field_return_complete" % id, false))
		tasks += int(done)
		victories += int(returned)
		var return_text := "+" if returned else ("READY" if done and guarded and state.get_zone_tier("ashen_bastion") >= 1 else "-")
		entries.append("%s: %s / %s / %s" % [ROOMS[id], "+" if done else "-", "+" if guarded else "-", return_text])
	var rows := ceili(float(entries.size()) / 2.0)
	for index in range(rows):
		lines.append(entries[index] + ("   |   " + entries[index + rows] if index + rows < entries.size() else ""))
	lines.append("TASKS %d/%d   RETURN VICTORIES %d/%d" % [tasks, ROOMS.size(), victories, ROOMS.size()])
	board.text = "\n".join(lines)
	var guidance := PackedStringArray([
		"The Causeway signals are Foot, Span, then Crown, spread up the road. Clear nearby foes to light each one. A signal is a landmark, not a safe camp.",
		"Repair the Forge winch and gearbox, then start its cooling fan. The service hoist saves a long climb. Barracks has four marked targets, but its beacon waves must also be completed.",
		"Open both Reservoir valves before calibrating Return, Intake, then Exhaust. An unfinished calibration restarts on loading; repairs and copied records can be saved separately at a lamp.",
		"Two Chapel side niches hold the Keepers' and Pilgrims' records. Copy both in either order and finish the original high-low-far bell sequence. Clear each room's upper guardians to unseal its field cache.",
		"The Outskirts watches are in the two side shelters. Clear each patrol, then collect its scout report. Rell and Sera stay at their posts; the gatekeeper's road quest remains separate.",
		"Emberspine has coolant feeds in the western intake branch and far eastern branch. Each shuts down its own fire lane. Both feeds and the deepest reserve guard unlock the Rim Cache; after awakening, return to Ember Heart.",
	])
	if state.get_zone_tier("ashen_bastion") >= 1:
		guidance.insert(0, "The Castellan has fallen. Finished field tasks and cleared upper niches reveal new patrols in the final galleries. Each patrol guards a separate reserve.")
	else:
		guidance.append("The Return column stays pending until the Castellan falls. The road tasks are optional; they never replace the original progression gates.")
	if tasks == ROOMS.size():
		guidance.insert(0, "All seven field tasks are recorded. The board keeps reserve guards and return victories separate, so you can see what remains.")
	keeper.set("dialogue_lines", guidance)
	keeper.set("next_line_index", 0)
	courier.set("dialogue_lines", PackedStringArray([
		"Three lamps can carry a warning farther than I can run. The Causeway's signal chain begins at Foot and ends at Crown.",
		"The road lights are burning again. I can follow the old route home." if bool(state.unlocked_shortcuts.get("ash_causeway_field_complete", false)) else "The signal towers have gone dark. I keep missing the old turns in the ash.",
		"You brought back both Chapel records. The keepers and pilgrims will have their place in the archive." if bool(state.unlocked_shortcuts.get("ash_chapel_field_complete", false)) else "The Chapel's side chambers hold records that never reached our archive. The bells alone cannot recover them.",
	]))
	courier.set("next_line_index", 0)
	keeper.set("social_lines", PackedStringArray(["Mark the upper guardians separately, Mira. A repaired road is not a cleared road."]))
	courier.set("social_lines", PackedStringArray(["I will, Oren. The signals are lit again." if bool(state.unlocked_shortcuts.get("ash_causeway_field_complete", false)) else "I will carry the next report when the signal chain is restored."]))
