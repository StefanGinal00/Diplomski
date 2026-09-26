@tool
extends "res://RouteFieldDressing.gd"

const ASH_FLOOR := preload("res://AshFieldOperations.gd")
const LOCAL_SITES := {
	"causeway": [
		[-1, 0.50, "camp", "THE WAYFARER'S SHELTER", "A ROADSIDE STOP, NOT A SAFE ZONE OR CHECKPOINT"],
		[1, 0.28, "signal_table", "THE REFUGE SIGNAL REGISTER", "LIGHT FOOT > SPAN > CROWN; CLEAR NEARBY FOES FIRST"],
		[2, 0.72, "haul", "ABANDONED CARAVAN", "SUPPLIES MAY BE EMPTY; THE UPPER RESERVE IS SEPARATE"],
		[3, 0.50, "garden", "ASHGRASS REST", "GRAZERS ARE NEUTRAL UNLESS STRUCK"],
		[4, 0.72, "arch", "THE BROKEN MARCH ARCH", "CLIMB THE SIDE NICHE FOR THE TWO SUPPLY GUARDIANS"],
		[5, 0.55, "survey", "SURVIVOR'S WAYSTONES", "THREE SIGNALS AND THE UPPER GUARDIANS UNSEAL THE RESERVE"],
		[6, 0.64, "reserve_board", "THE LAST REFUGE MARK", "AFTER THE CASTELLAN, REVISIT THIS FINAL GALLERY"],
	],
	"chapel": [
		[0, 0.45, "camp", "THE PILGRIM'S SHELTER", "A SURVEY STOP, NOT A SAFE ZONE OR CHECKPOINT"],
		[1, 0.28, "record_desk", "THE TWO VOTIVE RECORDS", "COPY BOTH SIDE-NICHE RECORDS IN EITHER ORDER"],
		[2, 0.72, "haul", "PILGRIM'S LOST BAGGAGE", "THE VOTIVE RESERVE NEEDS RECORDS, BELLS AND GUARDIANS"],
		[3, 0.50, "pool", "CANDLE REED POOL", "LEAVE RESTING GRAZERS UNDISTURBED FOR A QUIET PASSAGE"],
		[4, 0.82, "bell_memory", "THE OLD CHOIR'S ORDER", "RING THE ORIGINAL BELLS: HIGH > LOW > FAR"],
		[5, 0.55, "stacks", "PILGRIM'S RECORD SHELF", "THE TWO RECORDS DO NOT REPLACE THE ORIGINAL BELLS"],
		[6, 0.64, "reserve_board", "THE LAST VOTIVE MARK", "AFTER THE CASTELLAN, REVISIT THIS FINAL GALLERY"],
	],
}


func _sites() -> Array:
	return LOCAL_SITES[region]


func _zone() -> String:
	return "ashen_bastion"


func _site_tone() -> Color:
	return Color(0.77, 0.49, 0.30) if region == "causeway" else Color(0.69, 0.53, 0.64)


func _site_anchor(index: int) -> Vector2:
	var data: Array = _sites()[index]
	if int(data[0]) < 0:
		var crest: Rect2 = expansion._niche_crests[-int(data[0]) - 1]
		return crest.get_center() + Vector2(0, -crest.size.y * 0.5)
	var chamber: Rect2 = expansion._chamber_rect(data[0])
	# Ash builds its floor rectangles even in schematic editor mode. Resolve
	# the same supported point in both modes, without extra preview geometry.
	return ASH_FLOOR.supported_floor(expansion, int(data[0]) - 1, (float(data[1]) - 0.5) * chamber.size.x) + Vector2(0, 25)


func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		var state := get_node("/root/GameState")
		state.shortcut_changed.connect(_on_progress)
		state.zone_tier_changed.connect(_on_tier)
		_refresh_ash()


