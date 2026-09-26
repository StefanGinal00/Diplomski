extends "res://SluiceValve.gd"

var controller: Node
var station_index := 0


func activate(player: Player) -> bool:
	if player == null or player.is_dead or is_active or controller == null:
		return false
	return bool(controller.call("calibrate", station_index))


func set_calibrated(value: bool) -> void:
	is_active = value
	_update_visuals()
