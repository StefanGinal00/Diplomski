extends Sprite2D
## Six registered opening poses. Reward receipts remain entirely on the cache.
const SHEET := preload("res://art/visual_slice/cache_opening_v1.png")
const CROPS := [Rect2(25,179,230,171),Rect2(284,176,229,174),Rect2(538,158,226,192),Rect2(785,124,228,226),Rect2(1036,94,229,256),Rect2(1290,74,230,275),Rect2(24,488,230,172),Rect2(284,486,229,174),Rect2(538,466,229,194),Rect2(785,433,230,227),Rect2(1035,402,233,258),Rect2(1290,383,230,277),Rect2(23,805,232,169),Rect2(284,801,229,173),Rect2(536,778,230,196),Rect2(785,744,227,230),Rect2(1038,716,230,258),Rect2(1291,694,229,280)]
static var frames: Array[AtlasTexture] = []
var family := 0
var pose := 0
var opening_age := 0.0
var foot_y := 9.0

func _ready() -> void:
	set_process(false)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var key := str(get_parent().cache_id)
	family = 1 if "ash" in key or "cinder" in key else (2 if "starfall" in key else 0)
	if frames.is_empty():
		var ratio := SHEET.get_size()/Vector2(1536,1024)
		for crop in CROPS:
			var atlas := AtlasTexture.new()
			atlas.atlas = SHEET
			atlas.region = Rect2((crop.position-Vector2(2,2))*ratio,(crop.size+Vector2(4,4))*ratio)
			atlas.filter_clip = true
			frames.append(atlas)
	for named in ["Base", "Lid", "Core", "RuneHalo"]:
		var old := get_parent().get_node_or_null(NodePath(named)) as CanvasItem
		if old != null: old.self_modulate.a = 0
	scale = Vector2.ONE * (36.0 / (232.0*SHEET.get_width()/1536.0))
	show_pose(5 if get_parent().opened else 0)

func show_pose(value: int) -> void:
	pose = clampi(value, 0, 5)
	texture = frames[family * 6 + pose]
	var contact: float = (CROPS[family*6+pose].size.y+1)*SHEET.get_height()/1024.0
	position.y = foot_y + (texture.get_height() * 0.5 - contact) * scale.y
	set_meta("contact_row", contact)

func begin_opening() -> void:
	opening_age = 0
	show_pose(0)
	set_process(true)

func _process(delta: float) -> void:
	opening_age += delta
	show_pose(int(opening_age / 0.105))
	if pose == 5: set_process(false)

func supply_surfaces(surfaces: Array[Rect2]) -> void:
	var floor_rect := preload("res://WorldSupport.gd").below(get_parent().global_position, surfaces, 60)
	if not floor_rect.has_area(): return
	foot_y = get_parent().to_local(Vector2(global_position.x, floor_rect.position.y)).y
	show_pose(pose)
