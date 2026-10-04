extends CanvasLayer
## Runtime-only reading UI. World authors/controllers retain the source text.
## Never shares E with pumps/doors or claims quest rewards.
var rooms := {}
var entries: Array[Dictionary] = []
var nearest := -1
var current := -1
var owns_pause := false
var poll := 0.0
var player: Node2D
var state: Node
var ui: Node
var prompt: Button
var panel: PanelContainer
var heading: Label
var body: Label
var close_button: Button
var marker: Label
var marker_art: Sprite2D
const SIGN_OFFSET := Vector2(22,-10)
const Support := preload("res://WorldSupport.gd")
var sign_relative_bounds := Rect2(31,-3,22,36)

func _ready() -> void:
	name = "Readables"
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	var game := get_parent().get_parent()
	player = game.get_node("Player")
	state = get_node("/root/GameState")
	ui = game.get_node("UI")
	prompt = Button.new()
	prompt.name = "ReadPrompt"
	prompt.add_theme_font_size_override("font_size", 14)
	prompt.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	prompt.pressed.connect(open_nearest)
	add_child(prompt)
	prompt.hide()
	panel = PanelContainer.new()
	panel.name = "ReadingPanel"
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0d1824")
	style.border_color = Color("ad9166")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size", 20)
	heading.add_theme_color_override("font_color", Color("efcf95"))
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 116
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	body = Label.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 17)
	body.add_theme_color_override("font_color", Color("e8edf0"))
	scroll.add_child(body)
	close_button = Button.new()
	close_button.text = "Close  [G / Esc]"
	close_button.custom_minimum_size.y = 40
	close_button.pressed.connect(close)
	column.add_child(close_button)
	panel.hide()
	marker = Label.new()
	marker.text = "READ  [G]"
	marker.z_index = 25
	marker.add_theme_font_size_override("font_size", 8)
	marker.add_theme_constant_override("outline_size", 2)
	marker.add_theme_color_override("font_color", Color("eed09a"))
	marker.add_theme_color_override("font_outline_color", Color("081019"))
	game.add_child.call_deferred(marker)
	var sign := preload("res://FieldMachineryArt.gd").sprite(marker, 5, Vector2(20, 25), Vector2(22, 36))
	marker_art = sign
	# The atlas includes transparent padding. Register the opaque pedestal's
	# full footprint once so neither its right-hand offset nor its foot row
	# can silently hang beyond a short landing.
	var pixels := sign.texture.get_image()
	var used := pixels.get_used_rect()
	var painted := Rect2(Vector2(used.position)-sign.texture.get_size()/2,Vector2(used.size))
	sign_relative_bounds = sign.transform*painted
	sign_relative_bounds.position += SIGN_OFFSET
	sign.z_index = -26 # The sign belongs behind actors; only its small cue is above.
	marker.hide()
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	var view := get_viewport().get_visible_rect().size
	prompt.position = Vector2(maxf(12, view.x * 0.5 - 175), view.y - 58)
	prompt.size = Vector2(minf(350, view.x - 24), 42)
	var report := current>=0 and current<entries.size() and entries[current].has("provider")
	var height := minf(480 if report else 260,view.y-96)
	panel.position = Vector2(maxf(12, (view.x - 620) * 0.5), maxf(48, (view.y - height) * 0.5))
	panel.size = Vector2(minf(620, view.x - 24),height)

