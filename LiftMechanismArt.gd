extends Node2D
## Read-only hoist terminal: anchored posts, pulleys, attached suspension, deck.
## Native ShaftLift still owns access, destination, save state and transport.
const Atlas := preload("res://StructureAtlas.gd")
const Support := preload("res://WorldSupport.gd")
const Placement := preload("res://HoistClearancePlacement.gd")
var rest_head := Vector2.ZERO
var head: Sprite2D
var elapsed := 0.0

static func install(actor: Node2D, floor_rect: Rect2, id: String, surfaces: Array[Rect2], nodes: Array[Node]) -> void:
	var index := 2 if id.begins_with("starfall_") else 0
	var plan := Placement.plan(actor,floor_rect,index,nodes)
	var anchor := preload("res://PortalContextArt.gd")._anchor(actor.global_position.x,floor_rect,surfaces,nodes)
	if actor.has_node("LiftGantry"):
		var existing := actor.get_node("LiftGantry")
		if existing.get_script() == load("res://LiftMechanismArt.gd") and existing.get_meta("support_rect", Rect2()) == floor_rect and existing.get_meta("anchor_origin", Vector2.INF) == actor.global_position and existing.get_meta("clearance_plan",{}) == plan and existing.get_meta("structural_anchor",{}) == anchor and existing.get_meta("hoist_family",-1) == index:
			existing.global_transform = Transform2D(0,Vector2(actor.global_position.x,floor_rect.position.y))
			return
		# Only this system's obsolete decorative gantry is replaced.
		existing.free()
	var art := new()
	art.name = "LiftGantry"
	actor.add_child(art)
	art.global_transform = Transform2D(0,Vector2(actor.global_position.x,floor_rect.position.y))
	art._build(actor, floor_rect, id, plan, anchor)

