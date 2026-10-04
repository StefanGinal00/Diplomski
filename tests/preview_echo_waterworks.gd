extends "res://tests/preview_echo_guides.gd"
## Reuses the isolated-save GPU gallery and actual-room capture workflow.


func _guide_regions() -> Array:
	return ["tide", "causeway", "vault"]


func _instrument_kinds() -> Array:
	return ["valve", "anchor", "drain"]


func _capture_prefix() -> String:
	return "echo_waterworks"


func _room_cases() -> Array:
	var result: Array = []
	for room in [["TideWell", "echo_tide_well"], ["CrystalCauseway", "echo_causeway"], ["UndertowVault", "echo_vault"]]:
		for path in ["FieldDressing/FieldGuide", "FieldOperations/Control0", "FieldOperations/Control1"]:
			result.append([room[0], room[1], "LongTraversal/" + path])
	return result