func _build_site(index: int, data: Array, at: Vector2) -> void:
	super._build_site(index, data, at)
	var site := get_node("Site%d" % index)
	# Ash paints opaque chamber backgrounds in the parent's _draw at z=0.
	# Negative-depth scenery would disappear behind those backgrounds.
	site.z_index = 0
	var clue := site.get_node("RouteClue") as Label
	if (region == "causeway" and index == 1) or (region == "chapel" and index in [0, 4]):
		clue.position.y = 20
	clue.z_index = 3
	clue.add_theme_color_override("font_outline_color", Color(0.05, 0.025, 0.025))
	clue.add_theme_constant_override("outline_size", 3)
	match data[2]:
		"signal_table", "record_desk":
			_line(site, "Desk", [Vector2(-135, 0), Vector2(-135, -50), Vector2(135, -50), Vector2(135, 0)], tone.darkened(0.2), 7)
			var count := 3 if data[2] == "signal_table" else 2
			for i in range(count):
				var x := (float(i) - (count - 1) * 0.5) * 85
				if count == 3:
					_line(site, "SignalPost%d" % i, [Vector2(x, -50), Vector2(x, -114)], tone, 4)
					_poly(site, "ProgressLight%d" % i, [Vector2(x - 14, -91), Vector2(x, -130), Vector2(x + 14, -91)], tone.darkened(0.5))
				else:
					_poly(site, "Folio%d" % i, [Vector2(x - 31, -52), Vector2(x - 25, -110), Vector2(x + 25, -110), Vector2(x + 31, -52)], tone.darkened(0.45))
					_line(site, "ProgressLight%d" % i, [Vector2(x - 17, -84), Vector2(x + 17, -84)], tone.darkened(0.5), 5)
				var label := Label.new()
				label.position = Vector2(x - 42, -40)
				label.size.x = 84
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.text = ["FOOT", "SPAN", "CROWN"][i] if count == 3 else ["KEEPERS", "PILGRIMS"][i]
				label.add_theme_font_size_override("font_size", 11)
				site.add_child(label)
		"arch":
			_poly(site, "WestPier", [Vector2(-145, 0), Vector2(-145, -120), Vector2(-65, -160), Vector2(-45, -135), Vector2(-103, -100), Vector2(-103, 0)], tone.darkened(0.4))
			_poly(site, "EastPier", [Vector2(145, 0), Vector2(145, -120), Vector2(100, -143), Vector2(89, -108), Vector2(103, -95), Vector2(103, 0)], tone.darkened(0.4))
			_line(site, "CaravanMark", [Vector2(-25, -26), Vector2(0, -54), Vector2(25, -26)], tone.lightened(0.5), 4)
		"bell_memory":
			_line(site, "Belfry", [Vector2(-136, 0), Vector2(-136, -136), Vector2(136, -136), Vector2(136, 0)], tone.darkened(0.3), 6)
			for i in range(3):
				var x := float(i - 1) * 80
				_line(site, "Chain%d" % i, [Vector2(x, -136), Vector2(x, -103)], tone, 3)
				_poly(site, "BellLight%d" % i, [Vector2(x - 13, -103), Vector2(x + 13, -103), Vector2(x + 25, -62), Vector2(x - 25, -62)], tone.darkened(0.5))
		"reserve_board":
			_poly(site, "ReserveStone", [Vector2(-132, 0), Vector2(-132, -130), Vector2(132, -130), Vector2(132, 0)], tone.darkened(0.5))
			_ring(site, "FieldSeal", Vector2(-65, -78), 23, tone.lightened(0.2))
			_ring(site, "GuardianSeal", Vector2(65, -78), 23, tone.lightened(0.2))
			_line(site, "ReserveLatch", [Vector2(-80, -25), Vector2(80, -25)], tone.darkened(0.1), 5)


func _build_resident(at: Vector2) -> void:
	for side in [-1, 1]:
		var marker := Marker2D.new()
		marker.name = "CampStop%d" % side
		marker.position = at + Vector2(side * 28, -24)
		add_child(marker)
	var npc := RESIDENT.instantiate()
	npc.name = "FieldGuide"
	npc.position = at + Vector2(-28, -24)
	npc.resident_name = _resident_name()
	npc.coat_color = tone.darkened(0.3)
	npc.route_marker_names = PackedStringArray(["CampStop-1", "CampStop1"])
	npc.walk_speed = 16
	npc.victory_dialogue_lines = PackedStringArray()
	add_child(npc)
	npc.get_node("NameLabel").position.x = -130
	npc.get_node("NameLabel").position.y = -70
	npc.get_node("NameLabel").size.x = 260
	npc.get_node("NameLabel").z_index = 2
	npc.get_node("NameLabel").add_theme_color_override("font_outline_color", Color(0.05, 0.025, 0.025))
	npc.get_node("NameLabel").add_theme_constant_override("outline_size", 4)


