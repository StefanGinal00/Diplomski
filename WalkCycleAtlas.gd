extends RefCounted
## Shared, lazily loaded eight-frame strips. Registration comes from the opaque
## body components of the original PNGs, not from an assumed equal-cell grid.
## No image manipulation or image readback happens during gameplay.
const DATA := {
	"cave_female": [[69,20,284,462,127.0],[473,21,209,463,102.0],[854,21,228,466,112.0],[1226,22,272,460,143.0],[72,533,314,451,140.5],[482,529,222,455,105.5],[884,530,221,458,96.5],[1228,531,298,456,154.5]],
	"cave_male": [[51,22,319,441,157.5],[472,22,194,440,114.5],[858,22,179,442,88.0],[1206,21,315,438,168.0],[36,532,332,440,174.5],[463,532,206,440,121.0],[856,533,197,441,89.5],[1191,532,329,438,168.0]],
	"ash_female": [[62,23,313,460,172.0],[439,23,249,460,158.5],[828,22,219,461,130.0],[1210,22,299,461,163.5],[59,531,316,459,168.5],[456,534,254,461,156.5],[840,530,242,463,159.5],[1200,529,322,464,167.0]],
	"ash_male": [[49,5,308,478,163.5],[435,4,246,475,150.5],[876,4,193,475,98.0],[1188,4,338,475,182.5],[23,518,350,471,169.0],[447,517,253,471,155.0],[876,517,196,470,102.5],[1175,517,350,472,190.5]],
	"star_female": [[46,10,322,464,151.0],[409,11,278,467,158.5],[827,7,240,472,116.5],[1173,9,355,466,165.0],[43,514,338,466,145.0],[423,517,275,469,138.5],[831,516,229,472,109.5],[1173,518,356,465,172.0]],
	"star_male": [[51,13,329,465,147.5],[446,14,252,463,125.0],[825,13,218,465,100.0],[1169,14,333,464,136.0],[47,519,338,462,132.5],[439,519,249,463,126.0],[811,521,239,465,113.5],[1175,521,343,460,161.0]],
	"enemy": [[32,79,325,406,178.0],[428,99,321,391,165.0],[841,69,278,427,135.0],[1170,70,338,423,202.5],[27,552,359,415,200.0],[446,574,308,393,156.5],[814,548,313,423,165.0],[1168,548,345,425,205.0]],
	"fiend": [[23,50,356,430,154.5],[434,68,313,412,124.5],[825,50,283,431,120.5],[1154,51,354,428,162.0],[20,537,357,425,157.0],[429,557,318,408,128.0],[806,537,286,430,136.5],[1151,537,365,426,172.5]],
	"root": [[19,23,365,473,211.5],[431,19,320,479,175.5],[836,21,269,477,135.5],[1162,20,343,478,199.0],[17,524,392,473,225.0],[434,527,326,467,181.5],[837,527,285,468,145.5],[1160,525,353,473,198.5]],
}
static var cache := {}

static func frames_for(identity: String) -> Array:
	if cache.has(identity): return cache[identity]
	var path := "res://art/characters/resident_walk_%s_v2.png" % identity if "_" in identity else "res://art/characters/mob_walk_%s_v1.png" % identity
	var sheet := load(path) as Texture2D
	var ratio := sheet.get_size() / Vector2(1536,1024)
	var frames := []
	for box in DATA[identity]:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(Vector2(box[0]-2,box[1]-2)*ratio,Vector2(box[2]+4,box[3]+4)*ratio)
		atlas.filter_clip = true
		frames.append(atlas)
	cache[identity] = frames
	return frames

static func show(sprite: Sprite2D, identity: String, step: int, height: float, foot_y: float, facing: float) -> void:
	var frames := frames_for(identity)
	var box: Array = DATA[identity][posmod(step,8)]
	var texture: AtlasTexture = frames[posmod(step,8)]
	var ratio := texture.atlas.get_size()/Vector2(1536,1024)
	var contact: float = (box[3]+1)*ratio.y
	var pivot: float = (box[4]+2)*ratio.x
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.texture = texture
	sprite.offset = Vector2.ZERO
	sprite.scale = Vector2.ONE * height / (DATA[identity][0][3]*ratio.y)
	sprite.flip_h = facing < 0
	sprite.position = Vector2((texture.get_width()*0.5-pivot)*sprite.scale.x*facing,foot_y+(texture.get_height()*0.5-contact)*sprite.scale.y)
	sprite.set_meta("walk_frame",posmod(step,8))
	sprite.set_meta("contact_row",contact)
	sprite.set_meta("contact_floor",sprite.get_parent().to_global(Vector2(0,foot_y)).y)