func _build(actor: Node2D, floor_rect: Rect2, id: String, plan: Dictionary, anchor: Dictionary) -> void:
	z_index = -1
	var gothic := id.begins_with("starfall_")
	var index := 2 if gothic else 0
	var deck: Sprite2D = actor.get_node("FinishedDevice")
	Atlas.configure(deck, Atlas.HOISTS, Atlas.HOIST_SIZE, Atlas.HOIST_RECTS[index + 1], 48)
	deck.global_transform = Transform2D(0,Vector2.ONE*deck.scale.x,0,actor.global_position)
	# The walkable deck TOP coincides with the existing physical surface.
	# The chain sockets protrude above it; fascia is below, not under the boots.
	var ratio := Atlas.HOISTS.get_size() / Atlas.HOIST_SIZE
	deck.set_meta("contact_row", 44 * ratio.y)
	deck.z_index = 1
	deck.set_meta("structural_deck", true)
	Support.plant(deck, deck.get_meta("contact_row"), floor_rect.position.y)
	head = Sprite2D.new()
	head.name = "WinchHead"
	add_child(head)
	Atlas.configure(head, Atlas.HOISTS, Atlas.HOIST_SIZE, Atlas.HOIST_RECTS[index],plan.width)
	head.position = plan.head
	head.visible = plan.mode == "gantry"
	rest_head = head.position
	var head_ratio: float = plan.width / 69.0
	var material_texture := preload("res://art/visual_slice/starfall_masonry_v1.png") if gothic else preload("res://art/visual_slice/echo_walk_timber_v1.png")
	for side in [-1,1]:
		var x: float = side*28*head_ratio
		var foot_x := clampf(x, floor_rect.position.x - actor.global_position.x + 3, floor_rect.end.x - actor.global_position.x - 3)
		var post := Polygon2D.new()
		post.name = "LoadPostLeft" if x < 0 else "LoadPostRight"
		post.polygon = PackedVector2Array([Vector2(foot_x-3, 0), Vector2(x-3, head.position.y+5*head_ratio), Vector2(x+3, head.position.y+5*head_ratio), Vector2(foot_x+3, 0)])
		post.visible = head.visible
		add_child(post)
		preload("res://RoomArtFinish.gd")._material(post, material_texture, Color("a2a29a"))
		if not gothic: _timber_uv(post)
		move_child(post, 0)
	# Cables leave pulley bearings and terminate at the painted deck sockets.
	for side in [-1, 1]:
		var rope := Line2D.new()
		rope.name = "SuspensionLeft" if side < 0 else "SuspensionRight"
		rope.points = PackedVector2Array([head.position+Vector2(side*17*head_ratio,-8*head_ratio), Vector2(side * 21, -2)])
		rope.visible = head.visible
		rope.width = 1.1
		rope.default_color = Color("8a7458")
		rope.antialiased = true
		add_child(rope)
		move_child(rope, 0)
	set_meta("support_rect", floor_rect)
	set_meta("anchor_origin", actor.global_position)
	set_meta("destination_group", String(actor.target_marker_group))
	set_meta("clearance_plan",plan)
	set_meta("hoist_family",index)
	preload("res://LedgeSupportArt.gd").attach(self, 2 if gothic else 1, 58)
	var local_anchor: Rect2 = global_transform.affine_inverse() * anchor.rect
	if anchor.kind == "wall":
		var wall_x: float = local_anchor.get_center().x
		var side := signf(wall_x)
		# Separate structural members; the triangular space stays OPEN.
		_beam("WallLedger",Vector2(side*26,5),Vector2(wall_x,5),5,material_texture)
		_beam("WallBrace",Vector2(side*25,9),Vector2(wall_x,55),4,material_texture)
		_beam("WallSocket",Vector2(wall_x,0),Vector2(wall_x,62),6,material_texture)
	else:
		var bottom: float = maxf(45, local_anchor.position.y + 8)
		_beam("TrestleLeft",Vector2(-20,4),Vector2(-18,bottom),5,material_texture)
		_beam("TrestleRight",Vector2(20,4),Vector2(18,bottom),5,material_texture)
		for y in range(8,int(bottom)-12,60):
			_beam("CrossBrace",Vector2(-18,y),Vector2(18,minf(y+55,bottom)),3,material_texture)
	set_meta("structural_anchor", anchor)
	# Keep a small readable native prompt; never a permanent wall of labels.
	actor.prompt.add_theme_font_size_override("font_size", 9)
	actor.prompt.global_position.y = global_position.y+head.position.y-head.get_rect().size.y*head.scale.y*0.5+3
	actor.prompt.add_theme_color_override("font_outline_color", Color("09121a"))
	actor.prompt.add_theme_constant_override("outline_size", 2)

func _beam(named: String, a: Vector2, b: Vector2, width: float, texture: Texture2D) -> void:
	var normal := (b-a).normalized().orthogonal()*width*0.5
	var beam := Polygon2D.new()
	beam.name=named
	beam.z_index=-2
	beam.polygon=PackedVector2Array([a-normal,b-normal,b+normal,a+normal])
	add_child(beam)
	preload("res://RoomArtFinish.gd")._material(beam,texture,Color("939389"))
	if texture==preload("res://art/visual_slice/echo_walk_timber_v1.png"): _timber_uv(beam)

func _timber_uv(beam: Polygon2D) -> void:
	var wood: Texture2D=load("res://art/visual_slice/structural_timber_beams_v1.png")
	var ratio:=wood.get_size()/Vector2(1536,1024)
	beam.texture=wood
	beam.texture_repeat=CanvasItem.TEXTURE_REPEAT_DISABLED
	beam.color=Color(0.8,0.86,0.87)
	# Map the long grain axis ALONG each beam, including the diagonals.
	beam.uv=PackedVector2Array([Vector2(24,80)*ratio,Vector2(1518,80)*ratio,Vector2(1518,234)*ratio,Vector2(24,234)*ratio])

func _process(delta: float) -> void:
	if not is_visible_in_tree() or head == null: return
	# Feedback only during accepted transport, no incessant idle mechanism.
	if get_parent().in_transit:
		elapsed += delta
		head.position = rest_head + Vector2(sin(elapsed * 30) * 0.2, 0)
	else:
		head.position = rest_head
		elapsed = 0
