@tool
extends Sprite2D
## Small six-pose body sets for actors that still used icon/polygon placeholders.
const SHEET = preload("res://art/characters/combat_mobs_frames_v2.png")
const ROWS := {"enemy": 0, "fiend": 1, "root": 2, "sentry": 3}
const CONTACT_ROWS := {"enemy": [239, 239, 239, 238, 238, 239], "fiend": [239, 239, 239, 239, 239, 239], "root": [238, 239, 239, 239, 238, 239]}
const HEIGHTS := {"enemy": 26.0, "fiend": 31.0, "root": 42.0, "sentry": 26.0}
const STEP_DISTANCE := 14.0
@export_enum("enemy", "fiend", "root", "sentry") var identity := "enemy"
@export var heated := false
var pose := 0
var release_remaining := 0.0
var distance := 0.0
var walk_grace := 0.0
var last_position := Vector2.ZERO
var face_left := false

static func attach(actor: Node2D, kind: String) -> void:
	if actor.has_node("PaintedMobAppearance"):
		return
	var visual := new()
	visual.name = "PaintedMobAppearance"
	visual.identity = kind
	actor.add_child(visual)

func _ready() -> void:
	texture = SHEET
	hframes = 6
	vframes = 4
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	process_priority = 2
	last_position = get_parent().global_position
	var actor := get_parent()
	var collider := actor.get_node("CollisionShape2D") as CollisionShape2D
	position.y = collider.position.y + collider.shape.size.y * 0.5
	scale = Vector2.ONE * float(HEIGHTS[identity]) / 224.0
	offset = Vector2(0, -112)
	for named in ["Sprite2D", "BodyVisual", "RootMantle", "Thorns", "Eyes", "Shell", "Eye", "BackFlames"]:
		var old := actor.get_node_or_null(named) as CanvasItem
		if old != null:
			old.hide()
	if heated:
		material = ShaderMaterial.new()
		material.shader = preload("res://shaders/ash_sentry_palette.gdshader")
	visibility_changed.connect(_on_visibility_changed)
	_apply_pose(0)
	preload("res://MobDefeatEcho.gd").hook(self, "ash_sentry" if heated else identity)
	if Engine.is_editor_hint():
		set_process(false)

func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		release_remaining = 0
		walk_grace = 0
		distance = 0
		modulate = Color.WHITE
		last_position = get_parent().global_position
		_apply_pose(0)

func contact() -> void:
	release_remaining = 0.24
	_apply_pose(4)

func _process(delta: float) -> void:
	var actor := get_parent()
	var travel: Vector2 = actor.global_position - last_position
	last_position = actor.global_position
	if not is_visible_in_tree() or actor.is_dead:
		return
	release_remaining = maxf(0, release_remaining - delta)
	walk_grace = maxf(0, walk_grace - delta)
	if travel.length() >= 40:
		walk_grace = 0
		distance = 0
	elif absf(travel.x) > 0.02:
		distance = fmod(distance + absf(travel.x), STEP_DISTANCE * 2)
		walk_grace = 0.065
		face_left = travel.x < 0
	pose = 1 + int(distance / STEP_DISTANCE) % 2 if walk_grace > 0 else 0
	modulate = Color.WHITE
	match identity:
		"root":
			face_left = actor.facing < 0 if actor.phase != "patrol" else actor.patrol_direction < 0
			if actor.phase == "warning": pose = 3
			elif actor.phase == "burst": pose = 4
			elif actor.phase == "recovery": pose = 5
			modulate = actor.body_visual.modulate
		"sentry":
			pose = 3 if actor.windup_remaining > 0 else 0
			face_left = actor.aim_direction.x < 0
			modulate = actor.eye.modulate
		_:
			face_left = actor.direction < 0
			if is_instance_valid(actor.target_player) and actor.target_player.get("is_dead") != true and actor.global_position.distance_to(actor.target_player.global_position) < 30 and release_remaining <= 0:
				pose = 3
	if release_remaining > 0:
		pose = 4 if release_remaining > 0.12 else 5
	if identity in ["enemy", "fiend"]:
		# Native damage can flash without knockback/stun. The old hidden sprite
		# still receives this signal, so explicitly carry it onto the painted body.
		if actor.hit_flash_remaining > 0:
			modulate = actor.hit_flash_color
		if actor.hit_stun_remaining > 0:
			release_remaining = 0
			pose = 5
	_apply_pose(pose)

func _apply_pose(value: int) -> void:
	pose = clampi(value, 0, 5)
	material=null
	if pose in [1,2] and preload("res://WalkCycleAtlas.gd").DATA.has(identity):
		var collider: CollisionShape2D = get_parent().get_node("CollisionShape2D")
		var foot: float = collider.position.y + collider.shape.size.y*0.5
		preload("res://WalkCycleAtlas.gd").show(self,identity,int(distance/(STEP_DISTANCE*2)*8),float(HEIGHTS[identity]),foot,-1.0 if face_left else 1.0)
		return
	var library:="mob_attack_%s_v1"%identity
	var atlas:=preload("res://LivingSpriteAtlas.gd")
	if atlas.DATA.has(library):
		var actor:=get_parent()
		var painted_frame:=0
		if pose==3:
			var progress:=0.0
			if identity=="root": progress=1.0-float(actor.phase_remaining)/(0.7 if actor.zone_tier==0 else 0.55)
			elif identity=="sentry": progress=1.0-float(actor.windup_remaining)/maxf(0.01,actor.windup_time)
			painted_frame=1+clampi(int(progress*3),0,2)
		elif pose==4:
			painted_frame=4
			if identity=="root" and actor.phase=="burst": painted_frame=4+int(actor.phase_remaining<0.17)
		elif pose==5:
			painted_frame=6 if release_remaining>0.06 else 7
			if identity=="root" and actor.phase=="recovery": painted_frame=6+int(actor.phase_remaining<0.4)
		if release_remaining>0: painted_frame=clampi(4+int((0.24-release_remaining)/0.06),4,7)
		var shape: CollisionShape2D=actor.get_node("CollisionShape2D")
		var feet: float=shape.position.y+shape.shape.size.y*0.5
		set_meta("heated",heated)
		atlas.show(self,library,painted_frame,float(HEIGHTS[identity]),feet,-1.0 if face_left else 1.0,float(atlas.DATA[library].boxes[0][3]),"root")
		# This actor can fall or be relocated by spawn support before rendering.
		# Store its local contact, not a stale absolute world floor.
		remove_meta("contact_floor")
		set_meta("contact_floor_local",feet)
		return
	texture = SHEET
	hframes = 6
	vframes = 4
	var collider: CollisionShape2D = get_parent().get_node("CollisionShape2D")
	position = Vector2(0,collider.position.y+collider.shape.size.y*0.5)
	scale = Vector2.ONE*float(HEIGHTS[identity])/224.0
	offset = Vector2(0,-112)
	frame = int(ROWS[identity]) * 6 + pose
	if CONTACT_ROWS.has(identity): offset.y = texture.get_height() / float(vframes) / 2 - CONTACT_ROWS[identity][pose]
	flip_h = face_left
