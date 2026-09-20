extends Node2D

@onready var central_glow: Polygon2D = $CentralGlow
@onready var crystal_glow: Polygon2D = $CrystalGlow
@onready var arena_glow: Polygon2D = $ArenaGlow


func _process(_delta: float) -> void:
	var time := Time.get_ticks_msec() * 0.001
	central_glow.modulate.a = 0.68 + sin(time * 0.8) * 0.16
	crystal_glow.modulate.a = 0.58 + sin(time * 2.1) * 0.23
	arena_glow.modulate.a = 0.53 + sin(time * 1.2 + 1.5) * 0.2
