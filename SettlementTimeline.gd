extends Node2D

@export var changed_at_stage: int = 3
@export var changed_subtitle: String = ""
@export var changed_market_sign: String = ""
@export var changed_glow_color: Color = Color.WHITE
@export var glow_path: NodePath

@onready var subtitle: Label = $AreaSubtitle
@onready var market_sign: Label = $MarketSign

var glow: Polygon2D
var original_subtitle: String
var original_market_sign: String
var original_glow_color: Color


func _ready() -> void:
	glow = get_node_or_null(glow_path) as Polygon2D
	original_subtitle = subtitle.text
	original_market_sign = market_sign.text
	if glow != null:
		original_glow_color = glow.color
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.timeline_advanced.connect(_on_timeline_advanced)
		game_state.mode_changed.connect(_on_mode_changed)
	_refresh()


func _on_timeline_advanced(_stage: int, _room_id: String) -> void:
	_refresh()


func _on_mode_changed(_mode: String) -> void:
	_refresh()


func _refresh() -> void:
	var game_state := get_node_or_null("/root/GameState")
	var changed: bool = game_state != null and game_state.timeline_stage >= changed_at_stage
	subtitle.text = changed_subtitle if changed else original_subtitle
	market_sign.text = changed_market_sign if changed else original_market_sign
	if glow != null:
		glow.color = changed_glow_color if changed else original_glow_color