func register_room(id: String, nodes: Array = []) -> void:
	close()
	prompt.hide()
	marker.hide()
	var found: Array[Dictionary] = []
	# Population may have been unloaded since the last visit. Preserve live
	# sources, discard freed ones, and discover replacement labels in this pass.
	for entry in rooms.get(id, []):
		if is_instance_valid(entry.text) and entry.text.is_inside_tree(): found.append(entry)
	for node in nodes:
		if node.has_method("reading_report") and node.has_method("prepare_world_reading"):
			var anchor: Vector2 = node.prepare_world_reading()
			var source := node.get_node_or_null("ReadingSource") as Label
			if source==null:
				source = Label.new()
				source.name = "ReadingSource"
				node.add_child(source)
				source.global_position = anchor
				source.text = node.reading_report()
				_retire(source)
			if not found.any(func(entry): return entry.text==source):
				found.append({"title":null,"text":source,"at":anchor,"provider":node})
			continue
		if not node is Label or node.has_meta("world_readable"): continue
		if _is_operation_notice(node) or _is_city_notice(node) or _is_haven_notice(node) or _is_gate_notice(node) or _is_route_notice(node) or node.name=="HoistIdentity" or String(node.name).begins_with("RoomSign"):
			found.append({"title":null,"text":node,"at":_supported_anchor(node,nodes)})
			_retire(node)
		elif node.name == "RouteClue":
			var title := node.get_parent().get_node_or_null("Title") as Label
			var at:=_clear_supported_sign(node.get_parent().global_position+Vector2(0,-35),nodes)
			var entry := {"title": title, "text": node, "at": at}
			var task_board: Node = node.get_parent().get_node_or_null("TaskArt")
			if task_board != null and task_board.get_script()==preload("res://StarfallTaskArt.gd") and task_board.kind=="register":
				entry["physical_board"] = task_board
				entry["provider"] = task_board
			found.append(entry)
			if title != null: _retire(title)
			_retire(node)
		elif node.name in ["WorkOrder", "SurveyBoard", "CampSign", "RouteHint", "TopLiftHint", "LowerLiftHint", "DeepExitSign", "AreaSubtitle", "RouteIdentity", "HollowIdentity", "CrossingIdentity", "GalleryIdentity", "CisternIdentity", "ApproachIdentity", "HollowOreLandmark", "CisternOverflowLandmark", "FarEndSign", "OldQuarterSign", "SkyGardenSign", "WardLabel", "DangerLimit", "GardenTitle", "SupplySign", "ForgeSign", "EastWayfinding", "WestWayfinding", "BridgeWayfinding"] or String(node.name).begins_with("ChamberSign") or String(node.name).begins_with("ApproachWatchLabel"):
			var at: Vector2 = _supported_anchor(node, nodes)
			found.append({"title": null, "text": node, "at": at})
			_retire(node)
	for entry in found:
		if is_instance_valid(entry.get("physical_board")): continue
		# Keep the original reading location if its support disappears. Do not
		# transfer a clue to another tier just to make its optional sign fit.
		if not entry.has("sign_hint"): entry["sign_hint"] = entry.at
		var fit := _fit_near_sign(entry.sign_hint,nodes)
		entry["sign_supported"] = not fit.is_empty()
		entry["sign_support"] = fit.get("support",Rect2())
		entry.at = fit.get("at",entry.sign_hint)
	rooms[id] = found
	entries.assign(found)
	nearest = -1

func _is_operation_notice(label: Label) -> bool:
	# Several task authors create anonymous Labels (including renamed siblings).
	# Match the encounter's exact report, not nested enemy health/name labels.
	var parent := label.get_parent()
	if parent.get_script() == preload("res://LocalizedEncounter.gd"):
		return parent.status_label == label
	return String(label.get_parent().name) in ["FieldOperations","FieldDiscoveries","DiscoveryBoard"] and label.text.contains("\n")

func _is_haven_notice(label: Label) -> bool:
	var parent := label.get_parent()
	if parent.get_script()==preload("res://EchoSettlementExpansion.gd"):
		return String(label.name).begins_with("QuarterSign")
	return (parent.name==&"EchoHaven" and label.name in [&"HomeSign",&"MarketSign"]) or (parent.name==&"EchoHavenOutskirts" and label.name==&"GateSign")

func _is_city_notice(label: Label) -> bool:
	if String(label.name) not in ["DistrictName","WorkshopSign","CrownView","WorkplaceSign","CitySurvey"]:
		return false
	var ancestor := label.get_parent()
	while ancestor != null:
		if ancestor.get_script() == preload("res://StarfallUpperCity.gd"): return true
		ancestor = ancestor.get_parent()
	return false

func _is_gate_notice(label: Label) -> bool:
	var parent:=label.get_parent()
	if parent.get_script()==preload("res://CinderTownExpansion.gd") and String(label.name).begins_with("DistrictSign"): return true
	return (parent.name==&"CinderHearth" and label.name==&"GateSign") or (parent.name==&"StarfallCitadel" and label.name==&"OuterWatchSign")

func _is_route_notice(label: Label) -> bool:
	var parent:=label.get_parent()
	if parent.get_script()==preload("res://EchoTraversal.gd"):
		return String(label.name).begins_with("TierSign") or label.name==&"ReturnSign"
	return String(label.name).begins_with("DepthMarker") and parent.name==&"AuthoredDescent" and parent.get_parent().get_script()==preload("res://ShaftRoomExpansion.gd")

