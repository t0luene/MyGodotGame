extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
var shader_material: ShaderMaterial

func _ready():
	# Make sure Sprite2D has Prop.tres assigned in the Inspector
	shader_material = sprite.material as ShaderMaterial
	
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player" and shader_material:
		shader_material.set_shader_parameter("outline_enabled", true)

func _on_body_exited(body):
	if body.name == "Player" and shader_material:
		shader_material.set_shader_parameter("outline_enabled", false)
