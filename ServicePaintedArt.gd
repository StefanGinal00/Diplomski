@tool
extends Node2D
## Grounded shop/forge art only: native actors, stock, prices and reach survive.
const Support := preload("res://WorldSupport.gd")
const Layout := preload("res://WorldLayout.gd")
const Props := preload("res://WorkplaceAtlas.gd")
const SHEETS := [preload("res://art/characters/service_merchants_motion_v1.png"),preload("res://art/characters/service_smiths_motion_v1.png")]
const CROPS := [
	[Rect2(173,7,204,497),Rect2(661,14,226,490),Rect2(1132,11,331,494),Rect2(185,515,210,502),Rect2(669,518,210,499),Rect2(1152,517,318,500)],
	[Rect2(181,11,208,472),Rect2(621,13,337,470),Rect2(1141,11,302,472),Rect2(180,517,209,480),Rect2(622,504,345,493),Rect2(1140,516,310,480)],
]
const CONTACTS := [[495,488,492,500,497,498],[470,469,470,478,491,478]]
const PIVOTS := [[282,770,1247,285,770,1246],[280,770,1241,280,770,1241]]
var kind := 0
var role := 0
var pose := 0
var foot_y := 24.0
var age := 0.0
var clock := 0.0
var direction := 1.0
var base_scale := 1.0
var contact_row := 0.0
var prop_index := 0
var body: Sprite2D
var workplace: Sprite2D
var surfaces: Array[Rect2] = []
var frames: Array[AtlasTexture] = []
var retired: Array[CanvasItem] = []

static func attach(actor: Node2D) -> Node2D:
	if actor.has_node("ServicePainting"): return actor.get_node("ServicePainting")
	var art := (load("res://ServicePaintedArt.gd") as Script).new() as Node2D
	art.name = "ServicePainting"
	actor.add_child(art)
	return art

func _ready() -> void:
	set_process(false) # Native service drives the bounded visual update.
	var actor := get_parent()
	kind = 1 if actor.get("service_kind")=="anvil" else 0
	var identity := String(actor.get("service_name"))
	role = 1 if ("Selen" in identity or "Nalia" in identity) else 0
	prop_index = 2 if kind==1 else (1 if "Remedies" in identity else 0)
	for old_name in ["Stand","Body","Face","Sign","Goods","Anvil","Hammer"]:
		var old := actor.get_node_or_null(old_name) as CanvasItem
		if old != null:
			old.hide()
			retired.append(old)
	body = Sprite2D.new()
	body.name = "Body"
	body.z_index = 1
	body.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(body)
	var ratio: Vector2 = SHEETS[kind].get_size()/Vector2(1536,1024)
	base_scale = (30.0 if role==1 else 32.0)/(CROPS[kind][role*3].size.y*ratio.y)
	for i in range(role*3,role*3+3):
		var frame := AtlasTexture.new()
		frame.atlas = SHEETS[kind]
		frame.region = Rect2(CROPS[kind][i].position*ratio,CROPS[kind][i].size*ratio)
		frame.filter_clip = true
		frames.append(frame)
	workplace = Sprite2D.new()
	workplace.name = "Workplace"
	workplace.texture = Props.texture_for(prop_index)
	workplace.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	workplace.z_index = 0 # In front of facade scenery, behind this service body.
	add_child(workplace)
	age = absf(float(hash(str(actor.get_path()))%100))/13.0
	show_pose(0,1)
	call_deferred("_bootstrap_contacts")

func _bootstrap_contacts() -> void:
	var scope := get_parent().get_parent()
	var cursor := scope
	var found_room := false
	while cursor != null and cursor != get_tree().root:
		if cursor.has_node("WorldPresentationFinish"): return
		if not found_room: scope = cursor
		if String(cursor.name) in Layout.ROOM_NODES.values(): found_room = true
		cursor = cursor.get_parent()
	if scope == null or scope == get_tree().root: return
	var nodes: Array[Node] = []
	nodes.assign(scope.find_children("*","",true,false))
	supply_surfaces(Support.floors(nodes))

func supply_surfaces(value: Array[Rect2]) -> void:
	surfaces = value
	var floor_rect := Support.below(global_position,surfaces,80)
	if not floor_rect.has_area():
		workplace.hide() # No inventing floating furniture in unsupported authoring scenes.
		return
	foot_y = to_local(Vector2(global_position.x,floor_rect.position.y)).y
	set_meta("support_rect",floor_rect)
	var prop_height := 15.0 if kind==1 else (28.0 if prop_index==1 else 20.0)
	workplace.scale = Vector2.ONE * prop_height/workplace.texture.get_height()
	var half_width := workplace.texture.get_width()*workplace.scale.x/2
	# Choose the side with room for the complete workstation, then clamp the
	# painted prop to the actual ledge. Interaction/actor positions never move.
	direction = 1 if floor_rect.end.x-global_position.x >= global_position.x-floor_rect.position.x else -1
	var desired_x := global_position.x + direction*(half_width+5)
	var prop_x := clampf(desired_x,floor_rect.position.x+half_width+2,floor_rect.end.x-half_width-2)
	workplace.position.x = to_local(Vector2(prop_x,global_position.y)).x
	workplace.show()
	Support.plant(workplace,Props.contact(prop_index),floor_rect.position.y)
	show_pose(pose,direction)
	var label := get_parent().get_node_or_null("NameLabel") as Label
	if label != null:
		label.position.y = foot_y-(30 if role==1 else 32)-17
		label.add_theme_font_size_override("font_size",8)
		label.add_theme_color_override("font_outline_color",Color("08121b"))
		label.add_theme_constant_override("outline_size",2)
	var prompt := get_parent().get_node_or_null("InteractionPrompt") as Label
	if prompt != null: prompt.position.y = foot_y+4

func show_pose(value: int, facing: float) -> void:
	pose = value
	body.texture = frames[pose]
	var i := role*3+pose
	var ratio: Vector2 = SHEETS[kind].get_size()/Vector2(1536,1024)
	contact_row = CONTACTS[kind][i]*ratio.y
	var pivot: float = (PIVOTS[kind][i]-CROPS[kind][i].position.x)*ratio.x
	body.scale = Vector2.ONE*base_scale
	body.flip_h = facing<0
	body.position.x = (body.texture.get_width()/2.0-pivot)*base_scale*facing
	body.position.y = foot_y+(body.texture.get_height()/2.0-contact_row)*base_scale
	body.set_meta("contact_row",contact_row)
	body.set_meta("contact_floor",to_global(Vector2(0,foot_y)).y)

func advance(delta: float, visitor: Node2D) -> void:
	if not is_visible_in_tree(): return
	clock += delta
	var low := OS.has_feature("mobile") or bool(ProjectSettings.get_setting("world/ambient/low_cost",false))
	if clock < (0.1 if low else 0.05): return
	var step := clock
	clock = 0
	var view: Rect2 = get_viewport().canvas_transform.affine_inverse()*get_viewport().get_visible_rect()
	if not view.grow(80).has_point(global_position): return
	age += step
	var facing := direction
	var greeting := is_instance_valid(visitor) and visitor.is_visible_in_tree()
	if greeting and absf(visitor.global_position.x-global_position.x)>1: facing = signf(visitor.global_position.x-global_position.x)
	# These are quiet working poses, not a fabricated hammer strike without
	# contact frames. Merchants check a ledger; smiths prepare/inspect a tool.
	var next := 2 if greeting else (1 if fposmod(age,5.6)>3.8 else 0)
	show_pose(next,facing)
