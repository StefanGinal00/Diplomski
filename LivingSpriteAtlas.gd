extends RefCounted
const DATA := preload("res://LivingAtlasData.gd").DATA
static var cache := {}
static var masks := {}

static func frames_for(id: String) -> Array:
	if cache.has(id): return cache[id]
	var data: Dictionary = DATA[id]
	var sheet := load(data.path) as Texture2D
	var ratio := sheet.get_size()/Vector2(data.size[0],data.size[1])
	var frames := []
	for box in data.boxes:
		var image := AtlasTexture.new()
		image.atlas = sheet
		image.region = Rect2(Vector2(box[0]-2,box[1]-2)*ratio,Vector2(box[2]+4,box[3]+4)*ratio)
		image.filter_clip = true
		frames.append(image)
	cache[id] = frames
	return frames

static func show(art: Sprite2D, id: String, frame: int, height: float, foot_y := 0.0, facing := 1.0, reference_height := 0.0, pivot_kind := "center") -> void:
	var data: Dictionary = DATA[id]
	var box: Array = data.boxes[frame]
	var image: AtlasTexture = frames_for(id)[frame]
	var ratio := image.atlas.get_size()/Vector2(data.size[0],data.size[1])
	var reference := float(box[3]) if reference_height <= 0 else reference_height
	var pivot := float(box[2])*0.5
	if pivot_kind == "body": pivot = float(box[4])
	elif pivot_kind == "root": pivot = float(box[5])
	pivot = (pivot+2)*ratio.x
	var contact := (float(box[3])+1)*ratio.y
	art.hframes=1;art.vframes=1
	art.texture=image
	if data.has("spans"):
		var key:=id+":"+str(frame)+":"+str(bool(art.get_meta("heated",false)))
		if not masks.has(key):
			var mask:=ShaderMaterial.new()
			mask.shader=preload("res://shaders/living_frame_isolation.gdshader")
			mask.set_shader_parameter("source_rect",Vector4(float(box[0])/data.size[0],float(box[1])/data.size[1],float(box[2])/data.size[0],float(box[3])/data.size[1]))
			var spans:=PackedVector2Array()
			for pair in data.spans[frame]: spans.append(Vector2(float(pair[0])/data.size[0],float(pair[1])/data.size[0]))
			mask.set_shader_parameter("spans",spans)
			mask.set_shader_parameter("heated",bool(art.get_meta("heated",false)))
			masks[key]=mask
		art.material=masks[key]
	else:
		art.material=null
	art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.offset=Vector2.ZERO
	art.scale=Vector2.ONE*height/(reference*ratio.y)
	art.flip_h=facing<0
	art.position=Vector2((image.get_width()*0.5-pivot)*art.scale.x*facing,foot_y+(image.get_height()*0.5-contact)*art.scale.y)
	art.set_meta("atlas_frame",frame)
	art.set_meta("contact_row",contact)
	art.set_meta("contact_floor",art.get_parent().to_global(Vector2(0,foot_y)).y)
