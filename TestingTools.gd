extends CanvasLayer
## F2 / clickable button. Exists only in a debug build, never persists flags.
var player: Player
var panel: PanelContainer
var launcher: Button
var status: Label
var toggles: Array[CheckButton] = []
var owns_pause := false
var clock := 0.0

func _ready() -> void:
	if not OS.is_debug_build(): queue_free(); return
	layer=80
	process_mode=Node.PROCESS_MODE_ALWAYS
	player=get_parent().get_node("Player")
	var frame := Control.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	launcher=Button.new()
	launcher.text="TEST [F2]"
	launcher.position=Vector2(12,190)
	launcher.add_theme_font_size_override("font_size",14)
	frame.add_child(launcher)
	launcher.pressed.connect(toggle)
	panel=PanelContainer.new()
	frame.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left=-225; panel.offset_top=-224
	panel.offset_right=225; panel.offset_bottom=224
	var style := StyleBoxFlat.new()
	style.bg_color=Color("0c1825")
	style.border_color=Color("55bdbe")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left=20; style.content_margin_right=20
	style.content_margin_top=16; style.content_margin_bottom=16
	panel.add_theme_stylebox_override("panel",style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	panel.add_child(column)
	var title := Label.new()
	title.text="TEST TOOLS / samo za testiranje"
	title.add_theme_font_size_override("font_size",19)
	column.add_child(title)
	for label in ["Beskonacan health", "Letenje", "Prolaz kroz zidove (uz letenje)"]:
		var check := CheckButton.new()
		check.text=label
		check.add_theme_font_size_override("font_size",16)
		column.add_child(check)
		toggles.append(check)
		check.toggled.connect(_changed)
	var help := Label.new()
	help.text="Let: WASD / strelice, Space gore, Shift brze.\nOpcije se ne cuvaju u save-u. F2 / Esc zatvara."
	help.add_theme_font_size_override("font_size",14)
	column.add_child(help)
	_button(column,"Vrati me na siguran pod",_recover)
	_button(column,"Dopuni health i manu",_restore)
	_button(column,"Iskljuci sve test opcije",_reset)
	status=Label.new()
	status.add_theme_font_size_override("font_size",13)
	column.add_child(status)
	_button(column,"Nastavi igru [F2]",toggle)
	panel.hide()

func _button(column: Node, label: String, action: Callable) -> void:
	var button := Button.new()
	button.text=label
	button.add_theme_font_size_override("font_size",15)
	column.add_child(button)
	button.pressed.connect(action)

func is_open() -> bool:
	return panel!=null and panel.visible

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode==KEY_F2 or (is_open() and event.keycode==KEY_ESCAPE)):
		get_viewport().set_input_as_handled()
		toggle()

func toggle() -> void:
	if is_open():
		panel.hide()
		if owns_pause: get_tree().paused=false
		owns_pause=false
		return
	var state := get_node("/root/GameState")
	var transition := get_node("/root/RoomTransition")
	if get_tree().paused or not state.session_started or player.is_dead or transition.is_transitioning: return
	if get_parent().get_node("UI")._hud_menu_blocked(): return
	panel.show()
	owns_pause=true
	get_tree().paused=true
	toggles[0].grab_focus()
	_update_status()

func _changed(_value: bool) -> void:
	# Noclip implies flight; disabling flight also disables noclip.
	if toggles[2].button_pressed and not player.test_noclip:
		toggles[1].set_pressed_no_signal(true)
	if not toggles[1].button_pressed: toggles[2].set_pressed_no_signal(false)
	player.test_invincible=toggles[0].button_pressed
	var leaving_noclip := player.test_noclip and not toggles[2].button_pressed
	player.set_test_flight(toggles[1].button_pressed,toggles[2].button_pressed)
	if leaving_noclip: _recover()
	_update_status()

func _recover() -> void:
	var recovery := get_parent().get_node("WorldFallRecovery")
	var ok: bool = recovery.recover()
	status.text="Vracen na siguran pod." if ok else "Nije nadjen bezbedan pod u ovoj prostoriji."

func _restore() -> void:
	if player.is_dead: return
	player.current_health=player.max_health
	player.current_mana=player.max_mana
	player.health_changed.emit(player.current_health,player.max_health)
	player.mana_changed.emit(player.current_mana,player.max_mana)
	status.text="Health i mana dopunjeni."

func _reset() -> void:
	var was_noclip := player.test_noclip
	for check in toggles: check.set_pressed_no_signal(false)
	player.test_invincible=false
	player.set_test_flight(false)
	if was_noclip: _recover()
	_update_status()

func _update_status() -> void:
	var state := get_node("/root/GameState")
	var origin: Vector2 = preload("res://WorldLayout.gd").ROOM_ORIGINS.get(state.current_room_id,[Vector2.ZERO,Vector2.ZERO])[1]
	status.text="%s | x %.0f, y %.0f"%[state.current_room_id,player.global_position.x-origin.x,player.global_position.y-origin.y]

func _process(delta: float) -> void:
	if launcher==null: return
	clock+=delta
	if clock<0.2: return
	clock=0
	launcher.visible=get_node("/root/GameState").session_started and not player.is_dead and (is_open() or not get_tree().paused)
	launcher.text="TEST [F2] *" if player.test_invincible or player.test_flight else "TEST [F2]"

func _exit_tree() -> void:
	if owns_pause and get_tree()!=null: get_tree().paused=false
