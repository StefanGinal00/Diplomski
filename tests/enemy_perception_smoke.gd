extends "res://tests/pickup_motion_smoke.gd"
const Perception:=preload("res://EnemyPerception.gd")
var launches:=0

func _run() -> void:
	var state:=root.get_node("GameState")
	state.save_path="res://_tmp_enemy_perception.json"
	state.start_new_game("normal")
	player=_player()
	player.position=Vector2(260,0)
	player.get_node("Camera2D").enabled=false
	var ranged: StaticBody2D=load("res://RangedEnemy.tscn").instantiate()
	root.add_child(ranged)
	ranged.set_physics_process(false)
	ranged.shot_fired.connect(func(_aim): launches+=1)
	var wall:=_surface(Vector2(120,0),Vector2(12,160))
	for tick in 3: await physics_frame
	for tick in 100: ranged._physics_process(0.05)
	_check(launches==0 and ranged.shot_cooldown_remaining==0 and not ranged.has_clear_shot,"Cover did not block shots / kept recharging cooldown")
	wall.queue_free()
	for tick in 3: await physics_frame
	ranged._physics_process(0.05)
	_check(launches==0 and ranged.has_clear_shot and ranged.shot_cooldown_remaining>=0.34,"Cover exit skipped visible telegraph")
	for tick in 8: ranged._physics_process(0.05)
	_check(launches==1,"Shooter failed to engage at useful distance after full warning")
	ranged.suspend_room_combat()
	_check(not ranged.has_clear_shot and ranged.shot_cooldown_remaining>=0.6,"Room return replays stale attack")
	ranged.free()
	for shot in get_nodes_in_group("enemy_projectile"): shot.queue_free()
	var platform:=_surface(Vector2(0,25),Vector2(180,12))
	var stalker: CharacterBody2D=load("res://RootStalker.tscn").instantiate()
	stalker.patrol_radius=800
	stalker.position=Vector2.ZERO
	root.add_child(stalker)
	player.position=Vector2(500,0)
	for tick in 460: await physics_frame
	_check(absf(stalker.position.x)<90 and stalker.position.y<30,"Root patrol walked off its platform")
	stalker.set_physics_process(false)
	stalker.position=Vector2.ZERO
	player.position=Vector2(100,0)
	wall=_surface(Vector2(50,0),Vector2(10,80))
	for tick in 3: await physics_frame
	_check(not stalker._player_in_attack_range(),"Root attack acquires targets through terrain")
	var crawler: CharacterBody2D=load("res://ShaftCrawler.tscn").instantiate()
	crawler.position=Vector2(-30,0)
	root.add_child(crawler)
	crawler.patrol_speed=0
	crawler.attack_cooldown=10
	# Charge eligibility now requires real floor contact. Merely adding a
	# frozen body to the tree does not populate CharacterBody2D floor state.
	for tick in 30: await physics_frame
	_check(crawler.is_on_floor(),"Crawler perception fixture never reached its floor")
	crawler.set_physics_process(false)
	crawler.attack_cooldown=0
	for tick in 3: await physics_frame
	_check(not crawler._can_start_charge(),"Crawler starts charge through wall")
	wall.queue_free()
	for tick in 3: await physics_frame
	_check(stalker._player_in_attack_range() and crawler._can_start_charge(),"Perception blocks clear encounters")
	crawler.free();stalker.free();platform.free();player.free()
	state.delete_save()
	print("ENEMY PERCEPTION TEST PASSED" if failures.is_empty() else "ENEMY PERCEPTION TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
