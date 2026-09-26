extends Area2D

signal interaction_requested(npc: Area2D)

@export_enum("shop", "anvil") var service_kind: String = "shop"
@export var service_id: String = "echo_haven_shop"
@export var service_name: String = "Quartermaster"
@export var service_color: Color = Color(0.46, 0.72, 0.66, 1.0)

var player_in_range: Player

@onready var sign_visual: Polygon2D = $Sign
@onready var name_label: Label = $NameLabel
@onready var prompt: Label = $InteractionPrompt


func _ready() -> void:
	sign_visual.color = service_color
	name_label.text = service_name
	$Goods.visible = service_kind == "shop"
	$Anvil.visible = service_kind == "anvil"
	$Hammer.visible = service_kind == "anvil"
	prompt.text = "[E] Forge" if service_kind == "anvil" else "[E] Trade"
	prompt.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	sign_visual.modulate.a = 0.82 + 0.18 * sin(Time.get_ticks_msec() * 0.003 + position.x)


func _unhandled_input(event: InputEvent) -> void:
	if player_in_range == null or event.is_echo() or not event.is_action_pressed("interact"):
		return
	interaction_requested.emit(self)
	get_viewport().set_input_as_handled()


func _on_body_entered(body: Node) -> void:
	if body is Player:
		player_in_range = body
		prompt.show()


func _on_body_exited(body: Node) -> void:
	if body == player_in_range:
		player_in_range = null
		prompt.hide()
