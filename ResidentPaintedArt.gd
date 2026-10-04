@tool
extends Sprite2D
## Original shared regional bodies. All frame registration is measured from
## untouched source PNGs; interactions and routes remain on TownResident.
const SHEETS := [preload("res://art/characters/residents_cave_motion_v1.png"), preload("res://art/characters/residents_ash_motion_v1.png"), preload("res://art/characters/residents_star_motion_v1.png")]
const SOURCE_SIZE := Vector2(1536, 1024)
const CROPS := [
	[Rect2(140,8,135,469), Rect2(468,13,230,461), Rect2(854,12,234,464), Rect2(1238,9,209,468), Rect2(119,493,169,494), Rect2(462,494,268,488), Rect2(826,495,288,488), Rect2(1248,493,220,494)],
	[Rect2(128,16,140,454), Rect2(470,16,229,453), Rect2(842,17,255,452), Rect2(1274,16,198,454), Rect2(80,492,186,491), Rect2(449,493,261,488), Rect2(834,495,282,486), Rect2(1250,490,261,494)],
	[Rect2(148,7,147,452), Rect2(460,8,259,450), Rect2(835,9,271,449), Rect2(1236,8,220,452), Rect2(118,474,181,519), Rect2(433,474,293,512), Rect2(813,477,306,510), Rect2(1245,475,240,518)],
]
const CONTACTS := [[467,460,463,466,493,487,487,493], [453,452,451,453,489,487,485,491], [451,448,448,451,517,511,509,517]]
const PIVOTS := [[210,584,974,1310,200,579,980,1318], [200,580,963,1327,179,574,971,1330], [222,591,980,1320,216,593,979,1332]]
const WOMEN := ["Neris", "Ivara", "Vey", "Dara", "Mira", "Liora", "Cera", "Sable", "Nima", "Astra", "Lumen", "Sera", "Dena", "Elya", "Selka", "Lyra", "Tessa", "Nera", "Sela"]
var family := 0
var role := 0
var pose := -1
var contact_row := 0.0
var base_scale := 1.0
var pivot := 0.0
var frames: Array[AtlasTexture] = []
var walk_identity := ""

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_process(false)

func configure(actor: Node2D) -> void:
	var context := String(actor.get_path()).to_lower()
	family = 1 if ("cinder" in context or "ashen" in context or "ash" in context) else (2 if "starfall" in context else 0)
	var identity := String(actor.get("resident_name")).split(",")[0]
	role = 0 if identity in WOMEN else 1
	walk_identity = ["cave","ash","star"][family] + ("_female" if role == 0 else "_male")
	var ratio: Vector2 = SHEETS[family].get_size() / SOURCE_SIZE
	base_scale = (29.0 if role == 0 else 31.0) / (CROPS[family][role*4].size.y * ratio.y)
	for index in range(role*4, role*4+4):
		var atlas := AtlasTexture.new()
		atlas.atlas = SHEETS[family]
		atlas.region = Rect2(CROPS[family][index].position * ratio, CROPS[family][index].size * ratio)
		atlas.filter_clip = true
		frames.append(atlas)
	show_pose(0, 1, 14, 0)

func show_pose(next_pose: int, facing: float, foot_y: float, age: float) -> void:
	var gestures: String="resident_gestures_%s_v%d"%[["cave","ash","star"][family],2 if family==2 else 1]
	if next_pose in [0,3] and preload("res://LivingSpriteAtlas.gd").DATA.has(gestures):
		pose=next_pose
		var beat:=fposmod(age,4.8)
		var gesture:=0
		if next_pose==3:
			gesture=1 if beat<0.6 else (2 if beat<1.7 else (3 if beat<2.5 else 0))
		elif fposmod(age,8.5)>7.4: gesture=1
		var reference: float=preload("res://LivingSpriteAtlas.gd").DATA[gestures].boxes[role*4][3]
		preload("res://LivingSpriteAtlas.gd").show(self,gestures,role*4+gesture,29.0 if role==0 else 31.0,foot_y,facing,reference,"root")
		contact_row=float(get_meta("contact_row"))
		return
	material=null
	var index := role * 4 + next_pose
	if pose != next_pose:
		pose = next_pose
		texture = frames[pose]
		var ratio: Vector2 = SHEETS[family].get_size() / SOURCE_SIZE
		contact_row = CONTACTS[family][index] * ratio.y
		pivot = (PIVOTS[family][index] - CROPS[family][index].position.x) * ratio.x
	# Tiny breathing stretches from the planted boot, never levitates the body.
	scale = Vector2(base_scale, base_scale * (1.0 + sin(age * 2.0) * 0.0025))
	flip_h = facing < 0
	position.x = (texture.get_width()*0.5 - pivot) * scale.x * facing
	position.y = foot_y + (texture.get_height()*0.5 - contact_row) * scale.y
	set_meta("contact_row", contact_row)
	set_meta("contact_floor", get_parent().to_global(Vector2(0,foot_y)).y)

func show_walk(step: int, facing: float, foot_y: float) -> void:
	material=null
	preload("res://WalkCycleAtlas.gd").show(self,walk_identity,step,29.0 if role==0 else 31.0,foot_y,facing)
	pose = 4 + posmod(step,8)
	contact_row = float(get_meta("contact_row"))
