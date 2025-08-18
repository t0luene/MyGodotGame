extends Node2D

signal inspected(box: Node)

@onready var sprite: Sprite2D = $Sprite2D
@onready var inspect_button: Button = $InspectButton  # <-- add this in scene
var shader_material: ShaderMaterial
var already_inspected := false

func _ready():
	shader_material = sprite.material as ShaderMaterial
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)
	print("Children of Box:", get_children())  # debug: see if InspectButton is actually here
	inspect_button = $InspectButton
	if inspect_button:
		inspect_button.visible = false
		inspect_button.pressed.connect(_on_inspect_pressed)
	else:
		push_error("InspectButton not found on Box node!")

func _on_body_entered(body):
	if body.name == "Player" and shader_material and not already_inspected:
		shader_material.set_shader_parameter("outline_enabled", true)
		inspect_button.visible = true

func _on_body_exited(body):
	if body.name == "Player" and shader_material and not already_inspected:
		shader_material.set_shader_parameter("outline_enabled", false)
		inspect_button.visible = false

func _on_inspect_pressed():
	if already_inspected:
		return
	already_inspected = true
	inspect_button.visible = false
	shader_material.set_shader_parameter("outline_enabled", false)
	emit_signal("inspected", self)
