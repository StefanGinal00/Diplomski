@tool
extends Node2D
## Read-only task presentation. Native controls own all rules and save flags.
@export_enum("register", "winch", "terminal", "seedbed", "beacon", "growth", "lantern") var kind := "register"
@export var landmark_path: NodePath
@export var event_id := ""
const Atlas := preload("res://StarfallTaskAtlas.gd")
const Support := preload("res://WorldSupport.gd")
const Response := preload("res://FoliageResponse.gd")
const INK := Color("202837")
var retired: Array[CanvasItem] = []
var states: Array[String] = []
var indicators: Array[Polygon2D] = []
var captions: Array[Label] = []
var refresh_count := 0
var built := false
var refresh_pending := false
var painted: Sprite2D
var glow: Sprite2D
var foot_y := 0.0
var support := Rect2()
var motion_time := 0.0
var response := Response.new()
var wind := 0.0
var fit_scale := 1.0

func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	z_index = -1
	_build()
	if not Engine.is_editor_hint():
		get_node("/root/GameState").shortcut_changed.connect(_on_event)
	_refresh()

func _build() -> void:
	if built: return
	if kind == "register":
		for node in get_parent().get_children():
			if node is Polygon2D and String(node.name).begins_with("Light"):
				indicators.append(node)
				_retire(node)
			elif node is Label and String(node.name).begins_with("TaskCaption"):
				captions.append(node)
		_retire(get_parent().get_node("RegisterStand"))
	elif kind in ["growth", "lantern"]:
		_retire(get_node(landmark_path))
	else:
		foot_y = 25
		for named in ["Base", "Core", "Glow"]: _retire(get_parent().get_node(named))
	painted = Sprite2D.new()
	painted.name = "PaintedTask"
	painted.z_index = -1 # Keep live status marks in front of the painted panel.
	add_child(painted)
	set_meta("task_scenery",true)
	if kind in ["beacon","lantern","growth"]: set_meta("ambient_motion",true)
	if kind == "growth": set_meta("player_reactive",true)
	if kind in ["beacon","lantern"]:
		var gradient := Gradient.new()
		gradient.colors = PackedColorArray([Color(1,1,1,.65),Color(1,1,1,0)])
		var texture := GradientTexture2D.new()
		texture.gradient = gradient; texture.width = 64; texture.height = 64
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(.5,.5); texture.fill_to = Vector2(1,.5)
		glow = Sprite2D.new(); glow.name = "TaskLight"; glow.texture = texture
		glow.z_index = -1; add_child(glow)
	built = true

func _retire(node: CanvasItem) -> void:
	if node.get_child_count() == 0 and node.visible:
		node.hide(); retired.append(node)

func _on_event(changed_id: String) -> void:
	if kind == "register":
		if changed_id not in get_parent().get_parent()._events(): return
	elif kind in ["growth", "lantern"]:
		if changed_id != event_id: return
	else:
		var station := get_parent()
		if changed_id != station.shortcut_id and changed_id not in station.required_event_ids: return
	if refresh_pending: return
	# Let authoritative controllers consume the signal before reading status.
	refresh_pending = true
	call_deferred("_refresh")

func _refresh() -> void:
	refresh_pending = false
	states.clear()
	if kind == "register":
		var events: Array = get_parent().get_parent()._events()
		var state := get_node_or_null("/root/GameState")
		for index in range(indicators.size()):
			var complete := not Engine.is_editor_hint() and state != null and bool(state.unlocked_shortcuts.get(events[index], false))
			states.append("done" if complete else "pending")
	elif kind in ["growth", "lantern"]:
		var state := get_node_or_null("/root/GameState")
		states.append("done" if state != null and bool(state.unlocked_shortcuts.get(event_id, false)) else "pending")
	else:
		var station := get_parent()
		states.append("done" if station.is_active else ("pending" if station._requirements_met() else "locked"))
	var key := kind
	if kind == "register": key = "register_wood" if indicators.size()==2 else "register_stone"
	elif kind in ["seedbed","beacon","growth","lantern"] and states[0]=="done": key += "_done"
	Atlas.apply(painted,key)
	_layout()
	refresh_count += 1
	animate(motion_time)
	queue_redraw()

func supply_surfaces(surfaces: Array[Rect2]) -> void:
	# Only artwork moves; station, Area2D, reach and task anchors stay fixed.
	support = Support.below(global_position-Vector2(0,3),surfaces,90)
	if support.has_area(): foot_y = to_local(Vector2(global_position.x,support.position.y)).y
	fit_scale = 1.0
	if support.has_area():
		var bounds := painted_bounds()
		var available := bounds.size.y
		for ceiling in surfaces:
			if ceiling.end.y<support.position.y-4 and ceiling.end.x>bounds.position.x and ceiling.position.x<bounds.end.x:
				available = minf(available,support.position.y-ceiling.end.y-2)
		fit_scale = clampf(available/bounds.size.y,.15,1)
	_layout()
	queue_redraw()

