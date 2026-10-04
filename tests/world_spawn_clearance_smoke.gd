extends "res://tests/audit_actor_obstructions.gd"
func _initialize() -> void:
	audit_save_path = "res://_tmp_world_spawn_clearance.json"
	call_deferred("_run")

func _done(report: Array) -> void:
	if report.is_empty():
		print("WORLD SPAWN CLEARANCE TEST PASSED: all mapped rooms, sentry feet and enemy/crate separation")
	else: push_error("World spawn overlaps: "+JSON.stringify(report))
	quit(0 if report.is_empty() else 1)
