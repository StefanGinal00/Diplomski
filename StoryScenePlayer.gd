extends CanvasLayer
## Illustrated interludes own only their own pause. No reward or quest mutation.
const Data = preload("res://StoryScenes.gd")
const CROSSFADE_SECONDS := 0.85
const CHARACTERS_PER_SECOND := 32.0
var overlay: Control
var outgoing: TextureRect
var illustration: TextureRect
var title_label: Label
var text_label: Label
var page_label: Label
var next_button: Button
var skip_button: Button
var auto_button: Button
var replay_list: VBoxContainer
var replay_scroll: ScrollContainer
var active_id := ""
var page := 0
var prior_pause := false
var prior_focus: Control
var auto_play := true
var page_elapsed := 0.0
var reveal_end := 0.0
var hold_seconds := 4.0
var narration_pages: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	overlay = Control.new()
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("080d15")
	overlay.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outgoing = TextureRect.new()
	outgoing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	outgoing.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	overlay.add_child(outgoing)
	outgoing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outgoing.anchor_bottom = 0.68
	illustration = TextureRect.new()
	illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	overlay.add_child(illustration)
	illustration.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	illustration.anchor_bottom = 0.68
	var band := ColorRect.new()
	band.color = Color("0c1723")
	overlay.add_child(band)
	band.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	band.anchor_top = 0.66
	title_label = _label(22, Color("f1ce8a"))
	text_label = _label(17, Color("e3eaf2"))
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page_label = _label(13, Color("99b8cd"))
	next_button = Button.new()
	next_button.text = "Continue"
	overlay.add_child(next_button)
	next_button.pressed.connect(advance)
	skip_button = Button.new()
	skip_button.text = "Skip scene [Esc]"
	overlay.add_child(skip_button)
	skip_button.pressed.connect(finish)
	auto_button = Button.new()
	auto_button.text = "Auto: On"
	auto_button.toggle_mode = true
	auto_button.button_pressed = true
	auto_button.toggled.connect(_set_auto)
	overlay.add_child(auto_button)
	replay_list = VBoxContainer.new()
	replay_list.add_theme_constant_override("separation", 12)
	replay_scroll = ScrollContainer.new()
	replay_scroll.follow_focus = true
	replay_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	overlay.add_child(replay_scroll)
	replay_scroll.add_child(replay_list)
	replay_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	get_viewport().size_changed.connect(_layout)
	_layout()
	overlay.hide()

func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	overlay.add_child(label)
	return label

func _layout() -> void:
	var bounds := get_viewport().get_visible_rect().size
	var margin := maxf(24.0, bounds.x * 0.05)
	var top := bounds.y * 0.68
	title_label.position = Vector2(margin, top)
	title_label.size = Vector2(bounds.x - margin * 2, 32)
	text_label.position = Vector2(margin, top + 35)
	text_label.size = Vector2(bounds.x - margin * 2, bounds.y - top - 100)
	page_label.position = Vector2(margin, bounds.y - 40)
	next_button.position = Vector2(bounds.x - margin - 170, bounds.y - 48)
	next_button.size = Vector2(170, 36)
	skip_button.position = Vector2(bounds.x - margin - 354, bounds.y - 48)
	skip_button.size = Vector2(170, 36)
	auto_button.position = Vector2(bounds.x - margin - 478, bounds.y - 48)
	auto_button.size = Vector2(110, 36)
	replay_scroll.position = Vector2(margin, 28)
	replay_scroll.size = Vector2(minf(640, bounds.x - margin * 2), top - 50)

func is_open() -> bool:
	return is_instance_valid(overlay) and overlay.visible

func _begin_modal() -> void:
	if is_open(): return
	prior_pause = get_tree().paused
	prior_focus = get_viewport().gui_get_focus_owner()
	get_tree().paused = true
	overlay.show()
	_set_reading_mix(true)

func _set_reading_mix(reading: bool) -> void:
	var music := get_node_or_null("../../AmbientSoundscape")
	if music != null and music.is_inside_tree(): music.set_story_reading(reading)

func _exit_tree() -> void:
	_set_reading_mix(false)

func play(id: String) -> bool:
	var state := get_node("/root/GameState")
	if not Data.unlocked(state, id) or (is_open() and not active_id.is_empty()): return false
	_begin_modal()
	active_id = id
	# Snapshot route-aware narration once; a replay cannot change midway through.
	narration_pages = Data.pages_for(state, id)
	page = 0
	replay_list.hide()
	replay_scroll.hide()
	illustration.show()
	next_button.show()
	auto_button.show()
	skip_button.text = "Skip scene [Esc]"
	_show_page()
	next_button.grab_focus()
	return true