func _retire(label: Label) -> void:
	label.set_meta("world_readable", true)
	label.modulate.a = 0
	# The Echo records retain their live source label, but its old billboard
	# must retire with the text; otherwise a blank slab cuts across the houses.
	var author := label.get_parent()
	if author.get_script()==preload("res://EchoDiscoveryBoard.gd") and label==author.board:
		author.backing.hide()

func _supported_anchor(label: Label, nodes: Array) -> Vector2:
	var at: Vector2 = label.get_global_transform()*Vector2(label.size.x*.5,0)
	var best := INF
	var anchor := at
	var support := Rect2()
	for rect in _sign_supports(nodes):
		var foot := Vector2(clampf(at.x, rect.position.x + 10, rect.end.x - 10), rect.position.y - 35)
		var cost := foot.distance_squared_to(at)
		if cost < best:
			best = cost
			anchor = foot
			support = rect
	return _clear_door_mouth(anchor,support,nodes)

func _clear_supported_sign(anchor: Vector2,nodes: Array) -> Vector2:
	var members: Array[Node]=[]
	members.assign(nodes)
	var surfaces:=preload("res://WorldSupport.gd").floors(members)
	var support:=preload("res://WorldSupport.gd").below(anchor+Vector2(42,30),surfaces,25)
	if not support.has_area(): return anchor
	return _clear_door_mouth(Vector2(anchor.x,support.position.y-35),support,nodes)

func _clear_door_mouth(anchor: Vector2,support: Rect2,nodes: Array) -> Vector2:
	if not support.has_area(): return anchor
	var fit := _fit_on_support(anchor,support,nodes)
	return fit.get("at",anchor)

func _sign_supports(nodes: Array) -> Array[Rect2]:
	var floors: Array[Rect2] = []
	for node in nodes:
		if not is_instance_valid(node) or not node is CollisionShape2D or node.disabled or not node.shape is RectangleShape2D or not is_zero_approx(node.global_rotation): continue
		var parent: Node = node.get_parent()
		if not parent is StaticBody2D or parent.is_in_group("enemy") or parent.is_in_group("breakable"): continue
		var title := String(parent.name).to_lower()
		if "ceiling" in title or "roof" in title or "topwall" in title: continue
		var rect: Rect2 = node.global_transform*Rect2(-node.shape.size/2,node.shape.size)
		if rect.size.x>=sign_relative_bounds.size.x+2 and rect.size.y<=80 and rect.size.x>rect.size.y:
			floors.append(rect)
	return floors

func _fit_near_sign(anchor: Vector2,nodes: Array) -> Dictionary:
	var best := INF
	var selected := {}
	for support in _sign_supports(nodes):
		# Only repair the existing intended landing. A missing floor should
		# hide the pedestal, never teleport a clue up or down a shaft.
		if absf(support.position.y-anchor.y-sign_relative_bounds.end.y)>26: continue
		var center_x := anchor.x+sign_relative_bounds.get_center().x
		if center_x<support.position.x-112 or center_x>support.end.x+112: continue
		var fit := _fit_on_support(anchor,support,nodes)
		if fit.is_empty(): continue
		var cost: float = fit.at.distance_squared_to(anchor)
		if cost<best: best=cost; selected=fit
	return selected

func _fit_on_support(anchor: Vector2,support: Rect2,nodes: Array) -> Dictionary:
	if support.size.x<sign_relative_bounds.size.x+2: return {}
	# Fit the actual painted rectangle, not just the reading anchor. This is
	# required even when there are no doors anywhere near the landing.
	var doors: Array[Vector2] = []
	for node in nodes:
		if not is_instance_valid(node): continue
		if (node is LevelExit or node.is_in_group("room_door")) and absf(node.global_position.y-support.position.y)<85:
			var art:=node.get_node_or_null("FinishedDevice") as Sprite2D
			doors.append(Vector2(art.global_position.x if art!=null else node.global_position.x,node.global_position.y))
	var members: Array[Node] = []; members.assign(nodes)
	var solids := Support.solids(members)
	var selected := {}
	var best := INF
	for offset in [0,-48,48,-84,84,-112,112]:
		var fitted := Vector2(clampf(anchor.x+offset,support.position.x+1-sign_relative_bounds.position.x,support.end.x-1-sign_relative_bounds.end.x),support.position.y-sign_relative_bounds.end.y+.15)
		var bounds := Rect2(fitted+sign_relative_bounds.position,sign_relative_bounds.size)
		var clear := true
		var exposed := bounds; exposed.size.y = maxf(0,support.position.y-.25-exposed.position.y)
		for solid in solids:
			if solid.intersects(exposed): clear=false; break
		for door in doors:
			if absf(bounds.get_center().x-door.x)<44: clear=false; break
		if not clear: continue
		var score := fitted.distance_squared_to(anchor)
		if score<best:
			best=score; selected={"at":fitted,"support":support}
	return selected

