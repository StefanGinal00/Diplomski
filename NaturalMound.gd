extends StaticBody2D
## Shallow walkable rubble, registered to the untouched painted contour.
const Profiles:=preload("res://TerrainContourData.gd").DATA
const Atlas:=preload("res://LivingSpriteAtlas.gd")
var surface:=PackedVector2Array()
var footprint:=Rect2()
var family:="cave"
var variant:=0
var display_width:=144.0

func configure(biome: String, index: int, anchor: Vector2) -> void:
	family=biome
	variant=index
	global_position=anchor
	set_meta("natural_mound",true)
	var factor:=display_width/511.0
	var baseline: float=447 if family=="cave" else (446 if family=="ash" else 403)
	var source: Array=Profiles[family][variant]
	var top:=baseline
	for sample in source: top=minf(top,sample[1])
	var burial: float=(baseline-top)*factor-18.0
	for sample in source:
		surface.append(Vector2(float(sample[0])*factor-display_width*0.5,minf(0,(float(sample[1])-baseline)*factor+burial)))
	# Limit local rock teeth to a walkable angle without lifting the collider
	# away from the silhouette. Smoothing only lowers steep painted protrusions.
	for i in range(1,surface.size()):
		surface[i].y=maxf(surface[i].y,surface[i-1].y-(surface[i].x-surface[i-1].x)*0.55)
	for i in range(surface.size()-2,-1,-1):
		surface[i].y=maxf(surface[i].y,surface[i+1].y-(surface[i+1].x-surface[i].x)*0.55)
	var collision:=CollisionPolygon2D.new()
	collision.name="WalkableContour"
	collision.polygon=surface+PackedVector2Array([Vector2(display_width*0.5,5),Vector2(-display_width*0.5,5)])
	add_child(collision)
	var art:=Sprite2D.new()
	art.name="PaintedRubble"
	var sheet: Texture2D=Atlas.frames_for("terrain_segments_%s_v1"%family)[0].atlas
	var ratio:=sheet.get_size()/Vector2(1536,1024)
	var texture:=AtlasTexture.new()
	texture.atlas=sheet
	texture.region=Rect2(Vector2(variant*512,224)*ratio,Vector2(512,256)*ratio)
	texture.filter_clip=true
	art.texture=texture
	art.centered=false
	art.scale=Vector2.ONE*factor/ratio
	art.position=Vector2(-display_width*0.5,(224-baseline)*factor+burial)
	art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(art)
	footprint=Rect2(anchor-Vector2(display_width*0.5,20),Vector2(display_width,25))
	set_meta("natural_mound_bounds",footprint)

func height_at(world_x: float) -> float:
	var x:=world_x-global_position.x
	for i in range(surface.size()-1):
		if x>=surface[i].x and x<=surface[i+1].x:
			return global_position.y+lerpf(surface[i].y,surface[i+1].y,inverse_lerp(surface[i].x,surface[i+1].x,x))
	return global_position.y