func _show_page() -> void:
	var scene: Dictionary = Data.SCENES[active_id]
	outgoing.texture = illustration.texture
	outgoing.show()
	illustration.texture = load(scene.images[page])
	illustration.modulate.a = 0.0
	page_elapsed = 0.0
	title_label.text = scene.title
	text_label.text = narration_pages[page]
	text_label.visible_characters = 0
	text_label.modulate.a = 0.0
	reveal_end = CROSSFADE_SECONDS + text_label.get_total_character_count() / CHARACTERS_PER_SECOND
	hold_seconds = maxf(4.0, text_label.text.split(" ").size() * 0.18)
	page_label.text = "%d / %d" % [page + 1, scene.pages.size()]
	_update_next_caption()

func _set_auto(enabled: bool) -> void:
	auto_play = enabled
	auto_button.text = "Auto: On" if enabled else "Auto: Off"
	# Turning auto back on always leaves a full reading hold.
	if enabled and page_elapsed > reveal_end: page_elapsed = reveal_end

func _process(delta: float) -> void:
	_tick(delta)

func _tick(delta: float) -> void:
	if not is_open() or active_id.is_empty(): return
	page_elapsed += maxf(0.0, delta)
	illustration.modulate.a = smoothstep(0.0, CROSSFADE_SECONDS, page_elapsed)
	if page_elapsed >= CROSSFADE_SECONDS: outgoing.texture = null
	text_label.modulate.a = clampf((page_elapsed - CROSSFADE_SECONDS) / 0.3, 0.0, 1.0)
	text_label.visible_characters = mini(text_label.get_total_character_count(), int(maxf(0.0, page_elapsed - CROSSFADE_SECONDS) * CHARACTERS_PER_SECOND))
	if page_elapsed >= reveal_end: text_label.visible_characters = -1
	_update_next_caption()
	if auto_play and page_elapsed >= reveal_end + hold_seconds: _next_page()

func _update_next_caption() -> void:
	if page_elapsed < reveal_end:
		next_button.text = "Show text"
	else:
		next_button.text = "Return to the road" if page == Data.SCENES[active_id].pages.size() - 1 else "Continue"

func advance() -> void:
	if active_id.is_empty(): return
	if page_elapsed < reveal_end:
		page_elapsed = reveal_end
		_tick(0.0)
		return
	_next_page()

func _next_page() -> void:
	page += 1
	if page >= Data.SCENES[active_id].pages.size(): finish()
	else: _show_page()

func finish() -> void:
	if not is_open(): return
	if not active_id.is_empty(): get_node("/root/GameState").story_scenes_seen[active_id] = true
	active_id = ""
	narration_pages.clear()
	illustration.texture = null
	outgoing.texture = null
	page_elapsed = 0.0
	overlay.hide()
	_set_reading_mix(false)
	get_tree().paused = prior_pause
	if is_instance_valid(prior_focus) and prior_focus.is_visible_in_tree(): prior_focus.grab_focus()

func cancel() -> void:
	# Death, load or new game: interrupted scenes are not acknowledged.
	active_id = ""
	finish()

func open_library() -> void:
	_begin_modal()
	active_id = ""
	outgoing.texture = null
	illustration.texture = null
	outgoing.hide()
	illustration.hide()
	next_button.hide()
	auto_button.hide()
	title_label.text = "Scenes from the Road"
	text_label.text = "Unlocked scenes can be replayed without changing quests or rewards. Viewed and skipped scenes are saved at your next lamp."
	text_label.visible_characters = -1
	text_label.modulate.a = 1.0
	page_label.text = "STORY LIBRARY"
	skip_button.text = "Close [Esc]"
	for child in replay_list.get_children():
		replay_list.remove_child(child)
		child.queue_free()
	for id in Data.ORDER:
		var button := Button.new()
		var available := Data.unlocked(get_node("/root/GameState"), id)
		button.text = Data.SCENES[id].title if available else "Unreached chapter"
		button.disabled = not available
		button.custom_minimum_size.y = 42
		button.pressed.connect(play.bind(id))
		replay_list.add_child(button)
	replay_list.show()
	replay_scroll.show()
	replay_scroll.scroll_vertical = 0
	skip_button.grab_focus()

func _input(event: InputEvent) -> void:
	if not is_open() or event.is_echo(): return
	if event.is_action_pressed("ui_cancel"):
		finish()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("quest_log") or event.is_action_pressed("inventory") or event.is_action_pressed("skills_menu") or event.is_action_pressed("world_map"):
		get_viewport().set_input_as_handled()