func _add_streamed(actor: Node2D, kind: String) -> void:
	if kind == "neutral":
		actor.creature_name = _fauna_name()
	super._add_streamed(actor, kind)


func _resident_name() -> String:
	return "Tarn, Road Keeper" if region == "causeway" else "Mira, Votive Keeper"


func _fauna_name() -> String:
	return "Ashgrass Grazer" if region == "causeway" else "Candle Reed Grazer"


func activate_room_population() -> void:
	super.activate_room_population()
	if not Engine.is_editor_hint():
		_refresh_ash()


func _on_progress(event_id: String) -> void:
	if event_id.begins_with("ash_" + region + "_"):
		_refresh_ash()


func _on_tier(zone: String, _tier: int) -> void:
	if zone == "ashen_bastion":
		_refresh_ash()


func _refresh_ash() -> void:
	var state := get_node("/root/GameState")
	var prefix := "ash_" + region + "_"
	var flags: Dictionary = state.unlocked_shortcuts
	var complete := bool(flags.get(prefix + "field_complete", false))
	var guarded := bool(flags.get(prefix + "guarded_niche_cleared", false))
	var returned := bool(flags.get(prefix + "field_return_complete", false))
	var count := 0
	var total := 3 if region == "causeway" else 2
	for i in range(total):
		var active := bool(flags.get(prefix + ("signal_%d" if region == "causeway" else "record_%d") % i, false))
		count += int(active)
		get_node("Site1/ProgressLight%d" % i).modulate = Color(2.8, 2.8, 2.2) if active else Color.WHITE
	get_node("Site1/RouteClue").text = String(_sites()[1][3]) + "\n" + String(_sites()[1][4]) + "\nRECOVERED %d/%d" % [count, total]
	if region == "chapel":
		for i in range(3):
			get_node("Site4/BellLight%d" % i).modulate = Color(2.8, 2.8, 2.2) if flags.get("ash_chapel_bells", false) else Color.WHITE
	var reserve := get_node("Site6")
	reserve.get_node("FieldSeal").modulate = Color(0.4, 1, 0.55) if complete else Color.WHITE
	reserve.get_node("GuardianSeal").modulate = Color(0.4, 1, 0.55) if guarded else Color.WHITE
	reserve.get_node("ReserveLatch").modulate = Color(0.4, 1, 0.55) if complete and guarded else Color.WHITE
	reserve.get_node("RouteClue").text = String(_sites()[6][3]) + "\nFIELD TASK: " + ("DONE" if complete else "PENDING") + " | GUARDIANS: " + ("DONE" if guarded else "PENDING") + "\nAFTER THE CASTELLAN: RETURN TO THIS GALLERY"
	var guide := get_node_or_null("FieldGuide")
	if guide == null:
		return
	var advice := "Signals: %d/3. Light foot, then span, then crown. Clear nearby foes and stand close to each signal." % count if region == "causeway" else "Records: %d/2. Copy the two side-niche records in either order; the original bells still need high, low, far." % count
	if returned:
		advice = "The returning guardians are quiet. Their reserve and the upper cache are separate, one-time finds. Save at a lamp."
	elif complete and guarded:
		advice = "The upper reserve is unsealed. " + ("The final gallery's return trial is now awake." if state.get_zone_tier("ashen_bastion") >= 1 else "After the Castellan falls, revisit the final gallery for the return trial.")
	elif complete:
		advice = "The field task is complete. Defeat both upper-niche guardians to unseal its reserve and meet the return-trial prerequisites."
	guide.dialogue_lines = PackedStringArray([advice, "The signal shelters are not safe zones or checkpoints." if region == "causeway" else "The original bell reliquary needs only the bells. The separate upper reserve also requires both records and its guardians.", "Leave resting grazers alone if you want a quieter journey. Supplies can be empty; rest at a lamp to save."])
	guide.next_line_index = 0