func _layout() -> void:
	var key: String = painted.get_meta("task_frame")
	painted.scale = Vector2.ONE*float(Atlas.DATA[key][3])/painted.texture.get_width()*fit_scale
	painted.position = Vector2(0,foot_y)
	if kind == "register":
		for index in range(captions.size()):
			var label := captions[index]
			label.add_theme_font_size_override("font_size",6)
			label.add_theme_color_override("font_color",Color("d7c6a9"))
			label.add_theme_constant_override("outline_size",1)
			label.add_theme_color_override("font_outline_color",INK)
			label.size = Vector2(30,9)
			label.position = Vector2(_column(index)*fit_scale-15,foot_y-(_badge_y()-5)*fit_scale)
			label.z_index = 0
	elif kind not in ["growth","lantern"]:
		# Both live native texts used to overlap each other or the floor.
		for named in ["StatusLabel","InteractionPrompt"]:
			var label := get_parent().get_node_or_null(named) as Label
			if label == null: continue
			label.add_theme_font_size_override("font_size",8)
			label.add_theme_constant_override("outline_size",2)
			label.add_theme_color_override("font_outline_color",Color("08121a"))
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.size = Vector2(176,12)
			label.position = Vector2(-88,foot_y-52-(26 if named=="InteractionPrompt" else 0))
			label.z_index = 3
	if glow != null: glow.position = Vector2(0,foot_y-(32 if kind=="beacon" else 10)*fit_scale)

func painted_bounds() -> Rect2:
	# Reserve the largest state so growing a plant never buries another prop.
	var width := 90.0 if kind=="register" else (46.0 if kind in ["growth","seedbed","winch"] else 28.0)
	var height := 60.0 if kind=="register" else (32.0 if kind in ["growth","seedbed","lantern"] else 50.0)
	return global_transform*Rect2(-width/2,foot_y-height,width,height)

func reaction_bounds() -> Rect2:
	return painted_bounds()

func brush(force: float) -> bool:
	return response.push(force*.6) if kind=="growth" else false

func advance_response(delta: float) -> bool:
	var moving := response.step(delta)
	painted.skew = wind+response.bend
	return moving

func reset_response() -> void:
	response.reset(); painted.skew = wind

func animate(age: float) -> void:
	motion_time = age
	if kind=="growth":
		wind = sin(age*1.1+global_position.x*.03)*.009
		painted.skew = wind+response.bend
	if glow == null: return
	glow.visible = not states.is_empty() and states[0]=="done"
	var pulse := .85+.1*sin(age*4.7)+.05*sin(age*11.3)
	glow.scale = Vector2.ONE*(.37 if kind=="beacon" else .23)*pulse*fit_scale
	glow.modulate = Color(.79,.70,1,.28*pulse) if kind=="beacon" else Color(1,.76,.37,.3*pulse)
	queue_redraw()

func rest() -> void:
	wind = 0
	painted.skew = response.bend
	if glow != null: animate(0)

func _column(index: int) -> float:
	return (index-(indicators.size()-1)*.5)*(32 if indicators.size()==2 else 23)

func reading_report() -> String:
	if kind!="register": return ""
	var lines := PackedStringArray([get_parent().get_node("RouteClue").text, ""])
	for index in range(captions.size()):
		lines.append(captions[index].text+": "+("RECORDED" if states[index]=="done" else "PENDING"))
	return "\n".join(lines)

func _badge_y() -> float:
	return 36.0 if indicators.size()==2 else 40.0

func _tint(status: String) -> Color:
	return Color("91d2a9") if status=="done" else (Color("9a94a7") if status=="locked" else Color("d4b984"))

func _badge(at: Vector2,status: String) -> void:
	var color := _tint(status)
	draw_circle(at,3.6,INK)
	draw_arc(at,3.2,0,TAU,16,color,.7,true)
	if status=="done": draw_polyline(PackedVector2Array([at+Vector2(-1.9,0),at+Vector2(-.4,1.4),at+Vector2(2,-1.5)]),color,.9,true)
	elif status=="locked":
		draw_rect(Rect2(at+Vector2(-1.3,-.2),Vector2(2.6,2)),color)
		draw_arc(at+Vector2(0,-.3),1,PI,TAU,10,color,.7,true)
	else:
		draw_line(at,at+Vector2(0,-2),color,.8,true)
		draw_line(at,at+Vector2(1.6,.5),color,.8,true)

func _draw() -> void:
	if states.is_empty(): return
	if kind=="register":
		for index in range(states.size()): _badge(Vector2(_column(index)*fit_scale,foot_y-_badge_y()*fit_scale),states[index])
	elif kind not in ["growth","lantern"]:
		_badge(Vector2(22*fit_scale,foot_y-29*fit_scale),states[0])
	if glow != null and glow.visible:
		for index in 2:
			var phase := fposmod(motion_time*.48+index*.5,1)
			var at := glow.position+Vector2(sin(phase*TAU+index)*2,-phase*7)
			draw_circle(at,.35,Color(.9,.82,1,(1-phase)*.5))