func _process(delta: float) -> void:
	if is_open():
		_refresh_text()
		# Wrapped report labels briefly advertise a larger minimum during the
		# first container sort. Re-clamp after layout settles; otherwise the
		# native renderer can leave Close below the screen despite a small min.
		_layout()
		return
	poll += delta
	if poll < 0.15: return
	poll = 0
	_refresh_nearest()

func _can_read() -> bool:
	return is_instance_valid(player) and not player.is_dead and state.session_started and not get_tree().paused and not ui._hud_menu_blocked()

func _refresh_nearest() -> void:
	nearest = -1
	var best := 155.0 * 155.0
	if _can_read():
		for index in range(entries.size()):
			var source: Label = entries[index].text
			if not is_instance_valid(source) or not source.is_visible_in_tree() or source.text.is_empty(): continue
			var board: Node2D = entries[index].get("physical_board")
			if is_instance_valid(board): entries[index].at = board.to_global(Vector2(0,board.foot_y-25))
			var offset: Vector2 = player.global_position - entries[index].at
			if absf(offset.y) > 115: continue
			var cost := offset.length_squared()
			if cost < best:
				best = cost
				nearest = index
	prompt.visible = nearest >= 0
	marker.visible = nearest >= 0
	if nearest >= 0:
		prompt.text = "[G] Read: " + _title(entries[nearest])
		marker.global_position = entries[nearest].at + SIGN_OFFSET
		var board: Node2D = entries[nearest].get("physical_board")
		marker_art.visible = not is_instance_valid(board) and entries[nearest].get("sign_supported",false)
		if is_instance_valid(board):
			# A real readable board needs only its cue, not a second floating sign.
			marker.global_position = board.to_global(Vector2(-20,board.foot_y-72))

func _title(entry: Dictionary) -> String:
	return entry.title.text if is_instance_valid(entry.title) else entry.text.text.get_slice("\n", 0)

func open_nearest() -> void:
	_refresh_nearest() # Button/key must revalidate distance, death and modal state.
	if nearest < 0 or not _can_read(): return
	current = nearest
	owns_pause = true
	get_tree().paused = true
	panel.show()
	prompt.hide()
	marker.hide()
	_refresh_text()
	_layout()
	close_button.grab_focus()

func _refresh_text() -> void:
	if current < 0 or current >= entries.size() or not is_instance_valid(entries[current].text):
		close()
		return
	var provider: Node = entries[current].get("provider")
	var report_text: String = entries[current].text.text
	if is_instance_valid(provider):
		report_text = provider.reading_report()
		# A task ledger uses the controller's live clue as its source. Never
		# write the expanded report back into that same clue (recursive growth).
		if not entries[current].has("physical_board"): entries[current].text.text = report_text
	heading.text = _title(entries[current])
	body.text = report_text
	if not is_instance_valid(entries[current].title) and "\n" in body.text:
		body.text = body.text.substr(body.text.find("\n") + 1).strip_edges()

func close() -> void:
	if panel != null: panel.hide()
	current = -1
	if owns_pause:
		owns_pause = false
		get_tree().paused = false

func is_open() -> bool:
	return panel != null and panel.visible

func _input(event: InputEvent) -> void:
	if event.is_echo(): return
	if is_open() and (event.is_action_pressed("read_inscription") or event.is_action_pressed("ui_cancel")):
		close()
		get_viewport().set_input_as_handled()
	elif not is_open() and event.is_action_pressed("read_inscription") and _can_read():
		open_nearest()
		if is_open(): get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if owns_pause: get_tree().paused = false
	if is_instance_valid(marker): marker.queue_free()
